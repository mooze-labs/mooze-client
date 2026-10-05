// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'send_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PixPaymentQuote {

 int get satoshis; double get btcToBrlRate; int get brlAmount;
/// Create a copy of PixPaymentQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PixPaymentQuoteCopyWith<PixPaymentQuote> get copyWith => _$PixPaymentQuoteCopyWithImpl<PixPaymentQuote>(this as PixPaymentQuote, _$identity);

  /// Serializes this PixPaymentQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PixPaymentQuote&&(identical(other.satoshis, satoshis) || other.satoshis == satoshis)&&(identical(other.btcToBrlRate, btcToBrlRate) || other.btcToBrlRate == btcToBrlRate)&&(identical(other.brlAmount, brlAmount) || other.brlAmount == brlAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,satoshis,btcToBrlRate,brlAmount);

@override
String toString() {
  return 'PixPaymentQuote(satoshis: $satoshis, btcToBrlRate: $btcToBrlRate, brlAmount: $brlAmount)';
}


}

/// @nodoc
abstract mixin class $PixPaymentQuoteCopyWith<$Res>  {
  factory $PixPaymentQuoteCopyWith(PixPaymentQuote value, $Res Function(PixPaymentQuote) _then) = _$PixPaymentQuoteCopyWithImpl;
@useResult
$Res call({
 int satoshis, double btcToBrlRate, int brlAmount
});




}
/// @nodoc
class _$PixPaymentQuoteCopyWithImpl<$Res>
    implements $PixPaymentQuoteCopyWith<$Res> {
  _$PixPaymentQuoteCopyWithImpl(this._self, this._then);

  final PixPaymentQuote _self;
  final $Res Function(PixPaymentQuote) _then;

/// Create a copy of PixPaymentQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? satoshis = null,Object? btcToBrlRate = null,Object? brlAmount = null,}) {
  return _then(_self.copyWith(
satoshis: null == satoshis ? _self.satoshis : satoshis // ignore: cast_nullable_to_non_nullable
as int,btcToBrlRate: null == btcToBrlRate ? _self.btcToBrlRate : btcToBrlRate // ignore: cast_nullable_to_non_nullable
as double,brlAmount: null == brlAmount ? _self.brlAmount : brlAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PixPaymentQuote].
extension PixPaymentQuotePatterns on PixPaymentQuote {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PixPaymentQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PixPaymentQuote() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PixPaymentQuote value)  $default,){
final _that = this;
switch (_that) {
case _PixPaymentQuote():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PixPaymentQuote value)?  $default,){
final _that = this;
switch (_that) {
case _PixPaymentQuote() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int satoshis,  double btcToBrlRate,  int brlAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PixPaymentQuote() when $default != null:
return $default(_that.satoshis,_that.btcToBrlRate,_that.brlAmount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int satoshis,  double btcToBrlRate,  int brlAmount)  $default,) {final _that = this;
switch (_that) {
case _PixPaymentQuote():
return $default(_that.satoshis,_that.btcToBrlRate,_that.brlAmount);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int satoshis,  double btcToBrlRate,  int brlAmount)?  $default,) {final _that = this;
switch (_that) {
case _PixPaymentQuote() when $default != null:
return $default(_that.satoshis,_that.btcToBrlRate,_that.brlAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PixPaymentQuote implements PixPaymentQuote {
  const _PixPaymentQuote({required this.satoshis, required this.btcToBrlRate, required this.brlAmount});
  factory _PixPaymentQuote.fromJson(Map<String, dynamic> json) => _$PixPaymentQuoteFromJson(json);

@override final  int satoshis;
@override final  double btcToBrlRate;
@override final  int brlAmount;

/// Create a copy of PixPaymentQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PixPaymentQuoteCopyWith<_PixPaymentQuote> get copyWith => __$PixPaymentQuoteCopyWithImpl<_PixPaymentQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PixPaymentQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PixPaymentQuote&&(identical(other.satoshis, satoshis) || other.satoshis == satoshis)&&(identical(other.btcToBrlRate, btcToBrlRate) || other.btcToBrlRate == btcToBrlRate)&&(identical(other.brlAmount, brlAmount) || other.brlAmount == brlAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,satoshis,btcToBrlRate,brlAmount);

@override
String toString() {
  return 'PixPaymentQuote(satoshis: $satoshis, btcToBrlRate: $btcToBrlRate, brlAmount: $brlAmount)';
}


}

/// @nodoc
abstract mixin class _$PixPaymentQuoteCopyWith<$Res> implements $PixPaymentQuoteCopyWith<$Res> {
  factory _$PixPaymentQuoteCopyWith(_PixPaymentQuote value, $Res Function(_PixPaymentQuote) _then) = __$PixPaymentQuoteCopyWithImpl;
@override @useResult
$Res call({
 int satoshis, double btcToBrlRate, int brlAmount
});




}
/// @nodoc
class __$PixPaymentQuoteCopyWithImpl<$Res>
    implements _$PixPaymentQuoteCopyWith<$Res> {
  __$PixPaymentQuoteCopyWithImpl(this._self, this._then);

  final _PixPaymentQuote _self;
  final $Res Function(_PixPaymentQuote) _then;

/// Create a copy of PixPaymentQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? satoshis = null,Object? btcToBrlRate = null,Object? brlAmount = null,}) {
  return _then(_PixPaymentQuote(
satoshis: null == satoshis ? _self.satoshis : satoshis // ignore: cast_nullable_to_non_nullable
as int,btcToBrlRate: null == btcToBrlRate ? _self.btcToBrlRate : btcToBrlRate // ignore: cast_nullable_to_non_nullable
as double,brlAmount: null == brlAmount ? _self.brlAmount : brlAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PixPaymentRequest {

 bool get success; String get invoice; int get valueInSatoshis; String get pixKey; String get qrCode; int get valueInBrl; int get fee; PixPaymentQuote get quote;
/// Create a copy of PixPaymentRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PixPaymentRequestCopyWith<PixPaymentRequest> get copyWith => _$PixPaymentRequestCopyWithImpl<PixPaymentRequest>(this as PixPaymentRequest, _$identity);

  /// Serializes this PixPaymentRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PixPaymentRequest&&(identical(other.success, success) || other.success == success)&&(identical(other.invoice, invoice) || other.invoice == invoice)&&(identical(other.valueInSatoshis, valueInSatoshis) || other.valueInSatoshis == valueInSatoshis)&&(identical(other.pixKey, pixKey) || other.pixKey == pixKey)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.valueInBrl, valueInBrl) || other.valueInBrl == valueInBrl)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.quote, quote) || other.quote == quote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,invoice,valueInSatoshis,pixKey,qrCode,valueInBrl,fee,quote);

@override
String toString() {
  return 'PixPaymentRequest(success: $success, invoice: $invoice, valueInSatoshis: $valueInSatoshis, pixKey: $pixKey, qrCode: $qrCode, valueInBrl: $valueInBrl, fee: $fee, quote: $quote)';
}


}

/// @nodoc
abstract mixin class $PixPaymentRequestCopyWith<$Res>  {
  factory $PixPaymentRequestCopyWith(PixPaymentRequest value, $Res Function(PixPaymentRequest) _then) = _$PixPaymentRequestCopyWithImpl;
@useResult
$Res call({
 bool success, String invoice, int valueInSatoshis, String pixKey, String qrCode, int valueInBrl, int fee, PixPaymentQuote quote
});


$PixPaymentQuoteCopyWith<$Res> get quote;

}
/// @nodoc
class _$PixPaymentRequestCopyWithImpl<$Res>
    implements $PixPaymentRequestCopyWith<$Res> {
  _$PixPaymentRequestCopyWithImpl(this._self, this._then);

  final PixPaymentRequest _self;
  final $Res Function(PixPaymentRequest) _then;

/// Create a copy of PixPaymentRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? invoice = null,Object? valueInSatoshis = null,Object? pixKey = null,Object? qrCode = null,Object? valueInBrl = null,Object? fee = null,Object? quote = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,invoice: null == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as String,valueInSatoshis: null == valueInSatoshis ? _self.valueInSatoshis : valueInSatoshis // ignore: cast_nullable_to_non_nullable
as int,pixKey: null == pixKey ? _self.pixKey : pixKey // ignore: cast_nullable_to_non_nullable
as String,qrCode: null == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String,valueInBrl: null == valueInBrl ? _self.valueInBrl : valueInBrl // ignore: cast_nullable_to_non_nullable
as int,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PixPaymentQuote,
  ));
}
/// Create a copy of PixPaymentRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PixPaymentQuoteCopyWith<$Res> get quote {
  
  return $PixPaymentQuoteCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}


/// Adds pattern-matching-related methods to [PixPaymentRequest].
extension PixPaymentRequestPatterns on PixPaymentRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PixPaymentRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PixPaymentRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PixPaymentRequest value)  $default,){
final _that = this;
switch (_that) {
case _PixPaymentRequest():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PixPaymentRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PixPaymentRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  String invoice,  int valueInSatoshis,  String pixKey,  String qrCode,  int valueInBrl,  int fee,  PixPaymentQuote quote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PixPaymentRequest() when $default != null:
return $default(_that.success,_that.invoice,_that.valueInSatoshis,_that.pixKey,_that.qrCode,_that.valueInBrl,_that.fee,_that.quote);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  String invoice,  int valueInSatoshis,  String pixKey,  String qrCode,  int valueInBrl,  int fee,  PixPaymentQuote quote)  $default,) {final _that = this;
switch (_that) {
case _PixPaymentRequest():
return $default(_that.success,_that.invoice,_that.valueInSatoshis,_that.pixKey,_that.qrCode,_that.valueInBrl,_that.fee,_that.quote);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  String invoice,  int valueInSatoshis,  String pixKey,  String qrCode,  int valueInBrl,  int fee,  PixPaymentQuote quote)?  $default,) {final _that = this;
switch (_that) {
case _PixPaymentRequest() when $default != null:
return $default(_that.success,_that.invoice,_that.valueInSatoshis,_that.pixKey,_that.qrCode,_that.valueInBrl,_that.fee,_that.quote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PixPaymentRequest implements PixPaymentRequest {
  const _PixPaymentRequest({required this.success, required this.invoice, required this.valueInSatoshis, required this.pixKey, required this.qrCode, required this.valueInBrl, required this.fee, required this.quote});
  factory _PixPaymentRequest.fromJson(Map<String, dynamic> json) => _$PixPaymentRequestFromJson(json);

@override final  bool success;
@override final  String invoice;
@override final  int valueInSatoshis;
@override final  String pixKey;
@override final  String qrCode;
@override final  int valueInBrl;
@override final  int fee;
@override final  PixPaymentQuote quote;

/// Create a copy of PixPaymentRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PixPaymentRequestCopyWith<_PixPaymentRequest> get copyWith => __$PixPaymentRequestCopyWithImpl<_PixPaymentRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PixPaymentRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PixPaymentRequest&&(identical(other.success, success) || other.success == success)&&(identical(other.invoice, invoice) || other.invoice == invoice)&&(identical(other.valueInSatoshis, valueInSatoshis) || other.valueInSatoshis == valueInSatoshis)&&(identical(other.pixKey, pixKey) || other.pixKey == pixKey)&&(identical(other.qrCode, qrCode) || other.qrCode == qrCode)&&(identical(other.valueInBrl, valueInBrl) || other.valueInBrl == valueInBrl)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.quote, quote) || other.quote == quote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,invoice,valueInSatoshis,pixKey,qrCode,valueInBrl,fee,quote);

@override
String toString() {
  return 'PixPaymentRequest(success: $success, invoice: $invoice, valueInSatoshis: $valueInSatoshis, pixKey: $pixKey, qrCode: $qrCode, valueInBrl: $valueInBrl, fee: $fee, quote: $quote)';
}


}

/// @nodoc
abstract mixin class _$PixPaymentRequestCopyWith<$Res> implements $PixPaymentRequestCopyWith<$Res> {
  factory _$PixPaymentRequestCopyWith(_PixPaymentRequest value, $Res Function(_PixPaymentRequest) _then) = __$PixPaymentRequestCopyWithImpl;
@override @useResult
$Res call({
 bool success, String invoice, int valueInSatoshis, String pixKey, String qrCode, int valueInBrl, int fee, PixPaymentQuote quote
});


@override $PixPaymentQuoteCopyWith<$Res> get quote;

}
/// @nodoc
class __$PixPaymentRequestCopyWithImpl<$Res>
    implements _$PixPaymentRequestCopyWith<$Res> {
  __$PixPaymentRequestCopyWithImpl(this._self, this._then);

  final _PixPaymentRequest _self;
  final $Res Function(_PixPaymentRequest) _then;

/// Create a copy of PixPaymentRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? invoice = null,Object? valueInSatoshis = null,Object? pixKey = null,Object? qrCode = null,Object? valueInBrl = null,Object? fee = null,Object? quote = null,}) {
  return _then(_PixPaymentRequest(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,invoice: null == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as String,valueInSatoshis: null == valueInSatoshis ? _self.valueInSatoshis : valueInSatoshis // ignore: cast_nullable_to_non_nullable
as int,pixKey: null == pixKey ? _self.pixKey : pixKey // ignore: cast_nullable_to_non_nullable
as String,qrCode: null == qrCode ? _self.qrCode : qrCode // ignore: cast_nullable_to_non_nullable
as String,valueInBrl: null == valueInBrl ? _self.valueInBrl : valueInBrl // ignore: cast_nullable_to_non_nullable
as int,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PixPaymentQuote,
  ));
}

/// Create a copy of PixPaymentRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PixPaymentQuoteCopyWith<$Res> get quote {
  
  return $PixPaymentQuoteCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}


/// @nodoc
mixin _$WithdrawStatus {

 String get status;// 'pending', 'processing', 'completed', 'failed'
 String get withdrawId; String? get txid; String? get errorMessage; DateTime? get completedAt;
/// Create a copy of WithdrawStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawStatusCopyWith<WithdrawStatus> get copyWith => _$WithdrawStatusCopyWithImpl<WithdrawStatus>(this as WithdrawStatus, _$identity);

  /// Serializes this WithdrawStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.withdrawId, withdrawId) || other.withdrawId == withdrawId)&&(identical(other.txid, txid) || other.txid == txid)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,withdrawId,txid,errorMessage,completedAt);

@override
String toString() {
  return 'WithdrawStatus(status: $status, withdrawId: $withdrawId, txid: $txid, errorMessage: $errorMessage, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $WithdrawStatusCopyWith<$Res>  {
  factory $WithdrawStatusCopyWith(WithdrawStatus value, $Res Function(WithdrawStatus) _then) = _$WithdrawStatusCopyWithImpl;
@useResult
$Res call({
 String status, String withdrawId, String? txid, String? errorMessage, DateTime? completedAt
});




}
/// @nodoc
class _$WithdrawStatusCopyWithImpl<$Res>
    implements $WithdrawStatusCopyWith<$Res> {
  _$WithdrawStatusCopyWithImpl(this._self, this._then);

  final WithdrawStatus _self;
  final $Res Function(WithdrawStatus) _then;

/// Create a copy of WithdrawStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? withdrawId = null,Object? txid = freezed,Object? errorMessage = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,withdrawId: null == withdrawId ? _self.withdrawId : withdrawId // ignore: cast_nullable_to_non_nullable
as String,txid: freezed == txid ? _self.txid : txid // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawStatus].
extension WithdrawStatusPatterns on WithdrawStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawStatus value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawStatus():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawStatus value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String withdrawId,  String? txid,  String? errorMessage,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawStatus() when $default != null:
return $default(_that.status,_that.withdrawId,_that.txid,_that.errorMessage,_that.completedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String withdrawId,  String? txid,  String? errorMessage,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _WithdrawStatus():
return $default(_that.status,_that.withdrawId,_that.txid,_that.errorMessage,_that.completedAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String withdrawId,  String? txid,  String? errorMessage,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawStatus() when $default != null:
return $default(_that.status,_that.withdrawId,_that.txid,_that.errorMessage,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawStatus implements WithdrawStatus {
  const _WithdrawStatus({required this.status, required this.withdrawId, this.txid, this.errorMessage, this.completedAt});
  factory _WithdrawStatus.fromJson(Map<String, dynamic> json) => _$WithdrawStatusFromJson(json);

@override final  String status;
// 'pending', 'processing', 'completed', 'failed'
@override final  String withdrawId;
@override final  String? txid;
@override final  String? errorMessage;
@override final  DateTime? completedAt;

/// Create a copy of WithdrawStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawStatusCopyWith<_WithdrawStatus> get copyWith => __$WithdrawStatusCopyWithImpl<_WithdrawStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.withdrawId, withdrawId) || other.withdrawId == withdrawId)&&(identical(other.txid, txid) || other.txid == txid)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,withdrawId,txid,errorMessage,completedAt);

@override
String toString() {
  return 'WithdrawStatus(status: $status, withdrawId: $withdrawId, txid: $txid, errorMessage: $errorMessage, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$WithdrawStatusCopyWith<$Res> implements $WithdrawStatusCopyWith<$Res> {
  factory _$WithdrawStatusCopyWith(_WithdrawStatus value, $Res Function(_WithdrawStatus) _then) = __$WithdrawStatusCopyWithImpl;
@override @useResult
$Res call({
 String status, String withdrawId, String? txid, String? errorMessage, DateTime? completedAt
});




}
/// @nodoc
class __$WithdrawStatusCopyWithImpl<$Res>
    implements _$WithdrawStatusCopyWith<$Res> {
  __$WithdrawStatusCopyWithImpl(this._self, this._then);

  final _WithdrawStatus _self;
  final $Res Function(_WithdrawStatus) _then;

/// Create a copy of WithdrawStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? withdrawId = null,Object? txid = freezed,Object? errorMessage = freezed,Object? completedAt = freezed,}) {
  return _then(_WithdrawStatus(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,withdrawId: null == withdrawId ? _self.withdrawId : withdrawId // ignore: cast_nullable_to_non_nullable
as String,txid: freezed == txid ? _self.txid : txid // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PixPayment {

 String get withdrawId; String get invoice; int get valueInBrl; int get valueInSatoshis; String get pixKey; int get fee; PixPaymentQuote get quote; DateTime get createdAt;
/// Create a copy of PixPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PixPaymentCopyWith<PixPayment> get copyWith => _$PixPaymentCopyWithImpl<PixPayment>(this as PixPayment, _$identity);

  /// Serializes this PixPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PixPayment&&(identical(other.withdrawId, withdrawId) || other.withdrawId == withdrawId)&&(identical(other.invoice, invoice) || other.invoice == invoice)&&(identical(other.valueInBrl, valueInBrl) || other.valueInBrl == valueInBrl)&&(identical(other.valueInSatoshis, valueInSatoshis) || other.valueInSatoshis == valueInSatoshis)&&(identical(other.pixKey, pixKey) || other.pixKey == pixKey)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,withdrawId,invoice,valueInBrl,valueInSatoshis,pixKey,fee,quote,createdAt);

@override
String toString() {
  return 'PixPayment(withdrawId: $withdrawId, invoice: $invoice, valueInBrl: $valueInBrl, valueInSatoshis: $valueInSatoshis, pixKey: $pixKey, fee: $fee, quote: $quote, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PixPaymentCopyWith<$Res>  {
  factory $PixPaymentCopyWith(PixPayment value, $Res Function(PixPayment) _then) = _$PixPaymentCopyWithImpl;
@useResult
$Res call({
 String withdrawId, String invoice, int valueInBrl, int valueInSatoshis, String pixKey, int fee, PixPaymentQuote quote, DateTime createdAt
});


$PixPaymentQuoteCopyWith<$Res> get quote;

}
/// @nodoc
class _$PixPaymentCopyWithImpl<$Res>
    implements $PixPaymentCopyWith<$Res> {
  _$PixPaymentCopyWithImpl(this._self, this._then);

  final PixPayment _self;
  final $Res Function(PixPayment) _then;

/// Create a copy of PixPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? withdrawId = null,Object? invoice = null,Object? valueInBrl = null,Object? valueInSatoshis = null,Object? pixKey = null,Object? fee = null,Object? quote = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
withdrawId: null == withdrawId ? _self.withdrawId : withdrawId // ignore: cast_nullable_to_non_nullable
as String,invoice: null == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as String,valueInBrl: null == valueInBrl ? _self.valueInBrl : valueInBrl // ignore: cast_nullable_to_non_nullable
as int,valueInSatoshis: null == valueInSatoshis ? _self.valueInSatoshis : valueInSatoshis // ignore: cast_nullable_to_non_nullable
as int,pixKey: null == pixKey ? _self.pixKey : pixKey // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PixPaymentQuote,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of PixPayment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PixPaymentQuoteCopyWith<$Res> get quote {
  
  return $PixPaymentQuoteCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}


/// Adds pattern-matching-related methods to [PixPayment].
extension PixPaymentPatterns on PixPayment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PixPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PixPayment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PixPayment value)  $default,){
final _that = this;
switch (_that) {
case _PixPayment():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PixPayment value)?  $default,){
final _that = this;
switch (_that) {
case _PixPayment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String withdrawId,  String invoice,  int valueInBrl,  int valueInSatoshis,  String pixKey,  int fee,  PixPaymentQuote quote,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PixPayment() when $default != null:
return $default(_that.withdrawId,_that.invoice,_that.valueInBrl,_that.valueInSatoshis,_that.pixKey,_that.fee,_that.quote,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String withdrawId,  String invoice,  int valueInBrl,  int valueInSatoshis,  String pixKey,  int fee,  PixPaymentQuote quote,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PixPayment():
return $default(_that.withdrawId,_that.invoice,_that.valueInBrl,_that.valueInSatoshis,_that.pixKey,_that.fee,_that.quote,_that.createdAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String withdrawId,  String invoice,  int valueInBrl,  int valueInSatoshis,  String pixKey,  int fee,  PixPaymentQuote quote,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PixPayment() when $default != null:
return $default(_that.withdrawId,_that.invoice,_that.valueInBrl,_that.valueInSatoshis,_that.pixKey,_that.fee,_that.quote,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PixPayment implements PixPayment {
  const _PixPayment({required this.withdrawId, required this.invoice, required this.valueInBrl, required this.valueInSatoshis, required this.pixKey, required this.fee, required this.quote, required this.createdAt});
  factory _PixPayment.fromJson(Map<String, dynamic> json) => _$PixPaymentFromJson(json);

@override final  String withdrawId;
@override final  String invoice;
@override final  int valueInBrl;
@override final  int valueInSatoshis;
@override final  String pixKey;
@override final  int fee;
@override final  PixPaymentQuote quote;
@override final  DateTime createdAt;

/// Create a copy of PixPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PixPaymentCopyWith<_PixPayment> get copyWith => __$PixPaymentCopyWithImpl<_PixPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PixPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PixPayment&&(identical(other.withdrawId, withdrawId) || other.withdrawId == withdrawId)&&(identical(other.invoice, invoice) || other.invoice == invoice)&&(identical(other.valueInBrl, valueInBrl) || other.valueInBrl == valueInBrl)&&(identical(other.valueInSatoshis, valueInSatoshis) || other.valueInSatoshis == valueInSatoshis)&&(identical(other.pixKey, pixKey) || other.pixKey == pixKey)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,withdrawId,invoice,valueInBrl,valueInSatoshis,pixKey,fee,quote,createdAt);

@override
String toString() {
  return 'PixPayment(withdrawId: $withdrawId, invoice: $invoice, valueInBrl: $valueInBrl, valueInSatoshis: $valueInSatoshis, pixKey: $pixKey, fee: $fee, quote: $quote, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PixPaymentCopyWith<$Res> implements $PixPaymentCopyWith<$Res> {
  factory _$PixPaymentCopyWith(_PixPayment value, $Res Function(_PixPayment) _then) = __$PixPaymentCopyWithImpl;
@override @useResult
$Res call({
 String withdrawId, String invoice, int valueInBrl, int valueInSatoshis, String pixKey, int fee, PixPaymentQuote quote, DateTime createdAt
});


@override $PixPaymentQuoteCopyWith<$Res> get quote;

}
/// @nodoc
class __$PixPaymentCopyWithImpl<$Res>
    implements _$PixPaymentCopyWith<$Res> {
  __$PixPaymentCopyWithImpl(this._self, this._then);

  final _PixPayment _self;
  final $Res Function(_PixPayment) _then;

/// Create a copy of PixPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? withdrawId = null,Object? invoice = null,Object? valueInBrl = null,Object? valueInSatoshis = null,Object? pixKey = null,Object? fee = null,Object? quote = null,Object? createdAt = null,}) {
  return _then(_PixPayment(
withdrawId: null == withdrawId ? _self.withdrawId : withdrawId // ignore: cast_nullable_to_non_nullable
as String,invoice: null == invoice ? _self.invoice : invoice // ignore: cast_nullable_to_non_nullable
as String,valueInBrl: null == valueInBrl ? _self.valueInBrl : valueInBrl // ignore: cast_nullable_to_non_nullable
as int,valueInSatoshis: null == valueInSatoshis ? _self.valueInSatoshis : valueInSatoshis // ignore: cast_nullable_to_non_nullable
as int,pixKey: null == pixKey ? _self.pixKey : pixKey // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as int,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PixPaymentQuote,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of PixPayment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PixPaymentQuoteCopyWith<$Res> get quote {
  
  return $PixPaymentQuoteCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}

// dart format on
