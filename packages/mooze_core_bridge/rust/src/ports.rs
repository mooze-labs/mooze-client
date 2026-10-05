//! Native implementations of the mooze-core ports.
//!
//! - [`FileKv`]: one file per key in a directory.
//! - [`SystemClock`]: the operating system clock.
//! - [`TokioSpawner`]: runs blocking Electrum calls on tokio's blocking pool.
//! - [`runtime`]: the tokio runtime that drives every core future. reqwest
//!   and the Electrum spawner need a tokio context, which the
//!   flutter_rust_bridge executor does not provide.

use std::future::{ready, Future};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Arc, OnceLock};
use std::time::{SystemTime, UNIX_EPOCH};

use mooze_core::ports::{BlockingSpawner, Clock, KvStore, MaybeSend};
use mooze_core::{Error, Result};

/// Tokio runtime shared by every bridge call.
pub fn runtime() -> &'static tokio::runtime::Runtime {
    static RT: OnceLock<tokio::runtime::Runtime> = OnceLock::new();
    RT.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .thread_name("mooze-core")
            .enable_all()
            .build()
            .expect("tokio runtime")
    })
}

/// Runs `fut` on the shared runtime and waits for it from any executor.
pub async fn on_runtime<T, F>(fut: F) -> Result<T>
where
    T: Send + 'static,
    F: Future<Output = Result<T>> + Send + 'static,
{
    runtime().spawn(fut).await.map_err(|e| Error::Unexpected(format!("core task failed: {e}")))?
}

/// Installs ring as the process-wide rustls crypto provider.
///
/// The dependency tree compiles both rustls backends (ring and aws-lc).
/// rustls then cannot pick a default, and a TLS client built without an
/// explicit provider panics. Call this before any TLS use. Later calls,
/// and calls after another provider was installed, do nothing.
pub fn install_crypto_provider() {
    let _ = rustls::crypto::ring::default_provider().install_default();
}

/// [`BlockingSpawner`] over tokio's blocking thread pool.
#[derive(Debug, Clone, Copy, Default)]
pub struct TokioSpawner;

impl BlockingSpawner for TokioSpawner {
    fn spawn_blocking(&self, task: Box<dyn FnOnce() + Send + 'static>) {
        runtime().spawn_blocking(task);
    }
}

/// [`Clock`] over the operating system clock.
#[derive(Debug, Clone, Copy, Default)]
pub struct SystemClock;

impl Clock for SystemClock {
    fn now_ms(&self) -> u64 {
        SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_millis() as u64).unwrap_or(0)
    }
}

/// [`KvStore`] that keeps one file per key in a directory.
///
/// File names are the keys with every byte outside `[A-Za-z0-9._-]`
/// written as `%XX`, so `/` in keys never creates subdirectories.
/// Writes go to a temporary file first, then a rename replaces the old
/// file. A crash therefore leaves either the old or the new value.
#[derive(Debug, Clone)]
pub struct FileKv {
    dir: Arc<PathBuf>,
}

/// Longest file name most file systems accept.
const MAX_FILE_NAME: usize = 255;
/// Suffix of temporary files. Never a valid encoded key, because `~` is encoded.
const TMP_SUFFIX: &str = "~tmp";

impl FileKv {
    /// Store in `dir`. Creates the directory if needed.
    pub fn open(dir: impl Into<PathBuf>) -> Result<Self> {
        let dir = dir.into();
        std::fs::create_dir_all(&dir).map_err(|e| Error::storage(format!("create {}: {e}", dir.display())))?;
        Ok(Self { dir: Arc::new(dir) })
    }

    /// Directory of the store.
    pub fn dir(&self) -> &Path {
        &self.dir
    }

    fn path(&self, key: &str) -> Result<PathBuf> {
        let name = encode_key(key);
        if name.is_empty() || name.len() > MAX_FILE_NAME - TMP_SUFFIX.len() {
            return Err(Error::storage(format!("key length {} not supported", key.len())));
        }
        Ok(self.dir.join(name))
    }

    fn get_sync(&self, key: &str) -> Result<Option<Vec<u8>>> {
        match std::fs::read(self.path(key)?) {
            Ok(bytes) => Ok(Some(bytes)),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(e) => Err(Error::storage(format!("read {key}: {e}"))),
        }
    }

    fn put_sync(&self, key: &str, value: &[u8]) -> Result<()> {
        let path = self.path(key)?;
        let mut tmp = path.clone().into_os_string();
        tmp.push(TMP_SUFFIX);
        let tmp = PathBuf::from(tmp);
        let write = || -> std::io::Result<()> {
            let mut f = std::fs::File::create(&tmp)?;
            f.write_all(value)?;
            f.sync_all()?;
            std::fs::rename(&tmp, &path)
        };
        write().map_err(|e| Error::storage(format!("write {key}: {e}")))
    }

    fn delete_sync(&self, key: &str) -> Result<()> {
        match std::fs::remove_file(self.path(key)?) {
            Ok(()) => Ok(()),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(e) => Err(Error::storage(format!("delete {key}: {e}"))),
        }
    }

    fn list_sync(&self, prefix: &str) -> Result<Vec<String>> {
        let entries = std::fs::read_dir(self.dir.as_ref()).map_err(|e| Error::storage(format!("list: {e}")))?;
        let mut keys = Vec::new();
        for entry in entries {
            let entry = entry.map_err(|e| Error::storage(format!("list: {e}")))?;
            let Some(name) = entry.file_name().to_str().map(str::to_owned) else { continue };
            if name.ends_with(TMP_SUFFIX) {
                continue;
            }
            if let Some(key) = decode_key(&name) {
                if key.starts_with(prefix) {
                    keys.push(key);
                }
            }
        }
        keys.sort();
        Ok(keys)
    }
}

// The file operations are small and fast, so they run inline. The Electrum
// calls, which can block for seconds, go through `TokioSpawner` instead.
impl KvStore for FileKv {
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend {
        ready(self.get_sync(key))
    }

    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend {
        ready(self.put_sync(key, &value))
    }

    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend {
        ready(self.delete_sync(key))
    }

    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend {
        ready(self.list_sync(prefix))
    }
}

fn is_plain(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'.' | b'_' | b'-')
}

/// Encodes a key as a file name.
fn encode_key(key: &str) -> String {
    let mut out = String::with_capacity(key.len());
    for &b in key.as_bytes() {
        if is_plain(b) {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
    // "." and ".." are not usable file names.
    if out == "." || out == ".." {
        out = out.replace('.', "%2E");
    }
    out
}

/// Decodes a file name. `None` for names this store did not write.
fn decode_key(name: &str) -> Option<String> {
    let bytes = name.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'%' => {
                let hex = name.get(i + 1..i + 3)?;
                out.push(u8::from_str_radix(hex, 16).ok()?);
                i += 3;
            }
            b if is_plain(b) => {
                out.push(b);
                i += 1;
            }
            _ => return None,
        }
    }
    String::from_utf8(out).ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir(name: &str) -> PathBuf {
        let d = std::env::temp_dir().join(format!("mooze-ffi-test-{name}-{}", std::process::id()));
        std::fs::create_dir_all(&d).unwrap();
        d
    }

    #[test]
    fn key_encoding_roundtrip() {
        for key in ["tx/liquid/abc", "prefs/favorite_assets", "a b%c", "ç/ü", ".", "..", "mnemonic_mainWallet"] {
            let name = encode_key(key);
            assert!(!name.contains('/'), "{name}");
            assert_eq!(decode_key(&name).as_deref(), Some(key));
        }
        assert_eq!(decode_key("bad~name"), None);
    }

    #[test]
    fn file_kv_matches_the_kv_contract() {
        let kv = FileKv::open(temp_dir("contract")).unwrap();
        runtime().block_on(async {
            assert_eq!(kv.get("a/1").await.unwrap(), None);
            kv.put("a/1", b"x".to_vec()).await.unwrap();
            kv.put("a/2", b"y".to_vec()).await.unwrap();
            kv.put("b/1", b"z".to_vec()).await.unwrap();
            kv.put("a/1", b"x2".to_vec()).await.unwrap();
            assert_eq!(kv.get("a/1").await.unwrap(), Some(b"x2".to_vec()));
            assert_eq!(kv.list_keys("a/").await.unwrap(), vec!["a/1", "a/2"]);
            kv.delete("a/1").await.unwrap();
            kv.delete("a/1").await.unwrap();
            assert_eq!(kv.list_keys("").await.unwrap(), vec!["a/2", "b/1"]);
        });
    }

    #[test]
    fn leftover_temp_files_are_ignored() {
        let dir = temp_dir("tmp");
        std::fs::write(dir.join(format!("k{TMP_SUFFIX}")), b"partial").unwrap();
        let kv = FileKv::open(&dir).unwrap();
        assert!(runtime().block_on(kv.list_keys("")).unwrap().is_empty());
    }

    #[test]
    fn spawner_runs_blocking_work() {
        let v = runtime().block_on(mooze_core::ports::run_blocking(&TokioSpawner, || 40 + 2)).unwrap();
        assert_eq!(v, 42);
    }

    #[test]
    fn system_clock_is_after_2025() {
        assert!(SystemClock.now_ms() > 1_735_689_600_000);
    }
}
