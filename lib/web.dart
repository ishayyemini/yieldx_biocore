import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WebPage extends StatefulWidget {
  const WebPage({Key? key, required this.ssid}) : super(key: key);

  final String ssid;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  bool _isLoading = true;
  bool _isConnected = false;
  bool _isError = false;

  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse('http://192.168.4.1'));

  @override
  void initState() {
    WiFiForIoTPlugin.findAndConnect(widget.ssid, password: 'YieldXadmin')
        .then((_) => WiFiForIoTPlugin.forceWifiUsage(true))
        .then((_) => setState(() => _isConnected = true))
        .catchError((_) => setState(() => _isError = true));
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) => setState(() => _isConnected = false),
        onWebResourceError: (_) => setState(() {
          _isConnected = false;
          _isError = true;
        }),
        onPageFinished: (_) => setState(() => _isLoading = false),
      ),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ssid.length > 15
            ? 'Manage ${widget.ssid.substring(15)} Settings'
            : 'Manage Settings'),
      ),
      body: !_isError
          ? Stack(
              children: [
                _isConnected
                    ? WebViewWidget(
                        controller: controller,
                      )
                    : const SizedBox(),
                _isLoading
                    ? Center(
                        child: Card(
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Connecting...',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(
                                  height: 24.0,
                                ),
                                const CircularProgressIndicator(
                                  strokeWidth: 3.0,
                                ),
                                const SizedBox(
                                  height: 3.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox()
              ],
            )
          : Center(
              child: Text(
                'Error while trying to connect to device.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
    );
  }

  @override
  void dispose() {
    WiFiForIoTPlugin.forceWifiUsage(false);
    WiFiForIoTPlugin.disconnect();
    super.dispose();
  }
}
