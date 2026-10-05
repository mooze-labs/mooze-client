import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/database/database.dart' show AppDatabase;
import 'package:mooze_mobile/domain/entities/balance.dart' as v2;
import 'package:mooze_mobile/domain/entities/broadcast_result.dart';
import 'package:mooze_mobile/domain/entities/chain.dart';
import 'package:mooze_mobile/domain/entities/fee_estimate.dart';
import 'package:mooze_mobile/domain/entities/liquid_send_draft.dart';
import 'package:mooze_mobile/domain/entities/liquid_utxo.dart';
import 'package:mooze_mobile/domain/entities/receive_address.dart';
import 'package:mooze_mobile/domain/entities/send_request.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart' as v2;
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/domain/services/bitcoin_wallet_service.dart';
import 'package:mooze_mobile/domain/services/liquid_wallet_service.dart';
import 'package:mooze_mobile/features/wallet/data/repositories/service_backed_wallet_repository.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';
import 'package:mooze_mobile/features/wallet/domain/errors.dart';
import 'package:mooze_mobile/features/wallet/domain/repositories/swap_audit_repository.dart';
import 'package:mooze_mobile/shared/concurrency/liquid_spend_coordinator.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../../shared/database_test_helpers.dart';

class _MockLiquid extends Mock implements LiquidWalletService {}

class _MockBitcoin extends Mock implements BitcoinWalletService {}

class _MockSwapAudit extends Mock implements SwapAuditRepository {}

const _lqAddr =
    'lq1qqfk0uw9vlmqlggzs7cxmw49x8ks37l87udspmpt3ssgxjrkqqlww63xvus3c5gaz89r2kd393c4fvurwxf06qj87y2kd3vsln';
const _btcAddr = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq';

ServiceFailure _fail(String m, [ChainId chain = ChainId.bitcoin]) =>
    ServiceFailure(m, chain: chain);

v2.Transaction _v2Tx({
  required String id,
  required ChainId chain,
  required v2.TransactionDirection direction,
  int amount = 100000,
  int fee = 200,
  DateTime? at,
  v2.TransactionStatus status = v2.TransactionStatus.confirmed,
  int confirmations = 0,
  String? assetId,
  String? fromAssetId,
  String? toAssetId,
  int? sentAmountSat,
  int? receivedAmountSat,
}) {
  return v2.Transaction(
    id: id,
    chain: chain,
    direction: direction,
    status: status,
    amountSat: amount,
    feeSat: fee,
    timestamp: at ?? DateTime.utc(2026, 1, 1),
    confirmations: confirmations,
    assetId: assetId,
    fromAssetId: fromAssetId,
    toAssetId: toAssetId,
    sentAmountSat: sentAmountSat,
    receivedAmountSat: receivedAmountSat,
    source: chain == ChainId.bitcoin
        ? v2.TransactionSource.bdk
        : v2.TransactionSource.lwk,
  );
}

BroadcastResult _broadcast(ChainId chain, String txid, int amount) {
  return BroadcastResult(
    chain: chain,
    txId: txid,
    feePaidSat: 150,
    transaction: _v2Tx(
      id: txid,
      chain: chain,
      direction: v2.TransactionDirection.outgoing,
      amount: amount,
      status: v2.TransactionStatus.pending,
    ),
  );
}

FeeEstimate _fee(ChainId chain, int sat) =>
    FeeEstimate(chain: chain, priority: FeePriority.medium, absoluteFeeSat: sat);

void main() {
  late _MockLiquid liquid;
  late _MockBitcoin bitcoin;
  late ServiceBackedWalletRepository repo;

  setUpAll(() {
    registerFallbackValue(BigInt.zero);
    registerFallbackValue(
      const SendRequest(chain: ChainId.bitcoin, destination: '', amountSat: 0),
    );
  });

  setUp(() {
    liquid = _MockLiquid();
    bitcoin = _MockBitcoin();
    repo = ServiceBackedWalletRepository(
      liquid: liquid,
      bitcoin: bitcoin,
      spendCoordinator: LiquidSpendCoordinator(),
    );
  });

  group('getBalance', () {
    test('maps Liquid assets and BTC into the legacy balance map', () async {
      when(() => liquid.getBalance()).thenAnswer(
        (_) async => Right(
          v2.Balance(
            assets: const [
              v2.AssetBalance(
                chain: ChainId.liquid,
                assetId: lbtcAssetId,
                amountSat: 1000,
              ),
              v2.AssetBalance(
                chain: ChainId.liquid,
                assetId: usdtAssetId,
                amountSat: 2000,
              ),
              v2.AssetBalance(
                chain: ChainId.liquid,
                assetId: depixAssetId,
                amountSat: 3000,
              ),
              v2.AssetBalance(
                chain: ChainId.liquid,
                assetId: 'deadbeef',
                amountSat: 9,
              ),
            ],
            snapshotAt: DateTime.utc(2026),
          ),
        ),
      );
      when(() => bitcoin.getBalance()).thenAnswer(
        (_) async => Right(
          v2.Balance(
            assets: const [
              v2.AssetBalance(chain: ChainId.bitcoin, amountSat: 5000),
            ],
            snapshotAt: DateTime.utc(2026),
          ),
        ),
      );

      final balance = (await repo.getBalance().run()).getOrElse((_) => {});

      expect(balance, {
        Asset.lbtc: BigInt.from(1000),
        Asset.usdt: BigInt.from(2000),
        Asset.depix: BigInt.from(3000),
        Asset.btc: BigInt.from(5000),
      });
    });

    test('a failing service is skipped, not fatal', () async {
      when(() => liquid.getBalance())
          .thenAnswer((_) async => Left(_fail('down', ChainId.liquid)));
      when(() => bitcoin.getBalance()).thenAnswer(
        (_) async => Right(
          v2.Balance(
            assets: const [
              v2.AssetBalance(chain: ChainId.bitcoin, amountSat: 42),
            ],
            snapshotAt: DateTime.utc(2026),
          ),
        ),
      );

      final balance = (await repo.getBalance().run()).getOrElse((_) => {});
      expect(balance, {Asset.btc: BigInt.from(42)});
    });
  });

  group('getTransactions', () {
    void stubTxs(List<v2.Transaction> lq, List<v2.Transaction> btc,
        {int tip = 900000}) {
      when(() => liquid.listTransactions()).thenAnswer((_) async => Right(lq));
      when(() => bitcoin.listTransactions())
          .thenAnswer((_) async => Right(btc));
      when(() => bitcoin.getBlockHeight()).thenAnswer((_) async => Right(tip));
    }

    test('maps V2 rows to legacy rows, newest first', () async {
      stubTxs(
        [
          _v2Tx(
            id: 'lq-usdt',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.incoming,
            assetId: usdtAssetId,
            amount: 777,
            at: DateTime.utc(2026, 3, 1),
          ),
          _v2Tx(
            id: 'lq-swap',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.swap,
            assetId: lbtcAssetId,
            fromAssetId: lbtcAssetId,
            toAssetId: usdtAssetId,
            sentAmountSat: 10,
            receivedAmountSat: 20,
            at: DateTime.utc(2026, 2, 1),
          ),
          _v2Tx(
            id: 'lq-redeposit',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.selfTransfer,
            at: DateTime.utc(2026, 1, 15),
          ),
        ],
        [
          _v2Tx(
            id: 'btc-in',
            chain: ChainId.bitcoin,
            direction: v2.TransactionDirection.incoming,
            confirmations: 6,
            at: DateTime.utc(2026, 1, 10),
          ),
        ],
      );

      final txs = (await repo.getTransactions().run()).getOrElse((_) => []);

      expect(txs.map((t) => t.id), [
        'lq-usdt',
        'lq-swap',
        'lq-redeposit',
        'btc-in',
      ]);

      final usdt = txs[0];
      expect(usdt.asset, Asset.usdt);
      expect(usdt.blockchain, Blockchain.liquid);
      expect(usdt.type, TransactionType.receive);
      expect(usdt.amount, BigInt.from(777));
      expect(usdt.feesSat, BigInt.from(200));
      expect(
        usdt.blockchainUrl,
        'https://blockstream.info/liquid/tx/lq-usdt',
      );

      final swap = txs[1];
      expect(swap.type, TransactionType.swap);
      expect(swap.fromAsset, Asset.lbtc);
      expect(swap.toAsset, Asset.usdt);
      expect(swap.sentAmount, BigInt.from(10));
      expect(swap.receivedAmount, BigInt.from(20));

      expect(txs[2].type, TransactionType.redeposit);

      final btc = txs[3];
      expect(btc.asset, Asset.btc);
      expect(btc.blockchain, Blockchain.bitcoin);
      expect(btc.status, TransactionStatus.confirmed);
      expect(btc.confirmationHeight, 900000 - 6 + 1);
    });

    test('pairs a BTC send with an L-BTC receive into one swap row', () async {
      final audit = _MockSwapAudit();
      repo = ServiceBackedWalletRepository(
        liquid: liquid,
        bitcoin: bitcoin,
        swapAudit: audit,
      );
      stubTxs(
        [
          _v2Tx(
            id: 'lq-recv',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.incoming,
            amount: 99000,
            // The legacy matcher only collapses a pair when the send leg
            // sorts first (newer). This mirrors WalletRepositoryImpl.
            at: DateTime.utc(2026, 1, 1, 10),
          ),
        ],
        [
          _v2Tx(
            id: 'btc-send',
            chain: ChainId.bitcoin,
            direction: v2.TransactionDirection.outgoing,
            amount: 100000,
            at: DateTime.utc(2026, 1, 1, 11),
          ),
        ],
      );

      final txs = (await repo.getTransactions().run()).getOrElse((_) => []);

      expect(txs, hasLength(1));
      final swap = txs.single;
      expect(swap.id, 'btc-send_lq-recv_swap');
      expect(swap.type, TransactionType.swap);
      expect(swap.fromAsset, Asset.btc);
      expect(swap.toAsset, Asset.lbtc);
      expect(swap.sentAmount, BigInt.from(100000));
      expect(swap.receivedAmount, BigInt.from(99000));
      expect(swap.sendBlockchain, Blockchain.bitcoin);
      expect(swap.receiveBlockchain, Blockchain.liquid);
      // Cross-chain pairs are not internal Liquid swaps: no audit row.
      verifyNever(
        () => audit.recordCompleted(
          provider: any(named: 'provider'),
          direction: any(named: 'direction'),
          sendAsset: any(named: 'sendAsset'),
          receiveAsset: any(named: 'receiveAsset'),
          sendAmount: any(named: 'sendAmount'),
          receiveAmount: any(named: 'receiveAmount'),
          txId: any(named: 'txId'),
          metadata: any(named: 'metadata'),
        ),
      );
    });

    test('applies type, asset, blockchain, status and date filters', () async {
      stubTxs(
        [
          _v2Tx(
            id: 'lq-in-old',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.incoming,
            at: DateTime.utc(2025, 6, 1),
          ),
          _v2Tx(
            id: 'lq-in-new',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.incoming,
            at: DateTime.utc(2026, 6, 1),
          ),
          _v2Tx(
            id: 'lq-out',
            chain: ChainId.liquid,
            direction: v2.TransactionDirection.outgoing,
            amount: 1000,
            at: DateTime.utc(2026, 6, 2),
          ),
        ],
        [
          _v2Tx(
            id: 'btc-pending',
            chain: ChainId.bitcoin,
            direction: v2.TransactionDirection.incoming,
            status: v2.TransactionStatus.pending,
            at: DateTime.utc(2026, 6, 3),
          ),
        ],
      );

      Future<List<String>> ids({
        TransactionType? type,
        TransactionStatus? status,
        Asset? asset,
        Blockchain? blockchain,
        DateTime? start,
        DateTime? end,
      }) async {
        final r = await repo
            .getTransactions(
              type: type,
              status: status,
              asset: asset,
              blockchain: blockchain,
              startDate: start,
              endDate: end,
            )
            .run();
        return r.getOrElse((_) => []).map((t) => t.id).toList();
      }

      expect(await ids(type: TransactionType.send), ['lq-out']);
      expect(await ids(asset: Asset.btc), ['btc-pending']);
      expect(
        await ids(blockchain: Blockchain.liquid),
        ['lq-out', 'lq-in-new', 'lq-in-old'],
      );
      expect(await ids(status: TransactionStatus.pending), ['btc-pending']);
      expect(
        await ids(start: DateTime.utc(2026, 1, 1)),
        ['btc-pending', 'lq-out', 'lq-in-new'],
      );
      expect(await ids(end: DateTime.utc(2026, 1, 1)), ['lq-in-old']);
    });

    test('a failing chain returns the other chain only', () async {
      when(() => liquid.listTransactions())
          .thenAnswer((_) async => Left(_fail('x', ChainId.liquid)));
      when(() => bitcoin.listTransactions()).thenAnswer(
        (_) async => Right([
          _v2Tx(
            id: 'btc',
            chain: ChainId.bitcoin,
            direction: v2.TransactionDirection.incoming,
          ),
        ]),
      );

      final txs = (await repo.getTransactions().run()).getOrElse((_) => []);
      expect(txs.map((t) => t.id), ['btc']);
    });
  });

  group('invoices', () {
    test('bitcoin invoice carries the bare address', () async {
      when(() => bitcoin.nextReceiveAddress()).thenAnswer(
        (_) async => const Right(
          ReceiveAddress(chain: ChainId.bitcoin, address: _btcAddr),
        ),
      );

      final req = (await repo
              .createBitcoinInvoice(Some(BigInt.from(5000)), const Some('x'))
              .run())
          .toNullable()!;

      expect(req.address, _btcAddr);
      expect(req.asset, Asset.btc);
      expect(req.blockchain, Blockchain.bitcoin);
      expect(req.amount, BigInt.from(5000));
      expect(req.description, 'x');
    });

    test('L-BTC invoice is a liquidnetwork URI when an amount is set',
        () async {
      when(() => liquid.getReceiveAddress())
          .thenAnswer((_) async => const Right(_lqAddr));

      final withAmount = (await repo
              .createLiquidBitcoinInvoice(Some(BigInt.from(1000)), const None())
              .run())
          .toNullable()!;
      expect(
        withAmount.address,
        'liquidnetwork:$_lqAddr?assetid=$lbtcAssetId&amount=0.00001000',
      );

      final bare = (await repo
              .createLiquidBitcoinInvoice(const None(), const None())
              .run())
          .toNullable()!;
      expect(bare.address, _lqAddr);
      expect(bare.asset, Asset.lbtc);
    });

    test('stablecoin invoice always carries the asset id', () async {
      when(() => liquid.getReceiveAddress())
          .thenAnswer((_) async => const Right(_lqAddr));

      final req = (await repo
              .createStablecoinInvoice(
                Asset.usdt,
                Some(BigInt.from(1250000000)),
                const None(),
              )
              .run())
          .toNullable()!;
      expect(
        req.address,
        'liquidnetwork:$_lqAddr?amount=12.50000000&assetid=$usdtAssetId',
      );
      expect(req.asset, Asset.usdt);
    });

    test('receive address failure maps to sdkError', () async {
      when(() => liquid.getReceiveAddress())
          .thenAnswer((_) async => Left(_fail('boom', ChainId.liquid)));
      final err = (await repo.getLiquidReceiveAddress().run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.sdkError);
      expect(err.customDescription, 'Erro ao obter endereço Liquid: boom');
    });
  });

  group('bitcoin build + send', () {
    test('build estimates the fee with the requested rate', () async {
      when(() => bitcoin.estimateFee(any()))
          .thenAnswer((_) async => Right(_fee(ChainId.bitcoin, 321)));

      final p = (await repo
              .buildOnchainBitcoinPaymentTransaction(
                _btcAddr,
                BigInt.from(50000),
                7,
              )
              .run())
          .toNullable()!;

      expect(p.networkFees, BigInt.from(321));
      expect(p.amount, BigInt.from(50000));
      expect(p.drain, isFalse);
      expect(p.feeRateSatPerVByte, 7);
      final req =
          verify(() => bitcoin.estimateFee(captureAny())).captured.single
              as SendRequest;
      expect(req.chain, ChainId.bitcoin);
      expect(req.destination, _btcAddr);
      expect(req.amountSat, 50000);
      expect(req.feeRateOverrideSatPerVByte, 7.0);
      expect(req.drain, isFalse);
    });

    test('drain uses the wallet balance as amount', () async {
      when(() => bitcoin.estimateFee(any()))
          .thenAnswer((_) async => Right(_fee(ChainId.bitcoin, 400)));
      when(() => bitcoin.getBalance()).thenAnswer(
        (_) async => Right(
          v2.Balance(
            assets: const [
              v2.AssetBalance(chain: ChainId.bitcoin, amountSat: 80000),
            ],
            snapshotAt: DateTime.utc(2026),
          ),
        ),
      );

      final p = (await repo
              .buildDrainOnchainBitcoinTransaction(_btcAddr)
              .run())
          .toNullable()!;

      expect(p.drain, isTrue);
      expect(p.amount, BigInt.from(80000));
      expect(p.networkFees, BigInt.from(400));
      final req =
          verify(() => bitcoin.estimateFee(captureAny())).captured.single
              as SendRequest;
      expect(req.drain, isTrue);
    });

    test('build maps an address failure to invalidAddress', () async {
      when(() => bitcoin.estimateFee(any())).thenAnswer(
        (_) async => Left(_fail('invalid address: bad checksum')),
      );
      final err = (await repo
              .buildOnchainBitcoinPaymentTransaction(_btcAddr, BigInt.one)
              .run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.invalidAddress);
    });

    test('build maps other failures to transactionFailed', () async {
      when(() => bitcoin.estimateFee(any()))
          .thenAnswer((_) async => Left(_fail('InsufficientFunds')));
      final err = (await repo
              .buildOnchainBitcoinPaymentTransaction(_btcAddr, BigInt.one)
              .run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.transactionFailed);
      expect(err.customDescription, 'InsufficientFunds');
    });

    test('send broadcasts via the service and writes the legacy row',
        () async {
      final AppDatabase db = buildInMemoryDatabase();
      addTearDown(db.close);
      repo = ServiceBackedWalletRepository(bitcoin: bitcoin, database: db);
      when(() => bitcoin.sendOnchain(any())).thenAnswer(
        (_) async => Right(_broadcast(ChainId.bitcoin, 'txid-1', 60000)),
      );

      final tx = (await repo
              .sendOnchainBitcoinPayment(
                PreparedOnchainBitcoinTransaction(
                  destination: _btcAddr,
                  amount: BigInt.from(60000),
                  networkFees: BigInt.from(150),
                  drain: true,
                  feeRateSatPerVByte: 3,
                ),
              )
              .run())
          .toNullable()!;

      expect(tx.id, 'txid-1');
      expect(tx.asset, Asset.btc);
      expect(tx.type, TransactionType.send);
      expect(tx.status, TransactionStatus.pending);
      expect(tx.amount, BigInt.from(60000));

      final req =
          verify(() => bitcoin.sendOnchain(captureAny())).captured.single
              as SendRequest;
      expect(req.drain, isTrue);
      expect(req.feeRateOverrideSatPerVByte, 3.0);

      final row = await db.getTransactionById('txid-1');
      expect(row, isNotNull);
      expect(row!.blockchain, 'bitcoin');
      expect(row.type, 'send');
      expect(row.address, _btcAddr);
    });

    test('send maps a broadcast failure to connectionError', () async {
      when(() => bitcoin.sendOnchain(any())).thenAnswer(
        (_) async => Left(_fail('bdk sendOnchain failed: broadcast: timeout')),
      );
      final err = (await repo
              .sendOnchainBitcoinPayment(
                PreparedOnchainBitcoinTransaction(
                  destination: _btcAddr,
                  amount: BigInt.from(1),
                  networkFees: BigInt.zero,
                  drain: false,
                ),
              )
              .run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.connectionError);
    });
  });

  group('liquid build + send', () {
    test('L-BTC build and send go through the Liquid service', () async {
      when(() => liquid.estimateFee(any()))
          .thenAnswer((_) async => Right(_fee(ChainId.liquid, 26)));
      when(() => liquid.sendOnchain(any())).thenAnswer(
        (_) async => Right(_broadcast(ChainId.liquid, 'lq-tx', 1000)),
      );

      final p = (await repo
              .buildLiquidBitcoinPaymentTransaction(_lqAddr, BigInt.from(1000))
              .run())
          .toNullable()!;
      expect(p.networkFees, BigInt.from(26));
      expect(p.blockchain, Blockchain.liquid);

      final tx = (await repo.sendL2BitcoinPayment(p).run()).toNullable()!;
      expect(tx.id, 'lq-tx');
      expect(tx.asset, Asset.lbtc);
      expect(tx.blockchain, Blockchain.liquid);
      expect(tx.feesSat, BigInt.from(150));

      final req =
          verify(() => liquid.sendOnchain(captureAny())).captured.single
              as SendRequest;
      expect(req.chain, ChainId.liquid);
      expect(req.assetId, isNull);
      expect(req.amountSat, 1000);
    });

    test('L-BTC drain reads amount and fee from buildLbtcSend', () async {
      when(
        () => liquid.buildLbtcSend(
          destination: _lqAddr,
          amountSat: BigInt.zero,
          feeRateSatPerVb: null,
          drain: true,
        ),
      ).thenAnswer(
        (_) async => Right(
          LiquidSendDraft(
            pset: 'p',
            destination: _lqAddr,
            amountSat: BigInt.from(9970),
            feeSat: BigInt.from(30),
            feeRateSatPerKvb: 100,
            drain: true,
          ),
        ),
      );

      final p = (await repo.buildDrainLiquidBitcoinTransaction(_lqAddr).run())
          .toNullable()!;
      expect(p.drain, isTrue);
      expect(p.amount, BigInt.from(9970));
      expect(p.networkFees, BigInt.from(30));
    });

    test('on-chain build with a Liquid destination routes to Liquid',
        () async {
      when(() => liquid.estimateFee(any()))
          .thenAnswer((_) async => Right(_fee(ChainId.liquid, 30)));

      final p = (await repo
              .buildOnchainBitcoinPaymentTransaction(_lqAddr, BigInt.from(500))
              .run())
          .toNullable()!;
      expect(p.networkFees, BigInt.from(30));
      verifyNever(() => bitcoin.estimateFee(any()));
    });

    test('stablecoin build, drain and send carry the asset id', () async {
      when(() => liquid.estimateFee(any()))
          .thenAnswer((_) async => Right(_fee(ChainId.liquid, 40)));
      when(() => liquid.getBalance()).thenAnswer(
        (_) async => Right(
          v2.Balance(
            assets: const [
              v2.AssetBalance(
                chain: ChainId.liquid,
                assetId: usdtAssetId,
                amountSat: 250000000,
              ),
            ],
            snapshotAt: DateTime.utc(2026),
          ),
        ),
      );
      when(() => liquid.sendOnchain(any())).thenAnswer(
        (_) async => Right(_broadcast(ChainId.liquid, 'usdt-tx', 100000000)),
      );

      final p = (await repo
              .buildStablecoinPaymentTransaction(_lqAddr, Asset.usdt, 1.0)
              .run())
          .toNullable()!;
      expect(p.networkFees, BigInt.from(40));
      expect(p.satoshi, BigInt.from(100000000));

      final drain = (await repo
              .buildDrainStablecoinTransaction(_lqAddr, Asset.usdt)
              .run())
          .toNullable()!;
      expect(drain.drain, isTrue);
      expect(drain.amount, 2.5);

      final tx = (await repo.sendStablecoinPayment(p).run()).toNullable()!;
      expect(tx.asset, Asset.usdt);
      final req =
          verify(() => liquid.sendOnchain(captureAny())).captured.single
              as SendRequest;
      expect(req.assetId, usdtAssetId);
    });

    test('stablecoin drain with zero balance is insufficientFunds', () async {
      when(() => liquid.getBalance()).thenAnswer(
        (_) async => Right(
          v2.Balance(assets: const [], snapshotAt: DateTime.utc(2026)),
        ),
      );
      final err = (await repo
              .buildDrainStablecoinTransaction(_lqAddr, Asset.depix)
              .run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.insufficientFunds);
    });

    test('send failure maps to transactionFailed', () async {
      when(() => liquid.sendOnchain(any()))
          .thenAnswer((_) async => Left(_fail('nope', ChainId.liquid)));
      final err = (await repo
              .sendL2BitcoinPayment(
                PreparedLayer2BitcoinTransaction(
                  destination: _lqAddr,
                  amount: BigInt.from(10),
                  networkFees: BigInt.zero,
                  blockchain: Blockchain.liquid,
                  drain: false,
                ),
              )
              .run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.transactionFailed);
      expect(err.customDescription, 'nope');
    });
  });

  group('swap surface and chain metadata', () {
    test('utxos, sign and swap address delegate to the Liquid service',
        () async {
      final utxo = LiquidUtxo(
        txid: 't',
        vout: 1,
        assetId: lbtcAssetId,
        assetBlindingFactor: 'a',
        valueSat: BigInt.from(5),
        valueBlindingFactor: 'v',
      );
      when(() => liquid.getUtxos()).thenAnswer((_) async => Right([utxo]));
      when(() => liquid.signSwapPset(pset: 'pset', mnemonic: 'm'))
          .thenAnswer((_) async => const Right('signed'));
      when(() => liquid.getReceiveAddress())
          .thenAnswer((_) async => const Right(_lqAddr));

      expect((await repo.getLiquidUtxos().run()).toNullable(), [utxo]);
      expect(
        (await repo.signSwapPset(pset: 'pset', mnemonic: 'm').run())
            .toNullable(),
        'signed',
      );
      expect((await repo.getLiquidSwapAddress().run()).toNullable(), _lqAddr);
    });

    test('sign failure keeps the old kind and message', () async {
      when(() => liquid.signSwapPset(pset: 'p', mnemonic: 'm'))
          .thenAnswer((_) async => Left(_fail('bad', ChainId.liquid)));
      final err = (await repo.signSwapPset(pset: 'p', mnemonic: 'm').run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.transactionFailed);
      expect(err.customDescription, 'Erro ao assinar PSET de swap: bad');
    });

    test('block height failure maps to networkError', () async {
      when(() => bitcoin.getBlockHeight())
          .thenAnswer((_) async => Left(_fail('electrum down')));
      final err = (await repo.getCurrentBitcoinBlockHeight().run())
          .getLeft()
          .toNullable()!;
      expect(err.type, WalletErrorType.networkError);
      expect(
        err.customDescription,
        'Erro ao obter altura do bloco Bitcoin: electrum down',
      );
    });

    test('missing services return "not available"', () async {
      final empty = ServiceBackedWalletRepository();
      final btcErr = (await empty.getBitcoinReceiveAddress().run())
          .getLeft()
          .toNullable()!;
      final lqErr =
          (await empty.getLiquidUtxos().run()).getLeft().toNullable()!;
      expect(btcErr.type, WalletErrorType.sdkError);
      expect(btcErr.customDescription, 'Bitcoin wallet not available');
      expect(lqErr.customDescription, 'Liquid wallet not available');
    });
  });
}
