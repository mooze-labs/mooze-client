fn main() {
    println!("cargo:rerun-if-env-changed=TAURI_CONFIG");
    let testnet = std::env::var_os("CARGO_FEATURE_TESTNET").is_some();
    let expected = if testnet {
        "app.mooze.desktop.testnet"
    } else {
        "app.mooze.desktop"
    };
    let overlay = std::env::var("TAURI_CONFIG").ok();
    if let Some(ref overlay) = overlay {
        let config: serde_json::Value =
            serde_json::from_str(overlay).expect("invalid TAURI_CONFIG");
        if let Some(id) = config.get("identifier").and_then(|v| v.as_str()) {
            assert_eq!(
                id, expected,
                "bundle identifier must match the testnet Cargo feature"
            );
        } else if testnet {
            panic!("testnet TAURI_CONFIG must include the testnet identifier");
        }
    } else if testnet {
        std::env::set_var("TAURI_CONFIG", include_str!("tauri.testnet.conf.json"));
    }
    if let Ok(config) = std::env::var("TAURI_CONFIG") {
        println!("cargo:rustc-env=TAURI_CONFIG={}", config.replace('\n', ""));
    }
    tauri_build::build()
}
