# Sora Flutter SDK

## About Shiguredo's open source software

We will not respond to PRs or issues that have not been discussed on Discord. Also, Discord is only available in Japanese.

Please read https://github.com/shiguredo/oss before use.

## 時雨堂のオープンソースソフトウェアについて

利用前に https://github.com/shiguredo/oss をお読みください。

## 概要

Sora Flutter SDK は [WebRTC SFU Sora](https://sora.shiguredo.jp) の Flutter クライアントアプリケーションを開発するためのライブラリです。

## ドキュメント

準備中です。

## 対応プラットフォーム

- Windows x86_64
- macOS arm64
- iOS arm64
- iPadOS arm64
- Android arm64
- Ubuntu x86_64

対応予定

- Web
    - [Flutter on the Web](https://flutter.dev/multi-platform/web)
- Ubuntu arm64
    - [sony/flutter\-embedded\-linux: Embedded Linux embedding for Flutter](https://github.com/sony/flutter-embedded-linux)

## 対応ハードウェアエンコーダー/デコーダー

それぞれのプラットフォームでのハードウェアアクセラレーターに対応しています。

- NVIDIA VIDEO CODEC SDK (NVENC / NVDEC)
    - Windows / Linux
    - VP9 / H.264
- Apple macOS / iOS / iPadOS Video Toolbox
    - H.264
- Google Android HWA
    - VP8 / VP9 / H.264
- Intel oneVPL (Intel Media SDK の後継)
    - Windows / Linux
    - VP9 / AV1 / H.264

対応予定

- NVIDIA Jetson Video HWA
    - Linux
    - VP9 / AV1 / H.264

## ライセンス

Apache License 2.0

```
Copyright 2022-2023, Wandbox LLC (Original Author)
Copyright 2022-2023, SUZUKI Tetsuya (Original Author)
Copyright 2022-2023, Shiguredo Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
