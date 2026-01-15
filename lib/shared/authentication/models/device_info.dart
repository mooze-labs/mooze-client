import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@JsonSerializable()
class DeviceInfo {
  @JsonKey(name: 'battery_level')
  final int? batteryLevel;

  @JsonKey(name: 'screen_brightness')
  final double? screenBrightness;

  @JsonKey(name: 'boot_time')
  final DateTime? bootTime;

  DeviceInfo({this.batteryLevel, this.screenBrightness, this.bootTime});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);
}
