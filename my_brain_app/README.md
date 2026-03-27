# 宝宝大脑训练 APP  (MyBrainApp)

**适用年龄**：4 岁及以上（幼儿）

## 功能清单

| 模块 | 说明 | 关键技术 |
|------|------|----------|
| 记忆配对 | 翻开卡片找相同图案 | Flutter + Flame |
| 颜色辨认 | 语音提示点指定颜色 | flutter_tts |
| 简易算数 | 数动物、点数字 | Flutter UI |
| 形状拼图 | 拖拽拼合形状 | Flame Drag & Drop |
| **绘本阅读** | 自动朗读配图的绘本页面 | PageView + flutter_tts + 本地图片资源 |
| **音乐节奏** | 随音乐节拍点击屏幕，培养节奏感 | audioplayers + 触摸检测 |
| **小舞蹈** | 角色随音乐做简易舞蹈动画，配合语音提示 | Flare/Lottie 动画或自制帧动画 |

> **全部交互采用大图标+语音**，不需要识字，孩子可以通过听和点触完成。

## 项目结构（Flutter）
```
my_brain_app/
├─ android/            # Android 项目（已包含 TV leanback 支持）
├─ ios/                # iOS 项目（支持 iPad、Apple TV）
├─ lib/
│   ├─ main.dart      # 程序入口，检测平台并跳转 HomeScreen
│   ├─ screens/
│   │   ├─ home_screen.dart      # 大图标入口页面
│   │   ├─ picture_book_screen.dart   # 绘本阅读（PageView）
│   │   ├─ music_rhythm_screen.dart   # 音乐节奏游戏
│   │   ├─ dance_screen.dart          # 小舞蹈演示
│   │   └─ …（其他小游戏）
│   ├─ games/          # 所有游戏实现（Flame）
│   ├─ utils/          # 本地存储、TTS、音频封装
│   └─ widgets/        # 大按钮、星星进度条等通用 UI
├─ assets/
│   ├─ img/            # 卡通图片、绘本插画（免费素材）
│   ├─ audio/          # 语音提示、背景音乐、音效
│   └─ fonts/          # 思源黑体 Rounded（适合幼儿）
├─ pubspec.yaml        # 依赖声明
└─ .github/
    └─ workflows/
        └─ flutter_ci.yml   # GitHub Actions CI（构建 Android & iOS）
```

## 关键依赖（pubspec.yaml）
```yaml
name: my_brain_app
description: A brain‑training app for toddlers (4‑year‑old).
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.2.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_screenutil: ^5.7.0
  flame: ^1.9.0
  flame_audio: ^1.9.0
  flutter_tts: ^4.0.0
  audioplayers: ^5.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.2
  json_annotation: ^4.9.0
  lottie: ^3.2.2   # 用于舞蹈动画（可替换为 Flare）

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6
  hive_generator: ^2.0.1
  json_serializable: ^6.7.1
```

## 美术资源推荐
- **卡通图片 / 绘本插画**： https://openclipart.org/（搜索 `kids`, `animals`, `storybook`）
- **背景音乐 & 音效**： https://freesound.org/（搜索 `children`, `piano`, `click`）
- **字体**： 思源黑体 Rounded（Google Fonts）
- **舞蹈动画**： https://lottiefiles.com/（搜索 `dance kid`）

> 将下载好的资源放入 `assets/img/`、`assets/audio/`、`assets/fonts/`，并在 `pubspec.yaml` 中声明。

## 本地初始化（一步完成）
```bash
# 进入工作区
cd /root/.openclaw/workspace/my_brain_app

# 初始化 Git 仓库（后续推送到你的 GitHub）
git init

git add .
git commit -m "Initial commit – toddler brain‑training app"
```

## GitHub 远程仓库（可选）
1. 在 GitHub 上新建仓库（例如 `yourname/my_brain_app`）
2. 关联远程并推送：
```bash
gh repo create yourname/my_brain_app --public --source=. --push
```
> 需要在本机先登录 `gh auth login`，如果还未登录，请执行 `gh auth login` 并完成 OAuth 授权。

## CI / CD（GitHub Actions）
在 `.github/workflows/flutter_ci.yml` 中加入下面的模板，凡是向 `main` 分支 push 时会自动编译 Android APK、iOS IPA（仅 macOS runner）并生成 artefacts，方便后续发布到 Google Play / App Store。

```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests
        run: flutter test --no-pub
      - name: Build Android APK
        run: flutter build apk --release
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  ios_build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      - name: Install CocoaPods
        run: pod install --project-directory=ios
      - name: Build iOS IPA
        run: flutter build ios --release --no-codesign
      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: ios-ipa
          path: build/ios/ipa/*.ipa
```

## 后续发布准备
- **Google Play**：在 Google Play Console 创建应用，上传 `app-release.apk`，填写 **内容分级**（儿童）并勾选 **儿童隐私政策**（本 APP 完全本地存储，无第三方 SDK）。
- **Apple App Store**：在 App Store Connect 创建 iOS 应用，使用 Xcode 或 Fastlane 上传 `*.ipa`，在 **App Privacy** 填写「不收集用户数据」。
- **隐私声明**：在 `assets/` 目录放置 `privacy_policy.html`，在 App Store/Play 上链接即可。

## 小提示 & 注意事项
1. **所有交互都配语音**（使用 `flutter_tts`），确保孩子无需阅读即可玩。
2. **时长限制**：在 `utils/storage.dart` 中保存每日累计时长，HomeScreen 在启动时检查并弹出「已达今日上限，请休息」提示。
3. **绘本阅读实现**：在 `picture_book_screen.dart` 用 `PageView.builder` 渲染每页图片，`onPageChanged` 调用 `tts.speak(pageText[i])`（页面文字可写在 `assets/json/book.json`）。
4. **音乐节奏**：准备一段 30 秒的轻快背景音乐，使用 `audioplayers` 播放，监听用户在节拍点的点击次数与准确度，算分并显示星星奖励。
5. **小舞蹈**：可以使用 Lottie 动画 `dance.json`，配合音乐自动播放，完成后 TTS 说「跳得真棒！」。

---
**祝开发顺利，愿小朋友玩得开心、学习更快！**
