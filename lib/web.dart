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

  @override
  void initState() {
    WiFiForIoTPlugin.findAndConnect(widget.ssid, password: 'YieldXadmin')
        .then((_) => WiFiForIoTPlugin.forceWifiUsage(true))
        .then((_) => setState(() => _isConnected = true))
        .catchError((_) => setState(() => _isError = true));

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
                    ? WebView(
                        initialUrl: 'http://192.168.4.1',
                        onWebResourceError: (_) =>
                            setState(() => _isConnected = false),
                        onPageFinished: (_) =>
                            setState(() => _isLoading = false),
                      )
                    : const SizedBox(),
                _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Connecting...',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            const CircularProgressIndicator(),
                          ],
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
