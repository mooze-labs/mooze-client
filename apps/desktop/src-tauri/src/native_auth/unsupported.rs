use super::*;
pub struct Unsupported;
impl NativeAuthenticator for Unsupported {
    fn capabilities(&self) -> BoxFuture<'_, NativeCapabilities> {
        Box::pin(async {
            NativeCapabilities {
                kind: NativeKind::Unsupported,
                availability: NativeAvailability::Unavailable,
            }
        })
    }
    fn verify(&self, _: u64, _: String) -> BoxFuture<'_, NativeOutcome> {
        Box::pin(async { NativeOutcome::Unavailable })
    }
    fn cancel(&self, _: u64) {}
}
#[cfg(test)]
mod tests {
    use super::*;
    #[tokio::test]
    async fn unsupported_never_authenticates() {
        assert_eq!(
            Unsupported.verify(1, "unlock".into()).await,
            NativeOutcome::Unavailable
        );
    }
}
