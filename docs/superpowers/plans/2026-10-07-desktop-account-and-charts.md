# Desktop account level and asset charts

Scope confirmed by the user: account level and asset price charts are the first mobile-parity additions.

## Delivered behavior

- Account navigation opens `/account`: current tier, next-tier progress and the published tier table. The separate Pix limits card was removed at the user’s request. Unknown or unavailable account data never defaults to Bronze.
- Native `account_level` reads the authenticated `/users/me` endpoint and public tier configuration, parses through the existing core `User`, and reuses `compute_user_levels`. It returns only presentation data; tokens and user identifiers do not cross the desktop bridge.
- Asset detail includes a market reference chart for approved BTC, canonical L-BTC and canonical USDT. Asset identity selects the reference; arbitrary tickers and test coins cannot receive production valuations. L-BTC clearly identifies Bitcoin as its reference. DEPIX and unsupported assets show an unavailable state rather than fabricated history.
- Charts offer 1D/7D/1M and BRL/USD; timestamps are supplied by the provider. Percentage change is first-to-last within the returned period. Pointer exploration and a keyboard range control show historical prices.

## Boundaries and resilience

`DesktopClient` exposes provider-neutral account and price-history DTOs. The native host performs HTTP using the platform's existing transport; frontend CSP stays unchanged. CoinGecko is isolated in the core price adapter. Requests include coin ID, currency and period, never wallet addresses or balances. The optional native environment variable `COINGECKO_DEMO_API_KEY` supplies a Demo API header if needed; nothing is embedded in frontend assets.

Chart queries cache for five minutes, reuse BTC/L-BTC reference data, do not poll or retry automatically, and offer a manual retry on failure. Previously loaded values remain explicitly marked outdated when refresh fails. Account queries cache for one minute. Both use the existing wallet-generation query scope, and native calls stop on session changes. Preview account and chart data are synthetic and make no network requests.

## Validation

85 frontend tests, including market mapping, timestamp geometry, flat prices, keyboard exploration, period/currency switching, API failure, tier display, cents conversion and absence of the removed Pix limits card. 60 native desktop unit tests, including locked access, authenticated profile/public tier separation, public market requests and generated DTO parity. Two core history-adapter tests cover response validation and timestamp preservation. Frontend production build and native codegen build passed. The public CoinGecko endpoint returned HTTP 200 during an unauthenticated market-chart check. Safari synthetic preview verified account layout and chart period/currency switching. Real account data in the native app was not exercised.

## Diamond tier correction

Shared Rust and mobile defaults, preview data and fixtures use R$3,000 for Diamond. The externally hosted live tier configuration still publishes R$30,000; its correction is a separate operational follow-up. Desktop continues to display the published configuration.
