import Flutter
import UIKit

public class SwiftFlutterIcmpPingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let CHANNEL = "flutter_icmp_ping"
  private var pings: [Int:GBPingHelper] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "\(CHANNEL)/method", binaryMessenger: registrar.messenger())
    let stream = FlutterEventChannel(name: "\(CHANNEL)/event", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterIcmpPingPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    stream.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let hash = arguments["hash"] as? Int else {
      result(FlutterError(code: "Invalid argument", message: nil, details: nil))
      return
    }
    print("\(call.method):\(hash)")
    var ping = pings[hash]
    switch call.method {
    case "stop":
      ping?.stop()
    case "start":
      if ping == nil {
        ping = GBPingHelper()
        pings[hash] = ping
      }
      guard let arguments = call.arguments as? [String: Any],
            let host = arguments["host"] as? String else {
        result(FlutterError(code: "Invalid argument", message: nil, details: nil))
        return
      }
      let count = arguments["count"] as? UInt ?? 0
      let interval = arguments["interval"] as? TimeInterval ?? 1
      let timeout = arguments["timeout"] as? TimeInterval ?? 2
      let ipv6 = arguments["ipv6"] as? Bool ?? false
      let ttl = arguments["ttl"] as? UInt ?? 0
      ping?.start(withHost: host, ipv4: !ipv6, ipv6: ipv6, count: count, interval: interval, timeout: timeout, ttl: ttl) { ret in
        if let sink = self.eventSink {
          sink(ret.merging(["hash": hash]) {(_,new) in new})
        }
        if ret["received"] != nil {
          self.pings[hash] = nil
        }
      }
      result("started")
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  var eventSink: FlutterEventSink?

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
