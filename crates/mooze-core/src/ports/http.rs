use std::collections::BTreeMap;
use std::future::Future;

use super::{MaybeSend, MaybeSync};
use crate::{Error, Result};

/// HTTP method.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HttpMethod {
    Get,
    Post,
    Put,
    Patch,
    Delete,
}

impl HttpMethod {
    /// Upper-case method name.
    pub fn as_str(self) -> &'static str {
        match self {
            HttpMethod::Get => "GET",
            HttpMethod::Post => "POST",
            HttpMethod::Put => "PUT",
            HttpMethod::Patch => "PATCH",
            HttpMethod::Delete => "DELETE",
        }
    }
}

/// One HTTP request.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpRequest {
    pub method: HttpMethod,
    pub url: String,
    pub headers: BTreeMap<String, String>,
    pub body: Option<Vec<u8>>,
    /// Timeout in milliseconds. `None` means the platform default.
    pub timeout_ms: Option<u64>,
}

impl HttpRequest {
    /// GET request without a body.
    pub fn get(url: impl Into<String>) -> Self {
        Self { method: HttpMethod::Get, url: url.into(), headers: BTreeMap::new(), body: None, timeout_ms: None }
    }

    /// Request with a JSON body and a JSON content type.
    pub fn json<T: serde::Serialize>(method: HttpMethod, url: impl Into<String>, body: &T) -> Result<Self> {
        let mut headers = BTreeMap::new();
        headers.insert("Content-Type".to_owned(), "application/json".to_owned());
        Ok(Self { method, url: url.into(), headers, body: Some(serde_json::to_vec(body)?), timeout_ms: None })
    }

    /// Adds or replaces one header.
    pub fn header(mut self, name: impl Into<String>, value: impl Into<String>) -> Self {
        self.headers.insert(name.into(), value.into());
        self
    }

    /// Sets the timeout.
    pub fn timeout_ms(mut self, ms: u64) -> Self {
        self.timeout_ms = Some(ms);
        self
    }
}

/// One HTTP response.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HttpResponse {
    pub status: u16,
    pub headers: BTreeMap<String, String>,
    pub body: Vec<u8>,
}

impl HttpResponse {
    /// True for 2xx.
    pub fn is_success(&self) -> bool {
        (200..300).contains(&self.status)
    }

    /// Body as UTF-8 text, lossy.
    pub fn text(&self) -> String {
        String::from_utf8_lossy(&self.body).into_owned()
    }

    /// Returns `self` for 2xx, else [`Error::Http`].
    pub fn error_for_status(self) -> Result<Self> {
        if self.is_success() {
            Ok(self)
        } else {
            Err(Error::Http { status: self.status, body: self.text() })
        }
    }

    /// Parses a 2xx JSON body. Non-2xx becomes [`Error::Http`].
    pub fn json<T: serde::de::DeserializeOwned>(self) -> Result<T> {
        let ok = self.error_for_status()?;
        Ok(serde_json::from_slice(&ok.body)?)
    }
}

/// Sends HTTP requests.
pub trait HttpClient: MaybeSend + MaybeSync {
    /// Sends one request. Transport failures return [`Error::Network`].
    /// Non-2xx statuses are not errors here.
    fn send(&self, request: HttpRequest) -> impl Future<Output = Result<HttpResponse>> + MaybeSend;
}

impl<T: HttpClient + ?Sized> HttpClient for std::sync::Arc<T> {
    fn send(&self, request: HttpRequest) -> impl Future<Output = Result<HttpResponse>> + MaybeSend {
        (**self).send(request)
    }
}

/// [`HttpClient`] backed by `reqwest`. Works on native and wasm.
#[cfg(feature = "http-reqwest")]
#[derive(Debug, Clone, Default)]
pub struct ReqwestHttpClient {
    inner: reqwest::Client,
}

#[cfg(feature = "http-reqwest")]
impl ReqwestHttpClient {
    /// Wraps an existing client.
    pub fn new(inner: reqwest::Client) -> Self {
        Self { inner }
    }
}

#[cfg(feature = "http-reqwest")]
impl HttpClient for ReqwestHttpClient {
    fn send(&self, request: HttpRequest) -> impl Future<Output = Result<HttpResponse>> + MaybeSend {
        let client = self.inner.clone();
        async move {
            let method = reqwest::Method::from_bytes(request.method.as_str().as_bytes())
                .map_err(|e| Error::Unexpected(e.to_string()))?;
            let mut builder = client.request(method, &request.url);
            for (k, v) in &request.headers {
                builder = builder.header(k, v);
            }
            if let Some(body) = request.body {
                builder = builder.body(body);
            }
            #[cfg(not(target_arch = "wasm32"))]
            if let Some(ms) = request.timeout_ms {
                builder = builder.timeout(std::time::Duration::from_millis(ms));
            }
            let resp = builder.send().await.map_err(|e| {
                if e.is_timeout() {
                    Error::Timeout(e.to_string())
                } else {
                    Error::Network(e.to_string())
                }
            })?;
            let status = resp.status().as_u16();
            let headers = resp
                .headers()
                .iter()
                .filter_map(|(k, v)| v.to_str().ok().map(|v| (k.as_str().to_owned(), v.to_owned())))
                .collect();
            let body = resp.bytes().await.map_err(|e| Error::Network(e.to_string()))?.to_vec();
            Ok(HttpResponse { status, headers, body })
        }
    }
}
