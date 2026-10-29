# Changelog

本项目版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)：
`主版本.次版本.修订号`。功能新增升次版本，修 bug 升修订号，不兼容改动升主版本。

## [0.4.0] - 2026-10-29

首个公开发布版本。

### 新增

- **未被引用资源检测**：扫描项目中所有文本资源（`.gd`、`.tscn`、`.tres`、`.gdshader`、`.json`、`.csv`、`.cfg`、`.txt`、`.md`、`project.godot`），
  找出没有被任何地方引用的资源，并给出可回收的空间总量。
- 支持 `uid://` 引用：通过 `ResourceUID` 将 UID 还原为真实路径后比对，避免 Godot 4 项目大面积误报。
- 报告末尾显示体积最大的 10 个文件。
- 超规格贴图检测阈值可读（默认 2048 px / 2 MB）。
- 超规格音频检测（默认 1 MB）。
- 中英双语 README，附已知局限说明。

### 修复

- 取贴图尺寸时不再使用 `Image.load()`，消除导出时满屏的
  `WARNING: core/io/image.cpp:2770 - Loaded resource as image file, this will not work on export` 警告。
  改为 `ResourceLoader.load()` + `Texture2D.get_width() / get_height()`。
- 过滤 `.import` 与 `.uid` 文件，避免它们出现在体积排行里，也避免它们把源资源误判为"已使用"。
- 跳过 `res://addons/` 目录，不把第三方插件计入统计。

### 已知局限

- 静态文本扫描，无法识别运行时拼接出的资源路径，这类资源会被误报为"未被引用"。删除前请先提交版本控制。

## [0.1.0 – 0.3.0]

内部迭代版本，未公开发布。
