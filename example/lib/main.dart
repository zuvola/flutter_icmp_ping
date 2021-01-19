import 'package:flutter/material.dart';
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void startPing() async {
      try {
        final proc = await Ping.start(
          'google.com',
          count: 3,
          timeout: 1,
          interval: 1,
          ipv6: false,
        );
        proc.listen((event) {
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
              RaisedButton(
                child: Text('start'),
                onPressed: startPing,
              ),
              RaisedButton(
                child: Text('stop'),
                onPressed: () {
                  Ping.stop();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
