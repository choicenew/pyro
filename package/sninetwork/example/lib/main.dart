
import 'package:example/sninetwork_provider.dart';
import 'package:example/webview_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SninetworkProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sninetwork Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://raw.githubusercontent.com/flutter/flutter/master/README.md',
  );
  String _testResult = '';
  bool _isTesting = false;

  Future<void> _runTest() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _testResult = 'Please enter a URL to test.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = 'Testing...';
    });

    try {
      final sninetworkProvider = Provider.of<SninetworkProvider>(context, listen: false);
      
      String url = _urlController.text.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final uri = Uri.parse(url);
      
      final response = await sninetworkProvider.httpClient.get(uri);

      setState(() {
        _testResult = """
Status Code: ${response.statusCode}
Body (first 200 chars):
${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}
        """;
      });

    } catch (e) {
      setState(() {
        _testResult = 'Test failed with error:\n$e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  void _navigateToWebView() {
     String url = _urlController.text.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebviewTestScreen(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sninetworkProvider = Provider.of<SninetworkProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sninetwork Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Redirection rules are now active!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              sninetworkProvider.isLoading
                  ? const Text('Loading rules...')
                  : Text('Loaded ${sninetworkProvider.rules.length} rules with IP targets.'),
              const SizedBox(height: 40),
              
              // URL Input Field
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Enter URL to Test',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Test Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: sninetworkProvider.isLoading || _isTesting ? null : _runTest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isTesting 
                        ? const CircularProgressIndicator()
                        : const Text('Test Connection', style: TextStyle(fontSize: 14)),
                  ),
                  ElevatedButton(
                    onPressed: sninetworkProvider.isLoading ? null : _navigateToWebView,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Test in WebView', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Result Display
              if (_testResult.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResult,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
