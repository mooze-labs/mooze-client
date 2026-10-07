//! One network per binary. Never infer the network from persisted wallet data.
use mooze_app::dto::NetworkDto;
use mooze_core::domain::AppNetwork;
pub const fn network_dto() -> NetworkDto {
    if cfg!(feature = "testnet") {
        NetworkDto::Testnet
    } else {
        NetworkDto::Mainnet
    }
}
pub fn app_network() -> AppNetwork {
    network_dto().into()
}
pub const fn name() -> &'static str {
    if cfg!(feature = "testnet") {
        "Testnet"
    } else {
        "Mainnet"
    }
}
pub const fn data_directory() -> &'static str {
    if cfg!(feature = "testnet") {
        "testnet"
    } else {
        "mainnet"
    }
}
pub const fn credential_service() -> &'static str {
    if cfg!(feature = "testnet") {
        "app.mooze.desktop.testnet"
    } else {
        "app.mooze.desktop"
    }
}
pub const fn production_services_enabled() -> bool {
    !cfg!(feature = "testnet")
}
pub fn policy_asset() -> &'static str {
    if cfg!(feature = "testnet") {
        mooze_core::wallet::descriptors::LIQUID_TESTNET_POLICY_ASSET
    } else {
        mooze_core::domain::LBTC_ASSET_ID
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn storage_namespaces_match_build_and_preserve_legacy_testnet() {
        if cfg!(feature = "testnet") {
            assert_eq!(credential_service(), "app.mooze.desktop.testnet");
            assert_eq!(data_directory(), "testnet");
            assert!(!production_services_enabled());
        } else {
            assert_eq!(credential_service(), "app.mooze.desktop");
            assert_eq!(data_directory(), "mainnet");
            assert!(production_services_enabled());
        }
    }
}
