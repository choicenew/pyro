
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sninetwork/models/sninetwork_host_rule.dart';

class ApiService {
  final http.Client _client;
  // Using a well-known mirror for better accessibility in mainland China.
  static const String _rulesUrl = 'https://raw.gitmirror.com/SpaceTimee/Cealing-Host/main/Cealing-Host.json';

  ApiService(this._client);

  Future<List<SninetworkHostRule>> fetchRules() async {
    try {
      final response = await _client.get(Uri.parse(_rulesUrl));

      if (response.statusCode == 200) {
        // The JSON is a list of lists, e.g., [[["*github.com"], "", "IP"], ...]
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        final rules = data.map((item) {
          try {
            // Each item is a list representing a rule.
            return SninetworkHostRule.fromJson(item as List<dynamic>);
          } catch (e) {
            print('[ApiService] Skipping invalid rule format: $item. Error: $e');
            return null;
          }
        }).where((rule) => rule != null && rule.targetIp.isNotEmpty).cast<SninetworkHostRule>().toList();

        print('[ApiService] Successfully loaded ${rules.length} rules with target IPs.');
        return rules;
      } else {
        print('[ApiService] Failed to load rules. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[ApiService] Error fetching rules: $e');
      return [];
    }
  }
}
