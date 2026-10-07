use super::*;
use mooze_core::{
    domain::Asset,
    prices::{coingecko_history, Currency},
};
impl<P: Platform + Clone> WalletSession<P> {
    pub async fn price_history(
        &self,
        market: PriceMarketDto,
        currency: String,
        days: u32,
    ) -> Result<PriceHistoryDto> {
        let generation = self.authorize()?;
        let currency = Currency::from_code(&currency)
            .ok_or_else(|| DesktopError::new("invalid_input", "Moeda não suportada."))?;
        let asset = match market {
            PriceMarketDto::Bitcoin => Asset::Btc,
            PriceMarketDto::Tether => Asset::Usdt,
        };
        let http = self.platform.http();
        let demo_key = std::env::var("COINGECKO_DEMO_API_KEY").ok();
        let points = self
            .run_session_service(
                generation,
                coingecko_history(&http, asset, currency, days, demo_key.as_deref()),
            )
            .await??;
        self.same_generation(generation)?;
        Ok(PriceHistoryDto {
            points: points
                .into_iter()
                .map(|(timestamp_ms, price)| PricePointDto {
                    timestamp_ms,
                    price,
                })
                .collect(),
            source: "CoinGecko".into(),
            fetched_at_ms: self.platform.clock().now_ms(),
        })
    }
}
