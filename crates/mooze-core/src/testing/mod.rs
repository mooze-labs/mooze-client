//! In-memory implementations of every port.
//!
//! Tests use them. Platforms can use them for previews and demos.
//! They never touch the network or the disk.

use std::collections::{BTreeMap, VecDeque};
use std::future::{ready, Future};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

use crate::ports::{
    BlockingSpawner, Clock, HttpClient, HttpMethod, HttpRequest, HttpResponse, KvStore, MaybeSend, SecureStore, WsConnection,
    WsConnector, WsMessage,
};
use crate::{Error, Result};

/// [`KvStore`] and [`SecureStore`] backed by a `BTreeMap`.
#[derive(Debug, Default, Clone)]
pub struct MemoryKv {
    inner: Arc<Mutex<BTreeMap<String, Vec<u8>>>>,
}

impl MemoryKv {
    /// Empty store.
    pub fn new() -> Self {
        Self::default()
    }

    /// Number of keys.
    pub fn len(&self) -> usize {
        self.inner.lock().expect("poisoned").len()
    }

    /// True if no keys.
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

impl KvStore for MemoryKv {
    fn get(&self, key: &str) -> impl Future<Output = Result<Option<Vec<u8>>>> + MaybeSend {
        ready(Ok(self.inner.lock().expect("poisoned").get(key).cloned()))
    }

    fn put(&self, key: &str, value: Vec<u8>) -> impl Future<Output = Result<()>> + MaybeSend {
        self.inner.lock().expect("poisoned").insert(key.to_owned(), value);
        ready(Ok(()))
    }

    fn delete(&self, key: &str) -> impl Future<Output = Result<()>> + MaybeSend {
        self.inner.lock().expect("poisoned").remove(key);
        ready(Ok(()))
    }

    fn list_keys(&self, prefix: &str) -> impl Future<Output = Result<Vec<String>>> + MaybeSend {
        let keys = self
            .inner
            .lock()
            .expect("poisoned")
            .range(prefix.to_owned()..)
            .take_while(|(k, _)| k.starts_with(prefix))
            .map(|(k, _)| k.clone())
            .collect();
        ready(Ok(keys))
    }
}

impl SecureStore for MemoryKv {}

/// [`Clock`] that returns a settable time.
#[derive(Debug, Default)]
pub struct FixedClock {
    now: AtomicU64,
}

impl FixedClock {
    /// Clock fixed at `now_ms`.
    pub fn new(now_ms: u64) -> Self {
        Self { now: AtomicU64::new(now_ms) }
    }

    /// Moves the clock forward.
    pub fn advance(&self, ms: u64) {
        self.now.fetch_add(ms, Ordering::SeqCst);
    }

    /// Sets the clock.
    pub fn set(&self, now_ms: u64) {
        self.now.store(now_ms, Ordering::SeqCst);
    }
}

impl Clock for FixedClock {
    fn now_ms(&self) -> u64 {
        self.now.load(Ordering::SeqCst)
    }
}

#[derive(Debug, Clone)]
struct Route {
    method: HttpMethod,
    url: String,
    prefix: bool,
    response: Result<HttpResponse>,
    once: bool,
}

/// [`HttpClient`] that answers from registered routes and records requests.
///
/// Later routes win over earlier routes. Unmatched requests get a 404.
#[derive(Debug, Default, Clone)]
pub struct MockHttp {
    routes: Arc<Mutex<Vec<Route>>>,
    requests: Arc<Mutex<Vec<HttpRequest>>>,
}

impl MockHttp {
    /// No routes.
    pub fn new() -> Self {
        Self::default()
    }

    fn add(&self, method: HttpMethod, url: &str, prefix: bool, response: Result<HttpResponse>, once: bool) {
        self.routes.lock().expect("poisoned").push(Route { method, url: url.to_owned(), prefix, response, once });
    }

    /// Answers `method url` (exact match) with `status` and a JSON body.
    pub fn on_json(&self, method: HttpMethod, url: &str, status: u16, body: serde_json::Value) {
        self.add(method, url, false, Ok(json_response(status, &body)), false);
    }

    /// Answers every URL that starts with `prefix`.
    pub fn on_prefix_json(&self, method: HttpMethod, prefix: &str, status: u16, body: serde_json::Value) {
        self.add(method, prefix, true, Ok(json_response(status, &body)), false);
    }

    /// Answers `method url` once with a raw body.
    pub fn once_raw(&self, method: HttpMethod, url: &str, status: u16, body: &str) {
        let resp = HttpResponse { status, headers: BTreeMap::new(), body: body.as_bytes().to_vec() };
        self.add(method, url, false, Ok(resp), true);
    }

    /// Answers `method url` once with `status` and a JSON body.
    pub fn once_json(&self, method: HttpMethod, url: &str, status: u16, body: serde_json::Value) {
        self.add(method, url, false, Ok(json_response(status, &body)), true);
    }

    /// Fails `method url` with a transport error.
    pub fn on_error(&self, method: HttpMethod, url: &str, error: Error) {
        self.add(method, url, false, Err(error), false);
    }

    /// Every request sent so far.
    pub fn requests(&self) -> Vec<HttpRequest> {
        self.requests.lock().expect("poisoned").clone()
    }

    /// Last request sent.
    pub fn last_request(&self) -> Option<HttpRequest> {
        self.requests.lock().expect("poisoned").last().cloned()
    }
}

/// Builds a JSON response.
pub fn json_response(status: u16, body: &serde_json::Value) -> HttpResponse {
    let mut headers = BTreeMap::new();
    headers.insert("content-type".to_owned(), "application/json".to_owned());
    HttpResponse { status, headers, body: serde_json::to_vec(body).expect("json") }
}

impl HttpClient for MockHttp {
    fn send(&self, request: HttpRequest) -> impl Future<Output = Result<HttpResponse>> + MaybeSend {
        self.requests.lock().expect("poisoned").push(request.clone());
        let mut routes = self.routes.lock().expect("poisoned");
        let hit = routes.iter().rposition(|r| {
            r.method == request.method
                && if r.prefix { request.url.starts_with(&r.url) } else { request.url == r.url }
        });
        let result = match hit {
            Some(i) if routes[i].once => routes.remove(i).response,
            Some(i) => routes[i].response.clone(),
            None => Ok(HttpResponse {
                status: 404,
                headers: BTreeMap::new(),
                body: format!("no mock for {} {}", request.method.as_str(), request.url).into_bytes(),
            }),
        };
        ready(result)
    }
}

/// Reply function for [`MockWs`]: gets each sent frame, returns frames to queue.
pub type WsResponder = Arc<dyn Fn(&str) -> Vec<String> + Send + Sync>;

/// [`WsConnector`] whose connections answer through a responder function.
#[derive(Clone)]
pub struct MockWs {
    responder: WsResponder,
    preload: Vec<String>,
    sent: Arc<Mutex<Vec<String>>>,
}

impl std::fmt::Debug for MockWs {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("MockWs").field("preload", &self.preload).finish_non_exhaustive()
    }
}

impl MockWs {
    /// Connector with a responder.
    pub fn new(responder: impl Fn(&str) -> Vec<String> + Send + Sync + 'static) -> Self {
        Self { responder: Arc::new(responder), preload: Vec::new(), sent: Arc::default() }
    }

    /// Frames every new connection receives before any send.
    pub fn with_preload(mut self, frames: Vec<String>) -> Self {
        self.preload = frames;
        self
    }

    /// Every frame sent on any connection.
    pub fn sent(&self) -> Vec<String> {
        self.sent.lock().expect("poisoned").clone()
    }
}

/// Connection made by [`MockWs`].
pub struct MockWsConnection {
    responder: WsResponder,
    inbox: VecDeque<String>,
    sent: Arc<Mutex<Vec<String>>>,
    closed: bool,
}

impl WsConnector for MockWs {
    type Connection = MockWsConnection;

    fn connect(&self, _url: &str) -> impl Future<Output = Result<Self::Connection>> + MaybeSend {
        ready(Ok(MockWsConnection {
            responder: self.responder.clone(),
            inbox: self.preload.iter().cloned().collect(),
            sent: self.sent.clone(),
            closed: false,
        }))
    }
}

impl WsConnection for MockWsConnection {
    fn send_text(&mut self, text: String) -> impl Future<Output = Result<()>> + MaybeSend {
        let result = if self.closed {
            Err(Error::Network("closed".into()))
        } else {
            self.inbox.extend((self.responder)(&text));
            self.sent.lock().expect("poisoned").push(text);
            Ok(())
        };
        ready(result)
    }

    fn recv(&mut self) -> impl Future<Output = Result<WsMessage>> + MaybeSend {
        let msg = match self.inbox.pop_front() {
            Some(t) if !self.closed => WsMessage::Text(t),
            _ => WsMessage::Closed,
        };
        ready(Ok(msg))
    }

    fn close(&mut self) -> impl Future<Output = Result<()>> + MaybeSend {
        self.closed = true;
        ready(Ok(()))
    }
}

/// Runs a future to completion on the current thread. Test helper.
#[cfg(not(target_arch = "wasm32"))]
pub fn block_on<F: Future>(f: F) -> F::Output {
    futures::executor::block_on(f)
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod tests {
    use super::*;

    #[test]
    fn memory_kv_prefix() {
        let kv = MemoryKv::new();
        block_on(async {
            kv.put("a/1", b"x".to_vec()).await.unwrap();
            kv.put("a/2", b"y".to_vec()).await.unwrap();
            kv.put("b/1", b"z".to_vec()).await.unwrap();
            assert_eq!(kv.list_keys("a/").await.unwrap(), vec!["a/1", "a/2"]);
            kv.delete("a/1").await.unwrap();
            assert_eq!(kv.get("a/1").await.unwrap(), None);
        });
    }

    #[test]
    fn mock_http_once_then_fallback() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Get, "https://x/y", 200, serde_json::json!({"a":1}));
        http.once_json(HttpMethod::Get, "https://x/y", 500, serde_json::json!({}));
        block_on(async {
            assert_eq!(http.send(HttpRequest::get("https://x/y")).await.unwrap().status, 500);
            assert_eq!(http.send(HttpRequest::get("https://x/y")).await.unwrap().status, 200);
            assert_eq!(http.send(HttpRequest::get("https://x/z")).await.unwrap().status, 404);
        });
        assert_eq!(http.requests().len(), 3);
    }
}

/// [`BlockingSpawner`] that runs each task at once on the calling thread.
///
/// Tests use it. It blocks the caller, so real platforms must not.
#[derive(Debug, Default, Clone, Copy)]
pub struct InlineSpawner;

impl BlockingSpawner for InlineSpawner {
    fn spawn_blocking(&self, task: Box<dyn FnOnce() + Send + 'static>) {
        task();
    }
}

/// [`BlockingSpawner`] that drops every task. Tests the shutdown path.
#[derive(Debug, Default, Clone, Copy)]
pub struct DroppingSpawner;

impl BlockingSpawner for DroppingSpawner {
    fn spawn_blocking(&self, task: Box<dyn FnOnce() + Send + 'static>) {
        drop(task);
    }
}

#[cfg(all(test, not(target_arch = "wasm32")))]
mod blocking_tests {
    use super::*;
    use crate::ports::run_blocking;

    #[test]
    fn run_blocking_returns_result() {
        let v = block_on(run_blocking(&InlineSpawner, || 6 * 7)).unwrap();
        assert_eq!(v, 42);
    }

    #[test]
    fn dropped_task_is_an_error() {
        let r = block_on(run_blocking(&DroppingSpawner, || 1));
        assert!(matches!(r, Err(Error::Unexpected(_))));
    }
}
