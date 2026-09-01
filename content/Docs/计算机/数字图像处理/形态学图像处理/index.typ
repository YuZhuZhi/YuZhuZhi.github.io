#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "形态学图像处理",
  description: "结构元素驱动的形状分析与二值、灰度形态学",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

= 形态学图像处理

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

形态学图像处理关心的不是“像素值相差多少”，而是一个形状能否容纳、碰到或避开另一个小形状，这个小形状称为结构元素。把结构元素在图像上平移，就能把局部几何关系转化为腐蚀、膨胀、开闭、边界、连通量和骨架等可计算对象。#cite(<dip-book>)

需要一开始就固定一点：结构元素的形状、尺寸与原点就是本方法的模型。任何形态学结论都是相对这个模型而言的——同一个目标在小结构元素下可能连成一片，在大结构元素下却被分开；原点偏置还会造成方向性偏差。因此本章的要旨不是记住运算符，而是先看清“用哪个结构元素、在什么邻接约定下”再下结论。

#tufted.definition[二值图像的集合表示][设前景像素取 1、背景取 0。二值图像可以等价表示为格点集合
$
  A={(x,y) in ZZ^2 | f(x,y)=1}.
$
形态学集合运算只追踪前景集合 $A$；若程序以白色表示前景，则非零像素对应 $A$。]

#tufted.definition[结构元素][结构元素 $B subset.eq ZZ^2$ 是带有指定原点的小型格点集合。它在位置 $z$ 处的平移为
$
  B_(z)={b+z divides b in B},
$
关于原点的反射为 $hat(B)={-b divides b in B}$。结构元素的形状、尺寸和原点共同决定运算所检测的方向与尺度。]

#figure(
  image("images/structuring-element.png", width: 65%, alt: "二值集合上平移的方形结构元素及其原点"),
  caption: [蓝色格点构成前景集合 $A$；红色半透明方格是平移到位置 $z$ 的结构元素 $B_(z)$，红点是结构元素原点。]
)

结构元素不是越大越好。尺寸应当与目标尺度相关：过小的结构元素容纳不下目标尺度的噪声，无法真正去除；过大的结构元素则会抹掉窄连接、尖角和小目标。形状携带连通性语义：十字形偏向四邻接，方形同时连接对角方向，圆盘则近似各向同性。文中先建立二值集合定义，再给出灰度级扩展。

#tufted.remark[运算符约定][本章沿用数字图像处理教材中的记号：$A minus B$ 表示形态学腐蚀，$A plus B$ 表示形态学膨胀。这里的 $minus$、$plus$ 是专用运算符，不是集合差与普通加法；普通集合差将另行说明。]

#html.hr()
= 一、腐蚀与膨胀

== 1. 腐蚀

#tufted.definition[二值腐蚀][集合 $A$ 被结构元素 $B$ 腐蚀定义为
$
  A minus B={z divides B_(z) subset.eq A}.
$
也就是说，只有当平移后的整个 $B$ 都落在前景内时，原点位置 $z$ 才保留为前景。]

腐蚀会让前景边界向内退缩。退缩量不是固定“一个像素”，而由结构元素从原点到边界的距离和方向决定。它可以消除比结构元素小的亮点、断开狭窄连接、缩小物体，并为边界提取和距离分析提供基础。若结构元素原点不在几何中心，腐蚀结果还会产生方向偏移。

== 2. 膨胀

#tufted.definition[二值膨胀][集合 $A$ 被结构元素 $B$ 膨胀定义为
$
  A plus B={z divides hat(B)_(z) ∩ A != emptyset}.
$
即反射后的结构元素只要与前景至少相交一次，位置 $z$ 就成为前景。对中心对称结构元素有 $hat(B)=B$。]

膨胀让前景向外扩张，可填补比结构元素小的缝隙、连接邻近物体、加粗细线。它也会放大前景噪声，所以“先膨胀再腐蚀”与“先腐蚀再膨胀”具有不同作用，不能交换顺序。

#figure(
  image("images/erosion-dilation-series.png", width: 100%, alt: "同一二值集合腐蚀和膨胀前后的三幅对比图"),
  caption: [(a) 原二值集合；(b) 使用 $11 times 11$ 椭圆结构元素腐蚀，边界内缩且窄连接减弱；(c) 使用同一结构元素膨胀，边界外扩且邻近区域更易连接。]
)

```python
import cv2
import numpy as np


def binary_erode_dilate(
    binary: np.ndarray,
    kernel_size: int = 5,
) -> tuple[np.ndarray, np.ndarray]:
    if binary.ndim != 2:
        raise ValueError("binary image must be two-dimensional")
    if kernel_size <= 0 or kernel_size % 2 == 0:
        raise ValueError("kernel_size must be a positive odd number")

    foreground = np.where(binary > 0, 255, 0).astype(np.uint8)
    kernel = cv2.getStructuringElement(
        cv2.MORPH_ELLIPSE,
        (kernel_size, kernel_size),
    )
    eroded = cv2.erode(
        foreground,
        kernel,
        iterations=1,
        borderType=cv2.BORDER_CONSTANT,
        borderValue=0,
    )
    dilated = cv2.dilate(
        foreground,
        kernel,
        iterations=1,
        borderType=cv2.BORDER_CONSTANT,
        borderValue=0,
    )
    return eroded, dilated
```

== 3. 对偶性

#tufted.theorem[腐蚀与膨胀的对偶性][相对于全集的补集记为上标 $c$，则
$
  (A minus B)^c=A^c plus hat(B),
  quad
  (A plus B)^c=A^c minus hat(B).
$]

#tufted.proof[位置 $z$ 不属于 $A minus B$，等价于 $B_(z)$ 至少有一点落入 $A^c$；把这个相交条件改写为反射结构元素的膨胀，就得到第一式。第二式可对第一式同时取补集并将 $B$ 换成 $hat(B)$ 得到。]

#figure(
  image("images/duality.png", width: 72%, alt: "前景集合取补集后腐蚀和膨胀互相转换的示意"),
  caption: [取补集会交换前景与背景；同时反射结构元素后，腐蚀与膨胀互为对偶。]
)

对偶性既是理论关系，也是实现检查工具。例如用“补集—膨胀—补集”计算的腐蚀应与直接腐蚀一致。若不一致，通常是边界补充值、前景约定或非对称结构元素反射处理不同。

== 4. 灰度级腐蚀与膨胀

灰度形态学把二值集合的“完全包含”和“发生相交”推广为局部最小值与最大值。对平坦结构元素 $B$，
$
  (f minus B)(x,y)&=min_((s,t) in B) f(x+s,y+t),\
  (f plus B)(x,y)&=max_((s,t) in B) f(x-s,y-t).
$
腐蚀选择邻域最暗值，因此缩小亮区、扩大暗区；膨胀选择邻域最亮值，因此扩大亮区、缩小暗区。非平坦结构元素还带高度函数 $b(s,t)$，相应公式变为 $min(f-b)$ 和 $max(f+b)$。

#figure(
  image("images/gray-morphology-series.png", width: 100%, alt: "灰度图像腐蚀膨胀开闭运算的五幅系列图"),
  caption: [(a) 原灰度图；(b) 灰度腐蚀；(c) 灰度膨胀；(d) 灰度开运算；(e) 灰度闭运算。亮物体在腐蚀中收缩、在膨胀中扩张。]
)

```python
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11))
gray_eroded = cv2.erode(gray, kernel)
gray_dilated = cv2.dilate(gray, kernel)
```

#html.hr()
= 二、开运算与闭运算

== 1. 开运算

#tufted.definition[开运算][集合 $A$ 被 $B$ 开运算定义为
$
  A circle B=(A minus B) plus B.
$
先腐蚀删除容不下结构元素的前景，再膨胀恢复其余区域的大致尺寸。]

开运算能删除小亮点、切断细连接、平滑向外尖出的边界。它不会恢复在腐蚀阶段已经完全消失的分量，因此不是简单的“缩小后放大到原样”。

== 2. 闭运算

#tufted.definition[闭运算][集合 $A$ 被 $B$ 闭运算定义为
$
  A bullet B=(A plus B) minus B.
$
先膨胀跨越小缺口，再腐蚀恢复整体尺寸。]

闭运算适合填小孔、连接窄裂缝、平滑向内凹陷。开与闭互为对偶，但实际去噪时仍要依据噪声极性选择：白色孤立点使用开运算，黑色小孔使用闭运算。

#tufted.theorem[开闭运算的基本性质][若结构元素包含原点，则开运算具有反扩张性 $A circle B subset.eq A$，闭运算具有扩张性 $A subset.eq A bullet B$；二者均幂等：
$
  (A circle B) circle B=A circle B,
  quad
  (A bullet B) bullet B=A bullet B.
$]

#figure(
  image("images/open-close-series.png", width: 82%, alt: "开闭运算分别处理白点和黑孔噪声的四幅图"),
  caption: [(a) 含白色孤立噪声的二值图；(b) 开运算结果；(c) 含黑色小孔噪声的二值图；(d) 闭运算结果。]
)

== 3. 灰度级开闭运算

灰度开运算仍是先灰度腐蚀后灰度膨胀，用于压制比结构元素小的亮细节；灰度闭运算先膨胀后腐蚀，用于填平小暗细节。白顶帽 $T_(w)=f-(f circle B)$ 提取小亮结构，黑底帽 $T_(b)=(f bullet B)-f$ 提取小暗结构。

```python
opened = cv2.morphologyEx(image, cv2.MORPH_OPEN, kernel)
closed = cv2.morphologyEx(image, cv2.MORPH_CLOSE, kernel)
white_tophat = cv2.morphologyEx(image, cv2.MORPH_TOPHAT, kernel)
black_tophat = cv2.morphologyEx(image, cv2.MORPH_BLACKHAT, kernel)
```

#html.hr()
= 三、击中—击不中变换

#tufted.definition[击中—击不中变换][设 $B=(B_(1),B_(2))$，其中 $B_(1)$ 描述必须命中的前景形状，$B_(2)$ 描述必须命中的背景形状，且二者不相交。变换定义为
$
  A ⊛ B=(A minus B_(1)) ∩ (A^c minus B_(2)).
$
结果中的位置同时满足前景约束和背景约束。]

#figure(
  image("images/hit-miss-diagram.png", width: 67%, alt: "击中击不中模板的前景命中点与背景命中点"),
  caption: [绿色圆点属于 $B_(1)$，必须落在前景；红色叉属于 $B_(2)$，必须落在背景；未标记位置不作约束。]
)

击中—击不中不是只寻找“像素相同”的模板匹配。它把局部结构拆成必须存在与必须不存在的两部分，适合检测端点、拐角、分叉和特定排列。旋转目标需要同时旋转模板并合并各方向结果。

#figure(
  image("images/hit-miss-series.png", width: 100%, alt: "T形结构的击中击不中检测结果"),
  caption: [(a) 含多个局部结构的二值图；(b) 击中—击不中输出位置；(c) 将命中位置用红圈叠加回原图。]
)

```python
# 1 表示必须为前景，-1 表示必须为背景，0 表示不关心。
template = np.array(
    [
        [-1, 1, -1],
        [0, 1, 0],
        [0, 1, 0],
    ],
    dtype=np.int8,
)
binary01 = (binary > 0).astype(np.uint8)
hits = cv2.morphologyEx(binary01, cv2.MORPH_HITMISS, template)
```

灰度图没有天然的前景与背景集合。常见扩展是先按一个或多个灰度阈值构造水平集，再对每个水平集应用二值击中—击不中；另一种做法是用灰度腐蚀分别约束局部下界与上界。必须明确所采用的灰度模板定义，不能直接把二值 `MORPH_HITMISS` 用于任意灰度数组。

#html.hr()
= 四、边界提取

#tufted.definition[内边界][使用包含原点的小结构元素 $B$，集合 $A$ 的形态学内边界定义为
$
  beta(A)=A-(A minus B).
$
腐蚀后仍保留的是内部，原集合减去内部便得到靠前景一侧的边界。]

外边界可写为 $(A plus B)-A$；形态学梯度为 $(A plus B)-(A minus B)$，同时覆盖内外两侧。结构元素越大，所得边界越厚。灰度形态学梯度用膨胀图减腐蚀图，能突出局部亮暗跨度。

```python
kernel = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
inner_boundary = cv2.subtract(binary, cv2.erode(binary, kernel))
outer_boundary = cv2.subtract(cv2.dilate(binary, kernel), binary)
gradient = cv2.morphologyEx(gray, cv2.MORPH_GRADIENT, kernel)
```

#html.hr()
= 五、孔洞填充

#tufted.definition[孔洞][二值前景 $A$ 中的孔洞是 $A^c$ 内不与图像边界连通的背景连通分量。因而“黑色区域”不一定是孔洞；只有被前景完全包围的背景才是孔洞。]

若已知孔洞中的一个种子点集合 $X_(0)$，可以在补集内做受限膨胀：
$
  X_(k)=(X_(k-1) plus B) ∩ A^c,
  quad k=1,2,dots
$
直到 $X_(k)=X_(k-1)$。最终填充结果是 $A ∪ X_(k)$。交集约束阻止生长穿过前景边界。

#figure(
  image("images/boundary-fill-series.png", width: 82%, alt: "二值图像边界提取与孔洞填充的四幅图"),
  caption: [(a) 含孔洞的原集合；(b) 形态学内边界；(c) 与图像边界不连通的背景孔洞；(d) 将 (c) 并入前景后的填充结果。]
)

```python
def fill_holes(binary: np.ndarray) -> np.ndarray:
    foreground = np.where(binary > 0, 255, 0).astype(np.uint8)
    reachable_background = foreground.copy()
    flood_mask = np.zeros(
        (foreground.shape[0] + 2, foreground.shape[1] + 2),
        dtype=np.uint8,
    )
    cv2.floodFill(reachable_background, flood_mask, (0, 0), 255)
    holes = cv2.bitwise_not(reachable_background)
    return cv2.bitwise_or(foreground, holes)
```

上述洪泛实现从图像边界背景出发，先找“不是孔洞”的背景，再取反得到全部孔洞。若左上角不是背景，应从全部边界背景像素建立种子，或先添加一圈背景边框。

#html.hr()
= 六、连通分量提取

#tufted.definition[连通分量][在指定的四邻接或八邻接关系下，若前景集合中的任意两点之间都存在完全位于前景内的路径，则该集合连通。极大的连通子集称为连通分量。]

给定分量内的种子 $p$，可令 $X_(0)={p}$，迭代
$
  X_(k)=(X_(k-1) plus B) ∩ A
$
直到稳定。这里与孔洞填充的形式相同，但约束集合从 $A^c$ 换成 $A$。实际程序通常用 BFS、DFS 或两遍标记算法一次提取所有分量。

#figure(
  image("images/components-hull-series.png", width: 100%, alt: "二值集合、连通分量着色和凸壳轮廓"),
  caption: [(a) 原二值集合；(b) 八邻接连通分量分别着色；(c) 每个外部轮廓的凸壳以红线标出。]
)

```python
count, labels, statistics, centroids = cv2.connectedComponentsWithStats(
    (binary > 0).astype(np.uint8),
    connectivity=8,
)

for label in range(1, count):
    area = statistics[label, cv2.CC_STAT_AREA]
    left = statistics[label, cv2.CC_STAT_LEFT]
    top = statistics[label, cv2.CC_STAT_TOP]
    width = statistics[label, cv2.CC_STAT_WIDTH]
    height = statistics[label, cv2.CC_STAT_HEIGHT]
    component_mask = np.where(labels == label, 255, 0).astype(np.uint8)
```

#html.hr()
= 七、凸壳

#tufted.definition[凸集与凸壳][若集合 $C$ 中任意两点之间的整条线段都包含于 $C$，则 $C$ 为凸集。集合 $A$ 的凸壳 $H(A)$ 是包含 $A$ 的最小凸集。]

凸壳填平所有向内凹陷，但不会简单地把包围盒全部填满。数字图像中既可用一组方向性击中—击不中模板迭代填补凹口，也可先提取轮廓，再使用几何算法计算凸壳顶点。后者更直接，并能返回有序多边形。

```python
contours, _ = cv2.findContours(
    binary,
    cv2.RETR_EXTERNAL,
    cv2.CHAIN_APPROX_SIMPLE,
)
hull_mask = np.zeros_like(binary)
for contour in contours:
    hull = cv2.convexHull(contour)
    cv2.fillConvexPoly(hull_mask, hull, 255)
```

若多个物体必须分别处理，应先按连通分量或外轮廓计算各自凸壳；把所有前景点一次送入 `convexHull` 会得到包围全部物体的单个大凸壳。

#html.hr()
= 八、细化与粗化

== 1. 细化

#tufted.definition[细化][使用击中—击不中模板 $B$ 的细化定义为
$
  A ⊗ B=A-(A ⊛ B).
$
它删除符合模板的边界点。实际细化使用一组旋转模板循环处理，直到没有像素继续改变。]

细化的目标是把宽线条压缩为单像素宽表示，同时保持端点、连通性和主要拓扑。不能用普通腐蚀替代，因为腐蚀会从所有方向同时收缩并最终删除整个物体。Zhang–Suen 算法在两个子迭代中检查八邻域：邻居数必须在 2 到 6 之间，按圆周从 0 到 1 的跃迁次数必须为 1，再利用两组方向条件避免同时删除关键连接点。

== 2. 粗化

#tufted.definition[粗化][使用模板 $B$ 的粗化定义为
$
  A ⊙ B=A ∪ (A ⊛ B).
$
它把满足局部背景条件的位置加入前景，是细化在补集意义下的对偶。]

粗化可以连接断裂骨架、恢复线宽或逐步构造凸壳，但同样需要终止条件或约束集合，否则会持续扩张。实际中常把新增像素限制在掩膜 $M$ 内：$A_(k)=(A_(k-1) ⊙ B) ∩ M$。

#figure(
  image("images/thin-thick-skeleton-series.png", width: 82%, alt: "二值形状的细化粗化和形态学骨架结果"),
  caption: [(a) 加粗后的二值形状；(b) Zhang–Suen 细化结果；(c) 对细线作受限粗化的示意结果；(d) 原集合的形态学骨架。]
)

```python
def one_thinning_pass(binary01: np.ndarray, phase: int) -> np.ndarray:
    source = binary01.copy()
    remove = []
    for y in range(1, source.shape[0] - 1):
        for x in range(1, source.shape[1] - 1):
            if source[y, x] == 0:
                continue
            neighbors = [
                source[y - 1, x], source[y - 1, x + 1],
                source[y, x + 1], source[y + 1, x + 1],
                source[y + 1, x], source[y + 1, x - 1],
                source[y, x - 1], source[y - 1, x - 1],
            ]
            count = sum(neighbors)
            transitions = sum(
                neighbors[index] == 0
                and neighbors[(index + 1) % 8] == 1
                for index in range(8)
            )
            if not 2 <= count <= 6 or transitions != 1:
                continue
            north, east, south, west = (
                neighbors[0], neighbors[2], neighbors[4], neighbors[6]
            )
            if phase == 0:
                safe = north * east * south == 0 and east * south * west == 0
            else:
                safe = north * east * west == 0 and north * south * west == 0
            if safe:
                remove.append((y, x))
    for y, x in remove:
        source[y, x] = 0
    return source
```

#html.hr()
= 九、骨架

#tufted.definition[形态学骨架][令 $A minus k B$ 表示用 $B$ 连续腐蚀 $k$ 次，$K$ 是使 $A minus K B$ 非空的最大整数。骨架层定义为
$
  S_(k)(A)=(A minus k B)-((A minus k B) circle B),
$
完整骨架为
$
  S(A)=∪_(k=0)^K S_(k)(A).
$]

骨架可以理解为所有最大内接结构元素中心的集合。若一个以骨架点为中心的结构元素仍能增大而保持在 $A$ 内，它就不是最大内接元素。骨架适合描述形状的中心线、分支和局部厚度，但对边界噪声敏感：一个很小的凸起也可能产生很长的伪分支，因此常先平滑边界或在骨架后按分支长度剪枝。

#figure(
  image("images/skeleton-disks.png", width: 60%, alt: "形状内部最大圆盘中心及其连接形成骨架"),
  caption: [虚线圆表示局部最大内接圆，其圆心连接形成骨架；圆半径同时记录该处到边界的距离。]
)

#tufted.theorem[由骨架重建集合][若保留全部骨架层及其腐蚀次数，则
$
  A=∪_(k=0)^K (S_(k)(A) plus k B).
$]

```python
def morphological_skeleton(binary: np.ndarray) -> np.ndarray:
    work = np.where(binary > 0, 255, 0).astype(np.uint8)
    skeleton = np.zeros_like(work)
    kernel = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))

    while cv2.countNonZero(work) > 0:
        eroded = cv2.erode(work, kernel)
        opened = cv2.dilate(eroded, kernel)
        layer = cv2.subtract(work, opened)
        skeleton = cv2.bitwise_or(skeleton, layer)
        work = eroded
    return skeleton
```

这个循环实现集合公式：每轮产生一个 $S_(k)$ 层，再把输入腐蚀一次。若还要精确重建，必须分别保存各层及其 $k$，而不能只保存所有层的并集图像。

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
