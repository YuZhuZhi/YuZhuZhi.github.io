#import "../../../index.typ": template, tufted
#show: template.with(
  title: "光线追踪（一）——射线与摄像机",
  description: "从颜色、向量与坐标系出发，建立射线、针孔摄像机和最小渲染循环。",
)

#set math.equation(numbering: "(1)")
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 7pt)

= 光线追踪（一）——射线与摄像机

#tufted.full-width[
    #image("images/header.jpg")
]

光线追踪的核心问题可以说得很朴素：屏幕上的一个像素，应该呈现什么颜色？光栅化从三角形出发，把几何投影到屏幕；光线追踪则从像素出发，向场景发射查询射线，寻找最先遇到的表面，再沿反射、折射或阴影方向继续查询。后者很自然地表达了遮挡、镜面与透明介质，也为基于物理的渲染提供了统一框架。

真实光子从光源出发，只有极少数最终进入摄像机。若正向模拟全部光子，大部分计算与画面无关。几何光学满足光路可逆，因此基础渲染器通常反向从摄像机追踪路径。这种算法更准确的名字是“路径追踪”；“光线追踪”在本文中作为广义称呼使用。

#tufted.remark[本系列的主要参考][
  本系列的整体组织与实现路线主要参考 Peter Shirley、Trevor David Black 和 Steve Hollasch 的开源教程 #link("https://raytracing.github.io/")[Ray Tracing in One Weekend 系列]。前三篇从基础实现出发重新推导；从第四篇开始重点参考 #link("https://raytracing.github.io/books/RayTracingTheNextWeek.html")[《Ray Tracing: The Next Week》]，并用 Rust 独立实现和复现实验结果。文中的解释、公式组织与代码结构并非原文逐句翻译。
]

= 一、光线追踪基础

== 1. 渲染方程与蒙特卡洛估计

一个表面点 $x$ 沿方向 $omega_o$ 离开的辐亮度满足渲染方程
$
  L_o(x, omega_o) = L_e(x, omega_o)
  + integral_(Omega) f_r(x, omega_i, omega_o) L_i(x, omega_i)
    abs(n dot omega_i) upright(d) omega_i .
$ <eq-rendering>

其中 $L_e$ 是自发光，$f_r$ 是双向反射分布函数，$L_i$ 是来自半球 $Omega$ 的入射辐亮度，$n$ 是表面法向量。积分很少有闭式解，于是我们随机选择方向 $omega_k$，用样本均值近似：
$
  integral_(Omega) g(omega) upright(d)omega
  approx 1/N sum_(k=1)^N g(omega_k)/p(omega_k),
$
其中 $p$ 是采样概率密度。样本越多，噪声通常越小；但蒙特卡洛误差只按 $O(N^(-1/2))$ 收敛，把误差减半大约需要四倍样本。

#tufted.remark[光线追踪与路径追踪][
  经典 Whitted 光线追踪显式生成反射光、折射光与阴影光；路径追踪把式 @eq-rendering 的积分解释成随机路径上的期望。本文实现的是一个小型路径追踪器，但射线求交、摄像机和 BVH 同样适用于前者。
]

== 2. 向量、颜色与射线

三维点和向量都可以用三个实数存储，但语义不同：点表示位置，向量表示位移。若 $bold(a)=(a_x,a_y,a_z)$、$bold(b)=(b_x,b_y,b_z)$，则
$
  bold(a) dot bold(b) &= a_x b_x + a_y b_y + a_z b_z,
  & norm(bold(a)) &= sqrt(bold(a) dot bold(a)), \
  bold(a) times bold(b) &= (a_y b_z-a_z b_y, a_z b_x-a_x b_z, a_x b_y-a_y b_x).
$
点积给出夹角关系 $bold(a) dot bold(b)=norm(bold(a))norm(bold(b))cos theta$；叉积得到同时垂直于两向量的方向。归一化 $hat(bold(a))=bold(a)/norm(bold(a))$ 只改变长度，不改变方向。

颜色也可复用三分量向量，令 $bold(c)=(r,g,b)$。线性空间中的 $0.5$ 并不等于显示器编码值的 $0.5$。简单教程常用 gamma 2 近似，在输出前计算
$
  c_("display") = sqrt(max(c_("linear"),0)).
$

#tufted.definition[射线][
  给定起点 $bold(O)$ 和方向 $bold(d) != bold(0)$，射线是参数曲线
  $
    bold(r)(t)=bold(O)+t bold(d), quad t >= 0.
  $
  $t$ 不是距离，除非 $bold(d)$ 已归一化；但求交算法通常不要求单位方向。
]

#figure(
  image("images/ray-parameter.png"),
  caption: [射线参数 $t$ 与起点、方向的关系],
) <fig-ray-parameter>

图 @fig-ray-parameter 也解释了为什么“射线”与“直线”不同：直线允许任意实数参数，而从 $bold(O)$ 出发的射线只保留 $t >= 0$ 的半支。改变 $bold(d)$ 的长度会改变参数刻度，却不会改变射线经过的几何位置。

Rust 中只需保存两个向量，并实现沿射线取点：

```rust
#[derive(Clone, Copy, Debug)]
pub struct Ray {
    pub origin: Point3,
    pub direction: Vec3,
}

impl Ray {
    pub fn at(self, t: f64) -> Point3 {
        self.origin + t * self.direction
    }
}
```

= 二、射线与摄像机

== 1. 针孔摄像机

先看一个位于原点、朝 $-z$ 方向观察的摄像机。设视口高度为 $h$、宽高比为 $a$，则视口宽度为 $a h$。若视口左下角为 $bold(Q)$，水平边向量为 $bold(H)$，竖直边向量为 $bold(V)$，归一化像素坐标为 $(s,t) in [0,1]^2$，那么穿过视口采样点的射线为
$
  bold(r)_(s,t)(lambda)=bold(O)+lambda(bold(Q)+s bold(H)+t bold(V)-bold(O)).
$

为了任意摆放摄像机，给定观察位置 $bold(P)$、目标点 $bold(T)$ 与参考上方向 $bold(v)_("up")$，构造右手正交基
$
  bold(w) &= frac(bold(P)-bold(T), norm(bold(P)-bold(T))), \
  bold(u) &= frac(bold(v)_("up") times bold(w), norm(bold(v)_("up") times bold(w))), \
  bold(v) &= bold(w) times bold(u).
$ <eq-camera-basis>
这里 $-bold(w)$ 是观察方向，$bold(u)$ 向右，$bold(v)$ 向上。垂直视场角为 $theta$、焦平面距离为 $d$ 时，视口高度与宽度分别是
$
  h=2d tan(theta/2), quad w_("viewport")=a h.
$

#figure(
  image("images/ray-camera.png"),
  caption: [针孔摄像机从视点穿过成像平面采样场景],
) <fig-ray-camera>

#tufted.theorem[摄像机基的正交性][
  只要参考上方向不与观察方向平行，式 @eq-camera-basis 得到的 $bold(u),bold(v),bold(w)$ 两两正交且均为单位向量。
]

#tufted.proof[
  叉积 $bold(v)_("up") times bold(w)$ 同时垂直于两个操作数，归一化后得到单位向量 $bold(u)$。又因 $bold(u) perp bold(w)$，所以 $bold(w) times bold(u)$ 的长度为 $1$，且垂直于两者。由叉积顺序可知三者保持右手定向。
]

== 2. 像素采样与抗锯齿

若每个像素只在中心发射一条射线，物体边缘会出现阶梯。像素其实覆盖一个小面积，正确的像素值是该区域上辐亮度的积分。最简单的办法是在像素内加入均匀随机扰动：

```rust
let u = (x as f64 + rng.f64()) / (width - 1) as f64;
let v = (y as f64 + rng.f64()) / (height - 1) as f64;
color += ray_color(&camera.ray(u, v, &mut rng), world, depth, &mut rng);
```

累加 $N$ 个样本后一定要先除以 $N$，再做 gamma 编码。忽略这一步会让颜色迅速饱和：

```rust
let scale = 1.0 / samples as f64;
let encode = |c: f64| {
    (256.0 * (scale * c).sqrt().clamp(0.0, 0.999)) as u8
};
```

#tufted.remark[为什么把 $t_("min")$ 设为一个小正数？][
  后续反弹射线从浮点计算得到的表面点出发。若接受 $t=0$ 附近的交点，它可能立即再次命中原表面，产生“阴影痤疮”。小型渲染器常用 $t_("min")=0.001$ 回避问题；更严谨的实现会按浮点误差和表面尺度偏移射线原点。
]

= 三、程序实现

== 1. 最小渲染循环

暂时没有物体时，可以用射线方向生成天空渐变。这一步用到单线性插值：给定两个端点值 $p_0,p_1$ 与权重 $alpha in [0,1]$，插值点为
$
  p(alpha)=(1-alpha)p_0+alpha p_1.
$

#figure(
  image("images/linear-interpolation.png"),
  caption: [单线性插值把线段按权重分割],
) <fig-linear-interpolation>

当 $alpha=0$ 时得到 $p_0$，当 $alpha=1$ 时得到 $p_1$，中间取值沿两者之间匀速变化。令单位射线方向的 $y$ 分量映射为 $alpha=(hat(d)_y+1)/2$，再在白色与蓝色之间插值：
$
  bold(C)(bold(d))=(1-alpha)(1,1,1)+alpha(0.5,0.7,1.0).
$

#figure(
  image("images/sky.png"),
  caption: [Rust 阶段程序输出的渐变蓝天],
) <fig-gradient-sky>

图 @fig-gradient-sky 是配套工程 `stages` 二进制程序生成的实际结果，而不是装饰性封面。它同时验证了摄像机射线方向、线性插值和 PPM 写出流程；在加入任何物体之前，先得到这幅图有助于把几何错误与图像输出错误分开。

渲染器的控制流由此确定：逐行访问像素；在像素内生成多个摄像机样本；查询场景；累加线性颜色；平均、编码并写入图片。下一篇只需要把“查询场景”替换为球体求交，并让命中点根据材质生成下一条射线。

== 2. 实现检查清单

- 向量应支持点积、叉积、逐分量乘法、归一化与下标访问。
- 射线方向可以不归一化，但公式之间必须保持一致。
- 颜色累加发生在线性空间，平均之后再 gamma 编码。
- 相机上方向与观察方向不能平行。
- 随机数生成器应显式传递；固定种子便于复现实验和测试。

配套 Rust 工程中的 `vec3.rs`、`ray.rs`、`camera.rs` 与 `main.rs` 实现了本篇全部结构。第二篇将在此基础上加入几何求交、材质散射与薄透镜景深。
