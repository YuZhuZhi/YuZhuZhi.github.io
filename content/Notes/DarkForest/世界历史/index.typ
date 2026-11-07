#import "../../index.typ": template, tufted
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import fletcher.shapes: diamond

#show: template.with(
  title: "DarkForest 的世界历史的数据库设计",
  description: "通过关系数据库的实体、联系和范式理论，重新分析 DarkForest 的世界历史设计。",
  date: datetime(year: 2026, month: 11, day: 3),
  lang: "cn",
)

// 模仿 Report.typ：单列表格作为实体、主键加下划线、菱形表示联系。
#let db-table(name, fields) = {
  set text(size: 12pt)
  set underline(offset: 2pt, stroke: 1pt)
  table(
    columns: 1,
    align: left,
    inset: (x: 6pt, y: 4pt),
    stroke: .6pt + rgb("#556373"),
    fill: (x, y) => if y == 0 { rgb("#eaf0f7") } else { white },
    [#strong(name)],
    ..fields,
  )
}

= DarkForest 的世界历史的数据库设计

= 引言

== 问题的由来

在早期的 DarkForest 中，我们已经实现了回合推进、行为记录与独立模拟。然而，当世界规模逐渐扩大时，一个新的问题开始出现：游戏内存在的某个事实，究竟应该由谁保存？

例如，猎人 A 在一间房间中开枪。战斗系统需要知道枪声的发生时间与位置；地图可能保留一项声音标记；附近的猎人 B 可能听见枪声并写入记事本；回放系统则需要忠实重建发生过的战斗。如果让这些模块各自保存一套可以修改的“枪声事实”，我们很快就会面临内容不一致、过期时间不统一、重复计数与存储，以及更严重的信息泄漏。

因此，我们需要区分两种对象：*世界已经发生的事实*，以及*某个角色获准知道的事实*。前者应有唯一的权威记录；后者则是经过观察、拾取和时间约束之后，从事实中获得的局部视图。本专题尝试用关系数据库的实体、联系和范式理论，重新分析这一设计。

这里首先作出一个必要声明：当前代码已经采用 C\# 的 `record`、列表及索引组织统一历史，并没有实际建立 PostgreSQL、SQLite 或其他关系数据库。下文的 E-R 图、主外键和 `CREATE TABLE` 均是*在现行内存模型基础上提出的关系化设计*。

== 需求分析

从 `ActionJournal`、`WorldHistoryEntries`、`NoteBook`、`MapItem`、`MapView` 和 `ReplayTimeline` 的职责出发，可以整理出六项需求：

+ 每个世界事件只能拥有一份权威记录，并保留事件顺序、发生回合和来源。
+ 同一事件可以被不同角色在不同时间、以不同程度观察到；未观察到的事件不应进入其记事本。
+ 战斗、伤情、治疗和背包等信息能够按类型查询，但不应混入一张大量空值的宽表。
+ 地图是可以持有、丢弃和拾取的实体物品；不同地图拥有不同的标注，却引用同一个真实世界。
+ 回放可以从全局事件恢复对局，但玩家或 AI 不应因此自动获得回放所能读取的全部事实。
+ 多局模拟的事件编号可能从 1 重新开始，因此事件键必须包含所属对局。

= 设计概要

== 实体与联系分析

我们首先确定如下实体：`GameRun`（一局游戏）、`ActorIdentity`（角色身份）、`WorldEvent`（世界事件）、`Observation`（观察事实）、`MapItem`（实体地图）、`FactionAlertState`（阵营警觉状态）。此外，伤情、治疗、声音、遭遇等应当具有自己的分类表，而不能一概视为 `WorldEvent.Detail` 中的一段字符串。

实体之间的关系也不难确定：一局游戏具有多个角色和事件；一个事件可以产生多条针对不同角色的观察；一个角色可以持有多张地图；一张地图可以包含多个房间的知识及若干限时标注；阵营对某目标的警觉由一系列已核准的情报驱动。

为以下用单列表格表现实体，*下划线表示主键*，菱形表示联系。图中只放置关键属性，完整字段在后文给出；各图均是关系模型示意，不表示当前已经有相应 SQL 表。

#figure(
  diagram(
    spacing: (5pt, 5pt),
    node-stroke: .8pt,
    edge-stroke: 1pt,
    node-inset: 0pt,
    node-shape: rect,
    // node-corner-radius: 3pt,
    // edge-corner-radius: 4pt,

    node(
      (0, 0),
      db-table("GameRun", (
        [#underline[run_id]],
        [level, seed],
        [rules_version],
      )),
      name: <run>,
      stroke: none,
    ),

    node(
      (9, 0),
      db-table("WorldEvent", (
        [#underline[run_id, event_id]],
        [turn, step, actor_id],
        [kind],
      )),
      name: <event>,
      stroke: none,
    ),

    node(
      (18, 0),
      db-table("ActorIdentity", (
        [#underline[run_id, actor_id]],
        [kind, display_name],
      )),
      name: <actor>,
      stroke: none,
    ),

    node(
      (9, 6),
      [产生],
      name: <produce>,
      shape: diamond,
      inset: 8pt,
      fill: rgb("#fff6e5"),
    ),

    node(
      (9, 12),
      db-table("Observation", (
        [#underline[run_id, event_id]],
        [observer_id],
        [source_event_id],
        [text],
      )),
      name: <observation>,
      stroke: none,
    ),

    node(
      (0, 18),
      db-table("SignalObservation", (
        [#underline[run_id, event_id]],
        [direction, distance],
        [strength, signal_id],
      )),
      name: <signal>,
      stroke: none,
    ),

    node(
      (18, 18),
      db-table("EncounterObservation", (
        [#underline[run_id, event_id]],
        [opponent_id, entry_kind],
        [item_id, quantity],
      )),
      name: <encounter>,
      stroke: none,
    ),

    edge(<run>, <event>, "-"),
    edge(<actor>, <event>, "-"),
    edge(<event>, <produce>, "-"),
    edge(<produce>, <observation>, "-"),
    edge(<observation>, <signal>, "-"),
    edge(<observation>, <encounter>, "-"),
  ),
  caption: [世界事件及观察者局部记录的 E-R 示意；事件与观察是两个不同的事实层次],
) <fig:history-er>

在 @fig:history-er 中，`source_event_id` 尤其重要。一个事件被角色听见，并不意味着角色当时亲眼见到了事件本身；观察记录只应保存其实际获得的方向、距离、强度和描述，且引用来源以供规则内部核验。*引用来源事件*与*拥有读取来源事件全部字段的权限*是完全不同的两件事。

= 从非规范化记录到第三范式

== 未规范化的宽表及其问题

假设我们为了图方便，直接建立一张 `HistoryWide`，包含：`event_id`、`turn`、`actor_id`、`actor_name`、`kind`、`observer_id`、`note_text`、`opponent_name`、`item_id`、`item_name`、`quantity`、`position`、`health`、`bag_items`、`known_rooms`。如果一次战斗被三名角色听见，并产生两项道具转移，我们就会遇到两个问题：

其一，`bag_items` 和 `known_rooms` 都是列表，无法作为普通关系表中的原子属性；其二，一条战斗事件会因为观察者、道具数量与角色快照的笛卡尔组合而被重复存储。若原始枪声在第五回合发生、角色第七回合拾获一张记录该枪声的地图，则把 `turn` 同时当作发生时间与获知时间，还会掩盖事件传播的时序差异。

这样的结构将产生更新异常：修改角色名称需要更新所有历史行；删除某张地图记录可能误删唯一的世界事件；在尚未有人观察到某事件时，我们甚至无法单独插入完整的世界事实。可见，重复不仅浪费空间，而且会使游戏规则变得不可靠。

== 第一范式（1NF）：拆分重复组

第一范式要求每个字段在给定关系模型下取原子值。我们令 `(run_id, event_id)` 唯一表示一局游戏中的一个事件，将多个观察者拆成不同的 `Observation` 行，将角色状态拆成 `ActorState` 行，将背包道具拆成 `BagState` 行，将地图已知地块拆成 `MapRoom` 行。

注意，不是说 C\# 的 `IReadOnlyList`、`Dictionary` 在内存中不能使用；问题在于，如果我们选择*关系数据库*作为持久化模型，那么这些集合不应作为未经建模的重复组直接塞入一列。对于整份快照的 JSON 存储，可以视为另一种文档模型，但不能据此宣称其内容已经按上述关系满足 1NF。

== 第二范式（2NF）：消除部分函数依赖

随后考虑主键。因为单局的 `event_id` 会从 1 开始，所以多局数据库必须使用 `(run_id, event_id)` 作为事件复合键，或者另设全局唯一的事件键。本文采用前者。

事件的 `turn`、`step`、`actor_id` 和 `kind` 完全由 `(run_id, event_id)` 决定；它们不能重复放入以 `(run_id, event_id, observer_id)` 为键的观察者关联表，也不应放在 `(run_id, event_id, actor_id, item_id)` 为键的背包快照中。后者的 `quantity` 才依赖完整的四元键。

同样，某张地图对某个房间的探索次数，依赖于 `(run_id, map_id, room_id)`，而不是 `map_id` 或 `room_id` 单独一方。把世界房间的固定类型、可通行性记录到 `RoomDefinition`，并将每张地图的知识记录到 `MapRoom`，才能让同一房间被多张不同的地图引用而不产生不必要的复制。

== 第三范式（3NF）：消除非主属性的传递依赖

仅仅使各属性依赖主键仍然不够。例如，若在 `EncounterObservation` 里同时记录 `opponent_id` 和该角色的永久姓名，则一般存在 `opponent_id → opponent_name`。由于身份名称应当属于 `ActorIdentity`，在每条遭遇中复制姓名就构成冗余。相同道理，`item_id → item_name` 应由 `ItemDefinition` 承担。

我们最终希望满足：对每个非平凡函数依赖 `X → A`，或者 `X` 是超键，或者 `A` 是候选键中的主属性。更实际地说，一种世界事实只由拥有它的表维护，其他表通过主外键引用，不再复制稳定的名称、类型和定义信息。

这里也不能过度规范化。一次观察中的 `direction`、`distance_band`、`observed_text` 是*该观察者当时获得的结果*，并不是事后能从隐藏的真实位置直接推导出的值；它们应属于观察表。相反，信号的原始发生回合若已由被引用的来源事件唯一确定，就不应再维护一份可以独立修改的重复字段。需要保留历史快照时，应明确其是不可修改的事实副本，而非第二份世界真相。

== 关系表及主要依赖汇总

#table(
  columns: (1.1fr, 1.45fr, 2.6fr),
  stroke: .5pt + rgb("#c2cad2"),
  inset: 5pt,
  table.header([*关系表*], [*主键*], [*唯一负责的事实*]),
  [`GameRun`], [`run_id`], [关卡、种子与规则版本],
  [`ActorIdentity`], [`run_id, actor_id`], [稳定角色身份与类型],
  [`WorldEvent`], [`run_id, event_id`], [事件顺序、回合、行为者和事件类别],
  [`CombatEvent / InjuryEvent / TreatmentEvent`], [`run_id, event_id`], [不同事件类别的专有结算字段],
  [`Observation`], [`run_id, event_id`], [观察者、来源事件、当时已知文字],
  [`SignalObservation / EncounterObservation`], [`run_id, event_id`], [方向距离、识别结果与遭遇记录],
  [`ActorState`], [`run_id, event_id, actor_id`], [检查点时的角色状态],
  [`BagState`], [`run_id, event_id, actor_id, item_id`], [检查点中每种物品的数量],
  [`RoomDefinition`], [`run_id, room_id`], [唯一真实地图上的固定房间属性],
  [`MapItem`], [`run_id, map_id`], [物理地图身份及当前归属],
  [`MapRoom`], [`run_id, map_id, room_id`], [某张地图知道的房间及探索次数],
  [`MapSignal`], [`run_id, map_id, note_event_id`], [某地图引用的有效标注事件],
  [`AlertIntel / AlertTransition`], [`run_id, event_id`], [情报入账与警觉等级变更],
  [`FactionAlertState`], [`run_id, faction_id, target_id`], [按事件维护或重建的当前警觉投影视图],
)

以上列的是完整关系设计中的主要表，并不意味着当前代码已经建立了这些数据库表。尤其是 `FactionAlertState`，它可以作为从历史重建的投影视图或受控缓存；若同时长期保存状态表与转移事件，则必须保证缓存失效、回放重建及事务一致性，避免出现两个独立事实来源。

= 详细设计：事件、地图与回放

== 核心表的主键与外键

以下给出一个缩减的 PostgreSQL 结构草案，仅用于展示键与约束的安排。为了避免多局之间事件 ID 冲突，外键都携带 `run_id`；系统事件可没有对应的角色，因此其 `actor_id` 允许为空，而不是机械地把所有字段设为 `NOT NULL`。

```sql
CREATE TABLE GameRun (
  run_id uuid PRIMARY KEY,
  level_kind text NOT NULL,
  rules_version text NOT NULL
);

CREATE TABLE ActorIdentity (
  run_id uuid NOT NULL REFERENCES GameRun(run_id),
  actor_id text NOT NULL,
  actor_kind text NOT NULL,
  display_name text NOT NULL,
  PRIMARY KEY (run_id, actor_id)
);

CREATE TABLE WorldEvent (
  run_id uuid NOT NULL REFERENCES GameRun(run_id),
  event_id bigint NOT NULL CHECK (event_id > 0),
  turn_no int NOT NULL CHECK (turn_no > 0),
  step_no bigint NOT NULL CHECK (step_no >= 0),
  actor_id text,
  kind text NOT NULL,
  PRIMARY KEY (run_id, event_id),
  FOREIGN KEY (run_id, actor_id)
    REFERENCES ActorIdentity(run_id, actor_id)
);

CREATE TABLE Observation (
  run_id uuid NOT NULL,
  event_id bigint NOT NULL,
  observer_id text NOT NULL,
  source_event_id bigint,
  note_text text NOT NULL,
  PRIMARY KEY (run_id, event_id),
  FOREIGN KEY (run_id, event_id)
    REFERENCES WorldEvent(run_id, event_id),
  FOREIGN KEY (run_id, source_event_id)
    REFERENCES WorldEvent(run_id, event_id),
  FOREIGN KEY (run_id, observer_id)
    REFERENCES ActorIdentity(run_id, actor_id)
);

CREATE INDEX observation_owner_idx
  ON Observation(run_id, observer_id, event_id);
```

我们还必须规定 `source_event_id` 的意义：它只是内部来源引用，不能因为某个角色拿到了观察记录，就默认允许顺着外键查询来源事件中的全部字段。外键保证参照完整性，*并不授予读取权限*。

== 实体地图与投影视图

在新的实现中，`GameMap` 仍然是唯一的真实地图。`MapItem` 表示一张实体地图道具，拥有独立的已知、已探索房间及探索次数；`MapView.From(...)` 则将所选地图的信息合并，并且不会把合并结果写回任意原地图。

#figure(
  diagram(
    spacing: (5pt, 5pt),
    node-stroke: .8pt,
    edge-stroke: 1pt,
    node-inset: 0pt,
    node-shape: rect,
    node-corner-radius: 3pt,
    edge-corner-radius: 4pt,

    node(
      (0, 0),
      db-table("RoomDefinition", (
        [#underline[run_id, room_id]],
        [room_kind, exits],
      )),
      name: <room>,
      stroke: none,
    ),

    node(
      (9, 0),
      db-table("MapRoom", (
        [#underline[run_id, map_id, room_id]],
        [known, explored],
        [explore_count],
      )),
      name: <maproom>,
      stroke: none,
    ),

    node(
      (18, 0),
      db-table("MapItem", (
        [#underline[run_id, map_id]],
        [author_id],
        [holder_id],
      )),
      name: <mapitem>,
      stroke: none,
    ),

    node(
      (0, 8),
      db-table("WorldEvent", (
        [#underline[run_id, event_id]],
        [turn, kind],
      )),
      name: <world>,
      stroke: none,
    ),

    node(
      (9, 8),
      db-table("MapSignal", (
        [#underline[run_id, map_id, note_event_id]],
        [历史标记引用],
      )),
      name: <mapsignal>,
      stroke: none,
    ),

    node(
      (18, 8),
      [合并只读视图],
      name: <view>,
      shape: diamond,
      inset: 9pt,
      fill: rgb("#fff6e5"),
    ),

    edge(<room>, <maproom>, "-"),
    edge(<maproom>, <mapitem>, "-"),
    edge(<world>, <mapsignal>, "-"),
    edge(<mapsignal>, <mapitem>, "-"),
    edge(<mapitem>, <view>, "-"),
  ),
  caption: [实体地图、房间知识与世界历史的引用关系；菱形表示按持有权限计算视图],
) <fig:map-er>

设角色 $i$ 当前合法持有的地图集合是 $M_i$，则已知房间视图可写为

$ K_i = union.big_(m in M_i) K_m, quad E_i = union.big_(m in M_i) E_m. $

探索次数可以按同一房间的各张地图记录求和，但这代表的是*地图标注次数的合计*，并非必然等于世界真实发生的探索次数；重复来源应按照设计目标明确去重。声音标记也应按来源序号和可见条件去重，而且按原始信号发生时间而非地图拾取时间计算有效期。对于有效期为 $L$ 的信号，当前回合为 $t$ 时应验证

$ t - t_"signal" < L. $

换句话说，拾取另一张地图不应该把五回合前的枪声重新变成一条全新的、还能持续五回合的声音。`MapSignal` 应只引用已经写入世界历史的合法标记；普通地图合并不能把持有者本人的私有记事反向传播给其他角色。

== 世界历史与回放的关系

世界历史不仅给记事本提供数据，也给回放提供依据。最新代码中的 `ActionJournal` 使用 `WorldHistoryEntries.Create(...)` 对战斗、移动、探索、道具等事件分类；伤情、治疗和阵营警觉具有专门的 `record` 类型。`ReplayTimeline` 顺序应用这些记录，重建角色位置、生死状态、背包与部分角色记事，无须重新生成地图或重新执行随机决策。

当前版本的日志格式为 v5。普通 JSON 和带有 `DFR5` 文件头的 Brotli 压缩 `.dfreplay` 使用同一类事件序列；压缩回放会删除某些 AI 完整观察快照和未变化状态记录，并重新排列需要引用的事件序号。这有利于降低文件体积。拥有完整回放文件的观察者，仍可能访问其中的隐藏事件和其他角色记录。

= 角色记事本：从事实到可获知的信息

== 信息何时进入角色视图

我们可以把信息流拆成三个步骤：世界事件发生、观察规则判定、授权视图生成。假如 A 在房间 X 开枪，系统先写入 `WorldEvent`；然后根据听闻范围、地形以及是否潜伏等规则，决定 B 能否获得一条 `SignalObservation`；最后，B 才能在自己的记事本中看到“某方向传来枪声”之类的文字。

这与“把 `WorldEvent` 全部交给 B，再在界面上遮住部分字段”有本质区别。后者即使屏幕看上去没有泄密，AI 接口、插件、日志或者修改过的客户端仍可能读到未被遮住的原始对象。

#figure(
  diagram(
    spacing: (5pt, 5pt),
    node-stroke: .8pt,
    edge-stroke: 1pt,
    node-corner-radius: 5pt,
    edge-corner-radius: 5pt,
    node-inset: 10pt,
    mark-scale: 80%,
    node-shape: rect,

    node(
      (0, 0),
      align(center)[
        *世界历史* \
        全部真实事件
      ],
      name: <facts>,
      fill: rgb("#e9eff8"),
    ),

    node(
      (9, 0),
      align(center)[
        *观察规则* \
        是否亲见、听见、拾获
      ],
      name: <rules>,
      fill: rgb("#fff0dc"),
    ),

    node(
      (18, 0),
      align(center)[
        *授权投影* \
        观察者、时间、字段过滤
      ],
      name: <filter>,
      fill: rgb("#e7f4ed"),
    ),

    node(
      (18, 8),
      align(center)[
        *角色记事本与 AI 观测* \
        仅允许访问局部已知信息
      ],
      name: <notes>,
      fill: rgb("#e7f4ed"),
    ),

    node(
      (0, 8),
      align(center)[
        *可信回放与调试* \
        需要单独授权
      ],
      name: <replay>,
      fill: rgb("#eef0f2"),
    ),

    edge(<facts>, <rules>, "-|>"),
    edge(<rules>, <filter>, "-|>"),
    edge(<filter>, <notes>, "-|>"),
    edge(<facts>, <replay>, "-|>"),
  ),
  caption: [世界事实到角色私有视图的授权路径，完整回放位于另一信任边界],
) <fig:view-flow>

这一路径需要明确三个身份：`actor_id` 是事件行为者，`observer_id` 是实际获知信息的人，而 `source_event_id` 是内部证明这条信息从何而来的事件。三者不能互相代替。尤其在拾取地图或缴获笔记时，*原作者、原观察者和当前持有者可能是三个人*；转交能够改变对具体记录的合法知情权，但不能自动改变历史事实的发生时间。

== 读权限与字段脱敏

一个角色的完整记事视图可以抽象为：

$ V_i(t) = pi_"allowed fields" (sigma_("observer_id" = i and "time valid") ("Observation")). $

其中 $sigma$ 表示按观察者身份和有效期筛选，$pi$ 表示只返回这个角色可以看到的字段。对于经合法地图拾取取得的标记，应单独从当前实际持有的 `MapItem` 中增加授权数据，再与个人记事合并，而不能直接读取地图原作者的所有 `Observation`。

假设某条遭遇事件的内部记录同时含有 `opponent_id` 和 `opponent_name`，当敌人的身份尚未识别时，前端只允许显示“未知敌人”，而不应返回真实姓名、职业或不可见装备。这里值得审计一个具体细节：现有 `EncounterHistoryEntry` 保存 `OpponentName`，而 `EncounterRecord.Name` 可以直接从首条历史读取该姓名，尽管另外还有 `Identified` 标记。因此，*只要调用者能够拿到未经裁剪的对象，就有可能在尚未辨认前读到真实名字*。现有 UI 是否显示这些字段是另一回事；若将来接入不可信策略或联网客户端，需要在接口边界实际移除敏感字段，而不能仅依靠界面判断。

同理，`Observe(actorId)`、`ActionJournal.Events`、`EventAt(sequence)` 等现有接口在可信内部代码中可以使用，但不应未经包装就作为远程玩家或外部 AI 的公开接口。让外部请求随意传入另一个角色的 ID，再依此读取其观察，无异于把权限交给了请求者自己。

== 一致性与可验证的信息限制

我们可以提出一个比简单检查“记事本没有越界”更严格的性质。若两个世界状态 $s$ 与 $s'$ 对角色 $i$ 来说无法区分，记为 $s ~_i s'$，则该角色的观测也必须相同：

$ s ~_i s' => V_(i)(s) = V_(i)(s'). $

例如，只改变地图远处两个从未见过的角色的位置和装备，不应该改变本角色的观察数据；只改变一个角色没有听见的枪声来源，也不应该使其合法动作以外的隐藏字段发生变化。这可以转化为属性测试：构造两份仅在秘密字段上不同的状态，然后比较返回的 `AgentObservation`、记事本与地图视图。

有效期也必须单独测试：一个从旧地图上获得的信号，其寿命应由原始 `SignalTurn` 决定。当前 `MapItem.PruneSignals(...)` 已使用原发生回合，而 `NoteBook.VisibleEntries(...)` 的筛选主要采用记事条目的 `Turn`。因此，对*缴获导入的信号*还需要重点核对两条路径是否采用同一时效口径，防止信息转交意外延长声音有效期。这是应继续验证的边界，而不是可以直接宣称已经完全解决的问题。

= 安全性分析：如何防止越权、篡改与内存窃取

== 我们究竟要防范哪一种攻击者

首先应区分不同的威胁模型。正常玩家只是通过游戏界面操作；不可信的 AI 插件可能尝试调用超出允许范围的接口；联网玩家可能试图修改请求中的 `actor_id`；而能够附加调试器、读取进程转储或注入本机进程的攻击者，则已经控制了客户端执行环境。这些攻击者的能力不同，不能声称一个 `private` 字段、一个 C\# `IReadOnlyList` 或一个经过 3NF 规范化的表结构能够同时阻止他们。

*最重要的限制是：如果完整世界历史、密钥与隐藏状态已经进入玩家控制的进程，就无法在强攻击者模型下保证这些字节永不被读出。* 在单机离线游戏中可以提高篡改成本，但不能建立绝对的内存保密性。对于将来的多人联网或竞争性训练，真正可靠的边界应是：权威状态存在受信任的服务器或隔离进程中，不向玩家进程发送无权知道的事实。

== 最小授权与分层接口

针对未来的服务端实现，我建议建立以下三个不同的查询能力，而不是给所有调用方共享同一个 `ActionJournal` 实例：

+ `WorldHistoryWriter`：只允许规则引擎追加真实事件，不允许玩家或 AI 自造历史条目。事件写入与角色状态变更应在同一受控事务内进行。
+ `ObserverViewReader`：由可信会话决定观察者身份，内部验证事件、时间与地图持有权，只返回裁剪后的只读 DTO；调用者不能通过传入其他 `actor_id` 越权。
+ `ReplayArchiveReader`：仅为服务器复盘、获授权的旁观者或对局结束后批准公开的回放开放。面向普通玩家必须再次执行按视角裁剪。

其中 `source_event_id`、未公开的 `opponent_id`、内部警觉计数与随机状态，不应仅因为存在于某条可见记事的底层对象里就被序列化给玩家。对于 `FactionAlerts`，玩家只能获取规则允许公开的阵营等级或线索；敌对阵营的完整对象不能直接通过聚合接口送到客户端。

== SQL 行级控制与访问上下文

若未来使用 PostgreSQL，关系范式提供了清晰的外键和查询条件，但还需要数据库层的行级安全策略（RLS）或经过审计的存储过程。下列查询只是说明最小授权的原则，其中 `:authorized_actor_id` *必须由服务器验证过的会话确定*，而不能原封不动采用客户端提交的字符串。

```sql
SELECT e.event_id, e.turn_no, o.note_text
FROM Observation AS o
JOIN WorldEvent AS e
  ON e.run_id = o.run_id AND e.event_id = o.event_id
WHERE o.run_id = :authorized_run_id
  AND o.observer_id = :authorized_actor_id
  AND e.turn_no <= :current_turn
ORDER BY e.event_id;
```

这里还没有加入分类有效期、地图合法持有、身份揭示和字段脱敏；这些条件需要在受信任的视图服务中补全。*仅仅把查询做成参数化，解决的是注入风险，而不是 ID 越权风险*。此外，RLS 所使用的会话身份必须防止普通数据库用户随意伪造，视图的执行者权限、缓存与导出路径也必须采用相同的安全策略。

== 防止内存读取与回放泄密

内存防护应从数据流而非混淆出发。如果将来存在不可信客户端，服务器只向其发送已授权的观测投影；地图资源、敌人真实位置、未公开姓名、其他角色的私有记事和全局决策快照均不应出现在客户端消息中。客户端无法读取从未接收过的信息，这是比内存加密与变量改名更可靠的约束。

对于可以在同一进程中运行任意代码的 AI 插件，沙箱也很关键。一个策略即使接口签名是 `ChooseAction(AgentObservation)`，若它与 `GameController` 同进程并拥有反射、文件和进程权限，就不能假设它只能看到那个参数。将外部策略放在独立、受限的工作进程中，通过最小的消息协议交换合法观测与动作，才是更可信的隔离方案；若需要更强的保证，则采用操作系统级沙箱或独立服务。

回放文件也需要区分用途。`DFR5` 与 Brotli 是格式与压缩机制，不提供机密性或防篡改保证。公开文件应生成专门的*玩家视角回放*，只包含截至相应时间点该玩家可以得知的事件；完整回放应限制下载权限，并根据风险决定是否进行传输加密、静态加密和签名校验。加密可以保护未授权的文件读取，但如果解密密钥和完整明文在攻击者控制的客户端内存中，仍然不能阻止进程内存窥探。

== 审计与验证方案

为了让“不会泄密”成为可验证的性质，而不是一条写在文档中的承诺，我建议增加以下测试：

+ *观察隔离测试*：同一事件只写入真正看见或听见的角色视图；其他角色的 `NotesFor` 不返回该记录。
+ *身份推迟揭示*：未知敌人在辨认前，所有外部 DTO 中都不得出现真实姓名、角色种类或秘密装备；辨认事件之后才改变允许字段。
+ *地图持有权测试*：没有拾获地图时看不到其标注，合法拾获后按权限看到标注，丢弃之后不能继续通过旧引用获得更新；不同地图合并不会反写原地图。
+ *时间来源测试*：缴获记事和地图标记保留原始信号回合，重新拾获不会刷新寿命。
+ *越权参数测试*：以 A 的会话请求 B 的观察或完整事件，必须在业务接口与数据库两层拒绝。
+ *差分隐私边界测试（非差分隐私算法）*：只修改观察者不知道的世界字段，比较所有可见输出应保持不变；这里检验的是非干扰性，而不是统计意义的差分隐私。
+ *回放和日志审计*：玩家视角回放、异常日志、网络报文、调试面板均不得包含比其授权视图更完整的信息；可信完整回放则验证事件来源序号及重建一致性。

这里还应注意，一些“是否存在某事件”的元信息也可能泄漏秘密。比如 API 返回不同错误码、连续事件序号的缺口、消息大小或处理时间，都可能泄露本不应公开的活动。必要时应对外隐藏全局序号、规范化错误响应，并审计按回合聚合统计中可能透露的对手数量。

= 调试与问题

== 尚待实现的部分

当前事件中仍广泛存在 `Kind`、`Detail` 和预先写好的中文 `Text`；部分遭遇记录仍复制角色姓名，部分完整观察和角色状态快照仍以集合形式保存在事件对象里。因此，不能宣称当前的内存模型已经严格实现了第三范式，也不能将本文的 SQL 表、RLS、服务器隔离、认证与加密当作已落地功能。

在我看来，最值得优先解决的两项问题不是继续增加表的数量，而是：第一，明确每一种可见信息的授予条件，并让 `Observe()`、记事本、地图和回放使用相同的投影规则；第二，在未来接入不可信 AI 或多人网络时，避免把全局历史和隐藏状态直接交给策略进程或客户端。只有先保证这两条边界，范式设计才能真正转化为游戏中的信息安全。

= 总结

本专题从一个枪声事件为什么可能被多处记录出发，区分了世界事实、角色观察、物理地图和回放状态。经由 1NF 对重复组的拆分、2NF 对复合键部分依赖的消除以及 3NF 对角色身份和物品定义等传递依赖的清理，我们获得了一组具有明确主外键、可追溯来源与独立生命周期的概念关系表。

这也为未来的多智能体强化学习提供了更准确的基础：中央训练器可以在受信任环境中读取完整世界状态，但角色策略只能获得与其身份及经历一致的局部观测。世界历史并不只是为了方便回放而保存过去，它最终还应成为约束“谁知道什么、何时知道、为何知道”的权威证据。
