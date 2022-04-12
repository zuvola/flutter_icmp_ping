import 'package:flutter/material.dart';
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Ping? ping;

    void startPing() async {
      try {
        ping = Ping(
          'google.com',
          count: 3,
          timeout: 1,
          interval: 1,
          ipv6: false,
          ttl: 40,
        );
        ping!.stream.listen((event) {
          debugPrint(event.toString());
        });
      } catch (e) {
        debugPrint('error $e');
      }
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ping example app'),
        ),
        body: Center(
          child: Column(
            children: [
              TextButton(
                child: const Text('start'),
                onPressed: startPing,
              ),
              TextButton(
                child: const Text('stop'),
                onPressed: () {
                  ping?.stop();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
