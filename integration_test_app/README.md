# インテグレーションテスト

このアプリは、Sora Flutter SDKの開発者向けインテグレーションテスト用アプリです。

## アプリの実行方法

### 準備
`lib/environment.dart`を用意します。`lib/environment.example.dart`をコピーしてファイル名を変更し、テストに使う接続設定を編集します。

### iOS

```
flutter test -d iPhone integration_test/connect_test.dart
```

### macOS (arm64)

```
flutter test -d macos integration_test/connect_test.dart
```

### macOS (x86_64)

Sora Flutter SDK は macOS (x86_64) に対応していません。

### Ubuntu

```
flutter test -d linux integration_test/connect_test.dart
```

## Windowsでの実行方法

Windowsでは `flutter test` で実行できません。
Sora Flutter SDK は Windows ではリリースモードでしかビルド・実行できないため、
`flutter test`はリリースモードに対応していません。そのため、インテグレーションテストをアプリとして実行する必要があります。

本アプリは `--dart-define` で指定できる環境変数 `TEST_MODE` の値が `app_run` であればテストを実行するようにしてあります。
テストを実行するには、次のコマンドを実行してください。

```
flutter run -d windows --release --dart-define=TEST_MODE=app_run
```

ただし、 `flutter run` ではすべてのテストが終了してもプロセスが終了しないため、手動でプロセスを終了する必要があります。
CI などでテストを自動的に実行する場合は、一定時間後に `flutter run` を強制終了するなどの対応をしてください。
