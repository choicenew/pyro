
import 'package:json_annotation/json_annotation.dart';

part 'sninetwork_host_rule.g.dart';

@JsonSerializable(createToJson: false)
class SninetworkHostRule {
  final List<String> hosts;
  // The `sni` can be null, so we make it nullable.
  final String? sni;
  final String targetIp;

  SninetworkHostRule(this.hosts, this.sni, this.targetIp);

  // Custom fromJson factory to handle the list-based format.
  factory SninetworkHostRule.fromJson(List<dynamic> json) {
    return SninetworkHostRule(
      // The first element is a list of host strings.
      (json[0] as List<dynamic>).map((e) => e as String).toList(),
      // The second element is the SNI, which can be null.
      json[1] as String?,
      // The third element is the target IP address.
      json[2] as String,
    );
  }
}
