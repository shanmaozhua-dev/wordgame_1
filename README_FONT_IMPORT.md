# 字体接入说明：给复刻项目里的 Codex 和人工维护者

> 前提假设：本目录中的 `Fonts` 文件夹已经复制到了复刻项目根目录。
> 也就是说，复刻项目中现在应该已经存在 `res://Fonts/Zpix.tres` 和 `res://Fonts/Zpix.ttf`。

## Codex 优先读取规则

如果你是接入复刻项目的 Codex，请按下面规则处理字体：

1. 默认使用 `res://Fonts/Zpix.tres` 作为游戏主字体。
2. 不要优先使用系统字体，也不要新建另一套默认字体，除非用户明确要求。
3. 如果代码中需要绘制地图文字、剧情文字、可交互文字，统一引用：

   ```gdscript
   var font = preload("res://Fonts/Zpix.tres")
   ```

4. 如果 UI 控件需要字体，优先把 `Zpix.tres` 设置到 Theme 的默认字体；没有统一 Theme 时，再对单个控件加字体 override。
5. `Zpix-v3.1.6.tres` 是备用/对照字体，不作为默认字体。
6. `.import` 文件不是权威源文件。Godot 可以自动重新生成 `.import` 文件。
7. 如果 Godot 导入字体报错，优先删除 `Fonts/*.import` 后重新打开项目，而不是修改 `.tres` 路径。
8. 不要改动 `Zpix.tres` 中的 `font_data = res://Fonts/Zpix.ttf`，除非对应字体文件确实改名或移动。

## 新项目中应有的文件结构

复刻项目根目录应包含：

```text
YourReplicationProject/
  Fonts/
    Zpix.ttf
    Zpix.tres
    Zpix-v3.1.6.ttf
    Zpix-v3.1.6.tres
```

必须存在：

- `Fonts/Zpix.ttf`
- `Fonts/Zpix.tres`

建议保留：

- `Fonts/Zpix-v3.1.6.ttf`
- `Fonts/Zpix-v3.1.6.tres`

可有可无：

- `Fonts/Zpix.ttf.import`
- `Fonts/Zpix-v3.1.6.ttf.import`

## 主字体资源

主字体资源路径：

```text
res://Fonts/Zpix.tres
```

主字体真实字体文件：

```text
res://Fonts/Zpix.ttf
```

`Zpix.tres` 的关键参数应保持为：

```text
size = 54
use_mipmaps = true
extra_spacing_char = 1
font_data = res://Fonts/Zpix.ttf
```

如果复刻文字网格，优先沿用这些参数：

- 字体资源：`res://Fonts/Zpix.tres`
- 字号：`54`
- 单格绘制步长：约 `60`
- `use_mipmaps = true`
- `extra_spacing_char = 1`

## Codex 在复刻项目中的推荐接入方式

### 1. 脚本文字绘制

地图文字、可交互字、剧情打字机、手写 `draw_string` 绘制逻辑，建议统一这样引用：

```gdscript
var font = preload("res://Fonts/Zpix.tres")
```

如果项目使用 Godot 4 的 `draw_string`，保持使用同一个 `FontFile` 资源，不要临时加载 `.ttf`：

```gdscript
draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color.WHITE)
```

### 2. UI 控件

如果有统一 Theme，推荐设置 Theme 默认字体：

```gdscript
var theme := Theme.new()
theme.default_font = preload("res://Fonts/Zpix.tres")
```

如果只是单个 Label/Button：

```gdscript
$Label.add_theme_font_override("font", preload("res://Fonts/Zpix.tres"))
```

### 3. 字体导入异常处理

如果 Codex 在复刻项目里发现字体不显示、`.import` 冲突、资源 UID 异常：

1. 先确认 `Fonts/Zpix.ttf` 和 `Fonts/Zpix.tres` 都存在。
2. 确认 `Zpix.tres` 内部仍指向 `res://Fonts/Zpix.ttf`。
3. 删除 `Fonts/Zpix.ttf.import`。
4. 重新打开 Godot，让 Godot 自动重建 import。
5. 如果仍失败，再在 Godot 编辑器中重新保存 `Zpix.tres`。

不要直接把字体路径改成绝对路径，例如 `D:\WordGame\...`。复刻项目中必须使用 `res://Fonts/...`。

## 人类可读说明

这个字体包来自原项目的 `D:\WordGame\Fonts` 目录。原项目主要使用 Zpix 像素字体，文字游戏的地图字、剧情字和部分 UI 都依赖这个字体的像素风格。

原项目中主要引用位置：

- `Scripts/DrawText.gd` 使用 `res://Fonts/Zpix.tres`
- `Scripts/TextureText.gd` 使用 `res://Fonts/Zpix.tres`
- `Scenes/UI/DebugConsole.tscn` 使用 `res://Fonts/Zpix.tres`
- `Scenes/UI/StartMenu.tscn` 直接引用 `res://Fonts/Zpix.ttf`

`Zpix-v3.1.6` 在原项目中主要用于测试场景或版本对照。为了避免复刻时字体表现偏差，建议先只用 `Zpix.tres`，等文字排版稳定后再考虑是否比较 `Zpix-v3.1.6`。

## 检查清单

在复刻项目里接入完成后，检查以下项目：

- `res://Fonts/Zpix.tres` 能被 Godot 正常打开。
- `res://Fonts/Zpix.ttf` 存在。
- 运行时没有字体 import 报错。
- 地图文字使用 `Zpix.tres`。
- UI 文字如果需要像素风，也使用 `Zpix.tres`。
- 文字网格字号优先使用 `54`。
- 单格步长优先从 `60` 开始调。
- 没有把字体路径写成旧项目绝对路径。

## 授权提醒

当前导出包没有附带 Zpix 字体的 license 或 readme。技术接入可以按本文执行；如果复刻项目后续要公开发布、商用或分发，请单独确认 Zpix 字体的授权来源和使用条件。
