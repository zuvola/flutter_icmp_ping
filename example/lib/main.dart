import 'package:flutter/material.dart';
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Ping ping;

    void startPing() async {
      try {
        ping = Ping(
          'google.com',
          count: 3,
          timeout: 1,
          interval: 1,
          ipv6: false,
        );
        ping.stream.listen((event) {
          print(event);
        });
      } catch (e) {
        print('error $e');
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
                child: Text('start'),
                onPressed: startPing,
              ),
              TextButton(
                child: Text('stop'),
                onPressed: () {
                  ping.stop();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
