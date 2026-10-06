//! Fails when `generated/` differs from what `cargo run --features codegen --bin codegen` writes.
#![cfg(feature = "codegen")]

use std::path::PathBuf;
use std::process::Command;

#[test]
fn generated_files_are_up_to_date() {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let out = temp_dir();
    let status = Command::new(env!("CARGO_BIN_EXE_codegen")).arg(&out).status().unwrap();
    assert!(status.success());
    // The binary is the single writer: no per-type ts-rs exports beside its files.
    let mut present: Vec<String> = std::fs::read_dir(root.join("generated"))
        .unwrap()
        .map(|e| e.unwrap().file_name().to_string_lossy().into_owned())
        .collect();
    present.sort();
    assert_eq!(present, vec!["client.ts", "types.ts"], "unexpected files in generated/");
    for name in ["types.ts", "client.ts"] {
        let want = std::fs::read_to_string(out.join(name)).unwrap();
        let have = std::fs::read_to_string(root.join("generated").join(name)).unwrap();
        assert_eq!(have, want, "{name} is stale: run `cargo run --features codegen --bin codegen`");
    }
}

fn temp_dir() -> PathBuf {
    let d = std::env::temp_dir().join(format!("mooze-app-codegen-{}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    d
}
