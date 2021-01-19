# flutter_icmp_ping

Flutter plugin that sends ICMP ECHO_REQUEST.

## Getting Started


To use this plugin, add `flutter_icmp_ping` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

```yaml
dependencies:
 flutter_icmp_ping: 
```

Import the library in your file.

````dart
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';
````

See the `example` directory for a complete sample app using GridButton.
Or use the GridButton like below.

````dart
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
````