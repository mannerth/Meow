# AGENTS.md — SDU Meow（猫猫图鉴）

> 本文件用于指导在本仓库内工作的 agent。内容面向 Flutter/Dart 开发。

使用中文回复用户

## 1. 文档优先级（必须遵守）
1) `doc/默认模块.openapi.json`：导出的接口文档，**优先级最高**，有冲突以此为准。
2) `doc/接口说明.md`：接口说明补充文档。
3) `doc/猫猫图鉴.md`：产品需求文档（PRD）。
4) `doc/figma/`：Figma 导出文件（原型与视觉参考）。

## 2. 项目类型与入口
- 项目类型：**Flutter / Dart**（非 Node）。
- Flutter 版本：使用 FVM 配置，见 `.fvmrc`（当前为 `3.38.3`）。
- 只关心Android端
- 应用入口：`lib/main.dart`。
- 主要代码目录：`lib/`。

## 3. 目录速览
- `lib/`：核心业务代码（API、模型、UI、路由、状态管理等）。
  - `lib/api/`：网络层与服务层（Dio 封装、业务 API）。
  - `lib/model/`：数据模型（含 JSON 序列化）。
  - `lib/provider/`：Riverpod 状态管理。
  - `lib/ui/`：页面与组件。
  - `lib/router/`：路由。
  - `lib/util/`：工具类（本地存储、权限、时间等）。
- `assets/`：静态资源（icons/images）。
- `test/`：测试用例。
- `android/ios/web/windows/macos/linux/`：多端平台工程。

## 4. 构建 / Lint / 测试命令
> 默认在仓库根目录执行。

### 4.1 环境与依赖
- 使用 FVM（推荐）：
  - `fvm install`
  - `fvm use`
- 安装依赖：
  - `flutter pub get`

### 4.2 代码生成（Riverpod / JSON）
- `dart run build_runner build --delete-conflicting-outputs`
- 修改 model / provider 相关注解后必须重新生成。

### 4.3 静态分析与格式化
- Lint（使用 Flutter lints）：
  - `flutter analyze`
  - 备用：`dart analyze`
- 格式化：
  - `dart format .`

### 4.4 测试
- 运行全部测试：
  - `flutter test`
- 运行单个测试文件（推荐）：
  - `flutter test test/widget_test.dart`
  - `flutter test test/api_test.dart`

> 说明：`api_test.dart` 当前更像示例脚本，没有 `test()/expect()` 断言；
> 若需纳入 CI 严格测试，请改写为标准单元测试。

### 4.5 构建（按目标平台选择）
- Android：`flutter build apk`
- iOS（仅 macOS）：`flutter build ios`
- Web：`flutter build web`
- Windows：`flutter build windows`
- macOS：`flutter build macos`
- Linux：`flutter build linux`

### 4.6 运行（开发调试）
- `flutter run -d <device>`（如 `windows` / `chrome` / 模拟器）

## 5. 代码风格与约定
### 5.1 格式化与 Lint
- 统一使用 `dart format`，不要手动改格式。
- Lint 规则来自 `analysis_options.yaml`：
  - `include: package:flutter_lints/flutter.yaml`
  - `unnecessary_this` 被忽略。

### 5.2 命名规范
- 类 / 枚举 / 类型：`UpperCamelCase`。
- 变量 / 方法 / 字段：`lowerCamelCase`。
- 文件名：`snake_case.dart`。
- Widget 类保持 `const` 构造优先。

### 5.3 Import 规范
- 顺序：`dart:` → `package:` → `relative`。
- 本项目优先使用 `package:meow/...` 的绝对 package 引用。

### 5.4 状态管理（Riverpod）
- 使用 `@Riverpod` 注解的 provider：
  - 生成文件位于 `*.g.dart`，**禁止手改**。
  - 修改注解或依赖后运行 build_runner。
- Provider 状态更新保持简单可读，避免在 build 内做副作用。

### 5.5 数据模型与序列化
- 模型类位于 `lib/model/`，JSON 序列化使用 `json_serializable`。
- `*.g.dart` 由生成器维护，**不要直接编辑**。

### 5.6 API 与错误处理
- 网络层封装在 `lib/api/http.dart`（Dio）。
- 处理 `DioException` 时保持明确分支：
  - 401/403：需处理鉴权失效（当前实现会跳转登录页）。
  - 5xx：可重试，但必须避免无限重试。
- 返回值类型尽量明确（避免 `dynamic`）。

### 5.7 UI 与组件
- 页面在 `lib/ui/page/`，复用组件在 `lib/ui/widget/`。
- 新页面优先保持无副作用构造（可 `const`）。
- 颜色/间距等样式若需要复用，优先抽取为常量或主题配置。

## 6. 生成文件与忽略事项
- 生成文件（如 `*.g.dart`）由 build_runner 维护，**禁止手改**。
- `build/`、`.dart_tool/` 为构建产物或缓存，**不参与代码评审**。

## 7. 规则文件现状（Cursor / Copilot）
- 当前仓库 **不存在**：
  - `.cursor/` 目录
  - `.cursorrules`
  - `.github/copilot-instructions.md`
- 如需新增规则，请先与维护者确认，再补充到仓库并同步到本文件。

## 8. Agent 工作约束（合并规则摘要）
- 禁止生成或提交任何敏感信息（密钥、密码、PII、内部凭证）。
- 任何自动生成的代码必须经人工审查与测试后再提交。
- 不允许未经批准修改 CI/CD 或发布流程配置。
- 重大变更（功能/安全/依赖）必须附带原因与测试说明。

## 9. 常见任务提示
- 新增导航项：参考 `README.md` 的 `NavigationConfigRegistry.allConfigs` 示例。
- 修改 API 接口：以 `doc/默认模块.openapi.json` 为准，再同步 `doc/接口说明.md`。
- 修改模型字段：同步更新 model 与 API 解析，并运行 build_runner。

## 10. 环境与调试提示
- 接口基地址在 `lib/api/http.dart` 的 `Http.baseUrl`。
- 登录态由 `AuthState` 管理，Token 会持久化到本地存储（`lib/util/store.dart`）。
- `lib/main.dart` 的 `navigatorKey` 用于全局跳转（如鉴权失效跳转登录）。
- 需要替换资源时同步更新 `assets/` 与 `pubspec.yaml` 的 assets 列表。

## 11. 提交流程建议
- 修改了接口/模型/Provider：务必运行 build_runner 并确认 `*.g.dart` 更新。
- UI 改动优先确认 `const` 构造与可复用样式是否抽离。
- 重大变更请在 PR/提交说明中附上测试结果与风险点。

## 12. 质量检查清单（提交前）
- `dart format .`
- `flutter analyze`
- `flutter test`
- 如改动生成相关代码：`dart run build_runner build --delete-conflicting-outputs`
