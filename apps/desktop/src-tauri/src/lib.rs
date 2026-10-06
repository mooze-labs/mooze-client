mod commands;
mod diagnostics;
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
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_single_instance::init(|app, _, _| {
            if let Some(w) = app.get_webview_window("main") {
                let _ = w.show();
                let _ = w.set_focus();
            }
        }))
        .setup(|app| {
            let root = app.path().app_data_dir()?;
            #[cfg(debug_assertions)]
            let profile = std::env::var("MOOZE_TESTNET_PROFILE").ok();
            #[cfg(debug_assertions)]
            let platform = if let Some(profile) = profile.as_deref() {
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.set_title("Mooze Testnet — isolated validation");
                }
                NativePlatform::open_debug_profile(root, profile)?
            } else {
                NativePlatform::open(root.join("testnet"))?
            };
            #[cfg(not(debug_assertions))]
            let platform = NativePlatform::open(root.join("testnet"))?;
            let state = WalletSession::new(platform, BackendDto::Electrum);
            let handle = app.handle().clone();
            state.set_emitter(std::sync::Arc::new(move |event| {
                let _ = handle.emit_to("main", "mooze://event", event);
            }));
            app.manage(state);
            let tick = app.handle().clone();
            runtime::runtime().spawn(async move {
                loop {
                    tokio::time::sleep(std::time::Duration::from_secs(1)).await;
                    tick.state::<WalletSession<NativePlatform>>().check_expiry();
                }
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::record_activity,
            commands::settings,
            commands::remove_wallet,
            commands::diagnostics,
            commands::export_diagnostics,
            commands::test_node,
            commands::save_node,
            commands::save_display,
            commands::set_lock_minutes,
            commands::begin_setup,
            commands::cancel_setup,
            commands::complete_setup,
            commands::reveal_recovery_phrase,
            commands::change_pin,
            commands::parse_payment_request,
            commands::receive_request,
            commands::fee_options,
            commands::host_info,
            commands::holdings,
            commands::approved_assets,
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
            if let tauri::WindowEvent::Focused(focused) = event {
                window
                    .app_handle()
                    .state::<WalletSession<NativePlatform>>()
                    .set_foreground(*focused);
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
                    handle
                        .state::<WalletSession<NativePlatform>>()
                        .check_expiry();
                });
            }
            _ => {}
        });
}
