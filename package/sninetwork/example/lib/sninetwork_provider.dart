import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sninetwork/sninetwork.dart';

class SninetworkProvider with ChangeNotifier {
  final ApiService _apiService = ApiService(http.Client());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<SninetworkHostRule> _rules = [];
  List<SninetworkHostRule> get rules => _rules;

  late http.Client _httpClient;
  http.Client get httpClient => _httpClient;

  SninetworkProvider() {
    _httpClient = http.Client();
    _loadRules();
  }

  Future<void> _loadRules() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rules = await _apiService.fetchRules();

      // With our new, refactored getSealedClient, creating the client is now a single, clean step.
      _httpClient = getSealedClient(_rules);

      print(
          "[Sninetwork] The new, fully-featured 'Trinity' client is now active.");
    } catch (e) {
      print("Error loading rules or creating the sealed client: $e");
      _httpClient = http.Client(); // Fallback to a regular client on error
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
