#import "../../../index.typ": template, tufted
#show: template.with(
  title: "光线追踪（三）——BVH加速结构",
  description: "推导 AABB 的 slab 求交算法，构建并遍历二叉 BVH，并讨论划分策略、复杂度与工程细节。",
)

#set math.equation(numbering: "(1)")

= 光线追踪（三）——BVH 加速结构

#tufted.full-width[
    #image("images/header.jpg")
]

前两篇的线性场景列表会让每条射线测试全部 $N$ 个物体。若一张图有 $P$ 个像素、每像素 $S$ 个样本、平均每条路径 $D$ 段射线，粗略求交次数是 $O(P S D N)$。路径追踪会把任何低效放大数十亿次，因此加速结构不是锦上添花，而是渲染器的核心组件。

包围体层次结构（Bounding Volume Hierarchy，BVH）把若干物体包进简单盒子，再递归地把盒子组成树。射线若错过父盒，就不可能命中父盒内的任何物体，整棵子树都可跳过。

#figure(
  image("images/bvh.png"),
  caption: [对象空间中的嵌套包围盒及其二叉层次],
) <fig-bvh>

= 一、BVH 的几何基础

== 1. AABB 与 slab 方法

轴对齐包围盒（Axis-Aligned Bounding Box，AABB）由两个角点描述：
$
  bold(p)_("min")=(x_("min"),y_("min"),z_("min")), quad
  bold(p)_("max")=(x_("max"),y_("max"),z_("max")).
$
它不是体积最小的包围盒，但构造和求交非常便宜。把盒子看成三个坐标轴方向的 slab（两平行平面之间的区域）。以 $x$ 轴为例，把射线分量 $x(t)=O_x+t d_x$ 分别代入两个平面：
$
  t_x^0=(x_("min")-O_x)/d_x, quad
  t_x^1=(x_("max")-O_x)/d_x.
$
若 $d_x<0$，进入与离开次序相反，所以交换两者。三维射线位于盒内的参数区间是三个一维区间的交：
$
  t_("enter")=max(t_x^0,t_y^0,t_z^0,t_("min")), quad
  t_("exit")=min(t_x^1,t_y^1,t_z^1,t_("max")).
$ <eq-slab>
仅当 $t_("enter") <= t_("exit")$ 时命中。

#tufted.theorem[slab 判定的正确性][
  一条射线与 AABB 相交，当且仅当它分别位于 $x,y,z$ 三个 slab 内的参数区间存在公共部分。
]

#tufted.proof[
  AABB 是三个 slab 的集合交。射线在每个 slab 内对应一个闭参数区间，因此它在 AABB 内的参数集合正是三个区间之交。有限闭区间的交非空，当且仅当所有下界的最大值不大于所有上界的最小值，这就是式 @eq-slab。
]

Rust 实现逐轴收紧有效区间：

```rust
pub fn hit(&self, ray: &Ray, mut t_min: f64, mut t_max: f64) -> bool {
    for axis in 0..3 {
        let inv_d = 1.0 / ray.direction[axis];
        let mut t0 = (self.min[axis] - ray.origin[axis]) * inv_d;
        let mut t1 = (self.max[axis] - ray.origin[axis]) * inv_d;
        if inv_d < 0.0 { std::mem::swap(&mut t0, &mut t1); }
        t_min = t_min.max(t0);
        t_max = t_max.min(t1);
        if t_max < t_min { return false; }
    }
    true
}
```

#tufted.remark[平行射线与零方向分量][
  IEEE 754 浮点数中，非零数除以 $plus.minus 0$ 得到 $plus.minus infinity$，上述写法在常见情况下会自然工作；但 $0/0$ 会产生 `NaN`。工业实现往往预先计算逆方向与符号，并对平行于 slab 的射线显式判断，以保证所有边界情况可控。
]

两个 AABB 的最小公共 AABB 逐分量取极值：
$
  bold(p)_("min")=min(bold(a)_("min"),bold(b)_("min")), quad
  bold(p)_("max")=max(bold(a)_("max"),bold(b)_("max")).
$
这里的 `min` 和 `max` 是逐分量运算。BVH 自底向上构建时，父节点包围盒就是两个孩子包围盒的并盒。

== 2. BVH 的不变量

#tufted.definition[BVH 节点][
  一个二叉 BVH 节点保存左孩子、右孩子以及同时包围二者的 AABB。叶节点包含一个或少量真实图元；内部节点只负责空间裁剪，不直接表示可见表面。
]

正确实现应始终维持两个不变量：

1. 节点盒包含该节点子树中的每个图元；
2. 任一孩子的盒完全包含于父节点盒。

BVH 是“对象划分”：每个图元属于某个叶节点，空间可以重叠。它不同于均匀网格、八叉树或 k-d tree 等“空间划分”结构。BVH 对动态对象、尺度差异大的场景和通用图元都很友好，因此在离线与实时光追中都很常见。

= 二、BVH 的构建

== 1. 从中位数划分构建二叉树

一个简洁且稳定的构建算法是：

1. 计算当前对象集合的总包围盒；
2. 选择跨度最大的坐标轴；
3. 按对象包围盒在该轴上的位置排序；
4. 在中位数处分成等量两组，递归构建；
5. 合并孩子盒得到父盒。

若每层都较平衡，树高是 $O(log N)$。逐层排序的朴素实现一般为 $O(N log^2 N)$；在每层用线性选择或一次性维护有序数组，可接近 $O(N log N)$。

```rust
let extent = global.max - global.min;
let axis = if extent.x > extent.y && extent.x > extent.z { 0 }
    else if extent.y > extent.z { 1 } else { 2 };

objects.sort_by(|a, b| {
    a.bounding_box().min[axis]
        .partial_cmp(&b.bounding_box().min[axis])
        .unwrap_or(Ordering::Equal)
});
let right_objects = objects.split_off(objects.len() / 2);
let left = BvhNode::build(objects);
let right = BvhNode::build(right_objects);
let bbox = Aabb::surrounding(left.bounding_box(), right.bounding_box());
```

按盒的最小坐标排序足以完成教程实现；按质心排序通常更符合直觉。最大跨度轴比随机轴更稳定，但仍不直接衡量遍历成本。

== 2. 表面积启发式

等量分组可能产生高度重叠的孩子盒，射线便不得不同时访问两边。表面积启发式（Surface Area Heuristic，SAH）估计一次划分的期望成本：
$
  C = C_("trav")
  + frac(A_L,A_P) N_L C_("isect")
  + frac(A_R,A_P) N_R C_("isect").
$ <eq-sah>
其中 $A_P,A_L,A_R$ 是父、左、右盒表面积，$N_L,N_R$ 是图元数。直观上，射线命中孩子盒的概率近似与其表面积占父盒的比例成正比。构建器枚举候选切分位置，选择 $C$ 最小者；若划分成本还不如直接做叶节点，就停止递归。

#tufted.proposition[BVH 并不保证 $O(log N)$ 查询][
  平衡树只保证节点层数较小，不保证射线只访问一条根到叶路径。若孩子包围盒严重重叠，一条射线可能访问大量节点，最坏情况仍为 $O(N)$。
]

#tufted.proof[
  构造所有图元包围盒都覆盖同一区域的场景。任何命中该区域的射线都会通过每个内部盒测试，从而访问所有叶节点，工作量与图元数成正比。
]

这正是 SAH 关注表面积和重叠、而不只追求“树看起来平衡”的原因。实际工程常用分桶 SAH：把质心范围分成十几个桶，只在桶边界尝试划分，以较低构建成本得到接近完整 SAH 的树。

= 三、遍历与工程实现

== 1. 由近到远遍历

节点遍历先测试自身包围盒；若错过，立即返回。若命中，则查询两个孩子。查询第一个孩子得到交点 $t_L$ 后，第二个孩子只需在 $[t_(min),t_L]$ 内寻找，因为更远的交点不可见。

```rust
if !self.bbox.hit(ray, t_min, t_max) { return None; }
let left_hit = self.left.hit(ray, t_min, t_max);
let right_max = left_hit.map_or(t_max, |h| h.t);
self.right.hit(ray, t_min, right_max).or(left_hit)
```

这个版本总先访问左孩子，逻辑正确但不总是最快。若 AABB 测试同时返回进入参数，可以先访问 $t_("enter")$ 更小的孩子，更早获得近交点并缩短另一个孩子的区间。阴影射线只关心“是否存在遮挡”，找到任意交点即可立刻退出。

#tufted.remark[一个常见逻辑误区][
  “左孩子未命中，所以右孩子必命中”是错误的；射线可能只穿过父包围盒的空白区域。父盒命中只表示子树中“可能”有交点，两个孩子仍必须独立测试。
]

== 2. 静态、动态与实例化场景

静态场景只需构建一次 BVH。若物体移动但拓扑不变，可以保持树结构，仅自底向上重新计算盒子，这称为 refit；它很快，但多帧后树的划分质量可能恶化，需要重建。

大型场景通常采用两层结构：

- BLAS（Bottom-Level Acceleration Structure）包围单个网格的三角形；
- TLAS（Top-Level Acceleration Structure）包围网格实例及其变换。

同一个网格出现许多次时，BLAS 只保存一份；TLAS 叶节点引用实例变换。射线进入实例前转换到局部坐标，命中结果再转换回世界坐标。这是现代硬件光线追踪 API 的基本组织方式。

== 3. 复杂度之外的工程细节

- 盒边界应略微扩张，避免零厚度三角形盒和舍入误差导致漏交。
- 预计算射线逆方向能减少每个 AABB 测试中的除法。
- 节点若紧凑连续存储，比大量堆指针更利于 CPU 缓存和 SIMD。
- 叶节点容纳 2–8 个图元常比“每叶一个”更划算，因为能减少内部节点和盒测试。
- 构建与遍历应分开基准测试；最快构建的树未必渲染最快。
- 统计“每条射线测试的盒数和图元数”通常比只看总秒数更能解释性能变化。

= 四、结果与验证

== 1. 一次 BVH 开关对照

下面两次运行均由 Rust gallery 在 $1280 times 720$ 分辨率、每像素 $6$ 个样本下完成，并使用相同场景、相机与随机种子。关闭 BVH 时，渲染器逐个测试场景对象，本次实测耗时 $6927$ 毫秒：

#figure(
  image("images/bvh-off.png"),
  caption: [Rust 线性对象列表的渲染结果（6927 ms）],
) <fig-bvh-off>

启用 BVH 后，画面内容保持一致，本次实测耗时 $1930$ 毫秒：

#figure(
  image("images/bvh-on.png"),
  caption: [Rust BVH 的渲染结果（1930 ms）],
) <fig-bvh-on>

这次对照的查询与着色阶段获得约 $6927/1930 approx 3.59$ 倍加速，耗时减少约 $72.1%$。两幅图由同一 Rust 渲染函数生成，区别仅在传入 `HittableList` 还是 `BvhNode`；实际数据同时写入 `gallery/bvh-benchmark.txt`。这个结果仍不是 BVH 的固定倍率：构建策略、图元数量、光线分布、编译优化和计时范围都会影响结果。

== 2. 验证 BVH 没有改变画面

加速结构只能改变查询顺序，不能改变最近交点。建议保留线性 `HittableList` 作为参考实现，并做三类测试：

1. 随机生成射线，比较线性列表与 BVH 返回的命中与 $t$；
2. 单独测试平行射线、盒面起点、负方向和极小方向分量；
3. 固定随机种子分别渲染两张图，逐像素比较结果。

配套工程的测试验证了球体最近根、AABB 漏交和 BVH 最近命中。教程版选择最大跨度轴与中位数划分，结构清楚且已经能显著减少求交；若要继续扩展，可以依次加入三角形、分桶 SAH、近优先遍历和多线程分块渲染。
