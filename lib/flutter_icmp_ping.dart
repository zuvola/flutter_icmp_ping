// Copyright 2021 zuvola. All rights reserved.

/// Flutter plugin that sends ICMP ECHO_REQUEST.
library flutter_icmp_ping;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_icmp_ping/src/base_ping_stream.dart';
import 'package:flutter_icmp_ping/src/models/ping_data.dart';
import 'package:flutter_icmp_ping/src/ping_android.dart';
import 'package:flutter_icmp_ping/src/ping_ios.dart';

export 'package:flutter_icmp_ping/src/models/ping_data.dart';
export 'package:flutter_icmp_ping/src/models/ping_error.dart';
export 'package:flutter_icmp_ping/src/models/ping_response.dart';
export 'package:flutter_icmp_ping/src/models/ping_summary.dart';

class Ping {
  Ping(String host,
      {int? count, double? interval, double? timeout, bool? ipv6, int? ttl}) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _ping = PingiOS(host, count, interval, timeout, ipv6, ttl);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      _ping = PingAndroid(host, count, interval, timeout, ipv6, ttl);
    }
  }

  late BasePing _ping;

  /// On listen, start sending ICMP ECHO_REQUEST to network hosts
  ///
  /// Stop after sending [count] ECHO_REQUEST packets.
  /// Wait [interval] seconds between sending each packet.
  /// The [timeout] is the time to wait for a response, in seconds.
  Stream<PingData> get stream => _ping.stream;

  void stop() => _ping.stop();
}
