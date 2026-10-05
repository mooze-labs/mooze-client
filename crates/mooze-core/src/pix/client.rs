//! HTTP client for the PIX backend endpoints.
//!
//! Both calls carry `Authorization: Bearer <jwt>`.

use std::future::Future;

use serde::Deserialize;

use crate::ports::{HttpClient, HttpMethod, HttpRequest, MaybeSend, MaybeSync};
use crate::{Error, Result};

use super::entities::{NewDepositRequest, PixDepositResponse, PixTransactionDetails};

/// Default backend base URL.
pub const DEFAULT_BACKEND_URL: &str = "https://api.mooze.app";

/// Supplies the API session JWT. Integration wires it to the auth module.
pub trait TokenProvider: MaybeSend + MaybeSync {
    /// Returns a valid bearer token, refreshing the session if needed.
    fn token(&self) -> impl Future<Output = Result<String>> + MaybeSend;
}

/// PIX backend client.
#[derive(Debug, Clone)]
pub struct PixClient<H: HttpClient, T: TokenProvider> {
    http: H,
    tokens: T,
    base_url: String,
}

#[derive(Deserialize)]
struct DataEnvelope<D> {
    data: D,
}

#[derive(Deserialize)]
struct OptionalListEnvelope {
    #[serde(default)]
    data: Option<Vec<PixTransactionDetails>>,
}

impl<H: HttpClient, T: TokenProvider> PixClient<H, T> {
    /// Client for `base_url` (no trailing slash needed).
    pub fn new(http: H, tokens: T, base_url: impl Into<String>) -> Self {
        let base_url = base_url.into().trim_end_matches('/').to_owned();
        Self { http, tokens, base_url }
    }

    /// Base URL in use.
    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    /// Builds the `POST /v2/transactions` request.
    pub fn create_deposit_request(&self, req: &NewDepositRequest, token: &str) -> Result<HttpRequest> {
        Ok(HttpRequest::json(HttpMethod::Post, format!("{}/v2/transactions", self.base_url), req)?
            .header("Authorization", format!("Bearer {token}")))
    }

    /// Builds the `GET /transactions/status?ids=..` request.
    ///
    /// The list repeats the key for each id: `ids=a&ids=b`.
    pub fn deposits_status_request(&self, ids: &[String], token: &str) -> HttpRequest {
        let mut url = format!("{}/transactions/status", self.base_url);
        for (i, id) in ids.iter().enumerate() {
            url.push(if i == 0 { '?' } else { '&' });
            url.push_str("ids=");
            url.push_str(&percent_encode(id));
        }
        HttpRequest::get(url).header("Authorization", format!("Bearer {token}"))
    }

    /// Creates a PIX deposit. Only status 200 counts as success.
    pub async fn create_deposit(&self, req: &NewDepositRequest) -> Result<PixDepositResponse> {
        let token = self.tokens.token().await?;
        let request = self.create_deposit_request(req, &token)?;
        let resp = self.http.send(request).await?;
        if resp.status != 200 {
            return Err(Error::Http { status: resp.status, body: resp.text() });
        }
        let env: DataEnvelope<PixDepositResponse> = serde_json::from_slice(&resp.body)?;
        Ok(env.data)
    }

    /// Fetches the backend status of deposits. Missing `data` means no items.
    pub async fn get_deposits_status(&self, ids: &[String]) -> Result<Vec<PixTransactionDetails>> {
        let token = self.tokens.token().await?;
        let resp = self.http.send(self.deposits_status_request(ids, &token)).await?;
        if resp.status != 200 {
            return Err(Error::Http { status: resp.status, body: resp.text() });
        }
        let env: OptionalListEnvelope = serde_json::from_slice(&resp.body)?;
        Ok(env.data.unwrap_or_default())
    }
}

/// User message for a failed deposit creation.
///
// NOTE: the core has one `Timeout` variant, so a connect timeout also gets the "too slow" text.
pub fn create_deposit_error_message(error: &Error) -> String {
    match error {
        Error::Network(_) => {
            "Não foi possível conectar ao servidor. Verifique sua conexão com a internet e tente novamente.".into()
        }
        Error::Timeout(_) => "O servidor demorou muito para responder. Tente novamente.".into(),
        // A 2xx status other than 200 gets the generic text.
        Error::Http { status, .. } if !(200..300).contains(status) => match status {
            400 => "Dados inválidos. Verifique o valor e tente novamente.".into(),
            401 => "Erro ao processar sua solicitação. Tente novamente.".into(),
            403 => "Você não tem permissão para realizar esta operação.".into(),
            404 => "Serviço não encontrado. Entre em contato com o suporte.".into(),
            500 | 502 | 503 | 504 => {
                "O servidor está temporariamente indisponível. Tente novamente em alguns instantes.".into()
            }
            other => format!("Erro {other}: Falha ao conectar com o servidor"),
        },
        _ => "Não foi possível processar sua solicitação. Verifique sua conexão e tente novamente.".into(),
    }
}

/// Percent-encodes a query value (RFC 3986 unreserved set kept).
fn percent_encode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for b in s.bytes() {
        if b.is_ascii_alphanumeric() || matches!(b, b'-' | b'_' | b'.' | b'~') {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
    out
}

#[cfg(all(test, not(target_arch = "wasm32")))]
pub(crate) mod tests {
    use super::*;
    use crate::testing::{block_on, MockHttp};
    use serde_json::json;
    use std::future::ready;

    /// Token provider that returns a fixed token.
    #[derive(Debug, Clone)]
    pub struct StaticToken(pub &'static str);

    impl TokenProvider for StaticToken {
        fn token(&self) -> impl Future<Output = Result<String>> + MaybeSend {
            ready(Ok(self.0.to_owned()))
        }
    }

    fn client(http: &MockHttp) -> PixClient<MockHttp, StaticToken> {
        PixClient::new(http.clone(), StaticToken("jwt-1"), "https://test/")
    }

    fn req(tax: Option<&str>) -> NewDepositRequest {
        NewDepositRequest {
            address: "lq1qqaddr".into(),
            amount_in_cents: 1000,
            asset: crate::domain::DEPIX_ASSET_ID.into(),
            network: "liquid".into(),
            tax_id_number: tax.map(Into::into),
        }
    }

    #[test]
    fn create_deposit_builds_request_and_parses() {
        let http = MockHttp::new();
        http.on_json(
            HttpMethod::Post,
            "https://test/v2/transactions",
            200,
            json!({"data": {"transaction_id": "dep-1", "qr_copy_paste": "qr-copy", "qr_image_url": "https://img"}}),
        );
        let c = client(&http);
        let resp = block_on(c.create_deposit(&req(Some("52998224725")))).unwrap();
        assert_eq!(resp.deposit_id, "dep-1");
        assert_eq!(resp.qr_copy_paste, "qr-copy");
        let sent = http.last_request().unwrap();
        assert_eq!(sent.headers["Authorization"], "Bearer jwt-1");
        let body: serde_json::Value = serde_json::from_slice(sent.body.as_ref().unwrap()).unwrap();
        assert_eq!(
            body,
            json!({"address": "lq1qqaddr", "amount_in_cents": 1000, "asset": crate::domain::DEPIX_ASSET_ID,
                   "network": "liquid", "tax_id": "52998224725"})
        );
    }

    #[test]
    fn create_deposit_errors() {
        let http = MockHttp::new();
        http.on_json(HttpMethod::Post, "https://test/v2/transactions", 400, json!({"error": "bad"}));
        let err = block_on(client(&http).create_deposit(&req(None))).unwrap_err();
        assert_eq!(create_deposit_error_message(&err), "Dados inválidos. Verifique o valor e tente novamente.");

        http.on_json(HttpMethod::Post, "https://test/v2/transactions", 201, json!({}));
        let err = block_on(client(&http).create_deposit(&req(None))).unwrap_err();
        assert!(create_deposit_error_message(&err).starts_with("Não foi possível processar"));

        assert!(create_deposit_error_message(&Error::Http { status: 418, body: String::new() }).starts_with("Erro 418"));
        assert!(create_deposit_error_message(&Error::Network("x".into())).starts_with("Não foi possível conectar"));
    }

    #[test]
    fn status_request_uses_multi_list_format() {
        let http = MockHttp::new();
        let c = client(&http);
        let r = c.deposits_status_request(&["a b".into(), "c".into()], "t");
        assert_eq!(r.url, "https://test/transactions/status?ids=a%20b&ids=c");
        assert_eq!(c.deposits_status_request(&[], "t").url, "https://test/transactions/status");
    }

    #[test]
    fn get_deposits_status_parses() {
        let http = MockHttp::new();
        http.on_json(
            HttpMethod::Get,
            "https://test/transactions/status?ids=dep-1",
            200,
            json!({"data": [{"id": "dep-1", "status": "depix_sent", "amount_in_cents": 1000,
                              "blockchain_txid": "ab12", "asset_amount": 980000}]}),
        );
        let list = block_on(client(&http).get_deposits_status(&["dep-1".into()])).unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].asset_amount, Some(980_000));

        http.on_json(HttpMethod::Get, "https://test/transactions/status?ids=x", 200, json!({}));
        assert!(block_on(client(&http).get_deposits_status(&["x".into()])).unwrap().is_empty());

        http.on_json(HttpMethod::Get, "https://test/transactions/status?ids=y", 500, json!({}));
        let err = block_on(client(&http).get_deposits_status(&["y".into()])).unwrap_err();
        assert!(matches!(err, Error::Http { status: 500, .. }));
    }
}
