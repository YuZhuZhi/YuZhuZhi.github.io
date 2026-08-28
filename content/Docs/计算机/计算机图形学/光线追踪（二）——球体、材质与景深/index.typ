#import "../../../index.typ": template, tufted
#show: template.with(
  title: "光线追踪（二）——球体、材质与景深",
  description: "从射线—球体求交开始，实现表面法向量、漫反射、金属、电介质和薄透镜景深。",
)

#set math.equation(numbering: "(1)")

= 光线追踪（二）——球体、材质与景深

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/13772078")[夜蓝星炫]（Pixiv），#link("https://www.pixiv.net/artworks/97420493")[Source]_
]

第一篇建立了射线与摄像机。本篇让射线真正与场景交互：先求出球面的最近交点，再把几何与材质分离，用递归的散射过程近似渲染方程。最后把针孔改成有限孔径，得到聚焦清晰、前后景模糊的景深效果。

= 一、球体与采样

== 1. 射线与球的交点

#figure(
  image("images/sphere-intersection.png"),
  caption: [射线与球面的几何关系],
) <fig-sphere-hit>

球心为 $bold(C)$、半径为 $R$ 的球面满足
$
  norm(bold(P)-bold(C))^2=R^2.
$
把射线 $bold(P)=bold(O)+t bold(d)$ 代入，令 $bold(o)=bold(O)-bold(C)$，展开得
$
  (bold(d) dot bold(d))t^2 + 2(bold(o) dot bold(d))t
  + bold(o) dot bold(o)-R^2=0.
$ <eq-sphere-quadratic>
记 $a=bold(d) dot bold(d)$、$h=bold(o) dot bold(d)$、$c=bold(o) dot bold(o)-R^2$，则判别式和两个根为
$
  Delta=h^2-a c, quad t=(-h plus.minus sqrt(Delta))/a.
$
$Delta<0$ 表示错过球体，$Delta=0$ 表示相切，$Delta>0$ 表示穿过球面。渲染时不应仅问“是否命中”，而应在允许区间 $[t_(min),t_(max)]$ 内选择最小根，因为它对应沿射线最先看到的表面。

```rust
let oc = ray.origin - self.center;
let a = ray.direction.length_squared();
let half_b = oc.dot(ray.direction);
let c = oc.length_squared() - self.radius * self.radius;
let discriminant = half_b * half_b - a * c;
if discriminant < 0.0 { return None; }

let root = discriminant.sqrt();
let mut t = (-half_b - root) / a;
if t < t_min || t > t_max {
    t = (-half_b + root) / a;
    if t < t_min || t > t_max { return None; }
}
```

球面点 $bold(P)$ 的外法向量是
$
  bold(n)_("out")=(bold(P)-bold(C))/R.
$
为了让材质代码不区分射线来自物体外部还是内部，命中记录同时保存 `front_face`，并令存储的法向量永远朝向入射射线的反方向：

```rust
let front_face = ray.direction.dot(outward_normal) < 0.0;
let normal = if front_face { outward_normal } else { -outward_normal };
```

在材质系统出现之前，可以先用命中与否输出固定红色，再把法向量从 $[-1,1]^3$ 线性映射到 $[0,1]^3$ 作为 RGB：
$
  bold(C)_("normal")=frac(bold(n)+(1,1,1),2).
$
这两幅阶段图分别验证“求交是否正确”和“交点法向量是否正确”。此时每个像素只取中心样本，因此边缘仍可能出现锯齿；后面的超采样阶段才会处理它。

#figure(
  image("images/red-sphere.png"),
  caption: [命中球体时输出固定红色],
) <fig-red-sphere>

#figure(
  image("images/normal-sphere.png"),
  caption: [将球面法向量映射为 RGB 颜色],
) <fig-normal-sphere>

== 2. 从单球到世界与超采样

下一步加入一个半径很大的球作为地面。几何接口没有任何特殊分支：地面仍是普通球体，只是球心位于画面下方，摄像机附近只看见其很小的一段弧面。

#figure(
  image("images/sphere-ground.png"),
  caption: [添加地面],
) <fig-sphere-ground>

只在像素中心采样时，球体轮廓与地平线会暴露明显的阶梯。对每个像素生成多条带抖动的射线并取平均后，边缘覆盖率被近似积分，得到平滑过渡：

#figure(
  image("images/sphere-antialias.png"),
  caption: [实现超采样],
) <fig-sphere-antialias>

超采样还揭示了一个常见错误：如果累加多个样本却忘记除以样本数，输出通道会越界或在错误的颜色转换中发生周期性折返，形成下图的彩色条纹与同心伪影。它不是随机噪声，而是颜色归一化失败的诊断信号。

#figure(
  image("images/antialias-error.png"),
  caption: [抗锯齿时生成的错误图像],
) <fig-antialias-error>

#tufted.definition[可命中对象][
  可命中对象 `Hittable` 是能够回答两个问题的几何实体：一条射线在给定参数区间内的最近交点是什么；包围它的轴对齐包围盒是什么。球、三角形、网格以及第三篇的 BVH 节点都可以实现同一接口。
]

== 3. 递归路径与能量衰减

命中表面后，材质选择下一条射线 `scattered`，并返回逐通道衰减 `attenuation`。渲染函数具有非常紧凑的递归形式：

```rust
if depth == 0 { return Color::ZERO; }
if let Some(hit) = world.hit(ray, 0.001, f64::INFINITY) {
    if let Some((attenuation, scattered)) = hit.material.scatter(ray, &hit, rng) {
        return attenuation * ray_color(&scattered, world, depth - 1, rng);
    }
    return Color::ZERO;
}
return sky(ray.direction);
```

每次乘以衰减，模拟路径携带能量的变化；到达最大深度时终止，防止极端路径无限递归。生产级路径追踪器通常改用俄罗斯轮盘赌：根据当前吞吐量以一定概率终止，否则用存活概率校正权重，从而保持估计无偏。

#tufted.remark[递归深度不是“反射次数越大越真实”的旋钮][
  固定截断会引入轻微偏差，而过大的深度会浪费大量时间。多数普通场景在若干次反弹后能量已经很小。画质的主要瓶颈往往是采样方差，而不是深度不足。
]

= 二、材质模型

== 1. Lambert 漫反射

理想漫反射的 BRDF 为常数
$
  f_r=bold(rho)/pi,
$
其中 $bold(rho)$ 是反照率。若按余弦加权半球分布采样，概率密度 $p(omega)=cos theta/pi$ 会与渲染方程中的余弦项抵消，得到低方差估计。教程实现可先用一个近似而直观的构造：在法向量上叠加随机单位向量，所得方向自然偏向法线附近。

```rust
let mut direction = hit.normal + rng.unit_vector();
if direction.near_zero() { direction = hit.normal; }
Some((albedo, Ray::new(hit.point, direction)))
```

`near_zero` 分支处理随机向量几乎与 $-bold(n)$ 相等的退化情形。这里的 `albedo` 应位于 $[0,1]^3$；大于 $1$ 会凭空增加能量。

下面四幅图保留漫反射实现的递进过程。第一种随机球内采样虽然已经产生阴影，但能量衰减过强，整体接近黑色：

#figure(
  image("images/diffuse-first.png"),
  caption: [使用第一漫反射模型产生的结果],
) <fig-diffuse-first>

对线性颜色进行 gamma 2 近似编码后，中间调亮度恢复，暗部细节也更容易辨认。应注意 gamma 修正改变的是显示编码，而不是材质本身：

#figure(
  image("images/diffuse-gamma.png"),
  caption: [使用伽马修正产生的结果],
) <fig-diffuse-gamma>

改用更接近余弦分布的 Lambert 采样后，球面亮度过渡更均衡：

#figure(
  image("images/diffuse-lambert.png"),
  caption: [使用朗伯反射产生的结果],
) <fig-diffuse-lambert>

另一种半球采样方式会改变方向概率分布，图中阴影更集中。三种模型并非只造成“更亮或更暗”，其本质差别是对半球方向赋予了不同权重：

#figure(
  image("images/diffuse-hemisphere.png"),
  caption: [使用第三漫反射模型产生的结果],
) <fig-diffuse-hemisphere>

== 2. 金属：镜面反射与粗糙度

单位入射方向 $bold(i)$ 关于单位法向量 $bold(n)$ 的反射方向为
$
  bold(r)=bold(i)-2(bold(i) dot bold(n))bold(n).
$ <eq-reflect>
这是因为 $bold(i)$ 在法向分量上的投影为 $(bold(i) dot bold(n))bold(n)$，反射只需把该分量翻转。

理想镜面总沿 $bold(r)$ 传播。为了得到磨砂金属，可以在单位球内取随机向量 $bold(xi)$，引入粗糙参数 $f in [0,1]$：
$
  bold(r)'=bold(r)+f bold(xi).
$
若扰动后的方向进入表面，即 $bold(r)' dot bold(n) <= 0$，路径应当终止。

```rust
let direction = incoming.direction.unit().reflect(hit.normal)
    + fuzz.clamp(0.0, 1.0) * rng.in_unit_sphere();
(direction.dot(hit.normal) > 0.0)
    .then(|| (albedo, Ray::new(hit.point, direction)))
```

这个模型适合教学，但它不是严格的微表面 BRDF。更真实的渲染器会使用 GGX 等法线分布函数，并同时考虑几何遮蔽与 Fresnel 项。

当 $f=0$ 时，反射方向没有扰动，左右金属球呈现清晰而集中的镜面反射：

#figure(
  image("images/metal-smooth.png"),
  caption: [完全光滑球面的结果],
) <fig-metal-smooth>

增大 `fuzz` 后，反射射线落在理想方向附近的一簇方向上，高光和倒影被摊开，得到磨砂外观：

#figure(
  image("images/metal-fuzz.png"),
  caption: [磨砂金属球面的结果],
) <fig-metal-fuzz>

== 3. 电介质：折射、全反射与 Fresnel

#tufted.full-width[
  #image("images/material-focus.png")
]

设光线从折射率 $eta_1$ 的介质进入 $eta_2$，Snell 定律为
$
  eta_1 sin theta_1 = eta_2 sin theta_2.
$
令相对折射率 $eta=eta_1/eta_2$，单位入射方向为 $bold(i)$，法向量朝向入射一侧。把折射方向分成切向与法向分量：
$
  bold(r)_(perp) &= eta(bold(i)+cos theta_1 bold(n)), \
  bold(r)_(parallel) &= -sqrt(abs(1-norm(bold(r)_(perp))^2))bold(n), \
  bold(r) &= bold(r)_(perp)+bold(r)_(parallel).
$ <eq-refract>

当 $eta sin theta_1>1$ 时，$theta_2$ 没有实数解，发生全反射。即使可以折射，介质界面也会同时反射一部分能量。Schlick 近似以很低成本估计反射概率：
$
  R(theta)=R_0+(1-R_0)(1-cos theta)^5,
  quad R_0=((eta_1-eta_2)/(eta_1+eta_2))^2.
$ <eq-schlick>

实现时以 $R(theta)$ 为概率随机选择反射或折射，单条路径仍只生成一条后继射线；大量样本的平均值恢复两种分量。

#tufted.theorem[全反射判据][
  当光从光密介质进入光疏介质，即 $eta_1>eta_2$，若 $sin theta_1>eta_2/eta_1$，则不存在实数折射角，全部能量只能留在原介质一侧。
]

#tufted.proof[
  由 Snell 定律，$sin theta_2=(eta_1/eta_2)sin theta_1$。若右侧大于 $1$，它不可能对应任何实角度，因此折射解不存在。
]

空心玻璃球可以用同心的两个球表示：外球半径为正，内球半径为负。负半径会翻转外法线，使第二个表面表达由玻璃回到空气的界面。这是便利技巧；一般几何体更适合显式规定朝向。

如果只套用折射公式而没有检查根号是否存在，光线在应当全反射的角度无法得到合法的后继方向。gallery 程序故意让这类路径返回黑色，以便把错误暴露为明显的黑色缺口：

#figure(
  image("images/dielectric-no-tir.png"),
  caption: [未考虑全反射时的结果],
) <fig-dielectric-no-tir>

加入 $eta sin theta_1>1$ 的判定后，不存在折射解的路径改走反射方向，球体结构恢复：

#figure(
  image("images/dielectric-tir.png"),
  caption: [考虑全反射时的结果],
) <fig-dielectric-tir>

最后使用式 @eq-schlick 在反射与折射之间随机选择，空心玻璃球同时表现透射、边缘反射和内部界面：

#figure(
  image("images/dielectric-fresnel.png"),
  caption: [考虑 Fresnel 效应时的空心玻璃球],
) <fig-dielectric-fresnel>

= 三、摄像机与成像结果

== 1. 薄透镜与聚焦模糊

针孔相机的所有光线都从同一点出发，因此理论上整个场景都清晰。真实镜头有有限孔径：焦平面上的一点会被孔径各处发出的光线汇聚；不在焦平面上的点则在成像面形成弥散圆。

薄透镜近似不必模拟曲面。保持焦平面上的目标点不变，把射线起点从相机中心随机移动到半径 $r=a/2$ 的圆盘内。若圆盘样本为 $bold(q)=(q_x,q_y,0)$，相机基为 $bold(u),bold(v)$，偏移量是
$
  bold(delta)=r(q_x bold(u)+q_y bold(v)).
$
射线从 $bold(O)+bold(delta)$ 出发，仍瞄准原来的焦平面采样点。孔径越大，离焦区域越模糊；焦距参数决定哪一层清晰。

```rust
let disk = self.lens_radius * rng.in_unit_disk();
let offset = self.u * disk.x + self.v * disk.y;
Ray::new(
    self.origin + offset,
    self.lower_left + s*self.horizontal + t*self.vertical
        - self.origin - offset,
)
```

#tufted.remark[焦距、对焦距离与视场角][
  教程相机中的 `focus_distance` 是对焦平面距离，并不自动改变视场角；`vfov` 控制构图；`aperture` 控制孔径。现实镜头的参数互相关联，而薄透镜接口刻意把它们拆开，便于理解和调试。
]

下面四幅图分别隔离相机参数的影响。较大的垂直视场角容纳更广的范围，因此同一组物体在画面中所占比例更小：

#figure(
  image("images/camera-wideangle.png"),
  caption: [广角镜头的结果],
) <fig-camera-wideangle>

把观察点移远后，物体在画面中所占比例缩小，场景关系更容易整体辨认：

#figure(
  image("images/camera-distant.png"),
  caption: [改变镜头距离的结果],
) <fig-camera-distant>

在较近观察位置或较小视场角下，主体被放大，边缘物体会超出画幅：

#figure(
  image("images/camera-zoomin.png"),
  caption: [镜头缩放的结果],
) <fig-camera-zoomin>

启用有限孔径后，对焦平面附近的蓝色球保持清晰，前后景形成弥散圆。这正是薄透镜采样所模拟的聚焦模糊：

#figure(
  image("images/camera-depth-of-field.png"),
  caption: [实现景深的结果],
) <fig-camera-depth-of-field>

== 2. 完整程序的渲染结果

#tufted.remark[结果图的来源][
  本篇从红色球到最终随机场景的全部阶段图，均由配套 Rust 工程中的 `src/bin/gallery.rs` 生成。运行 `cargo run --release --bin gallery` 会在 `gallery/` 中写出对应的 PPM 文件；正文 PNG 只由这些 PPM 转码而来，不再使用原实验文档中的截图。
]

把随机场景、三类材质和景深全部组合，可得到更复杂的最终图。第一幅使用较宽的取景，展示大量小球、金属反射与空心玻璃结构：

#figure(
  image("images/final-scene-a.png"),
  caption: [随机球体场景的最终结果之一],
) <fig-final-scene-a>

第二幅调整了观察位置与构图，使前景小球和两个主要球体更突出：

#figure(
  image("images/final-scene-b.png"),
  caption: [随机球体场景的最终结果之二],
) <fig-final-scene-b>

把本篇的球体求交、三类材质、薄透镜相机与递归路径追踪组合起来，配套 Rust 程序会直接写出一幅 PPM 图像。下图使用 $1280 times 720$ 分辨率、每像素 $64$ 个随机样本和最大 $24$ 次反弹；从左到右分别是空心电介质球、Lambert 漫反射球和带少量粗糙度的金属球，黄色大球充当地面。固定随机种子使结果可以复现。

#figure(
  image("images/rust-render.png"),
  caption: [配套 Rust 路径追踪器的实际输出],
) <fig-rust-render>

程序使用纯文本 PPM，是因为这种格式无需图像编码依赖：文件头写入 `P3`、宽高和最大通道值，随后逐像素输出 RGB。需要用于网页时，再把 `render.ppm` 转为 PNG 即可；这不会改变渲染内容。

== 3. 从“能出图”到“可信”

- 始终返回区间内最近交点，并用当前最近 $t$ 缩短后续查询。
- 命中记录统一调整法向量朝向，电介质才能正确选择相对折射率。
- 材质颜色在线性空间相乘，输出时才进行 gamma 或 sRGB 编码。
- 漫反射随机方向必须位于表面外侧；严谨实现应使用余弦加权半球采样。
- 每次散射都要限制深度或使用俄罗斯轮盘赌。
- 景深采样发生在圆盘而不是球体内，所有样本仍瞄准同一焦平面点。

至此，一个小型路径追踪器已经具备球体、漫反射、金属、玻璃与景深。不过每条射线仍可能逐一测试所有物体；场景一大，求交就成为绝对瓶颈。第三篇用 AABB 和 BVH 把大多数不可能命中的物体成组排除。
