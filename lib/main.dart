import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'YieldX Biocore Settings'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _ssid = 'YieldX-BioCore';
  final String _password = 'YieldXadmin';
  final String _url = '192.168.4.1';
  bool isError = false;
  bool isConnected = false;

  @override
  initState() {
    super.initState();
  }

  void _handleConnect() async {
    setState(() {
      isConnected = true;
    });
    await WiFiForIoTPlugin.findAndConnect(_ssid, password: _password)
        .then((val) {
      WiFiForIoTPlugin.forceWifiUsage(true).then((val) {
        setState(() {
          isConnected = true;
        });
      });
    }).catchError((val) {
      setState(() {
        isError = true;
      });
    });
    if (await canLaunchUrl(Uri(scheme: 'http', host: _url))) {
      await launchUrl(Uri(
        scheme: 'http',
        host: _url,
      ));
    } else {
      throw "Could not launch $_url";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: !isConnected
          ? Center(
              child: ElevatedButton(
                onPressed: _handleConnect,
                child: const Text('Connect to Biocore'),
              ),
            )
          : const Center(),
    );
  }
}
