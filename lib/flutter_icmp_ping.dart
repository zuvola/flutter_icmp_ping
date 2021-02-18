// Copyright 2021 zuvola. All rights reserved.

/// Flutter plugin that sends ICMP ECHO_REQUEST.
library flutter_icmp_ping;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_icmp_ping/src/models/ping_data.dart';
import 'package:flutter_icmp_ping/src/ping_android.dart';
import 'package:flutter_icmp_ping/src/ping_ios.dart';

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
      return PingiOS.start(host, count, interval, timeout, ipv6);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PingAndroid.start(host, count, interval, timeout, ipv6);
    }
    return null;
  }

  /// Stop sending ECHO_REQUEST packets.
  static Future<void> stop() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return PingiOS.stop();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PingAndroid.stop();
    }
  }
}
