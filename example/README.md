# Sora Flutter SDK

## サンプル

example 以下がサンプルアプリ。マルチストリームで 1:1 の送受信ができる。


## システム条件

### iOS

- macOS 12
- Xcode 13
- iOS 14

### macOS

- Apple M1 (x86_64 は C++ SDK が非対応)
- macOS 12
- Xcode 13

### Android

- Android SDK 19
- Android Studio

### Windows

- Windows 10
- Visual Studio
- Android Studio

M1 Mac 上の仮想環境 (Parallels Desktop や VMware) ではビルドできない・ビルドできてもクラッシュするようなので注意。現段階では Dart は Windows ARM をサポートしていない。

### Ubuntu

- Ubuntu 20.04 x86_64

## インストール

インストールしたいプロジェクトで次のコマンドを実行する。
pub.dev に登録していないので、リポジトリのローカルパスか URL を指定する。

ローカルリポジトリのパスを指定 (ブランチは指定不可):

```
flutter pub add sora_flutter_sdk --path リポジトリのパス
```

GitHub リポジトリを指定:

```
flutter pub add sora_flutter_sdk --git-url https://github.com/shiguredo/sora-flutter-sdk.git [--git-ref ブランチ]
```

Linux の場合、追加で以下のコマンドを実行する必要がある。

```
./linux/flutter/ephemeral/.plugin_symlinks/sora_flutter_sdk/linux/install_deps.sh linux/
export PATH="`pwd`/linux/_install/llvm/clang/bin:$PATH"
```

`install_deps.sh` によって、sora_flutter_sdk のビルドに必要なライブラリやコンパイラを linux ディレクトリにインストールする。

## SDK の開発

example のサンプルアプリを利用する。このサンプルは本リポジトリのローカルのファイルパスを参照しているので、ライブラリのコードの変更はすぐにサンプルアプリに反映される。


## サンプルアプリのビルドと実行

example がサンプルアプリ。以下の操作は example に移動するか、ディレクトリを VSCode で開いて行う。


### 接続設定を用意する

接続設定を `lib/environment.dart` に書く。 `lib/environment.example.dart` をコピーしてファイル名を変更し、接続設定を指定する。

`lib/environment.dart` はリポジトリの管理対象から外すようにしてあるので、間違えて追加してしまう心配は不要。


### ビルドと実行

コマンドラインか VSCode のどちらかを使う。

VSCode の場合は、使用するデバイスを接続してからサイドバーの「実行とデバッグ」を実行する。ガイドメッセージに従って `launch.json` を生成してもよい。

コマンドラインの場合は `flutter run` で実行できる。オプションでデバイスを指定するか、何も指定しなければ現在接続されているデバイスで実行される。選択可能なデバイスは `flutter devices` で表示できる。

ビルドはリリースモードを推奨。 `flutter run` ではなく `flutter run --release` を利用すること。

コマンドラインの例:

```
flutter run --release # 接続中のデバイスまたは OS で起動
flutter run -d iPhone --release
flutter run -d iPad --release
flutter run -d macOS --release
flutter run -d windows --release
flutter run -d Pixel --release
```

## トラブルシューティング

### (Windows) エラーメッセージ「指定されたパスが見つかりません。」でビルドに失敗する

該当のファイルが存在するのにこのメッセージが表示されてビルドに失敗する場合は、 Windows のファイルパスの長さの制限に引っかかった可能性がある (デフォルトの設定では 260 文字まで) 。長いパスを使用可能に設定するか、リポジトリのディレクトリ名や位置を変更するなどしてリポジトリのファイルパスを制限内に収める必要がある。

参考: [Windows 10、バージョン 1607 以降で長いパスを有効にする](https://docs.microsoft.com/ja-jp/windows/win32/fileio/maximum-file-path-limitation?tabs=cmd#enable-long-paths-in-windows-10-version-1607-and-later)
