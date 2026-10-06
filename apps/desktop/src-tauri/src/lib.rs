mod commands;
pub mod dto;
pub mod error;
pub mod platform;
#[path = "session/rules.rs"]
pub mod rules;
pub mod send_review;
pub mod session;
use mooze_app::dto::BackendDto;
use platform::{runtime, NativePlatform};
use session::WalletSession;
use tauri::{Emitter, Manager};
pub fn run() {
    runtime::install_crypto_provider();
    tauri::async_runtime::set(runtime::runtime().handle().clone());
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _, _| {
            if let Some(w) = app.get_webview_window("main") {
                let _ = w.show();
                let _ = w.set_focus();
            }
        }))
        .setup(|app| {
            let platform = NativePlatform::open(app.path().app_data_dir()?.join("testnet"))?;
            let state = WalletSession::new(platform, BackendDto::Electrum);
            let handle = app.handle().clone();
            state.set_emitter(std::sync::Arc::new(move |event| {
                let _ = handle.emit_to("main", "mooze://event", event);
            }));
            app.manage(state);
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::host_info,
            commands::session_status,
            commands::import_wallet,
            commands::unlock,
            commands::lock,
            commands::snapshot,
            commands::refresh,
            commands::receive_address,
            commands::review_send,
            commands::confirm_send,
            commands::acknowledge_submission
        ])
        .on_window_event(|window, event| {
            if matches!(event, tauri::WindowEvent::Focused(false)) {
                let handle = window.app_handle().clone();
                runtime::runtime().spawn(async move {
                    let state = handle.state::<WalletSession<NativePlatform>>();
                    let _ = state.lock().await;
                });
            }
        })
        .build(tauri::generate_context!())
        .expect("desktop startup failed")
        .run(|app, event| match event {
            tauri::RunEvent::Exit => {
                runtime::runtime().block_on(app.state::<WalletSession<NativePlatform>>().stop())
            }
            tauri::RunEvent::Resumed => {
                let handle = app.clone();
                runtime::runtime().spawn(async move {
                    let _ = handle.state::<WalletSession<NativePlatform>>().lock().await;
                });
            }
            _ => {}
        });
}
