<h1 align="center">Shea's Sealer - Flutter 插件</h1>
<h3 align="center">一个实现了域名重定向逻辑的HTTP拦截器插件</h3>
<br>

## 其他语言
[English README](README_EN.md)

## 功能介绍
`sheas_sealer` 是一个Flutter插件，它提供了一个HTTP拦截器 `DomainRedirectInterceptor`。当你使用标准的 `http` 包发起网络请求时，这个拦截器可以根据预定义的规则，自动将请求重定向到可用的域名。

这对于需要动态切换API端点或在多个备用域名之间实现故障转移的场景非常有用。

## 如何安装
将此插件添加到你的 `pubspec.yaml` 文件中：

```yaml
dependencies:
  sheas_sealer:
    path: ../  # 或者使用版本号: ^1.0.0
  http: ^1.2.1
  http_interceptor: ^2.0.0
```
然后运行 `flutter pub get`。

## 如何使用

下面是一个如何在你的Flutter应用中使用 `sheas_sealer` 插件的完整示例。

### 1. 导入必要的包
```dart
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:sheas_sealer/sheas_sealer.dart';
```

### 2. 初始化并设置拦截器
在使用任何网络请求之前，你需要初始化 `ApiService` 并创建一个集成了 `DomainRedirectInterceptor` 的 `http` 客户端。

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

    // 1. 初始化 ApiService 以下载和管理重定向规则
    final apiService = ApiService();
    apiService.loadRules(); // 异步加载规则

    // 2. 创建一个集成了我们拦截器的HTTP客户端
    client = InterceptedClient.build(
      interceptors: [
        DomainRedirectInterceptor(apiService: apiService),
      ],
    );

    // 3. （可选）你可以使用此客户端发起请求
    // client.get(Uri.parse("https://example.com/api/data"));
  }

  @override
  Widget build(BuildContext context) {
    // ... 在你的应用中使用 'client' 变量
    return MaterialApp(
      // ...
    );
  }
}

```

### 3. 发起请求
现在，你可以像往常一样使用创建的 `client` 实例来发起网络请求。`DomainRedirectInterceptor` 会自动处理域名替换逻辑。

如果原始请求的域名在规则列表中，它将被替换为一个可用的目标域名。

```dart
Future<void> fetchData() async {
  try {
    // 假设 "https://original-domain.com" 是一个需要被重定向的域名
    final response = await client.get(Uri.parse("https://original-domain.com/some/path"));
    
    if (response.statusCode == 200) {
      print("请求成功: ${response.body}");
    } else {
      print("请求失败: ${response.statusCode}");
    }
  } catch (e) {
    print("发生错误: $e");
  }
}
```

## 查看示例
要查看一个完整的、可运行的示例，请参考 `example` 文件夹内的代码。

## 注意事项
*   本项目仅供学习和技术研究使用。
*   请确保你的网络环境可以正常访问规则服务器以及目标网站。
