import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:yieldx_wifi_config/web.dart';

enum ErrorState { ok, noAppLocation, noLocation, failedScan, notSupported }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ErrorState errorState = ErrorState.ok;
  bool isLoading = false;
  bool isTooMuch = false;
  List<WiFiAccessPoint> accessPoints = [];
  Stream<List<WiFiAccessPoint>> scanResult =
      WiFiScan.instance.onScannedResultsAvailable;

  @override
  initState() {
    _startScan();
    super.initState();
  }

  void _startScan([bool fromTrigger = false]) async {
    if (errorState == ErrorState.ok || fromTrigger) {
      CanStartScan canScan = await WiFiScan.instance.canStartScan();

      switch (canScan) {
        case CanStartScan.yes:
          setState(() => errorState = ErrorState.ok);
          bool scanInit = await WiFiScan.instance.startScan();
          if (!scanInit) {
            if (!isTooMuch) {
              setState(() => isTooMuch = true);
              Future.delayed(
                const Duration(seconds: 30),
                () => setState(() => isTooMuch = false),
              );
            }
            Fluttertoast.showToast(
              msg: "Couldn't scan again, please wait a few seconds",
            );
          }
          break;
        case CanStartScan.notSupported:
          setState(() => errorState = ErrorState.notSupported);
          break;
        case CanStartScan.noLocationPermissionUpgradeAccuracy:
          Fluttertoast.showToast(
            msg: 'Please allow precise location in settings',
          );
          AppSettings.openAppSettings();
          setState(() => errorState = ErrorState.noAppLocation);
          break;
        case CanStartScan.noLocationPermissionRequired:
        case CanStartScan.noLocationPermissionDenied:
          Fluttertoast.showToast(
            msg: 'Please allow location access in settings',
          );
          AppSettings.openAppSettings();
          setState(() => errorState = ErrorState.noAppLocation);
          break;
        case CanStartScan.noLocationServiceDisabled:
          Fluttertoast.showToast(
            msg: 'Please turn on location in settings',
          );
          AppSettings.openLocationSettings();
          setState(() => errorState = ErrorState.noLocation);
          break;
        default:
          setState(() => errorState = ErrorState.failedScan);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Device'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _startScan(true);
          await Future.delayed(const Duration(seconds: 1), () {});
        },
        notificationPredicate: (_) => !isTooMuch,
        child: errorState != ErrorState.ok
            ? ErrorView(
                errorState: errorState,
                startScan: () => _startScan(true),
              )
            : ListCards(
                scanResult: scanResult,
                startScan: () => _startScan(true),
              ),
      ),
    );
  }
}

class ListCards extends StatelessWidget {
  const ListCards({
    Key? key,
    required this.scanResult,
    required this.startScan,
  }) : super(key: key);

  final Stream<List<WiFiAccessPoint>> scanResult;
  final void Function() startScan;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WiFiAccessPoint>>(
      stream: scanResult,
      builder: (BuildContext context,
          AsyncSnapshot<List<WiFiAccessPoint>> snapshot) {
        if (snapshot.hasError) {
          return ErrorView(
            startScan: startScan,
            customError: snapshot.error.toString(),
          );
        } else {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.done:
            case ConnectionState.waiting:
              return const LoadingList();
            case ConnectionState.active:
              Iterable<WiFiAccessPoint> devices = snapshot.data!.where((item) =>
                  item.ssid.startsWith('YieldX-BioCore') ||
                  item.ssid.startsWith('YieldX-RedMite'));
              return GridView.count(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                crossAxisCount: devices.isNotEmpty ? 2 : 1,
                children: devices.isEmpty
                    ? [
                        Center(
                          child: Text(
                            'No devices found, pull down to refresh',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        )
                      ]
                    : devices
                        .map((item) => Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
                              ),
                              child: InkWell(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WebPage(ssid: item.ssid),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        item.ssid.startsWith('YieldX-BioCore')
                                            ? Icons.hub
                                            : Icons.pest_control,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 24.0,
                                      ),
                                      const SizedBox(height: 12.0),
                                      Text(
                                        item.ssid
                                            .replaceAll('YieldX-RedMite_', '')
                                            .replaceAll('YieldX-BioCore_', ''),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
              );
          }
        }
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    Key? key,
    required this.startScan,
    this.errorState = ErrorState.ok,
    this.customError = '',
  }) : super(key: key);

  final void Function() startScan;
  final ErrorState errorState;
  final String customError;

  @override
  Widget build(BuildContext context) {
    Map<ErrorState, String> errors = {
      ErrorState.failedScan: 'Unable to start scanning.',
      ErrorState.noAppLocation:
          'Please allow app precise location permission in settings.',
      ErrorState.noLocation: 'Please turn on location in settings.',
      ErrorState.notSupported: 'Wifi scanning is not supported.',
    };

    return Center(
      child: Card(
        margin: const EdgeInsets.all(24.0),
        elevation: 0,
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errors[errorState] ?? 'Unknown error occurred.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16.0),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: startScan,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24.0),
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Searching for devices...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 24.0),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
