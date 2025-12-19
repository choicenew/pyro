import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:sninetwork/sninetwork.dart';

class SniNetworkService {
  // 单例模式
  static final SniNetworkService _instance = SniNetworkService._internal();

  factory SniNetworkService() {
    return _instance;
  }

  SniNetworkService._internal();

  late http.Client _client;
  final ApiService _apiService = ApiService(http.Client());
  bool _isInitialized = false;
  List<SninetworkHostRule> _rules = [];

  /// 初始化服务并加载规则
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. 加载规则 (异步)
      _rules = await _apiService.fetchRules();

      // 2. 创建 Sealed Client
      _client = getSealedClient(_rules);

      _isInitialized = true;
      debugPrint(
          '[SniNetworkService] Initialized successfully with ${_rules.length} rules.');
    } catch (e) {
      debugPrint('[SniNetworkService] Initialization failed: $e');
      _client = http.Client();
      _rules = [];
    }
  }

  /// 获取 Sealed Client 实例
  http.Client get client {
    if (!_isInitialized) {
      debugPrint(
          '[SniNetworkService] Warning: Client accessed before initialization. Returning default client.');
      return http.Client();
    }
    return _client;
  }

  /// 判断是否需要拦截
  bool shouldIntercept(Uri url) {
    if (!_isInitialized) return false;
    return _rules.any((rule) => rule.hosts.any((host) =>
        host == url.host ||
        (host.startsWith('*') && url.host.endsWith(host.substring(1)))));
  }

  /// 注入 WebView 的 JS 脚本
  String get interceptorJs {
    // 提取所有规则中的 Host 列表，用于 JS 侧预过滤
    final allHosts = _rules.expand((r) => r.hosts).toList();
    final rulesJson = jsonEncode(allHosts);

    // 注入的脚本会拦截 window.fetch，如果域名匹配规则，则通过 bridge 调用原生网络请求
    return '''
      (function() {
          const rules = $rulesJson;

          function shouldInterceptUrl(url) {
              const hostname = new URL(url).hostname;
              return rules.some(host => {
                  if (host.startsWith('*')) {
                      return hostname.endsWith(host.substring(1));
                  } else {
                      return hostname === host;
                  }
              });
          }

          if (window.fetch.toString().includes("native code")) {
              const originalFetch = window.fetch;
              window.fetch = async function(url, options) {
                  const urlString = (url instanceof Request) ? url.url : url.toString();
                  
                  if (shouldInterceptUrl(urlString)) {
                      // debug log
                      // console.log('[JS Intercept] Intercepting: ' + urlString);
                      try {
                          const body = options?.body;
                          let bodyBase64 = null;
                          if (body) {
                              // 处理 Body
                              const reader = new FileReader();
                              const promise = new Promise((resolve, reject) => {
                                  reader.onloadend = () => resolve(reader.result);
                                  reader.onerror = reject;
                              });
                              if (body instanceof Blob) {
                                  reader.readAsDataURL(body);
                                  bodyBase64 = (await promise).split(',')[1];
                              } else {
                                  // 简化起见，我们暂只处理简单类型，复杂类型留待后续完善
                                  bodyBase64 = null; 
                              }
                          }

                          // 调用 Dart
                          const result = await window.flutter_inappwebview.callHandler('sealerFetch', {
                              'url': urlString,
                              'method': options?.method || 'GET',
                              'headers': options?.headers || {},
                              // 'body': bodyBase64 
                          });
                          
                          // 如果 Dart 返回 null，说明不需要拦截，继续走原始 fetch
                          if (result === null) {
                              return originalFetch(url, options);
                          }

                          return new Response(
                            result.statusCode === 204 ? null : atob(result.body), 
                            {
                              status: result.statusCode,
                              statusText: result.reasonPhrase,
                              headers: result.headers
                            }
                          );
                      } catch (e) {
                          // 出错或者 Dart 抛异常，降级回原始 fetch
                          console.error('[JS Intercept] Fallback: ', e);
                          return originalFetch(url, options);
                      }
                  } else {
                      return originalFetch(url, options);
                  }
              };
          }
      })();
    ''';
  }

  /// 处理来自 JS 的 Fetch 请求
  Future<Map<String, dynamic>?> handleJsFetch(Map<String, dynamic> args) async {
    final String urlStr = args['url'];
    final Uri uri = Uri.parse(urlStr);

    // 1. 检查是否需要拦截
    if (!shouldIntercept(uri)) {
      return null; // 返回 null 告诉 JS 继续走原始逻辑
    }

    debugPrint('[SniNetworkService] Intercepting JS fetch: $urlStr');

    try {
      final String method = args['method'];
      final Map<String, dynamic> headers =
          Map<String, dynamic>.from(args['headers'] ?? {});
      final String? bodyBase64 = args['body'];

      final request = http.Request(method, uri);

      headers.forEach((key, value) {
        request.headers[key] = value.toString();
      });

      if (bodyBase64 != null) {
        request.bodyBytes = base64Decode(bodyBase64);
      }

      // 2. 使用 Sealed Client 发送请求
      final response =
          await http.Response.fromStream(await _client.send(request));

      return {
        'statusCode': response.statusCode,
        'reasonPhrase': response.reasonPhrase,
        'headers': response.headers,
        'body': base64Encode(response.bodyBytes),
      };
    } catch (e) {
      debugPrint('[SniNetworkService] JS Fetch error: $e');
      throw e; // 抛出异常让 JS 侧捕获并降级
    }
  }

  /// 处理 WebView 导航拦截
  Future<void> handleNavigation(
      InAppWebViewController controller, URLRequest request) async {
    final uri = request.url;
    if (uri == null) return;

    debugPrint('[SniNetworkService] Overriding navigation for: $uri');

    try {
      final method = request.method ?? 'GET';
      final headers = request.headers
              ?.map((key, value) => MapEntry(key, value.toString())) ??
          {};

      final httpRequest = http.Request(method, uri)..headers.addAll(headers);
      final response =
          await http.Response.fromStream(await _client.send(httpRequest));

      await controller.loadData(
        data: utf8.decode(response.bodyBytes, allowMalformed: true),
        mimeType:
            response.headers['content-type']?.split(';').first ?? 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri.uri(uri),
      );
    } catch (e) {
      debugPrint('[SniNetworkService] Navigation Override Error: $e');
      // 可以在这里加载一个错误页或者不做处理
    }
  }
}
