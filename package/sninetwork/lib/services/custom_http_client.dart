import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:sninetwork/models/sninetwork_host_rule.dart';

// Implements the correct, existing interface: InterceptorContract
class RedirectionInterceptor implements InterceptorContract {
  final List<SninetworkHostRule> _rules;

  RedirectionInterceptor(this._rules);

  // This is the correct signature for InterceptorContract
  @override
  Future<http.BaseRequest> interceptRequest({required http.BaseRequest request}) async {
    final originalUri = request.url;

    for (final rule in _rules) {
      final matchingSource = rule.hosts.firstWhere(
        (s) =>
            originalUri.host == s ||
            (s.startsWith('*') && originalUri.host.endsWith(s.substring(1))),
        orElse: () => '',
      );

      if (matchingSource.isNotEmpty && rule.targetIp.isNotEmpty) {
        print(
            '[Sninetwork] Matched: ${originalUri.host}. Redirecting to IP: ${rule.targetIp}');

        final newUri = originalUri.replace(host: rule.targetIp);

        // The request is immutable, so we must create a new one.
        // We manually copy headers, content, and other properties.
        final newRequest = http.Request(request.method, newUri)
          ..headers.addAll(request.headers)
          ..headers[HttpHeaders.hostHeader] = originalUri.host;
        
        if (request is http.Request) {
          newRequest.bodyBytes = request.bodyBytes;
        }

        return newRequest;
      }
    }

    print(
        '[Sninetwork] No rule matched for: ${originalUri.host}. Proceeding normally.');
    return request;
  }

  @override
  Future<http.BaseResponse> interceptResponse(
      {required http.BaseResponse response}) async => response;

  // These methods are also required by the InterceptorContract interface
  @override
  Future<bool> shouldInterceptRequest() async => true;

  @override
  Future<bool> shouldInterceptResponse() async => true;
}


http.Client getSealedClient(List<SninetworkHostRule> rules) {
  final ioc = HttpClient();
  ioc.badCertificateCallback = (X509Certificate cert, String host, int port) {
    for (final rule in rules) {
      if (rule.targetIp == host) {
        print('[Sninetwork] Trusting certificate for redirected host: $host');
        return true;
      }
    }
    return false;
  };

  final baseClient = http_io.IOClient(ioc);

  // Use InterceptedClient.build with the correct InterceptorContract
  return InterceptedClient.build(
    client: baseClient, 
    interceptors: [
      RedirectionInterceptor(rules),
    ],
  );
}
