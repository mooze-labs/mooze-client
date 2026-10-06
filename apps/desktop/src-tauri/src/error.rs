use serde::Serialize;
#[derive(Debug, Clone, Serialize)]
pub struct DesktopError {
    pub code: String,
    pub message: String,
    pub details: Option<String>,
}
pub type Result<T> = std::result::Result<T, DesktopError>;
impl DesktopError {
    pub fn new(code: &str, message: &str) -> Self {
        Self {
            code: code.into(),
            message: message.into(),
            details: None,
        }
    }
}
impl From<mooze_core::Error> for DesktopError {
    fn from(e: mooze_core::Error) -> Self {
        mooze_app::AppError::from(e).into()
    }
}
impl From<mooze_app::AppError> for DesktopError {
    fn from(e: mooze_app::AppError) -> Self {
        let code = match e.details.as_deref() {
            Some("insufficient_fee_asset") => "insufficient_fee_asset",
            Some("fee_changed") => "fee_changed",
            Some("amount_changed") => "amount_changed",
            Some("submission_unknown") => "submission_unknown",
            _ => match e.code {
                mooze_app::ErrorCode::Storage | mooze_app::ErrorCode::Credential => "storage",
                mooze_app::ErrorCode::InvalidInput => "invalid_input",
                _ => "service",
            },
        };
        Self{code:code.into(),message:match code{"insufficient_fee_asset"=>"Saldo de L-BTC insuficiente para a taxa. Receba L-BTC para enviar este ativo.","amount_changed"=>"O valor disponível mudou. Revise novamente.","fee_changed"=>"A taxa mudou. Revise novamente.","submission_unknown"=>"O envio pode ter sido transmitido. Atualize o histórico antes de tentar novamente.","storage"=>"Não foi possível acessar o armazenamento seguro.",_=>"Não foi possível concluir a operação. Verifique os dados e a conexão."}.into(),details:None}
    }
}
