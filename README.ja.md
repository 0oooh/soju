<div align="center">
  <img src="Resources/AppIcon.png" width="140" alt="Soju アイコン">
  <h1>Soju</h1>
  <p><i>ウイスキーの次はソジュ</i></p>
  <p>
    <a href="../../actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/0oooh/soju/ci.yml?branch=main&label=CI" alt="CI"></a>
    <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+">
    <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license">
  </p>
  <p><a href="README.md">English</a> | <a href="README.ko.md">한국어</a> | 日本語</p>
</div>

Mac で Windows のアプリやゲームを — 本物の Mac アプリのように。Whisky の開発は 2025 年に終了しました。Soju はネイティブ SwiftUI で作られたオープンソースの後継です。Whisky にはなかった目玉機能がひとつあります: どんな Windows プログラムでも、単体で動く Mac アプリに変換できます。

<div align="center">
  <img src="docs/assets/main.png" width="650" alt="Soju メイン画面: ボトルとピン留めしたプログラム">
  <p><i>ボトル、ワンクリック起動、exe から直接抽出した本物のアイコン</i></p>
</div>

## 特徴

- **Mac アプリとして書き出し** — プログラムを右クリックすると単体の `.app` が生成されます。exe 内の本物のアイコンまで抽出され、Dock・Launchpad・Spotlight に登録。Soju が起動していなくてもダブルクリックでそのまま動きます。
- **ボトル** — ワンクリックで作れる独立した Windows 環境。ボトルごとに Windows バージョン(11 / 10 / 8.1 / 7 / XP)を設定できます。
- **エンジンは 2 種類** — 汎用の [Wine Staging](https://github.com/Gcenx/macOS_Wine_builds) と、DirectX 12 ゲーム向けの Apple [Game Porting Toolkit](https://github.com/Gcenx/game-porting-toolkit)(D3DMetal)。どちらも必要になったときにアップストリームのリリースからダウンロードされ、インストール済みの Wine や CrossOver も自動検出されます。
- **Steam をワンクリックでインストール** — Valve 公式 CDN からインストーラーを取得し、ボトル内でそのまま実行します。
- **Whisky からの取り込み** — 使っていた Whisky のボトルをワンクリックで移行できます。
- ネイティブ SwiftUI、ライト/ダークモード対応。Electron なし、Homebrew なし、ターミナルなし。

## システム要件

- macOS 14 Sonoma 以降
- Apple Silicon: Rosetta 2 が必要 — Soju が自動で確認し、インストールコマンドを 1 行で案内します
- Intel Mac 対応(ユニバーサルバイナリ)

## インストール

[Releases](../../releases) から最新の `Soju-*.zip` をダウンロードして解凍し、`Soju.app` をアプリケーションフォルダに移動してください。

ビルドは公証(notarize)されていません(このプロジェクトに有料の開発者アカウントはありません)。初回起動時に macOS が警告を出したら、アプリを右クリックして「開く」を選ぶか、次を実行してください:

```
xattr -cr /Applications/Soju.app
```

## Whisky からの移行

Soju が既存の Whisky ボトルを自動で検出します — ツールバーの取り込みボタンを押すだけ。プレフィックスはコピーされるので、元のデータはそのまま残ります。

## 仕組み

Soju 本体は薄いネイティブのマネージャで、互換レイヤーは [Wine](https://www.winehq.org/) です。エンジンは `~/Library/Application Support/Soju/Engines` に、ボトルは `.../Soju/Bottles` に通常の Wine プレフィックスとして保存されます。書き出された Mac アプリは、エンジン・ボトル・プログラムのパスが焼き込まれた小さなランチャーバンドルなので、即座に、単体で起動します。

## ソースからビルド

```
git clone https://github.com/0oooh/soju
cd soju
Scripts/build-app.sh
open build/Soju.app
```

Swift 5.9+(Xcode コマンドラインツール)が必要です。`swift test` でユニットテスト、`SOJU_IT=1 swift test --filter Integration` で実エンジンを使ったフルライフサイクルテストを実行できます。

## ロードマップ

- DXMT・DXVK グラフィックバックエンド(Metal 上でより速い DirectX 11)
- コミュニティのゲームレシピ — ゲームごとの検証済み設定をワンクリック適用
- Winetricks 統合
- 公証済みリリース

## クレジット

- [Wine](https://www.winehq.org/) — すべてを可能にしている互換レイヤー(LGPL)
- [Gcenx](https://github.com/Gcenx) — 継続的にメンテナンスされている macOS 向け Wine ビルド
- [Whisky](https://github.com/Whisky-App/Whisky) — このプロジェクトの原点。安らかに

## ライセンス

Soju のコードは MIT です。Soju は Wine をバンドルも再配布もしません。エンジンは初回実行時にアップストリームのリリースからダウンロードされます。
