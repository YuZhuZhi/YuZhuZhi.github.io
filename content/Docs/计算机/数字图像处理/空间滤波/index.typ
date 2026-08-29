#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "空间滤波",
  description: "相关、卷积与低通、高通、带通滤波器",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

= 空间滤波

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

灰度变换只读取当前像素，因而无法判断一个亮点是孤立噪声、平坦区域还是物体边缘。空间滤波把输出像素建立在一个局部邻域上：平滑滤波器汇集相近像素以抑制快速起伏，锐化滤波器比较邻近像素以强调变化。二者看似方向相反，却共享同一套邻域、核、边界和数据类型问题。#cite(<dip-book>)

本章先建立线性空间滤波的统一表达，再严格区分相关与卷积。之后讨论低通、高通和由低通组合得到的带通、带阻滤波器。代码中的中间结果会尽量保留为浮点或有符号类型，因为负响应和超出 255 的响应本身就是滤波信息，过早转为 `uint8` 会不可逆地丢掉它们。

#html.hr()
= 一、线性空间滤波

== 1. 邻域运算与核

#tufted.definition[线性空间滤波][设输入图像为 $f$，有限邻域偏移集合为 $cal(N)$，每个偏移 $(s,t)$ 对应权重 $w(s,t)$。若输出为
$
  g(x,y)=sum_((s,t) in cal(N)) w(s,t) f(x+s,y+t),
$
则称该运算为线性空间滤波。权重数组 $w$ 称为滤波器核、模板或掩模。]

核规定了三个要素：读取哪些相对位置、每个位置乘什么权重、乘积如何汇总。一个 $3 times 3$ 核覆盖中心周围九个位置；核中心通常称为锚点。把锚点放到输入坐标 $(x,y)$，逐项相乘再求和，就得到一个输出像素。随后锚点横向、纵向滑动，便生成完整输出图像。

当核越过图像边界时，公式会请求不存在的像素。实现必须选择边界扩展：常数填充会在图像外引入固定值，复制填充重复最外层像素，镜像填充则延续边缘附近结构。边界模式会改变靠近边缘的响应，尤其对求导核影响明显，因此它是算法定义的一部分，而不是无关的库参数。

#tufted.theorem[线性滤波的叠加性][固定核，并采用零填充、复制、镜像或其他对输入保持线性的边界扩展时，空间滤波算子 $cal(H)$ 满足
$
  cal(H)(a f+b q)=a cal(H)(f)+b cal(H)(q).
$
]

#tufted.proof[先由边界扩展的线性性分别扩展 $f$ 与 $q$，再把 $a f+b q$ 代入加权和。利用乘法对加法的分配律，将包含 $f$ 与 $q$ 的有限求和分开即可。]

叠加性让复杂滤波器可以由简单核相加、相减或串联分析。不过，固定为非零值的常数填充会额外引入与输入无关的边界项，使有限图像上的算子成为仿射而非严格线性；权重随图像内容改变时，运算一般也不再线性。因而“核的加权和是线性的”不能代替对完整边界实现的检查。

== 2. 非线性空间滤波

#tufted.definition[非线性空间滤波][若输出仍由局部邻域决定，但不能写成固定权重的像素加权和，或不满足叠加性，则称为非线性空间滤波。]

中值滤波是典型例子：它把邻域值排序并取中位数。若把所有输入乘以正数，中位数也相应缩放，但两个邻域之和的中位数通常不等于两个中位数之和，所以它不是线性算子。最大值、最小值、双边滤波以及根据局部方差改变权重的自适应滤波也属于非线性或数据依赖滤波。

非线性滤波也需要一个窗口来规定邻域，实际编程中这个窗口有时也被宽泛地叫作“核”。为了避免混淆，本章把“核”优先用于线性权重数组；对中值滤波则称为窗口或邻域，因为它没有与每个位置固定相乘的权重。

OpenCV 的 `filter2D` 可以执行任意二维线性核。`ddepth` 指定输出深度；`-1` 表示沿用输入深度，适用于和为 1 的平滑核，但不适合需要保留负值的导数核。#cite(<opencv-filter2d>)

```python
import cv2
import numpy as np

gray = cv2.imread("input.png", cv2.IMREAD_GRAYSCALE)
if gray is None:
    raise FileNotFoundError("input.png")

kernel = np.array(
    [
        [1, 2, 1],
        [2, 4, 2],
        [1, 2, 1],
    ],
    dtype=np.float32,
)
kernel /= kernel.sum()

smoothed = cv2.filter2D(
    gray,
    ddepth=-1,
    kernel=kernel,
    borderType=cv2.BORDER_REFLECT,
)
```

#html.hr()
= 二、相关与卷积

== 1. 相关

#tufted.definition[二维相关][对图像 $f$ 和有限核 $w$，本章采用的二维相关定义为
$
  (f star w)(x,y)=sum_(s) sum_(t) w(s,t) f(x+s,y+t).
$
计算时保持核的行列次序不变，只把核的锚点移动到各个输出坐标。]

相关直接寻找图像邻域与核图样的相似程度。如果核左侧为负、右侧为正，它会对“从左到右变亮”的边缘产生正响应，对相反方向产生负响应。核的朝向因此具有意义。

== 2. 卷积

#tufted.definition[二维卷积][二维离散卷积定义为
$
  (f * w)(x,y)=sum_(s) sum_(t) w(s,t) f(x-s,y-t).
$
令 $u=-s$、$v=-t$ 后可见，卷积等价于先把核绕锚点旋转 $180 degree$，再按相关的方式滑动。]

#figure(
  image("images/correlation-convolution.png", width: 83%, alt: "非对称核执行相关与卷积时的方向区别"),
  caption: [相关保持非对称核的方向，卷积先将核旋转 $180 degree$；因此二者可能产生符号或方向不同的响应。]
)

#tufted.theorem[中心对称核的相关与卷积][若核关于锚点中心对称，即 $w(s,t)=w(-s,-t)$，则在相同边界约定下，$f star w=f*w$。]

盒式核、高斯核和常用拉普拉斯核中心对称，所以两种运算的输出相同；对不对称核，相关与卷积则可能相差符号或方向。只看到函数名而不检查核是否翻转，容易把响应方向解释反。后文遇到具体的方向导数核时，再逐一分析它们的方向。

OpenCV 文档明确指出 `filter2D` 实际计算相关而不是翻转核的卷积。若需要数学定义下的卷积，应先用 `cv2.flip(kernel, -1)` 旋转核，并相应处理非中心锚点。#cite(<opencv-filter2d>)

```python
response_correlation = cv2.filter2D(
    gray,
    cv2.CV_32F,
    kernel,
    borderType=cv2.BORDER_REFLECT,
)

flipped = cv2.flip(kernel, -1)
response_convolution = cv2.filter2D(
    gray,
    cv2.CV_32F,
    flipped,
    borderType=cv2.BORDER_REFLECT,
)
```

#tufted.remark[机器学习中的“卷积”][机器学习库中的 `Conv2d` 通常直接做互相关，却沿用“卷积层”这一名称。训练时权重由数据学习，翻转前后的参数空间一一对应，网络仍能学到所需图样，因此这一命名惯例通常不削弱模型的表达能力。但是，移植手工设计的非对称核、解释响应方向或复现经典信号处理公式时，仍必须确认库究竟有没有旋转核。]

== 3. 可分离的核

#tufted.definition[可分离核][若 $m times n$ 核 $W$ 能写成列向量 $a$ 与行向量 $b^T$ 的外积
$
  W=a b^T, quad W_(i,j)=a_(i) b_(j),
$
则称 $W$ 可分离。非零核可分离当且仅当其矩阵秩为 1。]

对可分离核不必一次完成二维加权和。先沿一个方向用 $b$ 做一维滤波，得到中间图像；再沿另一方向用 $a$ 滤波，结果与二维核相同。每个像素的乘加次数从约 $m n$ 降为 $m+n$。例如 $15 times 15$ 核从 225 项降到 30 项，这也是大尺度高斯滤波常采用分离实现的原因。

#figure(
  image("images/separable-kernel.png", width: 77%, alt: "二维核分解为纵向向量和横向向量的外积"),
  caption: [二维高斯型权重可以先做横向一维滤波，再做纵向一维滤波；中间结果仍是一幅图像。]
)

二维高斯核可写成两个一维高斯向量的外积；矩形盒式核也可以分成纵向全 1 向量与横向全 1 向量，并把归一化系数分配给任一向量。可分离并不限于平滑核，例如一个方向上的差分向量也可以与另一个方向的平滑向量组成可分离核；具体的导数核将在高通滤波部分再讨论。

各向同性描述的是核在旋转坐标后响应是否保持不变或近似不变。理想圆对称高斯核是各向同性的，因为权重只取决于到中心的距离；只沿水平方向求差的核则明显具有方向性。可分离性关心矩阵能否分解，各向同性关心旋转行为，两者不是同一性质：可分离核可以有方向性，近似各向同性的离散核也要单独检查采样误差。

```python
g = cv2.getGaussianKernel(ksize=15, sigma=2.5)
separable = cv2.sepFilter2D(
    gray,
    ddepth=-1,
    kernelX=g,
    kernelY=g,
    borderType=cv2.BORDER_REFLECT,
)

two_dimensional_kernel = g @ g.T
direct = cv2.filter2D(
    gray,
    ddepth=-1,
    kernel=two_dimensional_kernel,
    borderType=cv2.BORDER_REFLECT,
)
```

#html.hr()
= 三、低通空间滤波器

低通滤波器保留缓慢变化的成分，削弱像素间快速起伏。在空间域中，它通常表现为邻域平均或稳健汇总，输出比输入平滑。平滑能抑制噪声和细纹理，也必然削弱窄结构与清晰边缘，因此窗口大小不是越大越好。

== 1. 盒式滤波器核

#tufted.definition[盒式滤波器][大小为 $m times n$ 的归一化盒式核在窗口内权重相同：
$
  w(s,t)=1/(m n).
$
其输出是窗口内像素的算术平均。]

核元素和为 1，所以常量图像仍保持原常量，不会仅因滤波整体变亮或变暗。盒式平均对随机零均值噪声有抑制作用，但方形等权窗口在边缘两侧混合像素，容易产生模糊；少数极端脉冲值也会直接进入平均数。

`cv2.blur` 执行归一化盒式滤波，`cv2.boxFilter` 还允许 `normalize=False` 得到窗口和。大窗口盒式和可以用积分图像加速，因为任意轴对齐矩形的和只需查询四个累计值。

```python
box_5 = cv2.blur(
    gray,
    ksize=(5, 5),
    borderType=cv2.BORDER_REFLECT,
)

window_sum = cv2.boxFilter(
    gray,
    ddepth=cv2.CV_32F,
    ksize=(15, 15),
    normalize=False,
    borderType=cv2.BORDER_REFLECT,
)
```

== 2. 低通高斯滤波器核

连续二维高斯函数为
$
  G(x,y)=1/(2 pi sigma^2) exp(-(x^2+y^2)/(2 sigma^2)).
$
$sigma$ 决定扩散尺度：越大，中心权重下降得越慢，平滑范围越广。实际核只能有限大，通常在中心两侧截取若干个 $sigma$ 并重新归一化，使离散权重之和为 1。

高斯权重由中心向外平滑衰减，比盒式核的突然截断更温和；它既可分离，又在连续模型中各向同性。核尺寸必须足以容纳所选 $sigma$，否则尾部被过度截断，实际滤波器会偏离期望高斯形状。

一个常用的 $3 times 3$ 离散近似为
$
  W=1/16 mat(1,2,1;2,4,2;1,2,1).
$
中心像素权重为 $4/16$，水平和垂直邻居各为 $2/16$，对角邻居各为 $1/16$；全部系数相加恰好为 1，所以常量区域经过滤波后保持不变。它还能分解成
$
  W=1/16 mat(1;2;1) mat(1,2,1),
$
因此先做一次横向的 $[1,2,1]$ 加权平均，再做一次纵向加权平均，就与直接使用二维核相同。这个小核只近似较小尺度的高斯；需要更强平滑时，应增大 $sigma$ 并使用足以容纳其尾部的核，而不是反复套用同一个小核后仍把实际尺度当成不变。

```python
gaussian = cv2.GaussianBlur(
    gray,
    ksize=(0, 0),
    sigmaX=2.0,
    sigmaY=2.0,
    borderType=cv2.BORDER_REFLECT,
)
```

把 `ksize` 设为 `(0, 0)` 时，OpenCV 根据标准差选择核尺寸。显式给定尺寸时应使用正奇数，以便锚点位于中心。OpenCV 对盒式、高斯和中值平滑提供了专用接口。#cite(<opencv-smoothing>)

== 3. 统计排序滤波器核

#tufted.definition[统计排序滤波][统计排序滤波器把邻域灰度排序，以某个次序统计量作为输出。若窗口共有 $n$ 个样本，取排序后的中间样本称为中值滤波；取最小或最大样本分别称为最小值或最大值滤波。]

中值不是线性加权和，却常与低通滤波器一起讨论，因为它能消除局部快速异常。对孤立的盐噪声或椒噪声，只要异常像素不足窗口样本的一半，中位数通常仍来自周围正常像素；均值则会被极端值拖动。中值滤波还能比盒式平均更好地保留阶跃边缘，但大窗口同样会吞掉比窗口窄的小结构。

#figure(
  image("images/low-pass-kernels.png", width: 88%, alt: "盒式权重、高斯权重与中值排序窗口"),
  caption: [盒式核等权平均，高斯核强调中心；中值滤波没有固定乘法权重，而是从排序后的邻域中选择中间值。]
)

```python
median_3 = cv2.medianBlur(gray, 3)
median_5 = cv2.medianBlur(gray, 5)

minimum = cv2.erode(
    gray,
    np.ones((3, 3), dtype=np.uint8),
)
maximum = cv2.dilate(
    gray,
    np.ones((3, 3), dtype=np.uint8),
)
```

最小值滤波会扩张暗区域、抑制孤立亮点；最大值滤波会扩张亮区域、抑制孤立暗点。这里用腐蚀和膨胀实现，相关形状性质将在形态学章节系统讨论。

#html.hr()
= 四、高通空间滤波器

高通滤波器响应快速灰度变化，常用于边缘检测和锐化。它们的核权重和通常为 0，因此常量区域响应为 0；响应可能为正也可能为负。显示时若直接转换为 `uint8`，负值会被截断，从而丢失一半方向信息，故计算阶段应使用 `CV_16S`、`CV_32F` 或更高精度。

== 1. 图像的一阶导数与二阶导数

连续函数的一阶导数度量局部斜率，二阶导数度量斜率本身的变化。数字图像只在整数坐标取样，因此用有限差分近似。例如一维前向一阶差分和中心二阶差分分别为
$
  Delta f(x)=f(x+1)-f(x),
$
$
  Delta^2 f(x)=f(x+1)-2f(x)+f(x-1).
$
平坦区域的两者均为 0。跨越阶跃边缘时，一阶差分在变化处产生单个主要响应；二阶差分通常在边缘两侧产生异号响应，并在其间出现过零。二维图像需要同时考虑水平和垂直方向。

求导会放大高频成分，而噪声也常表现为快速变化，所以导数图往往比原图更嘈杂。增大差分模板并加入正交方向平滑，或先做轻微高斯平滑，是降低噪声敏感性的常见办法，但也会牺牲定位精度和细小边缘。

== 2. 拉普拉斯核与锐化

#tufted.definition[图像的拉普拉斯算子][二维连续图像的拉普拉斯定义为
$
  nabla^2 f=frac(partial^2 f, partial x^2)+frac(partial^2 f, partial y^2).
$
它把两个坐标方向的二阶导数相加，是不指定边缘方向的二阶微分算子。]

二维拉普拉斯在离散网格上并不只有一种核。只使用水平、垂直邻居的四邻域近似为
$
  W_(4)=mat(0,1,0;1,-4,1;0,1,0).
$
若把四个对角邻居也纳入差分，可得到八邻域形式
$
  W_(8)=mat(1,1,1;1,-8,1;1,1,1).
$
还可以在两种邻域近似之间组合权重，以改善某些方向上的离散误差。不同形式对斜边、细线和噪声的响应并不完全相同：八邻域利用的方向更多，旋转对称性通常更好一些，但它也读取更多邻居，可能对细小噪声产生更强响应。

#tufted.theorem[拉普拉斯核的零和性质][上述离散拉普拉斯核的全部系数之和均为 0。因此，对任意常量图像 $f(x,y)=c$，滤波结果处处为 0。]

#tufted.proof[常量邻域中的每一项都等于 $c$，故输出为
$
  sum_(s) sum_(t) w(s,t)c=c sum_(s) sum_(t) w(s,t)=0.
$
这说明拉普拉斯只响应灰度变化，不响应恒定亮度。]

零和是导数核消除常量分量所必需的性质，但仅凭“系数和为 0”不能断定任意核就是合理的拉普拉斯近似，还要考察对称性、方向响应与差分精度。上述核中心为负、邻居为正；把每个系数同时乘以 $-1$，就得到正中心、负邻居的另一组常见形式。两组核的响应只差一个负号，边缘位置不变。

锐化要把原图与拉普拉斯响应组合。对负中心核，使用
$
  g=f-c nabla^2 f, quad c>0.
$
在边缘附近减去二阶响应可以增强灰度跃迁。若使用正中心核，公式中的减号要改为加号。记住“核的符号与组合公式必须配套”比死记某一个模板更可靠。

```python
source = gray.astype(np.float32)
laplacian = cv2.Laplacian(
    source,
    ddepth=cv2.CV_32F,
    ksize=3,
    borderType=cv2.BORDER_REFLECT,
)
sharpened_laplacian = np.clip(source - 0.7 * laplacian, 0, 255)
sharpened_laplacian = sharpened_laplacian.astype(np.uint8)
```

`cv2.Laplacian` 在离散网格上计算两个坐标方向的二阶导数并相加，输出仍应保留有符号深度。#cite(<opencv-gradients>)

== 3. 梯度锐化

#tufted.definition[图像梯度][连续图像 $f$ 的梯度为
$
  nabla f=mat(frac(partial f, partial x); frac(partial f, partial y))=mat(G_(x);G_(y)).
$
梯度方向 $theta="atan2"(G_(y),G_(x))$ 指向灰度增长最快的方向，梯度幅值可取 $sqrt(G_(x)^2+G_(y)^2)$；为降低计算量也常近似为 $abs(G_(x))+abs(G_(y))$。]

Roberts 交叉梯度使用两个 $2 times 2$ 核比较对角像素，例如
$
  R_(x)=mat(1,0;0,-1), quad R_(y)=mat(0,1;-1,0).
$
窗口小使它定位紧凑，却几乎不包含平滑，因而对噪声敏感；其响应方向相对于图像坐标轴旋转了 $45 degree$。

Sobel 用 $3 times 3$ 核把差分和平滑结合。水平灰度导数核可分离为
$
  mat(1;2;1) mat(-1,0,1),
$
即先沿纵向按 $1,2,1$ 平滑，再沿横向作中心差分；转置后得到另一方向。Sobel 因此比最简单的两点差分稳健，但仍会响应噪声。

#figure(
  image("images/derivative-kernels.png", width: 87%, alt: "Roberts、Sobel 与拉普拉斯离散导数核"),
  caption: [Roberts 比较对角像素；Sobel 将一维平滑与一维差分组合；拉普拉斯汇总两个方向的二阶差分。]
)

算法过程应保留两个分量，而不是一开始就把它们转成绝对值：

1. 把输入提升到浮点或有符号类型，选择与噪声尺度相称的核大小。
2. 分别求 $G_(x)$ 与 $G_(y)$，它们的正负表示灰度变化方向。
3. 由两个分量计算幅值；需要方向时用 `arctan2`，它能正确处理象限与零分量。
4. 若只为显示，再把幅值归一化或裁剪到 8 位；若用于后续算法，则保留浮点响应。

```python
source = gray.astype(np.float32)
gx = cv2.Sobel(
    source,
    cv2.CV_32F,
    dx=1,
    dy=0,
    ksize=3,
    borderType=cv2.BORDER_REFLECT,
)
gy = cv2.Sobel(
    source,
    cv2.CV_32F,
    dx=0,
    dy=1,
    ksize=3,
    borderType=cv2.BORDER_REFLECT,
)

magnitude = cv2.magnitude(gx, gy)
orientation = np.arctan2(gy, gx)

display_gradient = cv2.normalize(
    magnitude,
    None,
    0,
    255,
    cv2.NORM_MINMAX,
).astype(np.uint8)
```

梯度幅值可作为锐化掩膜加回原图，但它只增加边缘两侧的亮响应，视觉效果与带正负瓣的拉普拉斯锐化不同。参数应围绕“要强调多大尺度的边缘”选择，而不是把幅值系数无限增大。

== 4. 钝化掩蔽与高提升滤波

钝化掩蔽先从原图中减去低通图像，得到高频掩膜，再把掩膜加回原图。设低通算子为 $cal(L)$：
$
  m=f-cal(L)(f),
$
$
  g=f+k m=(1+k)f-k cal(L)(f).
$
$m$ 在平坦区域接近 0，在边缘与细节处较大。$k=1$ 常称钝化掩蔽；$k>1$ 称高提升滤波，表示比原始高频分量施加更大的增益。有些文献采用不同参数记号，判断方法仍是检查原图和模糊图的实际系数。

#figure(
  image("images/unsharp-bands.png", width: 87%, alt: "原信号、低通信号、高频掩膜及尺度带分解"),
  caption: [原图减去低通结果得到高频掩膜；两个不同尺度的低通结果相减，可以提取介于两种尺度之间的变化。]
)

```python
source = gray.astype(np.float32)
low = cv2.GaussianBlur(
    source,
    (0, 0),
    sigmaX=1.5,
    borderType=cv2.BORDER_REFLECT,
)
mask = source - low

amount = 1.2
high_boost = source + amount * mask
high_boost = np.clip(high_boost, 0, 255).astype(np.uint8)
```

模糊尺度决定哪些细节进入掩膜，`amount` 决定这些细节加回多少。尺度过大可能在强边缘周围形成亮暗光晕，增益过大则会放大噪声并产生裁剪。实际调参应先固定希望强调的结构尺度，再逐步增加增益。

#html.hr()
= 五、带阻、带通滤波器

只要已经有低通滤波器，就可以通过相减构造与它互补的高通滤波器；再准备两个截止尺度不同的低通滤波器，就可以进一步构造带通和带阻滤波器。因而这里不需要从头设计三套互不相关的核，关键是先看清：原图包含全部变化，而低通结果只保留较缓慢的变化。

1. 首先由一个低通滤波器得到高通。把恒等算子记为 $cal(I)$，低通算子记为 $cal(L)$，则
$
  cal(H)=cal(I)-cal(L).
$
对具体图像就是 $h=f-cal(L)(f)$：原图减去低通图，低频部分相互抵消，剩下该低通滤波器没有保留的快速变化。这正是钝化掩膜中高频掩膜的来源。

2. 然后由两个低通滤波器得到带通。设 $cal(L)_(1)$ 的平滑尺度较小，$cal(L)_(2)$ 的平滑尺度较大。$cal(L)_(1)$ 只去掉最高频的快速变化，因而仍保留中频和低频；$cal(L)_(2)$ 连中等尺度变化也会平滑掉，主要留下更低频的缓慢变化。将两者相减：
$
  cal(B P)=cal(L)_(1)-cal(L)_(2)
$
两幅低通图共同具有的低频部分相互抵消，最高频又早已被 $cal(L)_(1)$ 抑制，所以差值主要保留两个低通尺度之间的中间频带。这就是带通结果。

3. 最后由带通得到带阻。原图包含低、中、高三个范围的成分，从原图减去刚得到的中间频带：
$
  cal(B S)=cal(I)-cal(B P).
$
中间频带被抵消，低于它和高于它的成分被保留，于是得到带阻结果。把三步合在一起，可以写成
$
  cal(B S)=cal(I)-cal(L)_(1)+cal(L)_(2).
$
这个展开式也说明带阻不是简单的模糊：它既保留非常缓慢的背景，也保留比阻带更快的细节，只压制选定的中间尺度。

#tufted.remark[空间尺度与理想频带][有限高斯低通没有砖墙式截止频率，所以低通之差得到的是平滑重叠的尺度带，不是理想矩形频带。这里的“带通、带阻”应理解为由滤波器频率响应相减得到的实际频带；精确频域设计将在频域滤波章节讨论。]

```python
source = gray.astype(np.float32)

low_small = cv2.GaussianBlur(
    source,
    (0, 0),
    sigmaX=1.0,
    borderType=cv2.BORDER_REFLECT,
)
low_large = cv2.GaussianBlur(
    source,
    (0, 0),
    sigmaX=4.0,
    borderType=cv2.BORDER_REFLECT,
)

high_pass = source - low_small
band_pass = low_small - low_large
band_stop = source - band_pass

def display_signed(response: np.ndarray) -> np.ndarray:
    return cv2.normalize(
        response,
        None,
        0,
        255,
        cv2.NORM_MINMAX,
    ).astype(np.uint8)

cv2.imwrite("high-pass.png", display_signed(high_pass))
cv2.imwrite("band-pass.png", display_signed(band_pass))
cv2.imwrite("band-stop.png", np.clip(band_stop, 0, 255).astype(np.uint8))
```

`display_signed` 为了观察响应而把当前最小值和最大值拉到 0 与 255，因此输出不再保留不同图像之间的绝对幅度关系。定量比较时应保存浮点数组，并统一使用同一尺度。对彩色图像做增强时，也通常只处理亮度或线性光强分量，以避免每个颜色通道不同的边缘增益造成色偏。

#tufted.remark[从目的反推滤波器][抑制独立随机起伏可先考虑高斯或盒式低通；去除椒盐噪声优先考虑中值；检测带方向的边缘使用梯度；无方向锐化可使用拉普拉斯；可控地增强细节常用钝化掩蔽。任何平滑都可能损失细节，任何锐化都可能放大噪声，核大小、标准差和增益必须由目标结构的尺度共同决定。]

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
