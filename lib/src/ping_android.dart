import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_icmp_ping/src/models/ping_data.dart';
import 'package:flutter_icmp_ping/src/models/ping_error.dart';
import 'package:flutter_icmp_ping/src/models/ping_response.dart';
import 'package:flutter_icmp_ping/src/models/ping_summary.dart';

class PingAndroid {
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
              seq: int.parse(match.group(2)),
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
              seq: int.parse(match.group(1)),
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
