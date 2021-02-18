// Copyright 2021 zuvola. All rights reserved.

/// Flutter plugin that sends ICMP ECHO_REQUEST.
library flutter_icmp_ping;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Error code
enum PingError {
  RequestTimedOut,
  UnknownHost,
  Unknown,
}

/// Ping response data
class PingData {
  final PingResponse response;
  final PingSummary summary;
  final PingError error;

  PingData({this.response, this.summary, this.error});

  @override
  String toString() =>
      'PingData(response:$response, summary:$summary, error:$error)';
}

/// Summary of the results
class PingSummary {
  final int transmitted;
  final int received;
  final Duration time;

  PingSummary({this.transmitted, this.received, this.time});

  @override
  String toString() =>
      'PingSummary(transmitted:$transmitted, received:$received, time:${time.inMilliseconds} ms)';
}

/// Each probe response
class PingResponse {
  final int seq;
  final int ttl;
  final Duration time;
  final String ip;

  PingResponse({this.seq, this.ttl, this.time, this.ip});

  @override
  String toString() {
    final buff = StringBuffer('PingResponse(seq:$seq');
    if (ip != null) buff.write(', ip:$ip');
    if (ttl != null) buff.write(', ttl:$ttl');
    if (time != null) {
      final ms = time.inMicroseconds / Duration.millisecondsPerSecond;
      buff.write(', time:$ms ms');
    }
    buff.write(')');
    return buff.toString();
  }
}

class Ping {
  /// Start sending ICMP ECHO_REQUEST to network hosts
  ///
  /// Stop after sending [count] ECHO_REQUEST packets.
  /// Wait [interval] seconds between sending each packet.
  /// The [timeout] is the time to wait for a response, in seconds.
  static Future<Stream<PingData>> start(String host,
      {int count, double interval, double timeout, bool ipv6}) async {
    print(defaultTargetPlatform);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _PingiOS.start(host, count, interval, timeout, ipv6);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _PingAndroid.start(host, count, interval, timeout, ipv6);
    }
    return null;
  }

  /// Stop sending ECHO_REQUEST packets.
  static Future<void> stop() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _PingiOS.stop();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _PingAndroid.stop();
    }
  }
}

/// Ping for iOS
class _PingiOS {
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

/// Ping for Android
class _PingAndroid {
  static final _resRegex =
      RegExp(r'from (.*): icmp_seq=(\d+) ttl=(\d+) time=((\d+).?(\d+))');
  static final _seqRegex = RegExp(r'icmp_seq=(\d+)');
  static final _summaryRegexes = [
    RegExp(r'(\d+) packets transmitted'),
    RegExp(r'(\d+) received'),
    RegExp(r'time (\d+)ms'),
  ];
  static Process _process;

  /// StreamTransformer for Android response from process stdout/stderr.
  static StreamTransformer<String, PingData> _androidTransformer =
      StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      if (data.contains('unknown host')) {
        sink.add(
          PingData(
            error: PingError.UnknownHost,
          ),
        );
      }
      if (data.contains('bytes from')) {
        final match = _resRegex.firstMatch(data);
        if (match == null) {
          return;
        }
        sink.add(
          PingData(
            response: PingResponse(
              ip: match.group(1),
              seq: int.parse(match.group(2)) - 1,
              ttl: int.parse(match.group(3)),
              time: Duration(
                  microseconds:
                      ((double.parse(match.group(4))) * 1000).floor()),
            ),
          ),
        );
      }
      if (data.contains('no answer yet')) {
        final match = _seqRegex.firstMatch(data);
        if (match == null) {
          return;
        }
        sink.add(
          PingData(
            response: PingResponse(
              seq: int.parse(match.group(1)) - 1,
            ),
            error: PingError.RequestTimedOut,
          ),
        );
      }
      if (data.contains('packet loss')) {
        final transmitted = _summaryRegexes[0].firstMatch(data);
        final received = _summaryRegexes[1].firstMatch(data);
        final time = _summaryRegexes[2].firstMatch(data);
        if (transmitted == null || received == null || time == null) {
          return;
        }
        sink.add(
          PingData(
            summary: PingSummary(
              transmitted: int.parse(transmitted.group(1)),
              received: int.parse(received.group(1)),
              time: Duration(milliseconds: int.parse(time.group(1))),
            ),
          ),
        );
      }
    },
  );

  /// Start sending ICMP ECHO_REQUEST to network hosts
  static Future<Stream<PingData>> start(String host, int count, double interval,
      double timeout, bool ipv6) async {
    if (_process != null) {
      throw Exception('ping is already running');
    }
    var params = ['-O', '-n'];
    if (count != null) params.add('-c $count');
    if (timeout != null) params.add('-W $timeout');
    if (interval != null) params.add('-i $interval');
    _process = await Process.start(
        (ipv6 ?? false) ? 'ping6' : 'ping', [...params, host]);
    _process.exitCode.then((value) {
      _process = null;
    });
    final stream = StreamGroup.merge([_process.stderr, _process.stdout]);
    return stream
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .transform<PingData>(_androidTransformer);
  }

  /// Stop sending ECHO_REQUEST packets.
  static Future<void> stop() async {
    _process?.kill(ProcessSignal.sigint);
    _process = null;
  }
}
