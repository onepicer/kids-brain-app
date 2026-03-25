# 🧠 奇妙大脑岛 (Kids Brain App)

一款专为4岁儿童设计的思维训练 Flutter App，包含6个趣味游戏模块，帮助孩子们在玩乐中开发大脑。

## 📱 功能模块

### 1. 🧩 逻辑乐园
- 找规律游戏
- 训练观察力和逻辑思维

### 2. 🏰 记忆城堡
- 翻牌记忆游戏（4x3 网格）
- 锻炼短时记忆能力

### 3. 👑 数学王国
- 数数游戏
- 数字认知和数量比较

### 4. 🌀 空间迷宫
- 走迷宫游戏
- 培养空间感知能力

### 5. 🏝️ 语言岛
- 看图认动物
- 认知各种动物名称

### 6. 🌳 专注力森林
- 找不同游戏
- 提升专注力和观察力

## 🎨 设计特色

- **卡通扁平化风格**：高饱和度明亮色彩，圆润可爱
- **卡通岛屿地图**：主页采用岛屿式设计，各模块是岛上的建筑
- **中文界面**：完全中文化，适合中国儿童
- **动画效果**：
  - 建筑轻微浮动
  - 云朵飘动
  - 卡片翻转动画

## 🚀 编译安装

### 环境要求

- Flutter 3.x
- Dart 3.x
- Android SDK

### 步骤

1. **克隆项目**
```bash
cd /root/.openclaw/workspace/kids-brain-app
```

2. **获取依赖**
```bash
flutter pub get
```

3. **运行到 Android 设备**
```bash
# 连接设备或启动模拟器后
flutter run
```

4. **构建 APK**
```bash
# 调试版本
flutter build apk

# 发布版本
flutter build apk --release

# 安装到设备
flutter install
```

### 项目结构

```
kids-brain-app/
├── lib/
│   ├── main.dart                  # 入口文件
│   ├── screens/
│   │   └── home_screen.dart       # 主页
│   └── games/
│       ├── memory_game.dart       # 记忆城堡
│       ├── math_count_game.dart   # 数学王国
│       ├── pattern_game.dart      # 逻辑乐园
│       ├── maze_game.dart         # 空间迷宫
│       ├── object_recognition_game.dart  # 语言岛
│       └── find_diff_game.dart    # 专注力森林
├── android/                       # Android 配置
├── pubspec.yaml                   # 项目配置
└── README.md                      # 本文件
```

## 🎯 目标用户

- **年龄**：4岁左右儿童
- **场景**：亲子互动、早教启蒙

## 📝 技术栈

- **框架**：Flutter 3.x
- **语言**：Dart
- **目标平台**：Android

## 🔧 开发说明

### 添加新游戏

1. 在 `lib/games/` 目录下创建新的游戏文件
2. 在 `lib/screens/home_screen.dart` 中的 `_modules` 列表添加新模块

### 自定义配色

修改 `lib/screens/home_screen.dart` 中各模块的 `color` 属性即可。

## 📄 许可证

MIT License

## 🙏 致谢

感谢 Flutter 团队提供的优秀跨平台框架！
