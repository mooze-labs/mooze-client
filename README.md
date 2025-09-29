# mooze-client

Mooze is a mobile cryptocurrency wallet built with Flutter that focuses on Bitcoin and Liquid network assets, with integrated PIX (Brazilian instant payment system) support.

![Mooze Logo](assets/logos/logo_primary.svg)

## Features

- **Multi-chain Support**: Bitcoin and Liquid Network
- **PIX Integration**: Seamlessly convert between cryptocurrencies and Brazilian Real (BRL)
- **Asset Management**: View and manage multiple cryptocurrencies
- **Token Swaps**: Exchange between different Liquid Network assets
- **Store Mode**: Dedicated interface for merchants to receive payments

## Supported Assets

- Bitcoin (BTC)
- Liquid Bitcoin (L-BTC)
- Depix (DEPIX) on Liquid Network
- Tether USD (USDT) on Liquid Network

## Architecture

Mooze is built with a modern Flutter architecture:

- **Flutter & Dart**: UI framework and programming language
- **Riverpod**: State management solution
- **BDK** (Bitcoin Development Kit): Bitcoin wallet functionality
- **LWK** (Liquid Wallet Kit): Liquid Network wallet functionality
- **Secure Storage**: For seed phrases and private keys

## Getting Started

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Android Studio / Xcode for native development

### Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/mooze-app/mooze-client.git
   cd mooze-client
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run code generation:

   ```bash
   dart pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Building for Production

#### Android

```bash
flutter build apk --release
```

#### iOS

```bash
flutter build ios --release
```

## Security Notes

- Never share your mnemonic phrase or PIN with anyone
- The app securely stores sensitive information using native secure storage
- Transactions are signed locally on your device - private keys never leave your phone

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the [GNU General Public License](LICENSE).

## Acknowledgements

- Bitcoin Development Kit (BDK) team
- Bull Bitcoin for Dart bindings for LWK
- SideSwap for swap functionality
