import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:bdk_dart/bdk_dart.dart' as bdk;

/// Electrum access for the BDK wallet, with every network call moved off the
/// UI isolate.
///
/// `bdk_dart` exposes Electrum as synchronous FFI calls: `sync_`, `fullScan`,
/// `transactionBroadcast` and even the client constructor block the calling
/// thread for the whole round-trip. On the UI isolate that freezes the app
/// for seconds, so each call here runs inside [Isolate.run].
///
/// Native handles cross the isolate boundary as raw addresses. The UniFFI
/// `lower` call clones the underlying Rust `Arc` and hands over one
/// reference; `lift` on the other side takes ownership of that reference and
/// `dispose` releases it. The wallet itself never leaves the UI isolate:
/// callers build the request there, this class does the I/O in the
/// background, and the caller applies the returned [bdk.Update] on the UI
/// isolate.
///
/// The client is created lazily on first use, so an offline cold start does
/// not fail wallet setup. A failed creation is retried on the next call.
class BdkElectrum {
  BdkElectrum({
    required this.url,
    required this.timeoutSec,
    required this.retry,
    required this.validateDomain,
  });

  final String url;
  final int timeoutSec;
  final int retry;
  final bool validateDomain;

  static const _batchSize = 100;

  bdk.ElectrumClient? _client;
  Future<bdk.ElectrumClient>? _connecting;
  bool _disposed = false;

  /// Incremental sync of the scripts the wallet has already revealed.
  Future<bdk.Update> sync(bdk.SyncRequest request) async {
    final clientAddr = await _clientAddress();
    final requestAddr = bdk.SyncRequest.lower(request).address;
    final updateAddr = await Isolate.run(() {
      final client = bdk.ElectrumClient.lift(Pointer.fromAddress(clientAddr));
      final req = bdk.SyncRequest.lift(Pointer.fromAddress(requestAddr));
      try {
        final update = client.sync_(
          request: req,
          batchSize: _batchSize,
          fetchPrevTxouts: true,
        );
        return _handOver(update);
      } finally {
        req.dispose();
        client.dispose();
      }
    });
    return bdk.Update.lift(Pointer.fromAddress(updateAddr));
  }

  /// Full scan of every keychain up to [stopGap] unused scripts. Discovers
  /// funds sent to addresses the wallet has not revealed yet.
  Future<bdk.Update> fullScan(bdk.FullScanRequest request, int stopGap) async {
    final clientAddr = await _clientAddress();
    final requestAddr = bdk.FullScanRequest.lower(request).address;
    final updateAddr = await Isolate.run(() {
      final client = bdk.ElectrumClient.lift(Pointer.fromAddress(clientAddr));
      final req = bdk.FullScanRequest.lift(Pointer.fromAddress(requestAddr));
      try {
        final update = client.fullScan(
          request: req,
          stopGap: stopGap,
          batchSize: _batchSize,
          fetchPrevTxouts: true,
        );
        return _handOver(update);
      } finally {
        req.dispose();
        client.dispose();
      }
    });
    return bdk.Update.lift(Pointer.fromAddress(updateAddr));
  }

  /// Broadcasts [tx] and returns its txid as hex.
  Future<String> broadcast(bdk.Transaction tx) async {
    final clientAddr = await _clientAddress();
    final txAddr = bdk.Transaction.lower(tx).address;
    return Isolate.run(() {
      final client = bdk.ElectrumClient.lift(Pointer.fromAddress(clientAddr));
      final transaction = bdk.Transaction.lift(Pointer.fromAddress(txAddr));
      try {
        final txid = client.transactionBroadcast(tx: transaction);
        final hex = txid.toString();
        txid.dispose();
        return hex;
      } finally {
        transaction.dispose();
        client.dispose();
      }
    });
  }

  /// Current chain tip height as reported by the Electrum server.
  Future<int> tipHeight() async {
    final clientAddr = await _clientAddress();
    return Isolate.run(() {
      final client = bdk.ElectrumClient.lift(Pointer.fromAddress(clientAddr));
      try {
        return client.blockHeadersSubscribe().height;
      } finally {
        client.dispose();
      }
    });
  }

  /// Releases the client. Calls already in flight keep their own reference
  /// and finish normally.
  void dispose() {
    _disposed = true;
    _client?.dispose();
    _client = null;
  }

  /// Returns an owned reference to the client, as a raw address for the
  /// worker isolate to lift.
  Future<int> _clientAddress() async {
    final client = await _ensureClient();
    return bdk.ElectrumClient.lower(client).address;
  }

  Future<bdk.ElectrumClient> _ensureClient() {
    if (_disposed) {
      return Future.error(StateError('BdkElectrum is disposed'));
    }
    final existing = _client;
    if (existing != null) return Future.value(existing);
    return _connecting ??= _connect()
        .then((client) {
          if (_disposed) {
            client.dispose();
            throw StateError('BdkElectrum is disposed');
          }
          _client = client;
          return client;
        })
        .whenComplete(() => _connecting = null);
  }

  Future<bdk.ElectrumClient> _connect() async {
    final url = this.url;
    final timeout = timeoutSec;
    final retry = this.retry;
    final validate = validateDomain;
    // The constructor opens the TCP/TLS connection, so it blocks too.
    final addr = await Isolate.run(() {
      final client = bdk.ElectrumClient(
        url: url,
        socks5: null,
        timeout: timeout,
        retry: retry,
        validateDomain: validate,
      );
      return _handOver(client);
    });
    return bdk.ElectrumClient.lift(Pointer.fromAddress(addr));
  }
}

/// Transfers ownership of [handle] out of the worker isolate. `lower` clones
/// the reference that leaves as an address; `dispose` drops the worker's
/// own reference so its finalizer never runs on a dead isolate.
int _handOver(Object handle) {
  switch (handle) {
    case final bdk.Update u:
      final addr = bdk.Update.lower(u).address;
      u.dispose();
      return addr;
    case final bdk.ElectrumClient c:
      final addr = bdk.ElectrumClient.lower(c).address;
      c.dispose();
      return addr;
  }
  throw ArgumentError.value(handle, 'handle', 'unsupported handle type');
}
