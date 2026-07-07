# 核心系统说明

本文解释原项目中支撑关卡复刻的核心系统。复刻时可以换引擎或换实现方式，但建议保留这里描述的语义。

## 1. 地图与网格

地图场景位于：

- `D:\WordGame\Scenes\Maps`
- 第三章：`D:\WordGame\Scenes\Maps\第三章`

原项目中玩家和文字事件都在格子上移动。常见坐标写成 `Vector2(x, y)`，一格约等于 60 像素。

复刻时建议用以下模型：

```text
Map
  width, height
  events: Event[]
  player: Player
  switches: Map<string, bool>
  variables: Map<string, any>
  sentenceRules: Rule[]
```

每个文字实体最好绑定格子坐标，而不是只做 UI 文本。第三章谜题依赖文字之间的空间关系，例如推成一整句、删除一个字、把字推到另一个位置。

## 2. Event 文字实体

核心脚本：

- `D:\WordGame\Scripts\BaseCharacter.gd`
- `D:\WordGame\Scripts\Event.gd`

Event 是地图上的文字/机关/NPC 统一抽象。关键字段：

```text
text: 显示的文字
text_color: 文字颜色
can_push: 是否可推动
can_delete: 是否可退格删除
can_split: 是否可拆分
commands: 交互后执行的指令文本
event_trigger_action: AUTO / PRESS / TOUCH / LOOP
```

触发方式：

- `PRESS`：玩家面对该事件并按确认键触发。
- `TOUCH`：玩家接触或靠近触发。
- `AUTO`：地图刷新时自动触发。
- `LOOP`：循环执行，常用于持续检测或演出控制。

玩家可交互文字清单里只保留了玩家能通过调查、触碰、推动、退格、拆字等方式影响的文字，自动剧情事件没有作为主要复刻对象。

## 3. 玩家交互

核心脚本：

- `D:\WordGame\Scripts\Player.gd`

重要行为：

- 按确认键：检查玩家面前事件，执行其 `commands`。
- 推字：如果玩家拥有推力，且面前 Event `can_push = true`，则尝试推动。
- 退格：如果玩家拥有退格能力，且面前 Event `can_delete = true`，删除或触发特殊退格指令。
- 拆字：如果玩家拥有拆字能力，且 Event `can_split = true` 并符合拆分表，则生成拆分后的文字。

复刻时玩家系统至少需要：

```text
position
direction
has_push_power
has_backspace_power
has_split_power
interact()
pushFront()
backspaceFront()
splitFront()
```

## 4. 指令解释器

核心脚本：

- `D:\WordGame\Scripts\Interpreter.gd`
- `D:\WordGame\Scripts\Event.gd`

Event 的 `commands` 以类似下面的格式写在 `.tscn` 中：

```text
@[command_name]
param = value

@[another_command]
...
```

`Event.gd` 会把原始文本解析成指令列表，再交给 `Interpreter.gd` 执行。

复刻时不一定要完整支持所有指令，但第三章常用指令需要支持：

```text
type / type_parallel / type_fixed
clear_typed
move_route
map_transport
transport_event
set_event_params
refresh_event
remove_event
play_se / play_bgm / change_bgm
set_ctrl_z_power
set_backspace_power
set_push_power
set_split_power
append_sentence_rule
change_sentence_rule
delete_sentence_rule
clear_sentence_rule
sentence_legal_animation
highlight
call_method
set_achievement
save
```

最低可行复刻可以把这些指令转成自己的 JSON 或函数调用。例如：

```json
{
  "command": "set_push_power",
  "value": true
}
```

但需要保留执行顺序，因为大量演出依赖等待、移动、打字和开关状态。

## 5. Typewriter 打字机

核心脚本：

- `D:\WordGame\Scripts\Typewriter.gd`

第三章大量文字不是场景中静态摆放，而是在事件触发后由 Typewriter 生成。

字符串规则大致如下：

```text
普通字符：生成一个文字 Event
&：换行
|：等待
＿：空一格
<label>：切换标签
[event_name]：复用已有事件
[event_name{copy:true}]：复制已有事件
Ｍ：放置或移动玩家
字{can_push:true,can_delete:true,name:"x"}：给刚生成的字设置属性
```

复刻时需要实现“从字符串逐格生成文字”的能力。否则 `04_手套教學` 这类关卡会很难还原，因为可推/可删的字很多是打字机运行时生成的。

## 6. 成句规则

核心脚本：

- `D:\WordGame\Scripts\MainMap.gd`

地图会维护 `sentence_rules`。系统会扫描地图上横向、纵向连续文字，只要匹配某条规则，就设置对应开关。

规则常见字段：

```text
text: 需要形成的句子
switch: 匹配后打开的开关
except: 例外条件
memory: 记录匹配位置或文字
has_animation: 是否播放合法句动画
progress / level: 用于流程和难度标记
```

规则中的 `＊` 可以理解为通配符。匹配成功时会播放成句合法动画，并让后续事件或关卡出口可用。

复刻时建议实现：

```text
checkSentenceRules()
  读取当前地图横向/纵向文字串
  对每条 rule 做匹配
  匹配成功则 switches[rule.switch] = true
  匹配失败则 switches[rule.switch] = false
```

## 7. 全局流程与存档

核心脚本：

- `D:\WordGame\Scripts\Global.gd`

第三章入口：

```text
Global.enter_chapter(3)
=> map_transport("第三章/00_第三章字卡")
```

存档内容包括：

```text
当前地图
当前章节/小节
全局开关
全局变量
自开关
玩家状态
地图状态
章节进度
```

复刻单关可以暂时不做完整存档，但跨关复刻必须保留能力状态和关键开关，例如是否已获得退格/推字能力。

## 8. 最低可行复刻清单

要复刻第三章核心谜题，至少实现：

- 网格地图和文字实体。
- 玩家移动、朝向、调查。
- 可推文字。
- 可退格删除文字。
- Typewriter 字符串生成文字。
- 成句规则扫描。
- 开关变量。
- 事件指令顺序执行。
- 地图切换。

可后补：

- 完整音效/BGM。
- 存档。
- 全部 UI 动画。
- 成就系统。
- 复杂镜头效果。
