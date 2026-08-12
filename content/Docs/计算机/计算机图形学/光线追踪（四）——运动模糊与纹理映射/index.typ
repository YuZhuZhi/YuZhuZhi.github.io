#import "../../../index.typ": template, tufted
#show: template.with(
  title: "光线追踪（四）——运动模糊与纹理映射",
  description: "为射线加入时间维度，用快门区间模拟运动模糊；再从纹理抽象、三维棋盘到球面 UV 与图像纹理，建立表面颜色映射。",
)

#set math.equation(numbering: "(1)")

= 光线追踪（四）——运动模糊与纹理映射

#tufted.full-width[
    #image("images/header.jpg")
]

前三篇中的射线只携带空间信息，材质也只有一个固定反照率。本篇沿着 #link("https://raytracing.github.io/books/RayTracingTheNextWeek.html")[《Ray Tracing: The Next Week》] 的路线扩展这两个限制：首先把射线提升到时空查询，使不同样本观察到运动物体在快门期间的不同位置；然后把“颜色”抽象为一个可查询函数，让材质随空间位置或表面坐标变化。

配套 Rust 程序位于 `src/bin/chapter4.rs`。本篇四幅结果均由该程序以 $1280 times 720$ 分辨率、每像素 $48$ 个样本生成。

= 一、运动模糊

== 1. 从瞬时成像到快门时间积分

此前默认所有像素都在同一瞬间拍摄。真实相机的快门会在区间 $[t_0,t_1]$ 内保持开启，因此一个像素记录的是空间采样与时间采样的共同平均。若暂时只写出时间维度，像素值可以表示为
$
  L_("avg")=frac(1,t_1-t_0) integral_(t_0)^(t_1) L(t) upright(d)t.
$ <eq-temporal-average>

蒙特卡洛方法不需要显式求这个积分：对每条摄像机射线独立采样 $T_k in upright(U)(t_0,t_1)$，再取平均
$
  hat(L)_N=frac(1,N)sum_(k=1)^N L(T_k).
$

#tufted.theorem[均匀快门采样的无偏性][
  若 $T$ 在 $[t_0,t_1]$ 上均匀分布，且 $L(t)$ 可积，则 $hat(L)_N$ 是式 @eq-temporal-average 的无偏估计，即 $E[hat(L)_N]=L_("avg")$。
]

#tufted.proof[
  均匀分布的概率密度为 $p(t)=1/(t_1-t_0)$，因此
  $
    E[L(T)]=integral_(t_0)^(t_1)L(t)p(t)upright(d)t=L_("avg").
  $
  样本均值的期望等于各样本期望的平均，故结论成立。
]

#figure(
  image("images/motion-time.png"),
  caption: [快门区间内的不同射线样本观察到不同物体位置],
) <fig-motion-time>

== 2. 带时间的射线与摄像机

#tufted.definition[时空射线][
  带时间的射线由起点 $bold(O)$、方向 $bold(d)$ 和采样时刻 $tau$ 构成。其空间参数仍为
  $
    bold(r)(s;tau)=bold(O)+s bold(d), quad s>=0,
  $
  但场景求交必须在时刻 $tau$ 的几何状态下进行。$s$ 是沿射线的位置参数，$tau$ 是快门时间，两者不能混用。
]

Rust 中保留原来的双参数构造器，使旧代码默认在 $tau=0$ 渲染；需要运动模糊时再显式指定时间：

```rust
pub struct Ray {
    pub origin: Point3,
    pub direction: Vec3,
    pub time: f64,
}

impl Ray {
    pub const fn new(origin: Point3, direction: Vec3) -> Self {
        Self::with_time(origin, direction, 0.0)
    }

    pub const fn with_time(origin: Point3, direction: Vec3, time: f64) -> Self {
        Self { origin, direction, time }
    }
}
```

摄像机保存 `shutter_open` 与 `shutter_close`。生成射线时，除像素抖动和孔径圆盘采样外，再增加一次时间采样：

```rust
let time = if self.shutter_open == self.shutter_close {
    self.shutter_open
} else {
    rng.range(self.shutter_open, self.shutter_close)
};
Ray::with_time(origin, direction, time)
```

#tufted.remark[反弹射线不能重新抽时间][
  一条路径代表同一光学事件在同一场景时刻的传播。材质散射生成后继射线时必须复制 `incoming.time`；若每次反弹重新抽取时间，单条路径会在运动场景的多个状态之间跳跃，得到没有物理意义的几何组合。
]

== 3. 线性运动球体

令球心在 $t_0$ 时为 $bold(C)_0$、在 $t_1$ 时为 $bold(C)_1$。最简单的运动模型是线性插值：
$
  bold(C)(t)=bold(C)_0+frac(t-t_0,t_1-t_0)(bold(C)_1-bold(C)_0).
$ <eq-moving-center>
射线—球体求交的二次方程完全不变，只需把固定球心替换为 $bold(C)(tau)$。也就是说，时间维度被封装在“查询当前球心”这一步中。

```rust
pub fn center(&self, time: f64) -> Point3 {
    self.center0
        + ((time - self.time0) / (self.time1 - self.time0))
            * (self.center1 - self.center0)
}

let center = self.center(ray.time);
let oc = ray.origin - center;
```

运动图元仍要进入 BVH。节点包围盒必须覆盖整个快门区间；对于线性运动球，只需合并两个端点球的 AABB：
$
  B_("motion")=op("hull")(B(t_0),B(t_1)).
$

#tufted.proposition[线性运动球的端点并盒覆盖整段运动][
  半径固定、球心按式 @eq-moving-center 线性运动时，端点 AABB 的最小公共 AABB 包含任意 $t in [t_0,t_1]$ 时刻的球体。
]

#tufted.proof[
  球心的每个坐标都是两个端点坐标的凸组合，因此位于对应端点坐标的闭区间内。向三个方向各扩张固定半径后，任意时刻球体的坐标范围仍包含于端点盒逐分量合并得到的范围。
]

== 4. 静止快门与运动模糊对照

下面两幅图使用完全相同的五个线性运动球。第一幅把快门固定在 $t=0.5$，所有样本观察同一个瞬间，因此轮廓清晰：

#figure(
  image("images/ch4-motion-static.png"),
  caption: [固定快门时刻得到的瞬时画面],
) <fig-motion-static>

第二幅在 $[0,1]$ 内均匀采样。每个像素累计了物体沿轨迹处于不同位置时的贡献，于是运动方向被拉成连续的模糊带：

#figure(
  image("images/ch4-motion-blur.png"),
  caption: [在完整快门区间采样得到的运动模糊],
) <fig-motion-blur>

运动模糊并不是对最终二维图片做滤镜。遮挡、阴影、反射和材质查询都发生在各自采样时刻；这正是把时间放进射线而不是在渲染后处理的价值。

= 二、纹理映射

== 1. 把颜色提升为纹理函数

固定反照率可以写成常函数 $bold(T)(u,v,bold(p))=bold(c)$。更一般地，纹理是一个查询：
$
  bold(T):[0,1]^2 times bb(R)^3 arrow [0,1]^3,
  quad (u,v,bold(p)) mapsto bold(c).
$ <eq-texture-interface>
保留 $(u,v)$ 与三维位置 $bold(p)$ 两组输入，可以同时表达表面纹理和空间纹理。

#tufted.definition[空间纹理与表面纹理][
  空间纹理直接以三维点 $bold(p)$ 为输入，仿佛整个空间已经被颜色函数填充；表面纹理先把物体表面映射到二维坐标 $(u,v)$，再查询二维图像或函数。
]

一个三维棋盘纹理可令
$
  q(bold(p))=floor(x/s)+floor(y/s)+floor(z/s),
$
根据 $q$ 的奇偶选择两种颜色。这里必须使用向下取整而非向零截断，否则原点两侧的格子会不对称。

```rust
let x = (point.x / scale).floor() as i64;
let y = (point.y / scale).floor() as i64;
let z = (point.z / scale).floor() as i64;
if (x + y + z).rem_euclid(2) == 0 { even } else { odd }
```

#figure(
  image("images/ch4-checker-texture.png"),
  caption: [三维棋盘纹理同时作用于小球和大球地面],
) <fig-checker-texture>

棋盘线条在两个不同球面上连续弯曲，说明颜色来自同一个三维函数，而不是分别贴上的二维图片。

== 2. 球面 UV 坐标

图像纹理需要把单位球面点 $bold(p)=(x,y,z)$ 转成二维坐标。按照本系列采用的球面朝向，定义
$
  phi &= op("atan2")(-z,x)+pi, \
  theta &= arccos(-y), \
  u &= frac(phi,2pi), quad v=frac(theta,pi).
$ <eq-sphere-uv>
于是 $u,v in [0,1]$。$u$ 沿纬线方向绕球一周，$v$ 从南极走向北极。

#figure(
  image("images/sphere-uv.png"),
  caption: [球面经纬参数展开为单位正方形 UV 域],
) <fig-sphere-uv>

#tufted.remark[接缝与极点不可避免][
  球面不能无撕裂地展平为矩形：$u=0$ 与 $u=1$ 表示同一条接缝，而极点附近许多不同的 $u$ 会汇聚到同一点。纹理绘制时应把接缝放在不显眼处，并在极点附近避免过密细节。
]

== 3. 从 UV 到图像像素

设纹理图宽高为 $W,H$。最近邻采样先把 UV 限制在单位区间，再把坐标换成整数像素：
$
  i &= min(floor(u W),W-1), \
  j &= min(floor((1-v)H),H-1).
$ <eq-uv-pixel>
式中翻转 $v$，是因为数学纹理坐标通常向上增长，而图像数组的行号通常从顶部向下增长。

```rust
let u = u.clamp(0.0, 1.0);
let v = 1.0 - v.clamp(0.0, 1.0);
let i = ((u * width as f64) as usize).min(width - 1);
let j = ((v * height as f64) as usize).min(height - 1);
pixels[j * width + i]
```

配套程序不引入图像依赖，而是先用 Rust 生成一幅 $1440 times 720$ 的 PPM 经纬测试图，再由 `ImageTexture::load_ppm` 读回像素。源纹理如下：

#figure(
  image("images/ch4-uv-grid-source.png"),
  caption: [Rust 生成并重新读取的二维 UV 经纬测试纹理],
) <fig-uv-grid-source>

映射到球面后，粗黑线标出主要经纬区块，细白线帮助观察极点压缩、球面弯曲和接缝位置：

#figure(
  image("images/ch4-uv-image.png"),
  caption: [使用球面 UV 坐标查询图像纹理的结果],
) <fig-uv-image>

最近邻实现最容易验证，但放大时会出现块状边缘。若要使用双线性过滤，可读取 $(i,j)$ 周围四个像素并做两次线性插值；其数学形式与第一篇的单线性插值相同，只是分别沿 $u$、$v$ 两个方向执行。

= 三、实现检查清单

- 所有旧构造的射线默认时间为 $0$，保证静态场景兼容。
- 摄像机只在快门区间采样一次时间；整条反弹路径始终保留该时间。
- 运动物体求交使用 `ray.time`，运动 AABB 覆盖完整快门区间。
- 命中记录同时保存三维点、法向量和二维 UV。
- 空间纹理查询 $bold(p)$，图像纹理查询 $(u,v)$；材质不需要知道纹理的具体类型。
- 图像采样要限制边界并处理 $v$ 方向翻转。
- 本系列所有 Rust 渲染输出现统一为至少 $1280 times 720$。

完成这些改动后，路径追踪器不再只能渲染静态、纯色的球：时间成为场景查询的一部分，颜色也成为可组合的函数。下一步可以自然扩展到 Perlin 噪声、凹凸映射、发光纹理与更复杂的动画变换。
