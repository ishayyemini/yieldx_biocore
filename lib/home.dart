import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:yieldx_biocore/web.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String errorState = '';
  bool isLoading = false;
  List<WiFiAccessPoint> accessPoints = [];
  StreamSubscription<Result<List<WiFiAccessPoint>, GetScannedResultsErrors>>?
      subscription;

  Map<String, String> errors = {
    'SCAN_START': 'Unable to start scanning.',
    'SCAN': 'Error while scanning.',
  };

  @override
  initState() {
    _startScan();
    super.initState();
  }

  void _startScan() async {
    if (!(await WiFiScan.instance.hasCapability()) ||
        (await WiFiScan.instance.startScan(askPermissions: true)) != null) {
      setState(() => errorState = 'START_SCAN');
    } else {
      subscription =
          WiFiScan.instance.onScannedResultsAvailable.listen((result) {
        if (result.hasError) {
          setState(() => errorState = 'SCAN');
        } else {
          setState(() => accessPoints = result.value
                  ?.where(
                      (element) => element.ssid.startsWith('YieldX-BioCore'))
                  .toList() ??
              []);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select BioCore'),
      ),
      body: errorState != ''
          ? Center(
              child: Text(errors[errorState] ?? ''),
            )
          : accessPoints.isNotEmpty
              ? ListView.separated(
                  itemBuilder: (_, index) {
                    return ListTile(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  WebPage(ssid: accessPoints[index].ssid))),
                      title: Text(accessPoints[index].ssid.substring(
                          accessPoints[index].ssid.length > 15 ? 15 : 0)),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(),
                  itemCount: accessPoints.length,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Searching for devices...',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      const CircularProgressIndicator(),
                    ],
                  ),
                ),
    );
  }

  @override
  dispose() {
    super.dispose();
    subscription?.cancel();
  }
}
