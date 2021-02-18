import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_icmp_ping/src/models/ping_data.dart';
import 'package:flutter_icmp_ping/src/models/ping_error.dart';
import 'package:flutter_icmp_ping/src/models/ping_response.dart';
import 'package:flutter_icmp_ping/src/models/ping_summary.dart';

class PingiOS {
  static const _channelName = 'flutter_icmp_ping';
  static const _methodCh = MethodChannel('$_channelName/method');
  static const _eventCh = EventChannel('$_channelName/event');

  /// StreamTransformer for iOS response from the event channel.
  static StreamTransformer<dynamic, PingData> _iosTransformer =
      StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      var err;
      switch (data['error']) {
        case 'RequestTimedOut':
          err = PingError.RequestTimedOut;
          break;
        case 'UnknownHost':
          err = PingError.UnknownHost;
          break;
      }
      var response;
      if (data['seq'] != null) {
        response = PingResponse(
          seq: data['seq'],
          ip: data['ip'],
          ttl: data['ttl'],
          time: Duration(
              microseconds:
                  (data['time'] * Duration.microsecondsPerSecond).floor()),
        );
      }
      var summary;
      if (data['received'] != null) {
        summary = PingSummary(
          received: data['received'],
          transmitted: data['transmitted'],
          time: Duration(
              microseconds:
                  (data['time'] * Duration.microsecondsPerSecond).floor()),
        );
      }
      sink.add(
        PingData(
          response: response,
          summary: summary,
          error: err,
        ),
      );
    },
  );

  /// Start sending ICMP ECHO_REQUEST to network hosts
  static Future<Stream<PingData>> start(String host, int count, double interval,
      double timeout, bool ipv6) async {
    await _methodCh.invokeMethod('start', {
      'host': host,
      'count': count,
      'interval': interval,
      'timeout': timeout,
      'ipv6': ipv6,
    });
    return _eventCh
        .receiveBroadcastStream()
        .transform<PingData>(_iosTransformer);
  }

  /// Stop sending ECHO_REQUEST packets.
  static Future<void> stop() async {
    return _methodCh.invokeMethod('stop');
  }
}
