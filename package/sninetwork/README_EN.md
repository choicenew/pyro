<h1 align="center">Shea's Sealer - Flutter Plugin</h1>
<h3 align="center">An HTTP Interceptor Plugin for Domain Redirection Logic</h3>
<br>

## Other Languages
[中文说明](README.md)

## Features
`sheas_sealer` is a Flutter plugin that provides an HTTP interceptor, `DomainRedirectInterceptor`. When you make network requests using the standard `http` package, this interceptor can automatically redirect requests to an available domain based on a predefined set of rules.

This is particularly useful for scenarios that require dynamic API endpoint switching or failover capabilities across multiple alternative domains.

## How to Install
Add this plugin to your `pubspec.yaml` file:

```yaml
dependencies:
  sheas_sealer:
    path: ../  # Or use a version number: ^1.0.0
  http: ^1.2.1
  http_interceptor: ^2.0.0
```
Then, run `flutter pub get`.

## How to Use

Here is a complete example of how to use the `sheas_sealer` plugin in your Flutter application.

### 1. Import Necessary Packages
```dart
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:sheas_sealer/sheas_sealer.dart';
```

### 2. Initialize and Set Up the Interceptor
Before making any network requests, you need to initialize `ApiService` and create an `http` client that integrates `DomainRedirectInterceptor`.

```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final http.Client client;

  @override
  void initState() {
    super.initState();

    // 1. Initialize ApiService to download and manage redirection rules
    final apiService = ApiService();
    apiService.loadRules(); // Asynchronously loads the rules

    // 2. Create an HTTP client integrated with our interceptor
    client = InterceptedClient.build(
      interceptors: [
        DomainRedirectInterceptor(apiService: apiService),
      ],
    );

    // 3. (Optional) You can now use this client to make requests
    // client.get(Uri.parse("https://example.com/api/data"));
  }

  @override
  Widget build(BuildContext context) {
    // ... Use the 'client' variable in your app
    return MaterialApp(
      // ...
    );
  }
}
```

### 3. Make Requests
Now, you can use the created `client` instance to make network requests as usual. The `DomainRedirectInterceptor` will automatically handle the domain replacement logic.

If the domain of the original request is in the ruleset, it will be replaced with an available target domain.

```dart
Future<void> fetchData() async {
  try {
    // Assume "https://original-domain.com" is a domain that needs to be redirected
    final response = await client.get(Uri.parse("https://original-domain.com/some/path"));
    
    if (response.statusCode == 200) {
      print("Request successful: ${response.body}");
    } else {
      print("Request failed: ${response.statusCode}");
    }
  } catch (e) {
    print("An error occurred: $e");
  }
}
```

## See the Example
For a complete, runnable example, please refer to the code in the `example` folder.

## Disclaimer
*   This project is for learning and technical research purposes only.
*   Please ensure your network environment has access to the rule server and the target websites.
