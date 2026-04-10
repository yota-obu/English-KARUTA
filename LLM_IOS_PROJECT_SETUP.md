# iOS アプリ環境構築指示書（VSCode + SweetPad）

LLM がゼロから iOS アプリプロジェクトを構築する際に参照するドキュメントです。
Xcode を直接操作せず、**VSCode + SweetPad + XcodeGen + Swift Package Manager** の組み合わせで開発します。

---

## 前提条件

ユーザーの環境に以下がインストール済みであることを確認してください。
不足があればインストールコマンドを提示してください。

| ツール | 確認コマンド | インストール |
|--------|-------------|-------------|
| Xcode | `xcodebuild -version` | App Store からインストール |
| Xcode CLI Tools | `xcode-select -p` | `xcode-select --install` |
| XcodeGen | `xcodegen --version` | `brew install xcodegen` |
| swift-format | `swift-format --version` | `brew install swift-format` |
| VSCode | `code --version` | 公式サイトからインストール |

### 必須 VSCode 拡張機能

| 拡張機能 | ID | 役割 |
|----------|----|------|
| SweetPad | `sweetpad.sweetpad` | iOS ビルド・実行・シミュレータ管理 |
| Swift | `swiftlang.swift-vscode` | Swift 言語サポート・補完 |
| CodeLLDB | `vadimcn.vscode-lldb` | デバッグ |

```bash
code --install-extension sweetpad.sweetpad
code --install-extension swiftlang.swift-vscode
code --install-extension vadimcn.vscode-lldb
```

---

## プロジェクト作成手順

以下の手順を上から順に実行してください。
`{{AppName}}` はアプリ名（例: `MyApp`）、`{{BundleId}}` はバンドルID（例: `com.example.myapp`）に置き換えてください。

### Step 1: ディレクトリ構成を作成

```bash
mkdir -p {{AppName}}/Sources/{{AppName}}/{Models,Views,Views/Components,ViewModels,Services,Utilities,Resources}
mkdir -p {{AppName}}/Sources/{{AppName}}/Resources/Assets.xcassets/AppIcon.appiconset
mkdir -p {{AppName}}/Tests
mkdir -p {{AppName}}/.vscode
```

### Step 2: Package.swift を作成

Swift Package Manager のマニフェストです。アプリのビルド定義の基盤となります。

```swift
// swift-tools-version: 6.0
// {{AppName}}

import PackageDescription

let package = Package(
    name: "{{AppName}}",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "{{AppName}}",
            resources: [
                .copy("Resources"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
```

**注意点:**
- `swift-tools-version: 6.0` と `swiftLanguageModes: [.v6]` で Swift 6 の Strict Concurrency を有効化
- `.iOS(.v17)` は最低サポート iOS バージョン。必要に応じて変更
- リソースファイル（画像、DB、JSON 等）は `Sources/{{AppName}}/Resources/` に配置し、`.copy("Resources")` でバンドル
- 外部パッケージを使う場合は `dependencies` と `.product()` を追加：
  ```swift
  dependencies: [
      .package(url: "https://github.com/example/SomePackage.git", from: "1.0.0"),
  ],
  targets: [
      .executableTarget(
          name: "{{AppName}}",
          dependencies: [
              .product(name: "SomePackage", package: "SomePackage"),
          ],
          resources: [
              .copy("Resources"),
          ]
      ),
  ],
  ```

### Step 3: project.yml を作成（XcodeGen 用）

XcodeGen がこの YAML から `.xcodeproj` を自動生成します。

```yaml
name: {{AppName}}
options:
  bundleIdPrefix: {{BundleIdPrefix}}
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"

targets:
  {{AppName}}:
    type: application
    platform: iOS
    sources:
      - path: Sources/{{AppName}}
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {{BundleId}}
        INFOPLIST_GENERATION_MODE: GeneratedFile
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        GENERATE_INFOPLIST_FILE: "YES"
        INFOPLIST_KEY_CFBundleDisplayName: {{DisplayName}}
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        INFOPLIST_KEY_UILaunchScreen_Generation: "YES"
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
        SWIFT_VERSION: "6.0"
        SWIFT_STRICT_CONCURRENCY: complete
        CODE_SIGN_STYLE: Automatic
        CODE_SIGNING_REQUIRED: "YES"
        CODE_SIGNING_ALLOWED: "YES"
        DEVELOPMENT_TEAM: {{TeamId}}
        SUPPORTED_PLATFORMS: "iphonesimulator iphoneos"
        SDKROOT: iphoneos
```

**各フィールドの説明:**

| キー | 説明 | 例 |
|------|------|----|
| `{{AppName}}` | プロジェクト名・ターゲット名 | `MyApp` |
| `{{BundleIdPrefix}}` | バンドルIDのプレフィックス | `com.example` |
| `{{BundleId}}` | フルバンドルID | `com.example.myapp` |
| `{{DisplayName}}` | ホーム画面に表示されるアプリ名 | `My App` |
| `{{TeamId}}` | Apple Developer Team ID | `GMB638MVMY` |

**よく使う追加設定:**
- iPad 対応: `INFOPLIST_KEY_UISupportedInterfaceOrientations` に横向きも追加
- カメラ使用: `INFOPLIST_KEY_NSCameraUsageDescription: "カメラを使用します"` を追加
- 位置情報: `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription: "..."` を追加

### Step 4: .vscode/launch.json を作成

VSCode からのデバッグ実行に必要です。SweetPad が提供するタスクと連携します。

```json
{
    "configurations": [
        {
            "type": "swift",
            "request": "launch",
            "name": "Debug {{AppName}}",
            "preLaunchTask": "swift: Build Debug {{AppName}}",
            "target": "{{AppName}}",
            "configuration": "debug",
            "cwd": "${workspaceFolder}"
        },
        {
            "type": "swift",
            "request": "launch",
            "args": [],
            "cwd": "${workspaceFolder}",
            "name": "Release {{AppName}}",
            "target": "{{AppName}}",
            "configuration": "release",
            "preLaunchTask": "swift: Build Release {{AppName}}"
        }
    ]
}
```

### Step 5: .gitignore を作成

```gitignore
.DS_Store
/.build
/Packages
/*.xcodeproj
xcuserdata/
DerivedData/
.swiftpm/
*.xcworkspace
```

**重要:** `.xcodeproj` は XcodeGen で再生成するため Git 管理しません。

### Step 6: アプリのエントリポイントを作成

`Sources/{{AppName}}/{{AppName}}App.swift`:

```swift
import SwiftUI

@main
struct {{AppName}}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

`Sources/{{AppName}}/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

**SwiftData を使う場合:**

```swift
import SwiftUI
import SwiftData

@main
struct {{AppName}}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [/* SwiftData Model 型をここに列挙 */])
    }
}
```

### Step 7: AppIcon の Contents.json を作成

`Sources/{{AppName}}/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

1024x1024 の PNG 画像を同ディレクトリに配置し、`"filename": "icon.png"` を images に追加してください。

### Step 8: Xcode プロジェクトを生成してビルド確認

```bash
cd {{AppName}}
xcodegen generate
```

成功すると `{{AppName}}.xcodeproj` が生成されます。

ビルド確認:

```bash
xcodebuild -project {{AppName}}.xcodeproj \
  -scheme {{AppName}} \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

---

## プロジェクト構成テンプレート

最終的なディレクトリ構成は以下のようになります。

```
{{AppName}}/
├── Package.swift                          # SPM マニフェスト
├── project.yml                            # XcodeGen 設定
├── .gitignore
├── .vscode/
│   └── launch.json                        # デバッグ設定
├── Sources/{{AppName}}/
│   ├── {{AppName}}App.swift               # @main エントリポイント
│   ├── ContentView.swift                  # ルートビュー
│   ├── Models/                            # データモデル
│   ├── Views/                             # SwiftUI ビュー
│   │   └── Components/                    # 再利用可能コンポーネント
│   ├── ViewModels/                        # ビューモデル（@Observable）
│   ├── Services/                          # データアクセス・外部サービス
│   ├── Utilities/                         # 定数・ヘルパー
│   └── Resources/                         # バンドルリソース
│       ├── Assets.xcassets/               # 画像・アイコン
│       └── (その他リソースファイル)
├── Tests/                                 # テスト
└── Tools/                                 # ビルドスクリプト等（任意）
```

---

## アーキテクチャガイドライン

### MVVM パターン

```
View (SwiftUI)
  ↓ @State / @Binding
ViewModel (@Observable)
  ↓
Service (データアクセス層)
  ↓
Model (データ構造)
```

| レイヤー | 配置先 | 役割 |
|----------|--------|------|
| Model | `Models/` | データ構造の定義。SwiftData の `@Model` やプレーンな `struct` |
| View | `Views/` | UI の描画のみ。ロジックは持たない |
| ViewModel | `ViewModels/` | `@Observable` クラス。ビジネスロジックと状態管理 |
| Service | `Services/` | DB アクセス、API 通信、音声再生などの外部リソース操作 |
| Utility | `Utilities/` | 定数、カラーパレット、フォント定義など |

### Swift 6 での注意点

- `@Observable` を使う（`@StateObject` / `@ObservableObject` ではなく）
- Strict Concurrency が有効なので `Sendable` 準拠に注意
- グローバルなシングルトンは `@MainActor` を付けるか `nonisolated(unsafe)` で明示的に管理
- `Task {}` 内で UI 更新する場合は `@MainActor` を確認

---

## よく使うフレームワークの追加方法

### SwiftData（ローカルデータ永続化）

1. `import SwiftData` を追加
2. `@Model` でモデルクラスを定義
3. App エントリで `.modelContainer(for:)` を設定
4. View 内で `@Query` / `@Environment(\.modelContext)` を使用

### SQLite3（読み取り専用データベース）

1. `project.yml` の settings に追加不要（システムフレームワーク）
2. `import SQLite3` で使用可能
3. `.sqlite` ファイルを `Resources/` に配置して `.copy("Resources")` でバンドル
4. `Bundle.module.url(forResource:withExtension:)` でパスを取得

### AVFoundation（音声再生）

1. `import AVFoundation` で使用可能
2. 音声ファイルは `Resources/` に配置
3. `AVAudioPlayer` または `AVAudioSession` で再生

---

## ビルド・実行・デバッグ

### SweetPad でのビルド

VSCode 上で以下の操作が可能です：

| 操作 | 方法 |
|------|------|
| ビルド | `Cmd+Shift+B` → タスク選択 |
| デバッグ実行 | `F5`（launch.json の設定を使用） |
| シミュレータ選択 | コマンドパレット → `SweetPad: Select Destination` |
| クリーンビルド | コマンドパレット → `SweetPad: Clean` |

### コマンドラインでのビルド

```bash
# デバッグビルド（シミュレータ向け）
xcodebuild -project {{AppName}}.xcodeproj \
  -scheme {{AppName}} \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# リリースビルド
xcodebuild -project {{AppName}}.xcodeproj \
  -scheme {{AppName}} \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

### project.yml を変更した場合

project.yml を編集したら必ず再生成してください：

```bash
xcodegen generate
```

SweetPad は生成後の `.xcodeproj` を参照するため、再生成を忘れるとビルドエラーになります。

---

## トラブルシューティング

### よくあるエラーと対処

| エラー | 原因 | 対処 |
|--------|------|------|
| `No such module 'SwiftUI'` | SDK パスが通っていない | `sudo xcode-select -s /Applications/Xcode.app` |
| `Signing requires a development team` | Team ID 未設定 | `project.yml` の `DEVELOPMENT_TEAM` を設定 |
| `Cannot find type '...' in scope` | XcodeGen 再生成忘れ | `xcodegen generate` を実行 |
| `Resource not found` | リソースファイルのパスずれ | `Resources/` 配下にあるか確認、`Package.swift` の `.copy("Resources")` を確認 |
| SweetPad がプロジェクトを認識しない | `.xcodeproj` が無い | `xcodegen generate` を実行 |
| ビルドは通るがシミュレータに出ない | Destination 未選択 | SweetPad: Select Destination でシミュレータを選択 |

### project.yml 変更後のフロー

```
project.yml を編集 → xcodegen generate → ビルド
```

この3ステップを常に意識してください。

---

## チェックリスト

新規プロジェクト作成時に以下をすべて確認してください。

- [ ] `Package.swift` が存在し、iOS platform とターゲットが定義されている
- [ ] `project.yml` が存在し、Bundle ID・Team ID・Display Name が正しい
- [ ] `.vscode/launch.json` が存在し、ターゲット名が一致している
- [ ] `.gitignore` に `.xcodeproj`, `.build`, `DerivedData` が含まれている
- [ ] `Sources/{{AppName}}/{{AppName}}App.swift` に `@main` エントリポイントがある
- [ ] `Sources/{{AppName}}/Resources/` ディレクトリが存在する
- [ ] `xcodegen generate` が成功する
- [ ] `xcodebuild build` が成功する
- [ ] Git リポジトリが初期化されている（`git init`）
