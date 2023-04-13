# integration_test_app

## 実行方法

### Windows 以外

```sh
flutter test -d DEVICE_ID integration_test_app/integration_test/connect_test.dart
```

### Windows

Windows では Sora Flutter SDK はリリースモードでビルドする必要があるが、 Flutter のインテグレーションテストはリリースモードをサポートしていない。
そのため、 `flutter run` による起動でもテスト実行可能にしてある。

`flutter run` でテストを実行するには、 `--dart-define=TEST_MODE=app_run` を指定する必要がある。

```sh
flutter run -d DEVICE_ID --release --dart-define=TEST_MODE=app_run
```