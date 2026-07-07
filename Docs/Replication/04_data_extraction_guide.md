# 数据抽取与查证指南

本文给另一个 Codex 使用，用于从原项目继续抽取关卡复刻细节。

## 1. 先读现成清单

第三章玩家可交互文字明细：

```text
D:\WordGame\第三章可交互文字清单.md
```

这份清单已经按关卡整理：

- 文字。
- 交互方式。
- 数量。
- 位置/节点。
- 效果摘要。
- 来源。

同一关卡不同位置出现的同一文字，如果交互方式一致，只合并标注一次，并写了数量。

## 2. 查第三章可推/可删/可拆文字

PowerShell：

```powershell
rg -n "can_push = true|can_delete = true|can_split = true" "Scenes\Maps\第三章"
```

用途：

- 找静态摆放在 `.tscn` 中的可交互文字。
- 快速定位需要复刻的节点。

注意：这只能找到静态字段，Typewriter 运行时生成的文字需要查 `commands` 中的 `{can_push:true}`、`{can_delete:true}`。

## 3. 查某关的关键指令

以 `04_手套教學` 为例：

```powershell
rg -n "append_sentence_rule|sentence_legal_animation|set_push_power|set_backspace_power|map_transport" "Scenes\Maps\第三章\04_手套教學.tscn"
```

用途：

- 找能力开启。
- 找成句规则。
- 找过关跳转。
- 找关键演出。

## 4. 查 Typewriter 生成的可交互文字

```powershell
rg -n "\{[^}]*can_push|can_delete|can_split" "Scenes\Maps\第三章"
```

看到类似：

```text
不{can_push:true,can_delete:true}
```

复刻含义：

- 生成一个文字 `不`。
- 该文字可推动。
- 该文字可退格删除。

## 5. 查某关所有事件文本与指令

```powershell
rg -n "text = |commands = |event_trigger_action|can_push|can_delete|can_split" "Scenes\Maps\第三章\13_添譜來堂_方塊.tscn"
```

用途：

- 找所有可见文字。
- 找每个事件的触发方式。
- 找该事件是否可推/可删/可拆。
- 找交互后会发生什么。

## 6. 查成句规则

```powershell
rg -n "sentence_rules|append_sentence_rule|change_sentence_rule|delete_sentence_rule|clear_sentence_rule" "Scenes\Maps\第三章"
```

成句规则可能有两种来源：

- 地图导出的 `sentence_rules` 字段。
- 事件执行时通过 `append_sentence_rule` 动态添加。

复刻时两种都要合并到关卡规则表里。

## 7. 查地图跳转

```powershell
rg -n "map_transport|enter_chapter|now_map_name" "Scenes\Maps\第三章" "Scripts"
```

用途：

- 确认每关出口。
- 确认过场后进入哪张地图。
- 确认章节入口。

第三章入口在 `Global.gd`：

```text
enter_chapter(3) -> map_transport("第三章/00_第三章字卡")
```

## 8. 读 commands 的方法

`.tscn` 中的 commands 常是多行字符串。结构类似：

```text
@[type]
texts = "..."
pos = Vector2(...)

@[append_sentence_rule]
text = "..."
switch = "..."
```

解析方法：

1. 以 `@[xxx]` 切分指令段。
2. 每段内按 `key = value` 读取参数。
3. 按原顺序执行。
4. 遇到特殊段名需要挂到 Event 的特殊交互：
   - `@[backspace_command]`
   - `@[end_backspace_command]`
   - `@[split_command]`
   - `@[end_split_command]`

## 9. 坐标和打字规则

坐标：

```text
Vector2(x, y)
```

一般表示格子坐标，显示时乘以 60 像素。

Typewriter 文本规则：

```text
普通字符：在当前位置生成文字
&：换到下一行
|：等待
＿：空一格
Ｍ：玩家位置
[event_name]：复用事件
{...}：给刚生成的字设置属性
```

示例：

```text
Ｍ不{can_push:true,can_delete:true}確定地說
```

含义：

- `Ｍ` 放置/移动玩家。
- 生成可推可删的 `不`。
- 继续生成 `確`、`定`、`地`、`說` 等普通文字。

## 10. 推荐抽取流程

复刻某关时按这个顺序：

1. 在 `第三章可交互文字清单.md` 找该关，确认有哪些玩家可交互文字。
2. 用 `rg` 打开该关 `.tscn`，找 `commands`、`can_push`、`can_delete`、`can_split`。
3. 找 `sentence_rules` 和 `append_sentence_rule`，整理胜利条件。
4. 找 `map_transport`，确认过关去向。
5. 找 `set_*_power`，确认玩家能力变化。
6. 把 Typewriter 字符串转成关卡数据。
7. 用新实现跑一遍，检查文字位置、交互方式和开关结果是否一致。

## 11. 原始脚本入口

需要理解机制时优先看这些文件：

```text
D:\WordGame\Scripts\Event.gd
D:\WordGame\Scripts\Player.gd
D:\WordGame\Scripts\BaseCharacter.gd
D:\WordGame\Scripts\Typewriter.gd
D:\WordGame\Scripts\MainMap.gd
D:\WordGame\Scripts\Interpreter.gd
D:\WordGame\Scripts\Global.gd
```

这些脚本共同决定关卡如何运行。不要只看 `.tscn`，否则会漏掉推字后检查规则、退格后执行特殊指令、Typewriter 内联属性等行为。
