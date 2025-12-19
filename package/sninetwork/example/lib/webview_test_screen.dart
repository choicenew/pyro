
import 'dart:convert';

import 'package:example/sninetwork_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class WebviewTestScreen extends StatefulWidget {
  final String url;

  const WebviewTestScreen({super.key, required this.url});

  @override
  State<WebviewTestScreen> createState() => _WebviewTestScreenState();
}

class _WebviewTestScreenState extends State<WebviewTestScreen> {
  late http.Client _sealerHttpClient;
  bool _isSealerReady = false;
  late Uri _initialUri;

  @override
  void initState() {
    super.initState();
    _initialUri = Uri.parse(widget.url);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sealerHttpClient =
          Provider.of<SealerProvider>(context, listen: false).httpClient;
      setState(() {
        _isSealerReady = true;
      });
    });
  }

  bool _shouldIntercept(Uri url) {
    final sealer = Provider.of<SealerProvider>(context, listen: false);
    return sealer.rules.any((rule) => rule.hosts.any((host) =>
        host == url.host ||
        (host.startsWith('*') && url.host.endsWith(host.substring(1)))));
  }

  @override
  Widget build(BuildContext context) {
    // FIX 1: Construct the JS string inside the build method to correctly access instance members.
    final String fetchOverrideJs = '''
      (function() {
          if (window.fetch.toString().includes("native code")) {
              const originalFetch = window.fetch;
              window.fetch = async function(url, options) {
                  const urlString = (url instanceof Request) ? url.url : url.toString();
                  
                  if (urlString.includes('${_initialUri.host}')) {
                      console.log('[JS Intercept] Fetching: ' + urlString);
                      try {
                          const body = options?.body;
                          let bodyBase64 = null;
                          if (body) {
                              const reader = new FileReader();
                              const promise = new Promise((resolve, reject) => {
                                  reader.onloadend = () => resolve(reader.result);
                                  reader.onerror = reject;
                              });
                              if (body instanceof Blob) {
                                  reader.readAsDataURL(body);
                                  bodyBase64 = (await promise).split(',')[1];
                              } else {
                                 bodyBase64 = btoa(await new Response(body).text());
                              }
                          }

                          const result = await window.flutter_inappwebview.callHandler('sealerFetch', {
                              'url': urlString,
                              'method': options?.method || 'GET',
                              'headers': options?.headers || {},
                              'body': bodyBase64
                          });

                          return new Response(
                            result.statusCode === 204 ? null : atob(result.body), 
                            {
                              status: result.statusCode,
                              statusText: result.reasonPhrase,
                              headers: result.headers
                            }
                          );
                      } catch (e) {
                          console.error('[JS Intercept] Error: ', e);
                          return Promise.reject(e);
                      }
                  } else {
                      return originalFetch(url, options);
                  }
              };
          }
      })();
  ''';

    return Scaffold(
      appBar: AppBar(title: const Text('WebView Test')),
      body: _isSealerReady
          ? InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri.uri(_initialUri)),
              onWebViewCreated: (controller) {
                controller.addJavaScriptHandler(
                    handlerName: 'sealerFetch',
                    callback: (args) async {
                      final Map<String, dynamic> fetchArgs = args[0];
                      final String url = fetchArgs['url'];
                      final String method = fetchArgs['method'];
                      final Map<String, dynamic> headers = fetchArgs['headers'];
                      final String? bodyBase64 = fetchArgs['body'];

                      try {
                        final request = http.Request(method, Uri.parse(url));
                        headers.forEach((key, value) {
                          request.headers[key] = value.toString();
                        });
                        if (bodyBase64 != null) {
                          request.bodyBytes = base64Decode(bodyBase64);
                        }
                        final response = await http.Response.fromStream(
                            await _sealerHttpClient.send(request));
                        return {
                          'statusCode': response.statusCode,
                          'reasonPhrase': response.reasonPhrase,
                          'headers': response.headers,
                          'body': base64Encode(response.bodyBytes),
                        };
                      } catch (e) {
                        return {
                          'statusCode': 500,
                          'reasonPhrase': 'Internal Error',
                          'headers': {},
                          'body': base64Encode(utf8.encode(e.toString())),
                        };
                      }
                    });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri != null && _shouldIntercept(uri)) {
                  print('[WebView-Sealer] Overriding URL loading for: $uri');
                  try {
                    final method = navigationAction.request.method ?? 'GET';
                    final headers = navigationAction.request.headers?.map((key, value) => MapEntry(key, value.toString())) ?? {};
                    final request = http.Request(method, uri)..headers.addAll(headers);
                    final response = await http.Response.fromStream(await _sealerHttpClient.send(request));

                    // FIX 2: Correctly decode the Uint8List to a String for the 'data' parameter.
                    await controller.loadData(
                      data: utf8.decode(response.bodyBytes, allowMalformed: true),
                      mimeType: response.headers['content-type']?.split(';').first ?? 'text/html',
                      encoding: 'utf-8',
                      baseUrl: WebUri.uri(uri),
                    );
                    return NavigationActionPolicy.CANCEL;
                  } catch (e) {
                    print('[WebView-Sealer] Error overriding URL: $e');
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) {
                controller.evaluateJavascript(source: fetchOverrideJs);
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Waiting for Sealer..."),
                ],
              ),
            ),
    );
  }
}
