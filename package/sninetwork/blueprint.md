
# Peinture AI 绘画应用 - Flutter 版本

## 概览

这是一个使用 Flutter 构建的 AI 绘画应用程序。该应用旨在作为 React Native 版本 "Peinture" 的一个功能完整的替代品，利用 `firebase_ai` 通过 Google 的 Gemini 和 Imagen 模型生成文本和图像。

## 设计与风格

应用将遵循现代、简洁的设计原则，注重用户体验。

- **颜色:** 以深色主题为基础，使用紫色作为强调色，营造出创造性和科技感。
- **字体:** 使用 `google_fonts` 加载 `Oswald` (用于标题) 和 `Roboto` (用于正文) 字体。
- **布局:** 采用响应式布局，确保在移动设备和 Web 上都有良好的显示效果。使用卡片、清晰的间距和直观的控件。
- **图标:** 使用 `lucide_icons` 提供清晰、一致的图标。

## 已实现功能 (V1)

- **Provider 选择:** 用户可以在不同的模型提供商之间切换 (Hugging Face, Gitee, ModelScope)。
- **模型选择:** 根据所选的 Provider，动态加载并显示支持的模型列表。
- **Aspect Ratio 选择:** 用户可以选择生成图像的宽高比 (方形, 竖屏, 横屏)。
- **Steps 和 Guidance Scale 滑块:** 提供滑块让用户调整生成图像的步数和引导比例 (但逻辑尚不完善)。
- **基本的 State 管理:** 使用 `flutter_riverpod` 管理应用状态。

## 当前任务：功能对齐与完善 Control Panel

**目标:** 使 Flutter 版本的 `control_panel.dart` 与 React 版本的 `ControlPanel.tsx` 功能完全一致。

**计划步骤:**

1.  **添加 `lucide_icons` 依赖:** 将 `lucide_icons` 包添加到 `pubspec.yaml` 以使用与 React 版本匹配的图标。

2.  **更新 `constants.dart`:**
    *   从 React 版本的 `constants.ts` 文件中迁移 `Z_IMAGE_MODELS` 和 `FLUX_MODELS` 列表。
    *   迁移 `getModelConfig` 和 `getGuidanceScaleConfig` 的逻辑，以便在 Flutter 中动态获取模型的配置（如 min/max steps）。

3.  **完善 `app_providers.dart`:**
    *   添加 `seedProvider = StateProvider<String>((ref) => '');`
    *   添加 `enableHDProvider = StateProvider<bool>((ref) => false);`
    *   添加 `isAdvancedOpenProvider = StateProvider<bool>((ref) => false);`

4.  **重构 `control_panel.dart`:**
    *   **引入高级设置:** 使用 `ExpansionTile` 来创建一个可折叠的 "Advanced Settings" 面板，并将 Steps, Guidance Scale, Seed 控件移入其中。
    *   **实现 Seed 输入功能:**
        *   添加一个带 `+` 和 `-` 按钮的 `TextField` 用于调整 Seed。
        *   添加一个带 `Dices` 图标的 `IconButton` 用于随机生成 Seed。
    *   **实现 HD 切换功能:**
        *   在模型选择器旁边，根据当前模型是否在 `Z_IMAGE_MODELS` 或 `FLUX_MODELS` 列表中，条件性地显示一个 `Switch` 来控制 `enableHDProvider`。
    *   **修复滑块逻辑:**
        *   使 "Steps" 滑块的 `min` 和 `max` 值根据 `getModelConfig` 的逻辑动态变化。
        *   使 "Guidance Scale" 滑块仅在 `getGuidanceScaleConfig` 返回有效配置时才显示。
    *   **美化 UI:**
        *   为各个选择器和按钮添加 `lucide_icons` 图标。
        *   调整布局和间距，使其更接近 React 版本的外观。
        *   在滑块旁边显示当前值。

5.  **后续检查:**
    *   运行 `flutter pub get`。
    *   运行 `flutter format .`。
    *   检查应用以确保所有功能正常工作且没有编译错误。
