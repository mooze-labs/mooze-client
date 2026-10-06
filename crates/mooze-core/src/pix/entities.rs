//! PIX entities. Serde names match the backend JSON and the Dart models.

use serde::{Deserialize, Deserializer, Serialize, Serializer};

use crate::domain::Asset;

use super::tax_id::format_cpf_cnpj;

/// Status of a PIX deposit. Port of the Dart `DepositStatus` enum.
///
/// Serializes to the API string (`under_review`). Unknown strings parse to
/// [`DepositStatus::Unknown`], as in Dart `DepositStatus.fromString`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum DepositStatus {
    Pending,
    UnderReview,
    Processing,
    FundsPrepared,
    DepixSent,
    Paid,
    Broadcasted,
    Finished,
    Completed,
    Failed,
    Expired,
    Refunded,
    Med,
    ProcessingRefund,
    BroadcastedRefund,
    FinishedRefund,
    Timeout,
    Unknown,
}

impl DepositStatus {
    /// Every status, in Dart declaration order.
    pub const ALL: [DepositStatus; 18] = [
        DepositStatus::Pending,
        DepositStatus::UnderReview,
        DepositStatus::Processing,
        DepositStatus::FundsPrepared,
        DepositStatus::DepixSent,
        DepositStatus::Paid,
        DepositStatus::Broadcasted,
        DepositStatus::Finished,
        DepositStatus::Completed,
        DepositStatus::Failed,
        DepositStatus::Expired,
        DepositStatus::Refunded,
        DepositStatus::Med,
        DepositStatus::ProcessingRefund,
        DepositStatus::BroadcastedRefund,
        DepositStatus::FinishedRefund,
        DepositStatus::Timeout,
        DepositStatus::Unknown,
    ];

    /// Parses an API string. Unknown strings return [`DepositStatus::Unknown`].
    pub fn from_api_str(status: &str) -> Self {
        match status {
            "pending" => Self::Pending,
            "under_review" => Self::UnderReview,
            "processing" => Self::Processing,
            "funds_prepared" => Self::FundsPrepared,
            "depix_sent" => Self::DepixSent,
            "paid" => Self::Paid,
            "broadcasted" => Self::Broadcasted,
            "finished" => Self::Finished,
            "completed" => Self::Completed,
            "failed" => Self::Failed,
            "expired" => Self::Expired,
            "refunded" => Self::Refunded,
            "med" => Self::Med,
            "processing_refund" => Self::ProcessingRefund,
            "broadcasted_refund" => Self::BroadcastedRefund,
            "finished_refund" => Self::FinishedRefund,
            "timeout" => Self::Timeout,
            _ => Self::Unknown,
        }
    }

    /// API string (Dart `toApiString`).
    pub fn as_api_str(self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::UnderReview => "under_review",
            Self::Processing => "processing",
            Self::FundsPrepared => "funds_prepared",
            Self::DepixSent => "depix_sent",
            Self::Paid => "paid",
            Self::Broadcasted => "broadcasted",
            Self::Finished => "finished",
            Self::Completed => "completed",
            Self::Failed => "failed",
            Self::Expired => "expired",
            Self::Refunded => "refunded",
            Self::Med => "med",
            Self::ProcessingRefund => "processing_refund",
            Self::BroadcastedRefund => "broadcasted_refund",
            Self::FinishedRefund => "finished_refund",
            Self::Timeout => "timeout",
            Self::Unknown => "unknown",
        }
    }

    /// Dart enum name (`underReview`). The history filter compares this name.
    pub fn dart_name(self) -> &'static str {
        match self {
            Self::Pending => "pending",
            Self::UnderReview => "underReview",
            Self::Processing => "processing",
            Self::FundsPrepared => "fundsPrepared",
            Self::DepixSent => "depixSent",
            Self::Paid => "paid",
            Self::Broadcasted => "broadcasted",
            Self::Finished => "finished",
            Self::Completed => "completed",
            Self::Failed => "failed",
            Self::Expired => "expired",
            Self::Refunded => "refunded",
            Self::Med => "med",
            Self::ProcessingRefund => "processingRefund",
            Self::BroadcastedRefund => "broadcastedRefund",
            Self::FinishedRefund => "finishedRefund",
            Self::Timeout => "timeout",
            Self::Unknown => "unknown",
        }
    }
}

impl Serialize for DepositStatus {
    fn serialize<S: Serializer>(&self, s: S) -> std::result::Result<S::Ok, S::Error> {
        s.serialize_str(self.as_api_str())
    }
}

impl<'de> Deserialize<'de> for DepositStatus {
    fn deserialize<D: Deserializer<'de>>(d: D) -> std::result::Result<Self, D::Error> {
        let s = String::deserialize(d)?;
        Ok(Self::from_api_str(&s))
    }
}

/// Body of `POST /v2/transactions`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct NewDepositRequest {
    /// Liquid address that receives the asset.
    pub address: String,
    /// Deposit amount in BRL cents.
    pub amount_in_cents: u64,
    /// Asset id (Liquid asset hash).
    pub asset: String,
    /// Network name. The app always sends `liquid`.
    pub network: String,
    /// Payer CPF/CNPJ digits. Omitted when absent.
    #[serde(rename = "tax_id", skip_serializing_if = "Option::is_none", default)]
    pub tax_id_number: Option<String>,
}

/// `data` object of the create-deposit response.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PixDepositResponse {
    /// Backend deposit id.
    #[serde(rename = "transaction_id")]
    pub deposit_id: String,
    /// PIX "copia e cola" payload.
    pub qr_copy_paste: String,
    /// URL of the QR image.
    pub qr_image_url: String,
}

/// One item of `GET /transactions/status`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PixTransactionDetails {
    /// Backend deposit id.
    pub id: String,
    /// Raw API status string.
    pub status: String,
    /// Deposit amount in BRL cents.
    pub amount_in_cents: u64,
    /// Liquid txid that paid the asset.
    #[serde(default)]
    pub blockchain_txid: Option<String>,
    /// Asset amount sent, in base units.
    #[serde(default)]
    pub asset_amount: Option<u64>,
}

/// Status change of one deposit. Port of the Dart `PixStatusEvent`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PixStatusEvent {
    /// Backend deposit id.
    #[serde(rename = "transaction_id")]
    pub deposit_id: String,
    /// New status.
    pub status: DepositStatus,
    /// Liquid txid, if known.
    #[serde(default)]
    pub blockchain_txid: Option<String>,
    /// Asset amount in base units, if known.
    #[serde(default)]
    pub asset_amount: Option<u64>,
    /// Backend error text, if any.
    #[serde(default)]
    pub error_message: Option<String>,
}

impl PixStatusEvent {
    /// Event with only an id and a status.
    pub fn new(deposit_id: impl Into<String>, status: DepositStatus) -> Self {
        Self {
            deposit_id: deposit_id.into(),
            status,
            blockchain_txid: None,
            asset_amount: None,
            error_message: None,
        }
    }
}

/// A PIX deposit as the app shows it. Port of the Dart `PixDeposit`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PixDeposit {
    /// Backend deposit id.
    pub deposit_id: String,
    /// PIX "copia e cola" payload.
    pub pix_key: String,
    /// Asset the user receives.
    pub asset: Asset,
    /// Deposit amount in BRL cents.
    pub amount_in_cents: u64,
    /// Network name.
    pub network: String,
    /// Current status.
    pub status: DepositStatus,
    /// Creation time, ms since the Unix epoch.
    pub created_at_ms: u64,
    /// Liquid txid, if known.
    pub blockchain_txid: Option<String>,
    /// Asset amount in base units, if known.
    pub asset_amount: Option<u64>,
}

/// Quote breakdown for a deposit. Port of the Dart `PaymentDetails`.
#[derive(Debug, Clone, PartialEq)]
pub struct PaymentDetails {
    /// Deposit amount in BRL.
    pub deposit_amount: f64,
    /// Asset price in BRL.
    pub quote: f64,
    /// Asset amount in base units.
    pub asset_amount: u64,
    /// Fee in BRL.
    pub fee: f64,
}

/// Quote inside a PIX send request. JSON keys are camelCase (freezed).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PixPaymentQuote {
    /// Satoshis to pay.
    pub satoshis: u64,
    /// BTC price in BRL.
    pub btc_to_brl_rate: f64,
    /// Amount in BRL cents.
    pub brl_amount: u64,
}

/// Server answer to a PIX send request.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PixPaymentRequest {
    /// True if the server accepted the request.
    pub success: bool,
    /// Invoice the wallet pays.
    pub invoice: String,
    /// Value in satoshis.
    pub value_in_satoshis: u64,
    /// PIX key of the payee.
    pub pix_key: String,
    /// PIX QR payload.
    pub qr_code: String,
    /// Value in BRL cents.
    pub value_in_brl: u64,
    /// Fee in BRL cents.
    pub fee: u64,
    /// Quote used.
    pub quote: PixPaymentQuote,
}

/// Status of a PIX withdrawal (send).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct WithdrawStatus {
    /// `pending`, `processing`, `completed` or `failed`.
    pub status: String,
    /// Withdrawal id.
    pub withdraw_id: String,
    /// Payment txid, if any.
    #[serde(default)]
    pub txid: Option<String>,
    /// Error text, if any.
    #[serde(default)]
    pub error_message: Option<String>,
    /// ISO-8601 completion time, if any.
    #[serde(default)]
    pub completed_at: Option<String>,
}

/// A confirmed PIX send.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PixPayment {
    /// Withdrawal id.
    pub withdraw_id: String,
    /// Invoice paid.
    pub invoice: String,
    /// Value in BRL cents.
    pub value_in_brl: u64,
    /// Value in satoshis.
    pub value_in_satoshis: u64,
    /// PIX key of the payee.
    pub pix_key: String,
    /// Fee in BRL cents.
    pub fee: u64,
    /// Quote used.
    pub quote: PixPaymentQuote,
    /// ISO-8601 creation time.
    pub created_at: String,
}

/// A saved payer CPF/CNPJ. Port of the Dart `FavoritePayer`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FavoritePayer {
    /// Store id. `None` for a payer not saved yet.
    pub id: Option<u64>,
    /// User label.
    pub label: String,
    /// Unmasked taxpayer digits: CPF (11) or CNPJ (14).
    pub cpf: String,
}

impl FavoritePayer {
    /// CPF/CNPJ formatted for display.
    pub fn masked_cpf(&self) -> String {
        format_cpf_cnpj(&self.cpf)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn status_roundtrip_and_unknown() {
        for s in DepositStatus::ALL {
            if s != DepositStatus::Unknown {
                assert_eq!(DepositStatus::from_api_str(s.as_api_str()), s);
            }
        }
        assert_eq!(DepositStatus::from_api_str("weird"), DepositStatus::Unknown);
        let s: DepositStatus = serde_json::from_value(json!("processing_refund")).unwrap();
        assert_eq!(s, DepositStatus::ProcessingRefund);
        assert_eq!(
            serde_json::to_value(DepositStatus::UnderReview).unwrap(),
            json!("under_review")
        );
        assert_eq!(DepositStatus::FundsPrepared.dart_name(), "fundsPrepared");
    }

    #[test]
    fn status_event_from_json() {
        let e: PixStatusEvent = serde_json::from_value(json!({
            "transaction_id": "dep-1", "status": "depix_sent",
            "blockchain_txid": "ab", "asset_amount": 5000000
        }))
        .unwrap();
        assert_eq!(e.status, DepositStatus::DepixSent);
        assert_eq!(e.asset_amount, Some(5_000_000));
        assert_eq!(e.error_message, None);
    }

    #[test]
    fn new_deposit_request_omits_tax_id() {
        let mut r = NewDepositRequest {
            address: "lq1".into(),
            amount_in_cents: 1000,
            asset: "aa".into(),
            network: "liquid".into(),
            tax_id_number: None,
        };
        let v = serde_json::to_value(&r).unwrap();
        assert!(v.get("tax_id").is_none());
        r.tax_id_number = Some("52998224725".into());
        assert_eq!(
            serde_json::to_value(&r).unwrap()["tax_id"],
            json!("52998224725")
        );
    }

    #[test]
    fn send_entities_camel_case() {
        let req: PixPaymentRequest = serde_json::from_value(json!({
            "success": true, "invoice": "lnbc1", "valueInSatoshis": 15000,
            "pixKey": "k", "qrCode": "q", "valueInBrl": 1000, "fee": 50,
            "quote": {"satoshis": 15000, "btcToBrlRate": 650000.0, "brlAmount": 1000}
        }))
        .unwrap();
        assert_eq!(req.quote.btc_to_brl_rate, 650000.0);
        let w: WithdrawStatus =
            serde_json::from_value(json!({"status": "processing", "withdrawId": "w1"})).unwrap();
        assert_eq!(w.txid, None);
    }

    #[test]
    fn masked_cpf() {
        let p = FavoritePayer {
            id: None,
            label: "a".into(),
            cpf: "52998224725".into(),
        };
        assert_eq!(p.masked_cpf(), "529.982.247-25");
    }
}
