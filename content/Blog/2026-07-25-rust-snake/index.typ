#import "../index.typ": template, tufted

#show: template.with(
  title: "使用 Rust 编写贪吃蛇游戏",
  description: "从 snake.rs 的基本模型，到 game.rs 的状态转移，再到 render.rs 的 Piston 绘制，记录一个 Rust 贪吃蛇的设计过程。",
  date: datetime(year: 2026, month: 7, day: 25),
  lang: "cn",
)

= 使用 Rust 编写贪吃蛇游戏

最近我用 Rust 和 Piston 写了一个贪吃蛇。这个项目表面上很小：棋盘、蛇、食物、方向键，再加一个窗口，似乎很快就能完成。但真正动手以后，我发现它正好包含了一组非常适合练习游戏程序设计的问题：

- 应该怎样表示一个格点、一个方向和一条不断增长的蛇？
- 食物被吃掉或过期后，谁负责把它从游戏中移除？
- 数学坐标系中的负坐标如何映射到左上角为原点的屏幕像素？
- “吃到食物”应该在移动前判断，还是移动后判断？
- 渲染帧率、游戏更新频率和蛇的移动速度如何解耦？
- 一次移动前连续收到多个方向键时，如何防止蛇绕过“不能反向”的规则？

我不想先写一个大而全的 `Game`，再逐渐把代码拆出去，而是从最底层的数据开始设计。项目最终分为：

- `snake.rs`：格点、方向、食物和蛇；
- `game.rs`：棋盘、计时器、食物批次、碰撞和游戏状态；
- `render.rs`：把游戏状态绘制到 Piston 窗口。

这也是本文的叙述顺序。前两个文件决定了游戏规则与状态不变量，是文章的重点；`render.rs` 只负责把已经确定的状态显示出来。

= `snake.rs`：实现格点、食物与蛇

`snake.rs` 是整个项目最底层的模块。它不需要知道窗口有多大，也不需要知道一秒钟会更新多少次。它只回答几个领域问题：

- 一个格点是什么？
- 一个方向如何使格点移动一步？
- 食物有哪些类型和属性？
- 蛇身如何保存？
- 蛇执行一步时，如何同时完成移动、增长和计分？
- 输入方向怎样在真正移动之前保持合法？

先把这些规则写清楚，`game.rs` 才能在上层组合它们。

== `Point`：用逻辑格点隔离像素细节

蛇不应该直接保存像素坐标。假如每个格子宽 50 像素，蛇从一个格点移动到下一个格点，在逻辑上只是 $x$ 或 $y$ 增减一，而不是增减 50。

因此我定义了泛型 `Point<T>`：

```rust
#[derive(PartialEq, Clone, Copy, Eq, Hash)]
pub struct Point<T> {
    x: T,
    y: T,
}
```

实际游戏使用 `Point<i32>`。使用有符号整数是因为棋盘采用以原点为中心的数学坐标系，格点可以位于负半轴。

这个小结构体派生的 trait 都有具体用途：

- `PartialEq` 和 `Eq`：比较两个格点是否相同；
- `Hash`：让格点可以成为 `HashSet` 的元素；
- `Copy`：格点只包含两个小整数，可以低成本按值复制；
- `Clone`：与 `Copy` 配套，也便于需要显式复制的泛型代码。

如果没有 `Eq + Hash`，后面就不能使用 `HashSet<Point<i32>>` 管理空闲格点。由此我第一次很具体地感受到：trait 不是为了形式上“给类型贴标签”，而是在声明这个类型能参加哪些操作。

`Point` 的字段保持私有，通过方法读取：

```rust
impl<T> Point<T> {
    pub fn new(x: T, y: T) -> Self {
        Self { x, y }
    }

    pub fn x(&self) -> &T {
        &self.x
    }

    pub fn y(&self) -> &T {
        &self.y
    }
}
```

`x()` 和 `y()` 返回引用而不是强制复制，使这个泛型实现不要求任意 `T` 都实现 `Copy`。尽管当前的 `i32` 可以复制，这种写法仍然保持了泛型接口的完整性。

== `Direction` 与一步移动

方向是一个有限集合，适合使用枚举：

```rust
#[derive(PartialEq, Clone, Copy)]
pub enum Direction {
    Up,
    Down,
    Left,
    Right,
}
```

真正的移动规则属于 `Point<i32>`：

```rust
impl Point<i32> {
    pub fn step(&self, direction: &Direction) -> Self {
        match direction {
            Direction::Up =>
                Point::new(self.x, self.y + 1),
            Direction::Down =>
                Point::new(self.x, self.y - 1),
            Direction::Left =>
                Point::new(self.x - 1, self.y),
            Direction::Right =>
                Point::new(self.x + 1, self.y),
        }
    }
}
```

这里明确选择了数学坐标约定：

- 向上是 $y + 1$；
- 向下是 $y - 1$；
- 向左和向右分别改变 $x$。

这看起来只是四行匹配，却提前决定了后面 `Board::toPixel` 必须翻转 $y$ 轴。若底层采用屏幕坐标的“向下为正”，坐标映射会简单一点，但逻辑层就不再是我希望使用的 $x O y$ 坐标系。

我选择让逻辑模型保持数学意义，把与屏幕有关的不一致全部留给 `game.rs` 中的 `Board` 处理。

== `FoodType` 与三种食物等级

普通贪吃蛇往往只有一种食物。为了增加选择，我设计了三种等级：

```rust
#[derive(PartialEq, Clone, Copy)]
pub enum FoodType {
    Normal,
    Medium,
    Huge,
}
```

三类食物对应不同的分数和真实时间寿命：

- `Normal`：1 分，存在 60 秒；
- `Medium`：3 分，存在 30 秒；
- `Huge`：5 分，存在 15 秒。

奖励越高，留给玩家的时间越短。`Food` 保存位置、分数、绝对过期时间和类型：

```rust
pub struct Food {
    pub position: Point<i32>,
    pub score: i32,
    pub expireAt: Instant,
    pub foodType: FoodType,
}
```

构造食物时，根据枚举一次性确定属性：

```rust
impl Food {
    pub fn new(
        position: Point<i32>,
        foodType: FoodType,
    ) -> Self {
        let score = match foodType {
            FoodType::Normal => 1,
            FoodType::Medium => 3,
            FoodType::Huge => 5,
        };

        let expireAt = match foodType {
            FoodType::Normal =>
                Instant::now() + Duration::from_secs(60),
            FoodType::Medium =>
                Instant::now() + Duration::from_secs(30),
            FoodType::Huge =>
                Instant::now() + Duration::from_secs(15),
        };

        Self {
            position,
            score,
            expireAt,
            foodType,
        }
    }

    pub fn isExpired(&self) -> bool {
        Instant::now() >= self.expireAt
    }
}
```

我一开始想到的方案是保存一个整数 `lifeTime`，每次更新减一。但这样食物寿命会依赖游戏更新频率；两个食物若在不同时间产生，还需要格外注意各自减去了多少次。

保存 `expireAt: Instant` 后，食物不需要启动线程，也不需要“主动倒计时”。真实时间会自然流逝，查询时只需比较 `Instant::now()` 和到期时刻。`Instant` 还是单调时钟，不会因为用户调整系统日期而突然前进或后退。

这里还要区分“知道自己过期”和“删除自己”。`Food::isExpired()` 只能报告状态；真正删除食物的权力属于拥有它的 `Game`。这一点会在 `game.rs` 中继续讨论。

== `Snake`：为什么选择 `VecDeque`

蛇每次移动的结构变化非常固定：

1. 在头部插入一个新格点；
2. 如果没有吃到食物，删除尾部；
3. 如果吃到食物，保留尾部，长度增加一。

如果使用普通 `Vec`，并把蛇头放在下标零，那么每次 `insert(0, newHead)` 都可能移动后面的全部元素。`VecDeque` 正好支持两端操作，因此更符合蛇的模型：

```rust
pub struct Snake {
    body: VecDeque<Point<i32>>,
    direction: Direction,
    pendingDirection: Direction,
    score: i32,
    speed: f64,
}
```

初始蛇从原点向负 $x$ 轴延伸：

```rust
Self {
    body: VecDeque::from([
        Point::new(0, 0),
        Point::new(-1, 0),
        Point::new(-2, 0),
    ]),
    direction: Direction::Right,
    pendingDirection: Direction::Right,
    score: 0,
    speed: 1.5,
}
```

队首始终是蛇头，队尾始终是蛇尾。外部模块不直接取得 `body` 的所有权，只能借用迭代器：

```rust
pub fn points(
    &self,
) -> impl Iterator<Item = &Point<i32>> {
    self.body.iter()
}
```

这既隐藏了具体容器，也保证渲染器和 `Game` 遍历蛇身时不会把内部集合移动出去。将来即使改变蛇身容器，只要仍能返回相同迭代器，调用方也不必跟着修改。

== `Snake::step`：用 `Option` 表达增长

最初我把“吃食物”写成一个独立方法，直接把食物坐标追加到蛇尾。这个思路是不正确的：食物位于蛇头前方，它的位置和当前尾巴没有关系；直接把食物位置作为新尾节，会让蛇身瞬间断裂。

正确的增长方式是：

- 总是在头部加入新蛇头；
- 普通移动删除旧蛇尾；
- 吃到食物时不删除旧蛇尾。

当前实现让 `Game` 提前判断本次是否吃到食物，然后把分数作为 `Option<i32>` 传入：

```rust
pub fn step(
    &mut self,
    score: Option<i32>,
) -> (Point<i32>, Option<Point<i32>>) {
    self.direction = self.pendingDirection;

    let newHead =
        self.getHead().step(&self.direction);

    self.body.push_front(newHead);

    if let Some(s) = score {
        self.score += s;
        self.speed = self.calculateSpeed();
        (newHead, None)
    } else {
        let oldTail = self.body.pop_back();
        (newHead, oldTail)
    }
}
```

参数的含义是：

- `None`：没有吃到食物，删除尾巴；
- `Some(score)`：吃到食物，计分并保留尾巴。

返回值中的 `Option<Point<i32>>` 则表示：

- `Some(oldTail)`：旧尾巴已经离开，可以重新成为空闲格；
- `None`：蛇增长了，没有任何尾部格点被释放。

这让我认识到，`Option<T>` 不只是空指针的替代品。它还可以表达一次状态转移中“某件事是否发生，并在发生时携带什么数据”，从而避免再维护一组容易失去同步的布尔字段。

== 蛇长与速度

我希望蛇越长，移动越快，但又不能无限加速。当前速度按蛇长线性增长：

```rust
fn calculateSpeed(&self) -> f64 {
    let newSpeed =
        1.5 + (self.length() - 3) as f64 * 0.1;

    newSpeed.min(5.0)
}
```

初始长度为三，速度为每秒 1.5 格；每增长一节增加 0.1 格每秒；最大速度为每秒 5 格。

`Snake` 只保存和计算“每秒走几格”，并不自行计时。何时调用 `Snake::step` 是 `Game` 和 `Timer` 的职责。这样蛇的领域模型不会依赖 Piston 的帧率。

更稳妥的写法还可以使用：

```rust
let extraLength =
    self.length().saturating_sub(3) as f64;
```

虽然当前蛇只会增长，不会短于三节，但 `saturating_sub` 能防止将来加入缩短机制后发生 `usize` 下溢。

== 快速连续输入：为什么需要两个方向

“新方向不能和当前方向相反”看似简单，直接在按键事件中修改 `direction` 却有一个漏洞。

假设蛇实际上向右移动。在下一次逻辑步发生前，玩家快速输入：

```text
Up → Left
```

如果第一个按键立即把 `direction` 改为 `Up`，第二个 `Left` 相对 `Up` 仍然合法。蛇还没有真正向上走过，却最终从向右直接变成向左，相当于实际反向。

解决办法是区分：

- `direction`：上一次实际移动使用的方向；
- `pendingDirection`：下一步准备使用的方向。

输入始终和上一次实际方向比较：

```rust
pub fn changeDirection(
    &mut self,
    newDirection: Direction,
) {
    let isOppositeToCurrentDirection =
        (self.direction == Direction::Up
            && newDirection == Direction::Down)
        || (self.direction == Direction::Down
            && newDirection == Direction::Up)
        || (self.direction == Direction::Left
            && newDirection == Direction::Right)
        || (self.direction == Direction::Right
            && newDirection == Direction::Left);

    if !isOppositeToCurrentDirection {
        self.pendingDirection = newDirection;
    }
}
```

预判下一蛇头时使用 `pendingDirection`：

```rust
pub fn nextHead(&self) -> Point<i32> {
    self.getHead().step(&self.pendingDirection)
}
```

真正执行 `step()` 时才提交：

```rust
self.direction = self.pendingDirection;
```

于是 `Right → Up → Left` 中，最后的 `Left` 会因为与实际方向 `Right` 相反而被拒绝，本次移动仍然向上。

这个问题不依赖窗口，很适合单元测试：

```rust
#[test]
fn rapid_inputs_cannot_reverse_before_a_step() {
    let mut snake = Snake::new();

    snake.changeDirection(Direction::Up);
    snake.changeDirection(Direction::Left);

    assert!(snake.nextHead() == Point::new(0, 1));

    snake.step(None);
    assert!(snake.getHead() == Point::new(0, 1));
}
```

至此，`snake.rs` 已经能够独立描述格点、方向、食物和一次蛇移动。下一步才是让 `Game` 组织这些对象。

= `game.rs`：实现棋盘与状态转移

`game.rs` 是整个项目的核心。`snake.rs` 只描述“蛇怎样走一步”，而 `Game` 必须决定：

- 什么时候应该走这一步；
- 目标位置有没有食物；
- 食物何时生成和过期；
- 哪些格点仍然空闲；
- 移动之后是否越界、自撞或胜利；
- 暂停和游戏结束时是否继续更新。

我把 `Board`、`Timer` 和 `Game` 放在这个模块中。它们分别负责空间、时间和完整状态转移。

== `Board`：只保存空间规则，不复制实体状态

一开始我考虑过让 `Board` 保存二维格点数组，每个格子记录“空白、蛇头、蛇身或食物”。但 `Snake` 已经保存身体，`Food` 已经保存位置。如果棋盘再保存一份内容，每次移动就必须同步多个真相来源。

重复状态最危险的地方不是多占一点内存，而是它们可能不一致：蛇已经移动，`Snake.body` 是新位置，棋盘数组却仍然是上一帧。

所以 `Board` 最终只保存空间参数：

```rust
pub struct Board {
    xMax: i32,
    yMax: i32,
    cellSize: i32,
}
```

棋盘逻辑范围为：

```text
x ∈ [-xMax, xMax)
y ∈ [-yMax, yMax)
```

边界判断为：

```rust
pub fn isInBounds(
    &self,
    point: &Point<i32>,
) -> bool {
    *point.x() >= -self.xMax
        && *point.x() < self.xMax
        && *point.y() >= -self.yMax
        && *point.y() < self.yMax
}
```

这里采用左闭右开区间，格子数量正好是 `2 * xMax` 乘 `2 * yMax`。

== 从 $x O y$ 格点映射到屏幕像素

这是我写代码前就预想到的难点之一。

逻辑坐标系使用：

- 原点在棋盘中央；
- $x$ 向右；
- $y$ 向上；
- 点 $(x,y)$ 代表单位区域 $[x,x+1) times [y,y+1)$。

但屏幕坐标系的原点位于左上角，$y$ 向下增加。映射必须同时完成平移和纵轴翻转：

```rust
pub fn toPixel(
    &self,
    point: &Point<i32>,
) -> [f64; 4] {
    let cell = self.cellSize as f64;

    let pixelX =
        (*point.x() + self.xMax) as f64 * cell;

    let pixelY =
        (self.yMax - *point.y() - 1) as f64
            * cell;

    [pixelX, pixelY, cell, cell]
}
```

其中：

- `x + xMax` 把最左侧逻辑坐标平移到屏幕零点；
- `yMax - y` 翻转并平移纵坐标；
- 额外的 `-1` 来自“整数点代表一个单位方格”的约定。

例如 `(0,0)` 代表数学原点右上方的 `[0,1) × [0,1)`，因此它应该绘制在窗口中轴线的上方。

窗口大小同样由 `Board` 计算，而不是在 `main` 中另写一套常量：

```rust
pub fn pixelSize(&self) -> [u32; 2] {
    [
        (2 * self.xMax * self.cellSize) as u32,
        (2 * self.yMax * self.cellSize) as u32,
    ]
}
```

这样修改棋盘半宽、半高或格子像素大小时，窗口、网格和实体都会一起变化。

== `Timer`：把 Piston 更新频率与蛇速解耦

蛇不能在每个渲染帧移动一次，否则 60 FPS 和 144 FPS 下会成为两个不同的游戏。即使使用 Piston 的固定更新事件，也不应该把 UPS 直接当作蛇速。

`Timer` 只保存累计时间：

```rust
pub struct Timer {
    pub accumulator: f64,
}

impl Timer {
    pub fn update(&mut self, dt: f64) {
        self.accumulator += dt;
    }

    pub fn consume(&mut self, interval: f64) -> bool {
        if self.accumulator >= interval {
            self.accumulator -= interval;
            true
        } else {
            false
        }
    }

    pub fn reset(&mut self) {
        self.accumulator = 0.0;
    }
}
```

若蛇速为每秒 $v$ 格，则移动间隔为：

$ T_"step" = 1 / v $

达到间隔后，计时器减去一个间隔，而不是把累计值清零。这样超出的零碎时间会保留下来，长期运行不会因为反复舍去余数而逐渐变慢。

`Timer` 不持有 `Snake`，也不回调 `Game`。它只报告“是否积累够了一个间隔”。这种设计避免了 `self.timer` 已被可变借用时，又从回调中借用整个 `self` 的问题。

== `Game`：拥有全部游戏实体

完整状态为：

```rust
pub struct Game {
    pub board: Board,
    pub snake: Snake,
    pub foods: [Option<Food>; 2],

    pub state: GameState,
    pub timer: Timer,

    pub blankCells: HashSet<Point<i32>>,
}
```

`Game` 是 `Snake`、`Food`、`Board` 和 `Timer` 的所有者。渲染器只借用 `&Game`，输入和更新逻辑通过 `&mut Game` 修改状态。

游戏阶段也用枚举表达：

```rust
pub enum GameState {
    Initial,
    Running,
    Paused,
    GameOver,
    Victory,
}
```

这样 `pause()`、`resume()`、`start()` 和 `gameOver()` 都可以限制合法状态转移，而不是散落多个布尔变量，例如 `isPaused`、`isOver`、`hasStarted`。多个布尔量很容易组合出“既暂停又结束”之类的非法状态，枚举则一次只能处于一个阶段。

== `blankCells`：维护空闲格点不变量

为了避免食物生成在蛇身或另一个食物上，最简单的做法是不断随机坐标，若被占用就重试。棋盘比较空时这种方法很快，但蛇接近填满棋盘时，尝试次数会越来越多。

这个项目维护：

```rust
pub blankCells: HashSet<Point<i32>>,
```

它满足不变量：

```text
blankCells
= 棋盘全部格点
- 蛇占用格点
- 食物占用格点
```

初始化时先插入棋盘全部格点，再借用蛇身迭代器移除初始蛇：

```rust
for x in -xMax..xMax {
    for y in -yMax..yMax {
        blankCells.insert(Point::new(x, y));
    }
}

for point in snake.points() {
    blankCells.remove(point);
}
```

这里的 `point` 是 `&Point<i32>`。循环只借用蛇身，不会导致 `Snake` 丢失集合的所有权；`HashSet::remove(point)` 删除的是空闲集合中相等的元素，不是蛇内部的点。

蛇普通移动时：

- 旧蛇尾加入 `blankCells`；
- 新蛇头从 `blankCells` 删除。

蛇增长时没有尾巴离开，只删除新蛇头。食物被吃时，它所在的格点从“食物占用”直接变成“蛇头占用”，所以不能短暂加入空闲集合。

== 概率双食物是一批，而不是两个独立生成器

我设计的食物规则是“批次生成”：

- 通常生成一个食物；
- 有 10% 概率生成两个；
- 双食物批次中，第一个固定为普通食物；
- 第二个为中型或大型食物；
- 只有整批食物全部被吃掉或过期，才生成下一批。

所以我选择固定数组：

```rust
pub foods: [Option<Food>; 2],
```

它比 `Vec<Food>` 更直接地表达“最多两个槽位”，而 `Option<Food>` 表达每个槽位当前是否有实体。

当前生成逻辑为：

```rust
let possibilityOfTwoFoods =
    rng.gen_range(1..=10);

let possibilityOfFoodType =
    rng.gen_range(1..=10);

if possibilityOfTwoFoods == 10 {
    let foodType =
        if possibilityOfFoodType < 8 {
            FoodType::Medium
        } else {
            FoodType::Huge
        };

    self.foods[0] =
        self.generateOneFood(FoodType::Normal);
    self.foods[1] =
        self.generateOneFood(foodType);
} else {
    // 生成一个随机等级的食物
}
```

`1..=10` 正好包含十个等概率整数，因此 `== 10` 表示 10% 概率。单食物分支中还会按区间选择普通、中型或大型食物。

生成一个食物时，不需要随机碰撞重试，而是直接从空闲集合抽取：

```rust
if let Some(&position) =
    self.blankCells.iter().choose(&mut rng)
{
    self.blankCells.remove(&position);
    Some(Food::new(position, foodType))
} else {
    None
}
```

整批是否结束可以直接由类型结构判断：

```rust
if self.foods
    .iter()
    .all(|slot| slot.is_none())
{
    self.generateFood();
}
```

双食物中只消失一个时，另一个槽位仍是 `Some`，因此不会补充；当两个槽位都变为 `None`，才产生下一批。这正好对应设计规则，不需要另外保存 `remainingFoods`。

== 食物过期、所有权与 `take`

`Food` 可以判断自己过期，但所有权属于：

```text
Game → [Option<Food>; 2] → Food
```

因此必须由 `Game` 删除过期实体：

```rust
fn removeExpiredFoods(&mut self) {
    let mut expiredIndices = Vec::new();

    for (index, slot) in
        self.foods.iter().enumerate()
    {
        if slot
            .as_ref()
            .is_some_and(|food| food.isExpired())
        {
            expiredIndices.push(index);
        }
    }

    for index in expiredIndices {
        if let Some(food) =
            self.foods[index].take()
        {
            self.blankCells.insert(food.position);
        }
    }
}
```

这里先收集下标，再进行修改，是为了避免一边不可变遍历 `self.foods`，一边修改同一个数组。

`Option::take()` 会：

1. 把槽位从 `Some(food)` 变成 `None`；
2. 把 `Food` 的所有权移动到局部变量；
3. 局部变量离开作用域后自动析构。

不需要手动 `free`，也不需要给 `Food` 启动后台线程。真正要维护的是：食物过期后，它原来的坐标必须重新加入 `blankCells`。

对于真实时间过期，还有一个值得继续收紧的细节：同一次逻辑更新最好只取得一次 `Instant::now()`，让清理与进食判断使用相同的时间快照。否则食物可能在两个相邻检查之间恰好到期。更完善的接口可以是：

```rust
food.isExpiredAt(now)
```

然后由 `Game::looping` 将同一个 `now` 传给本轮全部判断。

== `Game::step`：一次移动的准确时序

这是整个实现中最重要的部分。

问题首先在于：“吃到食物”究竟应该在移动前还是移动后判断？

- 若移动前检查当前蛇头，蛇进入食物格子的这一拍检测不到；
- 若先按普通移动删除尾巴，再检查移动后的蛇头，又不方便实现增长；
- 用户还可能在即将吃到时改变方向，目标格点必须使用本次最终方向计算。

解决办法是：在修改蛇身之前计算 `nextHead`，检查的是本次将进入的目标位置，而不是当前蛇头。

一次 `Game::step` 的顺序是：

```text
1. 使用 pendingDirection 计算 nextHead
2. 在两个食物槽位中查找 nextHead
3. 提前取得食物分数
4. 调用 Snake::step(Some(score)) 或 Snake::step(None)
5. 移除被吃掉的 Food
6. 将普通移动产生的旧蛇尾放回 blankCells
7. 从 blankCells 删除新蛇头
8. 判断胜利、越界和自撞
9. 整批食物结束后生成下一批
```

关键实现是：

```rust
let nextHead = self.snake.nextHead();

let eatenIndex =
    self.foods.iter().position(|slot| {
        slot.as_ref().is_some_and(|food| {
            !food.isExpired()
                && food.position == nextHead
        })
    });

let gainedScore =
    eatenIndex.and_then(|index| {
        self.foods[index]
            .as_ref()
            .map(|food| food.score)
    });

let (newHead, oldTail) =
    self.snake.step(gainedScore);
```

因为 `nextHead()` 使用 `pendingDirection`，所以如果玩家在移动发生前改变方向，这次食物判断会使用新目标格点。输入事件若发生在逻辑步之后，则自然应用到下一步。

随后同步所有权和空闲格点：

```rust
if let Some(index) = eatenIndex {
    self.foods[index].take();
}

if let Some(oldTail) = oldTail {
    self.blankCells.insert(oldTail);
}

self.blankCells.remove(&newHead);
```

一个容易遗漏的边界情况是：蛇头可以进入本次正要离开的旧蛇尾格。在不增长时这是合法的。代码先插入 `oldTail`，再删除 `newHead`；即使二者相等，最终该格仍然不在 `blankCells` 中。

自撞检查必须跳过队首：

```rust
pub fn hasSelfCollision(&self) -> bool {
    let head = self.getHead();

    self.body
        .iter()
        .skip(1)
        .any(|point| *point == head)
}
```

如果直接执行 `body.contains(&head)`，结果永远为真，因为蛇头本来就是身体集合的第一个元素。

当 `blankCells` 为空时，说明棋盘已经没有任何未占用格点，可以进入 `Victory`；若新蛇头越界或与身体重叠，则进入 `GameOver`。

== `Game::looping`：什么时候调用一次 `step`

Piston 更新事件会把 `dt` 传给：

```rust
game.looping(args.dt);
```

`looping` 先清理过期食物，再检查是否处于 `Running`。整批食物结束后生成下一批，然后累计时间：

```rust
pub fn looping(&mut self, dt: f64) {
    self.removeExpiredFoods();

    if self.state != GameState::Running {
        return;
    }

    if self.foods
        .iter()
        .all(|slot| slot.is_none())
    {
        self.generateFood();
    }

    self.timer.update(dt.min(0.25));

    // 根据累计时间执行零次、一次或多次 step
}
```

移动间隔由当前蛇速动态计算：

```rust
let interval = 1.0 / self.snake.getSpeed();
```

然后循环消费时间：

```rust
let mut performedSteps = 0;

loop {
    let speed = self.snake.getSpeed();
    let interval = 1.0 / speed;

    if !self.timer.consume(interval) {
        break;
    }

    self.step();
    performedSteps += 1;

    if self.state != GameState::Running
        || performedSteps >= 8
    {
        break;
    }
}
```

使用 `while` 式循环而不是单个 `if`，是为了在短暂卡顿后补足应该发生的逻辑步；最多补八步，则防止调试断点后蛇瞬间移动几十格。`dt.min(0.25)` 也限制了单次异常更新带来的时间增量。

蛇若在某个 `step` 中增长，`Snake::step` 会立即重新计算速度。下一次循环重新读取 `getSpeed()`，因此新的移动间隔马上生效。

暂停期间不向 `Timer` 累加 `dt`，所以恢复后不会补跑整个暂停时段。至于食物使用真实时间，暂停时是否继续过期，则是另一个规则选择：当前清理发生在 `Running` 判断之前，因此食物会继续按真实时间到期。

= `render.rs`：把状态绘制出来

当 `snake.rs` 和 `game.rs` 已经把状态与时序确定以后，`render.rs` 的职责就很单纯：

- 根据 `Board` 创建合适大小的窗口；
- 每帧清除背景；
- 绘制有效食物；
- 遍历蛇身，区分蛇头与身体颜色；
- 绘制网格线和坐标轴。

它不负责移动蛇、不负责删除食物，也不修改 `blankCells`。

== 窗口尺寸由 `Board` 决定

```rust
pub fn createWindow(
    title: &str,
    board: &Board,
) -> GlutinWindow {
    let opengl = OpenGL::V3_2;

    WindowSettings::new(title, board.pixelSize())
        .graphics_api(opengl)
        .exit_on_esc(true)
        .resizable(false)
        .build()
        .expect("failed to create window")
}
```

这样渲染层不需要重复知道棋盘半宽、半高和格子大小。

== 为什么每帧完整重绘

我没有采用“只擦除旧尾巴、只绘制新蛇头”的增量绘制。OpenGL 通常使用双缓冲，上一帧并不是一块适合长期局部修改的可靠画布；而贪吃蛇每帧只需要绘制少量矩形，完整重绘更简单也更稳定。

一帧中先清屏，然后遍历 `foods` 和 `snake.points()`：

```rust
gl.draw(args.viewport(), |context, graphics| {
    clear(BACKGROUND_COLOR, graphics);

    for slot in &game.foods {
        let Some(food) = slot else {
            continue;
        };

        if food.isExpired() {
            continue;
        }

        let rect =
            game.board.toPixel(&food.position);

        rectangle(
            foodColor(food.foodType),
            insetRect(rect, 2.0),
            context.transform,
            graphics,
        );
    }

    for (index, point) in
        game.snake.points().enumerate()
    {
        let color =
            if index == 0 {
                HEAD_COLOR
            } else {
                BODY_COLOR
            };

        rectangle(
            color,
            insetRect(game.board.toPixel(point), 2.0),
            context.transform,
            graphics,
        );
    }

    drawGrid(
        &game.board,
        context.transform,
        graphics,
    );
});
```

网格线只依赖 `Board::columns()`、`rows()` 和 `cellSize()`。数学原点对应窗口中央，因此还可以在普通网格上画两条更粗的坐标轴。

== Piston 事件循环只是连接三类事件

程序使用 120 UPS 和最高 60 FPS：

```rust
let mut events = Events::new(
    EventSettings::new()
        .ups(120)
        .max_fps(60),
);
```

主循环分别处理输入、更新和渲染：

```rust
while let Some(event) = events.next(&mut window) {
    if let Some(Button::Keyboard(key)) =
        event.press_args()
    {
        // 只更新输入意图或暂停状态
    }

    if let Some(args) = event.update_args() {
        game.looping(args.dt);
    }

    if let Some(args) = event.render_args() {
        render::renderFrame(&mut gl, &args, &game);
    }
}
```

输入事件修改 `pendingDirection`，更新事件推进真实状态，渲染事件只读取状态。渲染慢一点不会改变游戏规则，按键也不会直接让蛇越过计时器移动。

= 在这个项目中学到的 Rust

虽然程序规模不大，它却把不少 Rust 概念连在了一起。

== 所有权同时也是职责边界

`Game` 拥有食物，所以由 `Game` 调用 `Option::take()` 删除食物；`Food` 只能报告自己是否过期。`Snake` 拥有身体，因此外部只取得借用迭代器，不能移动内部 `VecDeque`。

当我发现一个对象很难被安全删除时，问题往往不在于 Rust “太严格”，而在于我还没有确定谁才是真正的所有者。

== 借用区分读取与修改

渲染函数接收 `&Game`，只能读取；`Game::looping` 和 `Game::step` 接收 `&mut self`，负责状态转移。函数签名直接表达了模块权限。

== `Option` 可以消除非法状态

- `Option<Food>`：槽位有无食物；
- `Option<i32>`：本次是否进食并获得分数；
- `Option<Point<i32>>`：本次是否释放旧蛇尾。

这些含义若分别使用值和布尔变量表达，很容易出现“标记为没有食物，但仍保存一份食物对象”的矛盾组合。

== 枚举适合有限规则

`Direction`、`FoodType`、`GameState` 都是有限集合。使用枚举和 `match` 后，编译器会提醒遗漏分支，也避免依赖难以理解的整数常量。

== 容器应匹配主要操作

- `VecDeque` 匹配蛇头插入和蛇尾删除；
- `HashSet` 匹配格点占用查询；
- `[Option<Food>; 2]` 匹配最多两个食物槽位。

选择数据结构不是为了追求理论上最复杂的优化，而是让最常见的状态变化能够自然表达。

== 包名不一定等于 Rust 中的 crate 名

Cargo.toml 中写：

```toml
piston2d-opengl_graphics = "0.81.0"
pistoncore-glutin_window = "0.69.0"
```

源码导入却是：

```rust
use opengl_graphics::{GlGraphics, OpenGL};
use glutin_window::GlutinWindow;
```

Piston 生态的版本也必须彼此匹配。来自两个版本的同名 `Graphics` trait 仍然是不同类型。处理依赖问题让我更理解 Cargo 包名、库名和版本解析之间的区别。

== 单元测试不一定需要启动整个游戏

快速反向、格点移动和速度计算都属于纯逻辑，可以直接测试 `snake.rs`。把底层模型与窗口隔离以后，很多关键规则都不需要图形环境就能验证。

= 还可以继续改进什么？

当前结构已经形成了完整主线，但仍有一些可以继续收紧的地方：

- 将驼峰命名逐步改为 Rust 惯用的 `snake_case`；
- 让一次更新共享同一个 `Instant`，统一食物过期快照；
- 将 `generateFood` 限制为只有整批结束时才能调用的内部方法；
- 明确 `Paused`、`GameOver` 时食物是否继续过期或生成；
- 给 `GameOver`、`Victory` 和暂停状态增加界面；
- 增加 `blankCells` 不变量、坐标映射、批次结束和进入旧蛇尾格的测试；
- 若以后支持高速连续拐弯，可以把单个 `pendingDirection` 扩展为长度受限的方向队列。

= 结语

这个项目真正困难的地方并不是画出一个绿色矩形，而是把规则分层：

#tufted.remark[][
  `snake.rs` 先定义稳定的领域对象和一步移动；`game.rs` 再决定时间、空间、所有权和状态转移；`render.rs` 最后把结果完整地显示出来。
]

当顺序是从底层模型到上层协调，再到视图以后，很多问题会自然得到答案：

- `Food` 不该自己删除自己，因为它的所有者是 `Game`；
- `Snake` 不该知道帧率，因为何时移动由 `Timer` 和 `Game` 决定；
- `Board` 不该复制蛇和食物，因为实体已经有唯一状态来源；
- `render.rs` 不该改变规则，因为它只是 `Game` 的只读视图。

Rust 的所有权和借用检查在这个过程中不只是编译限制，更像是一种设计反馈：谁拥有数据，谁才能决定它的生命周期；谁只有共享引用，谁就只能观察。把这些边界理顺以后，一个小小的贪吃蛇也能拥有清晰、可扩展且可测试的结构。
