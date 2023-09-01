## 3.1.3
- fix GBPing occasional crash under multi-threading.
- fix to work on android.

## 3.1.2
- support iOS native call GBPing

## 3.1.1
- Fixed a case where events could not be retrieved when offline
  
## 3.1.0
- Added ttl option

## 3.0.2
- Fixed missing timeout argument on iOS

## 3.0.1
- Fixed a bug of simultaneous ping

## 3.0.0
- Fixed a bug related to simultaneous ping on iOS

## 3.0.0-nullsafety.1
- Fixed a bug that caused an exception when RequestTimedOut.

## 3.0.0-nullsafety.0
- Null safety migration

## 2.0.0+1
- Fixed readme

## 2.0.0

- Reorganized source files
- Refactored classes so that a Ping instance provides a stream which starts the ping process when listened to
- Enable concurrent ping instances
- Explicitly support Android platform in pubspec (for pub.dev)

## 1.1.1
- Fixed end time and sequence when timeout.

## 1.1.0
- Made iOS end time the same as Android.
- Fixed Android "seq" to start from 0.

## 1.0.0+1

- Updated docs.

## 1.0.0

- First Release.
