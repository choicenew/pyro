// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sninetwork_host_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SninetworkHostRule _$SninetworkHostRuleFromJson(Map<String, dynamic> json) =>
    SninetworkHostRule(
      (json['hosts'] as List<dynamic>).map((e) => e as String).toList(),
      json['sni'] as String?,
      json['targetIp'] as String,
    );
