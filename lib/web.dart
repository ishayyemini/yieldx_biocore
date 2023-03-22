import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WebPage extends StatefulWidget {
  const WebPage({Key? key, required this.ssid}) : super(key: key);

  final String ssid;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  final String url = '192.168.4.1';

  bool _isLoading = true;
  bool _isError = false;
  bool _isFinishedConfig = false;

  WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  @override
  void initState() {
    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) => setState(() {
          _isLoading = false;
          controller.getTitle().then((value) {
            if (value != null && value.startsWith(url)) {
              _isFinishedConfig = true;
              if (value.contains('Done')) {
                Fluttertoast.showToast(
                  msg: 'Configuration finished successfully',
                );
                Navigator.pop(context);
              }
            }
          });
        }),
      ),
    );

    WiFiForIoTPlugin.findAndConnect(widget.ssid, password: 'YieldXadmin')
        .then((_) => WiFiForIoTPlugin.forceWifiUsage(true))
        .then((_) => controller.loadRequest(Uri.parse('http://$url')))
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
        centerTitle: true,
        elevation: 6.0,
      ),
      body: !_isError
          ? Stack(
              children: [
                !_isFinishedConfig || _isLoading
                    ? WebViewWidget(controller: controller)
                    : Center(
                        child: Card(
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Finished configuration',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 24.0),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Go Back'),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
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
                                  style: Theme.of(context).textTheme.titleLarge,
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
