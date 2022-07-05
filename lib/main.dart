import 'package:flutter/material.dart';
import 'package:yieldx_biocore/home.dart';

void main() {
  runApp(const BioCoreApp());
}

class BioCoreApp extends StatelessWidget {
  const BioCoreApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}
