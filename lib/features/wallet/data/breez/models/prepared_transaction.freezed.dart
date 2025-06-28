// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prepared_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PreparedTransaction {

 Object get res;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreparedTransaction&&const DeepCollectionEquality().equals(other.res, res));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(res));

@override
String toString() {
  return 'PreparedTransaction(res: $res)';
}


}

/// @nodoc
class $PreparedTransactionCopyWith<$Res>  {
$PreparedTransactionCopyWith(PreparedTransaction _, $Res Function(PreparedTransaction) __);
}


/// @nodoc


class OnchainPsbt implements PreparedTransaction {
  const OnchainPsbt(this.res);
  

@override final  PreparePayOnchainResponse res;

/// Create a copy of PreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnchainPsbtCopyWith<OnchainPsbt> get copyWith => _$OnchainPsbtCopyWithImpl<OnchainPsbt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnchainPsbt&&(identical(other.res, res) || other.res == res));
}


@override
int get hashCode => Object.hash(runtimeType,res);

@override
String toString() {
  return 'PreparedTransaction.onchain(res: $res)';
}


}

/// @nodoc
abstract mixin class $OnchainPsbtCopyWith<$Res> implements $PreparedTransactionCopyWith<$Res> {
  factory $OnchainPsbtCopyWith(OnchainPsbt value, $Res Function(OnchainPsbt) _then) = _$OnchainPsbtCopyWithImpl;
@useResult
$Res call({
 PreparePayOnchainResponse res
});




}
/// @nodoc
class _$OnchainPsbtCopyWithImpl<$Res>
    implements $OnchainPsbtCopyWith<$Res> {
  _$OnchainPsbtCopyWithImpl(this._self, this._then);

  final OnchainPsbt _self;
  final $Res Function(OnchainPsbt) _then;

/// Create a copy of PreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? res = null,}) {
  return _then(OnchainPsbt(
null == res ? _self.res : res // ignore: cast_nullable_to_non_nullable
as PreparePayOnchainResponse,
  ));
}


}

/// @nodoc


class L2Psbt implements PreparedTransaction {
  const L2Psbt(this.res);
  

@override final  PrepareSendResponse res;

/// Create a copy of PreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$L2PsbtCopyWith<L2Psbt> get copyWith => _$L2PsbtCopyWithImpl<L2Psbt>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is L2Psbt&&(identical(other.res, res) || other.res == res));
}


@override
int get hashCode => Object.hash(runtimeType,res);

@override
String toString() {
  return 'PreparedTransaction.l2(res: $res)';
}


}

/// @nodoc
abstract mixin class $L2PsbtCopyWith<$Res> implements $PreparedTransactionCopyWith<$Res> {
  factory $L2PsbtCopyWith(L2Psbt value, $Res Function(L2Psbt) _then) = _$L2PsbtCopyWithImpl;
@useResult
$Res call({
 PrepareSendResponse res
});




}
/// @nodoc
class _$L2PsbtCopyWithImpl<$Res>
    implements $L2PsbtCopyWith<$Res> {
  _$L2PsbtCopyWithImpl(this._self, this._then);

  final L2Psbt _self;
  final $Res Function(L2Psbt) _then;

/// Create a copy of PreparedTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? res = null,}) {
  return _then(L2Psbt(
null == res ? _self.res : res // ignore: cast_nullable_to_non_nullable
as PrepareSendResponse,
  ));
}


}

// dart format on
