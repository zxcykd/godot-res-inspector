# Res Inspector

A project audit plugin for **Godot 4**. It tells you how heavy your game's assets are, which ones are oversized, and — most importantly — which ones nothing in your project references anymore.

Built for indie developers who want to know *why* their build is 400 MB before shipping.

## What it reports

- **Overview** — file count, texture count and total weight, audio count and total weight
- **Oversized textures** — dimension larger than 2048 px, or file larger than 2 MB
- **Oversized audio** — file larger than 1 MB
- **Unused assets** — textures / audio / fonts that no scene, resource, or script references, plus the total space you could reclaim
- **Top 10 largest files** — the usual suspects, ranked

## Installation

1. Copy the `addons/res_inspector` folder into your project's root.
2. Open **Project → Project Settings → Plugins** and enable **Res Inspector**.
3. Run it from **Project → Tools → 资源体检**.

## How "unused" is detected

The plugin scans the text of every `.gd`, `.tscn`, `.tres`, `.gdshader`, `.json`, `.csv`, `.cfg` and `project.godot` file for `res://` and `uid://` references. UID references are resolved back to real paths through `ResourceUID`, so projects that use UID-based references are handled correctly.

`.import` and `.uid` files are deliberately excluded — including them would mark every source asset as "used".

## Limitations

- Asset paths assembled at runtime from strings can't be seen by a static scan and will be reported as unused. **Commit before deleting anything.**
- Third-party assets under `res://addons/` are never reported, to avoid flagging other plugins' files.
- Scene/resource files themselves are not reported as unused; only textures, audio, and fonts.

## 中文说明

Godot 4 项目资源体检插件：统计贴图与音频占用，标出尺寸或体积超标的资源，并找出项目里**没有被任何场景、资源或脚本引用**的贴图 / 音频 / 字体，算出能回收多少空间。

安装：把 `addons/res_inspector` 复制到项目根目录，在 **项目设置 → 插件** 中启用，然后从 **项目 → 工具 → 资源体检** 启动。

「未被引用」基于静态文本引用扫描，代码中拼接出来的路径可能被误报，**删除前请先提交版本控制**。

## License

MIT — see [LICENSE](LICENSE).
