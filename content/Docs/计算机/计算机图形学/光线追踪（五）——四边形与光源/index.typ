#import "../../../index.typ": template, tufted
#show: template.with(
  title: "光线追踪（五）——四边形与光源",
  description: "实现平行四边形的射线求交与表面坐标，并以自发光材质和面积光源生成直接照明、阴影与 Cornell Box。",
)

#set math.equation(numbering: "(1)")

= 光线追踪（五）——四边形与光源

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/13772078")[夜蓝星炫]（Pixiv），#link("https://www.pixiv.net/artworks/97420493")[Source]_
]

只有球体的渲染器可以展示反射、折射和纹理，却很难构造墙壁、地板、灯板与盒子。本篇继续参考 #link("https://raytracing.github.io/books/RayTracingTheNextWeek.html")[《Ray Tracing: The Next Week》]：先加入平行四边形图元，再让普通几何通过自发光材质变成具有实际面积的光源。二者结合之后，就能搭建用于研究间接光照的经典 Cornell Box。

配套 Rust 程序位于 `src/bin/chapter5.rs`，生成四幅 $1280 times 720$ 结果图。程序采用每像素 $48$ 个样本，并对面积光源进行显式随机采样。

#tufted.remark[Perlin 噪声为何不作为本篇重点][
  Perlin 噪声改变的是纹理值随空间位置的变化方式；四边形求交、自发光和可见性测试都不依赖它。它可以像第四篇的棋盘纹理一样作为反照率或发光纹理使用，却不会改变本篇的几何与照明算法，因此这里不展开。后续讨论程序纹理时再系统介绍噪声、湍流与大理石纹理更合适。
]

= 一、四边形图元

== 1. 用角点和两条边定义平行四边形

这里的 `Quad` 并非任意四边形，而是由角点 $bold(Q)$ 与两条不平行的边向量 $bold(u),bold(v)$ 定义的平行四边形：
$
  bold(S)(alpha,beta)=bold(Q)+alpha bold(u)+beta bold(v),
  quad 0<=alpha<=1, quad 0<=beta<=1.
$ <eq-quad-param>
四个顶点依次为 $bold(Q)$、$bold(Q)+bold(u)$、$bold(Q)+bold(v)$ 和 $bold(Q)+bold(u)+bold(v)$。$bold(u)$ 与 $bold(v)$ 不必正交，因此这种表示也覆盖倾斜的平行四边形。

#figure(
  image("images/quad-coordinates.png"),
  caption: [射线与四边形所在平面相交，再用 $(alpha,beta)$ 判断交点是否落在边界内],
) <fig-quad-coordinates>

#tufted.definition[退化四边形][
  若 $bold(u) times bold(v)=bold(0)$，两条边平行，张成面积为零，无法定义唯一法线与二维坐标。构造器应拒绝这种输入，而不是让后续除法产生 `NaN`。
]

Rust 构造器预先缓存法线、平面常数和坐标变换所需的向量：

```rust
let n = u.cross(v);
assert!(n.length_squared() > 1e-16);
let normal = n.unit();
let d = normal.dot(q);
let w = n / n.length_squared();
```

== 2. 先与无限平面求交

四边形所在平面满足
$
  bold(n) dot bold(x)=D,
  quad bold(n)=frac(bold(u) times bold(v),norm(bold(u) times bold(v))),
  quad D=bold(n) dot bold(Q).
$ <eq-quad-plane>
把射线 $bold(r)(t)=bold(O)+t bold(d)$ 代入，得到
$
  t=frac(D-bold(n) dot bold(O),bold(n) dot bold(d)).
$ <eq-ray-quad-plane>
当分母接近零时，射线与平面平行；否则还要检查 $t$ 是否落在当前有效区间。这里只有通过平面测试，才值得继续判断有限边界。

```rust
let denominator = self.normal.dot(ray.direction);
if denominator.abs() < 1e-9 { return None; }
let t = (self.d - self.normal.dot(ray.origin)) / denominator;
if t < t_min || t > t_max { return None; }
```

== 3. 平面坐标与边界判断

令交点为 $bold(P)$，并记 $bold(p)=bold(P)-bold(Q)$。即使两条边并不正交，也可用
$
  bold(w)&=frac(bold(n),bold(n) dot bold(n)), quad bold(n)=bold(u) times bold(v),\
  alpha&=bold(w) dot (bold(p) times bold(v)),\
  beta&=bold(w) dot (bold(u) times bold(p))
$ <eq-quad-coordinates>
恢复式 @eq-quad-param 中的两个系数。随后只需检查 $alpha,beta in [0,1]$。这两个系数同时就是四边形的 UV 坐标，可以直接交给第四篇的图像纹理。

#tufted.theorem[平面坐标公式的正确性][
  若 $bold(p)=alpha bold(u)+beta bold(v)$ 且 $bold(u),bold(v)$ 不平行，则式 @eq-quad-coordinates 恢复出的数值恰为 $alpha,beta$。
]

#tufted.proof[
  对等式两边右叉乘 $bold(v)$，含 $beta bold(v) times bold(v)$ 的项为零，故
  $
    bold(p) times bold(v)=alpha(bold(u) times bold(v))=alpha bold(n).
  $
  再与 $bold(w)=bold(n)/(bold(n) dot bold(n))$ 点乘便得到 $alpha$。对等式左叉乘 $bold(u)$，同理得到 $beta$。
]

```rust
let planar = point - self.q;
let alpha = self.w.dot(planar.cross(self.v));
let beta  = self.w.dot(self.u.cross(planar));
if !(0.0..=1.0).contains(&alpha)
    || !(0.0..=1.0).contains(&beta) {
    return None;
}
```

== 4. 包围盒与更多平面图元

四边形的 AABB 可由四个顶点逐分量取最小值和最大值。若四边形与某个坐标平面平行，其中一个轴的厚度会严格为零；为避免擦边射线被浮点比较意外丢弃，应沿零厚度方向加入很小的 padding。

更重要的是，平面相交和二维坐标恢复可以复用。只需替换 $(alpha,beta)$ 的内部测试，就能得到不同图元：

- 三角形：$alpha>=0$、$beta>=0$ 且 $alpha+beta<=1$；
- 椭圆：把坐标移到中心后检查二次型；
- 圆环：检查半径平方位于内外半径之间；
- 遮罩平面：利用 UV 查询透明度纹理。

#figure(
  image("images/ch5-quadrilaterals.png"),
  caption: [Rust 程序渲染的五个不同朝向与倾斜程度的平行四边形],
) <fig-quadrilaterals>

= 二、光源与直接照明

== 1. 自发光材质

此前材质只有散射：射线命中表面后得到衰减颜色和下一条射线。光源还需要一个独立的发射项 $L_e$。对普通材质，$L_e=bold(0)$；对自发光材质，命中表面就返回指定辐亮度，而且可以不再散射。

路径递归因此从单纯的“衰减乘以后继路径”变为
$
  L(bold(r))=L_e+f_r L(bold(r)').
$ <eq-emission-recursion>
在完整路径追踪器中，第二项还包含方向余弦、概率密度和采样权重；Lambert 材质使用匹配的余弦加权采样时，这些因子可以部分约去。

```rust
match hit.material {
    Material::Light(emission) => emission,
    Material::Diffuse(albedo) => {
        // 估计直接光照，并继续追踪间接光
    }
}
```

#tufted.remark[发光颜色可以大于一][
  反照率表示反射比例，通常限制在 $[0,1]$；发射辐亮度不是反射比例，可以明显大于 $1$。例如 `Color::new(15.0, 13.5, 10.5)` 表示一个偏暖且很亮的光源，最后再通过曝光或色调映射压缩到显示范围。
]

把 `Light` 材质赋给球体、四边形或任何可求交对象，它就成为可见光源。背景色在这一阶段应设为黑色，否则天空本身仍会提供环境照明，使局部光源的作用不易辨认。

== 2. 从点光源到面积光源

点光源容易计算，但没有面积，通常产生完全锐利的阴影。四边形恰好可以同时充当可见几何和面积光源。对光源上的随机点
$
  bold(y)=bold(Q)+xi_1 bold(u)+xi_2 bold(v),
  quad xi_1,xi_2 in upright(U)(0,1),
$
从表面点 $bold(x)$ 向 $bold(y)$ 发射阴影射线。若中间没有物体，样本就对直接光照作出贡献。

#figure(
  image("images/area-light.png"),
  caption: [面积光源采样：不同光源位置可能被遮挡，也可能对表面可见],
) <fig-area-light>

均匀采样面积为 $A_L$ 的光源时，一次 Lambert 直接光照估计可写成
$
  hat(L)_d=
  frac(rho L_e A_L,pi)
  frac(max(0,bold(n)_x dot bold(omega))
        max(0,bold(n)_y dot (-bold(omega))),
       norm(bold(y)-bold(x))^2)
  V(bold(x),bold(y)),
$ <eq-area-light-estimator>
其中 $rho$ 是反照率，$bold(omega)$ 从 $bold(x)$ 指向 $bold(y)$，$V$ 是可见性函数。两个余弦分别描述接收面和发光面朝向，距离平方体现几何衰减，$A_L$ 来自均匀面积采样概率密度 $p_A=1/A_L$。

#tufted.definition[可见性函数][
  若连接 $bold(x)$ 与 $bold(y)$ 的开线段不与其他表面相交，则 $V(bold(x),bold(y))=1$；否则为 $0$。实现时用 $[epsilon,1-epsilon]$ 作为阴影射线参数区间，既避免表面自相交，也避免把采样到的光源端点误判成遮挡物。
]

== 3. 光源尺寸与软阴影

面积光源上的每个位置都像一个微小光源。若遮挡物只挡住其中一部分，表面仍会收到其余部分的光，形成半影；光源越大，从一个像素看见的光源位置差异越大，阴影边界通常越柔和。

#figure(
  image("images/ch5-small-area-light.png"),
  caption: [较小面积光源：照度较低，阴影边界较集中],
) <fig-small-light>

#figure(
  image("images/ch5-large-area-light.png"),
  caption: [较大面积光源：覆盖立体角更大，阴影具有更宽的半影],
) <fig-large-light>

这组对照保持光源表面辐亮度不变，因此增大面积也会增大总功率。若只想比较阴影软硬而保持总功率近似不变，应按面积的倒数缩放 $L_e$。另一方面，每像素只取少量光源样本会产生明显噪点；增加样本、分层采样，或按光源对表面的贡献做重要性采样，都能降低方差。

= 三、用四边形搭建场景

== 1. 六个面组成长方体

给定轴对齐长方体的对角点 $bold(a),bold(b)$，先逐分量求 `min`、`max`，再构造 $bold(d)_x,bold(d)_y,bold(d)_z$ 三条边。每个面都是一个起点加两条边向量，共六个 `Quad`。注意相对面的边向量顺序应反转，使外法线方向一致；即使命中记录会根据入射射线翻转法线，稳定的几何朝向对单面发光和背面剔除仍很重要。

```rust
let faces = [
    Quad::new(point(min.x, min.y, max.z),  dx,  dy, mat),
    Quad::new(point(max.x, min.y, max.z), -dz,  dy, mat),
    Quad::new(point(max.x, min.y, min.z), -dx,  dy, mat),
    // 左、顶、底三个面……
];
```

这些面仍是普通 `Hittable`，可以和球体一起放进第三篇的 BVH。这里无需为“盒子”重新设计求交公式；组合已有图元往往比增加特殊分支更容易验证。

== 2. Cornell Box

Cornell Box 用白色地板、顶板与后墙，加上红、绿侧墙和顶部面积光源，构造一个几何简单但光照关系丰富的封闭场景。彩色墙面对其他表面的间接反射会形成 color bleeding；顶部灯板则提供明确的面积光源和软阴影。

#figure(
  image("images/ch5-cornell-box.png"),
  caption: [由四边形墙面、四边形面积光源、六面体和球体组成的 Cornell Box],
) <fig-cornell-box>

本篇程序为便于快速演示，显式估计直接光照，并以少量漫反射递归近似间接光；它已经能够展示遮挡、半影和墙面染色，但并非最终的无偏积分器。若完全采用第一篇渲染方程的路径采样，必须记录每种采样策略的概率密度。下一阶段进一步加入“按光源采样”和多重重要性采样，才能同时稳定处理小光源与复杂材质。

= 四、实现检查清单

- 四边形两条边不得平行，构造时缓存法线、$D$ 与 $bold(w)$。
- 先求射线与无限平面交点，再用 $(alpha,beta)$ 做有限边界测试。
- 把 $(alpha,beta)$ 写入命中记录，直接作为四边形 UV。
- 对零厚度 AABB 添加微小 padding，避免 BVH 擦边漏交。
- 发射项与散射项分开；普通材质默认发射黑色。
- 阴影射线使用带偏移的起点和不包含端点的参数区间。
- 面积光源采样必须包含面积、双侧余弦和距离平方等几何因子。
- 光源尺寸决定半影范围，光源样本数决定噪声水平。

四边形补足了平面几何，自发光材质则让几何本身成为光源。渲染器从依赖天空背景的球体展示，迈向了能够组织室内空间、可见灯具、直接阴影与间接反射的完整场景。
