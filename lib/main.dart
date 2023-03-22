import 'package:flutter/material.dart';
import 'package:yieldx_wifi_config/home.dart';

void main() {
  runApp(const WifiConfigApp());
}

class WifiConfigApp extends StatelessWidget {
  const WifiConfigApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yieldx Device Config',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color.fromRGBO(4, 100, 164, 1),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}
