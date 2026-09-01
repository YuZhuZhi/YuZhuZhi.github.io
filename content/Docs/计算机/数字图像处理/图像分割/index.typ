#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "图像分割",
  description: "边缘、阈值、区域生长与分水岭分割",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

= 图像分割

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

图像分割把像素域划分为具有任务意义的区域。它不是简单地让图像“看起来轮廓更明显”，而是输出边界、区域标签或前景掩膜，使同一区域内部满足某种一致性，不同区域之间存在足够差异。边缘检测从局部不连续性出发，阈值处理按灰度统计分类，区域生长从种子扩展同质区域，分水岭则把梯度图解释为地形并寻找集水盆地之间的分界。#cite(<dip-book>)

#tufted.definition[图像分割][设图像定义域为 $R$。分割是寻找非空子区域 $R_(1),dots,R_(n)$，满足
$
  union_(i=1)^n R_(i)=R,
  quad
  R_(i) ∩ R_(j)=emptyset quad (i!=j),
$
且每个 $R_(i)$ 满足区域内一致性谓词 $Q(R_(i))$，相邻区域的并集不再满足同一谓词。]

分割结果没有脱离任务的唯一“正确答案”。其关键在于谓词 $Q$：$Q$ 规定了“区域内部怎样才算一致”，而一致与否本身取决于任务。同一张医学图像可以按器官、病灶或组织纹理分割；阈值、平滑尺度、邻接方式和标记都会改变结果。因此算法说明必须同时给出假设、参数和失败条件，不能只给一幅看似漂亮的输出。

#html.hr()
= 一、边缘检测

== 1. 点与线的检测

孤立点和细线都是局部灰度不连续结构。检测方法是用零和核做相关：均匀区域的正负系数互相抵消，局部异常则产生大响应。孤立点常用
$
  W_(p)=mat(-1,-1,-1;-1,8,-1;-1,-1,-1).
$
中心像素与八邻域差异越大，$abs(W_(p) star f)$ 越大。阈值过低会把噪声点全部检出，通常应先抑制噪声或要求响应同时满足局部极大条件。

规定方向的线检测使用方向性核。例如水平、竖直、$+45 degree$ 和 $-45 degree$ 的典型 $3 times 3$ 核为
$
  W_(H)&=mat(-1,-1,-1;2,2,2;-1,-1,-1),\
  W_(V)&=mat(-1,2,-1;-1,2,-1;-1,2,-1),\
  W_(+45)&=mat(-1,-1,2;-1,2,-1;2,-1,-1),\
  W_(-45)&=mat(2,-1,-1;-1,2,-1;-1,-1,2).
$
核中系数 2 所在方向与要检测的亮线方向一致。对每个像素计算四个绝对响应，最大者给出最可能的线方向；若目标是暗线，还要保留响应符号或同时检测反相核。

#figure(
  image("images/point-line-series.png", width: 100%, alt: "输入图像、孤立点响应和三个方向线响应的系列图"),
  caption: [(a) 含点、水平线、竖直线和斜线的测试图；(b) 孤立点检测响应；(c) 水平线核响应；(d) 竖直线核响应；(e) $45 degree$ 方向线核响应。]
)

```python
point_kernel = np.array(
    [[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]],
    dtype=np.float32,
)
line_kernels = {
    "horizontal": np.array(
        [[-1, -1, -1], [2, 2, 2], [-1, -1, -1]],
        dtype=np.float32,
    ),
    "vertical": np.array(
        [[-1, 2, -1], [-1, 2, -1], [-1, 2, -1]],
        dtype=np.float32,
    ),
    "diagonal_45": np.array(
        [[-1, -1, 2], [-1, 2, -1], [2, -1, -1]],
        dtype=np.float32,
    ),
}

point_response = cv2.filter2D(gray, cv2.CV_32F, point_kernel)
line_responses = {
    name: cv2.filter2D(gray, cv2.CV_32F, kernel)
    for name, kernel in line_kernels.items()
}
best_direction = np.argmax(
    np.stack([np.abs(response) for response in line_responses.values()]),
    axis=0,
)
```

== 2. 边缘模型

#tufted.definition[边缘][边缘是图像局部性质相对于给定尺度与判据发生变化的位置。灰度边缘通常以一阶导数的局部极大值或二阶导数的过零点作为候选，再用幅值阈值排除弱响应。尺度、导数离散方式和阈值共同决定检测结果；边缘不是必然精确落在物体真实边界上的单像素曲线。]

理想阶跃边缘在一个像素处突然改变灰度；真实镜头和采样会把它变成斜坡边缘。屋脊边缘先升后降，代表细线或窄脊；脉冲模型则描述更窄的孤立结构。不同模型的导数响应不同：阶跃的一阶导数产生单峰，屋脊产生一正一负响应，二阶导数在变化中心附近发生符号改变。

#figure(
  image("images/edge-models.png", width: 100%, alt: "阶跃斜坡屋脊和脉冲四种一维边缘灰度模型"),
  caption: [从左到右分别为阶跃、斜坡、屋脊和脉冲模型。边缘宽度越大，一阶导数峰值越低，定位的不确定范围越宽。]
)

噪声包含大量高频变化，求导会把它放大。因此边缘检测必须在“抑制噪声”和“保持定位”之间选择尺度。平滑越强，虚假边缘越少，但相邻边缘可能合并，细小目标也可能消失。

== 3. 边缘检测

连续图像的一阶梯度为
$
  nabla f=mat(frac(partial f, partial x);frac(partial f, partial y))=mat(G_(x);G_(y)),
$
幅值和方向为
$
  M=sqrt(G_(x)^2+G_(y)^2),
  quad
  alpha="atan2"(G_(y),G_(x)).
$
$alpha$ 是灰度增长最快的法线方向，边缘切线方向与其相差 $pi/2$。离散核只能近似导数，不同算子在噪声抑制、旋转对称性和定位上有不同折中。

=== a. 一维核

最简单前向差分为 $[-1,1]$，响应位于两个采样点之间；中心差分 $[-1,0,1]$ 使用两侧样本，尺度稍大且响应中心更对称。二维图像分别沿行、列应用差分得到 $G_(x),G_(y)$。使用 `uint8` 直接求导会丢失负响应，因此必须输出到有符号或浮点类型。

=== b. 罗伯特交叉梯度算子

Roberts 使用两个 $2 times 2$ 对角差分核：
$
  R_(x)=mat(1,0;0,-1),
  quad
  R_(y)=mat(0,1;-1,0).
$
它计算量小、定位紧凑，但窗口太小，几乎没有平滑能力，对噪声敏感，方向也相对对角轴旋转。

=== c. Prewitt 算子

Prewitt 将一个方向的中心差分与正交方向的三点均值结合：
$
  P_(x)=mat(-1,0,1;-1,0,1;-1,0,1),
  quad
  P_(y)=mat(-1,-1,-1;0,0,0;1,1,1).
$
三行或三列累加提供轻微平滑，比 Roberts 稳定，但没有强调靠近中心的样本。

=== d. Sobel 算子

Sobel 把正交方向权重改为 $[1,2,1]$：
$
  S_(x)=mat(-1,0,1;-2,0,2;-1,0,1),
  quad
  S_(y)=mat(-1,-2,-1;0,0,0;1,2,1).
$
它可分离为平滑向量与差分向量，中心权重改善了噪声下的梯度估计，是常用的一阶算子。OpenCV 的 `Sobel` 参数 `dx=1,dy=0` 计算 $G_(x)$，反之计算 $G_(y)$。

=== e. Kirsch 罗盘核

Kirsch 用八个相隔 $45 degree$ 的罗盘核检测方向。北向核可写为
$
  K_(N)=mat(5,5,5;-3,0,-3;-3,-3,-3),
$
其余七个核由旋转得到。最终响应常取八个方向绝对值的最大值，并记录取得最大值的方向。较大的正负权重使响应强，但也更容易放大噪声。

#figure(
  image("images/edge-operator-series.png", width: 100%, alt: "Roberts Prewitt Sobel Kirsch 四类边缘算子的结果对比"),
  caption: [(a) 输入图像；(b) Roberts 交叉梯度；(c) Prewitt 梯度；(d) Sobel 梯度；(e) Kirsch 八方向最大响应。]
)

```python
gx = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
gy = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
magnitude = cv2.magnitude(gx, gy)
direction = np.arctan2(gy, gx)

# 只为显示才归一化；后续阈值应使用原浮点幅值。
display = cv2.normalize(magnitude, None, 0, 255, cv2.NORM_MINMAX)
display = display.astype(np.uint8)
```

== 4. Marr–Hildreth 边缘检测子

Marr–Hildreth 先用高斯函数平滑，再对结果求拉普拉斯，最后检测二阶响应的过零点。卷积的结合律允许把两步合成高斯拉普拉斯核：
$
  "LoG"(x,y)=nabla^2 G(x,y)
  =((x^2+y^2-2sigma^2)/(2pi sigma^6))
  exp(-(x^2+y^2)/(2sigma^2)).
$
符号整体取反不会改变过零位置。$sigma$ 控制尺度：小 $sigma$ 定位细节但敏感于噪声，大 $sigma$ 只保留较粗结构。

只检查相邻像素符号不同会产生大量弱噪声边缘，还应要求过零两侧的响应差超过阈值。二维中通常检查水平、竖直和两条对角方向。LoG 的各向同性使其在连续边缘附近较易形成闭合响应，但这不是保证；噪声、边界缺口和阈值仍会使轮廓断裂。二阶导数还可能在宽斜坡两侧产生双边缘。

#figure(
  image("images/log-series.png", width: 100%, alt: "输入图像高斯拉普拉斯响应与过零边缘"),
  caption: [(a) 输入图像；(b) 高斯平滑后的拉普拉斯响应，为显示而归一化；(c) 同时满足符号改变和响应跨度阈值的过零边缘。]
)

```python
def marr_hildreth(
    gray: np.ndarray,
    sigma: float,
    crossing_threshold: float,
) -> tuple[np.ndarray, np.ndarray]:
    blurred = cv2.GaussianBlur(gray, (0, 0), sigma)
    response = cv2.Laplacian(blurred, cv2.CV_32F, ksize=3)
    edges = np.zeros(gray.shape, dtype=np.uint8)

    for y in range(1, gray.shape[0] - 1):
        for x in range(1, gray.shape[1] - 1):
            window = response[y - 1:y + 2, x - 1:x + 2]
            crosses_zero = window.min() < 0 < window.max()
            has_contrast = window.max() - window.min() >= crossing_threshold
            if crosses_zero and has_contrast:
                edges[y, x] = 255
    return response, edges
```

== 5. Canny 边缘检测子

Canny 的目标不是简单组合“高斯 + Sobel + 阈值”，而是在检测率、定位精度和单边缘单响应之间取得折中。完整过程包含五个互相依赖的步骤。

=== a. 高斯平滑

先用尺度 $sigma$ 的高斯滤波抑制高频噪声。$sigma$ 决定检测尺度，核尺寸通常覆盖约 $plus.minus 3sigma$。若直接在噪声图上求梯度，后续非极大值抑制无法区分噪声峰和真实边缘峰。

=== b. 梯度幅值与方向

对平滑图计算 $G_(x),G_(y)$，再求 $M$ 和 $alpha$。方向必须使用 `atan2`，否则无法区分象限且 $G_(x)=0$ 时会除零。OpenCV 的 `L2gradient=True` 使用 $sqrt(G_(x)^2+G_(y)^2)$，否则可用较快的 $abs(G_(x))+abs(G_(y))$ 近似。

=== c. 非极大值抑制

梯度峰通常有数个像素宽。对每个像素沿梯度方向比较前后两个插值幅值，只有局部最大值才保留。实现时可把方向量化为 $0 degree,45 degree,90 degree,135 degree$ 四类，也可做线性插值提高定位。注意比较方向是梯度法线方向，不是边缘切线方向。

=== d. 双阈值分类

选择高阈值 $T_(H)$ 与低阈值 $T_(L)$，且 $T_(L)<T_(H)$。幅值不小于 $T_(H)$ 的像素是强边缘，小于 $T_(L)$ 的像素删除，中间像素是弱边缘候选。单一低阈值会保留噪声，单一高阈值会打断低对比边缘。

=== e. 滞后连接

从全部强边缘出发，沿八邻接递归吸收与强边缘连通的弱边缘；不与任何强边缘连通的弱响应删除。这一步利用边缘的空间连续性，使低对比段只有在属于可靠轮廓时才保留。

#figure(
  image("images/canny-stage-series.png", width: 100%, alt: "Canny 边缘检测从平滑到滞后连接的六幅过程图"),
  caption: [(a) 输入图像；(b) 高斯平滑；(c) 梯度幅值；(d) 非极大值抑制；(e) 双阈值分类，灰色为弱边缘、白色为强边缘；(f) 滞后连接后的最终边缘。]
)

```python
def canny_edges(
    gray: np.ndarray,
    sigma: float = 1.2,
    low_threshold: float = 40.0,
    high_threshold: float = 100.0,
) -> np.ndarray:
    if not 0 <= low_threshold < high_threshold:
        raise ValueError("thresholds must satisfy 0 <= low < high")

    blurred = cv2.GaussianBlur(gray, (0, 0), sigma)
    return cv2.Canny(
        blurred,
        threshold1=low_threshold,
        threshold2=high_threshold,
        apertureSize=3,
        L2gradient=True,
    )
```

#tufted.remark[阈值不能脱离梯度尺度][改变输入位深、归一化方式、Sobel 核尺寸或高斯尺度都会改变梯度幅值范围，因此同一组 Canny 阈值不能无条件迁移到另一条处理流水线。应查看梯度分布或在验证集上选择阈值。]

#html.hr()
= 二、全局阈值处理

#tufted.definition[全局阈值分割][给定单一阈值 $T$，二值输出为
$
  g(x,y)=cases(1 & f(x,y)>T, 0 & f(x,y)<=T).
$
若所有像素共享同一个 $T$，称为全局阈值；若 $T$ 随位置变化，则属于局部或自适应阈值。]

全局阈值适用于目标与背景灰度分布相对分离、照明变化不强的图像。直方图若有两个峰，谷底附近阈值往往合理；但直方图只统计灰度数量，不包含像素位置，所以相同直方图可以对应完全不同的空间结构。

== 1. 基本全局阈值处理

若不知道阈值，可以迭代估计：

1. 以图像均值或最小、最大灰度中点作为初值 $T_(0)$。
2. 用 $T_(k)$ 把像素分为 $G_(1)={f>T_(k)}$ 与 $G_(2)={f<=T_(k)}$。
3. 分别计算两组均值 $m_(1),m_(2)$。
4. 更新 $T_(k+1)=(m_(1)+m_(2))/2$。
5. 当 $abs(T_(k+1)-T_(k))<epsilon$ 时停止。

若某组为空，均值无定义，程序应停止或保留旧阈值。这个方法相当于一维两类聚类，但容易受类别面积极不均衡、离群值和重叠分布影响。

```python
def iterative_global_threshold(
    gray: np.ndarray,
    tolerance: float = 0.5,
    maximum_iterations: int = 100,
) -> tuple[float, np.ndarray]:
    values = gray.astype(np.float64)
    threshold = 0.5 * (values.min() + values.max())

    for _ in range(maximum_iterations):
        high = values[values > threshold]
        low = values[values <= threshold]
        if high.size == 0 or low.size == 0:
            break
        updated = 0.5 * (high.mean() + low.mean())
        if abs(updated - threshold) < tolerance:
            threshold = updated
            break
        threshold = updated

    binary = np.where(values > threshold, 255, 0).astype(np.uint8)
    return threshold, binary
```

== 2. Otsu 方法

Otsu 方法不假定两个峰服从高斯分布，而是在所有候选阈值中选择类间方差最大的一个。这里的“最优”是针对单个统计量——把两类分离得最开——并不意味着结果在感知或任务上最优；若两个类在灰度上本来严重重叠，任何阈值都只能把分布切开，误差并不会因此消失。设灰度级为 $0,dots,L-1$，直方图计数为 $n_(i)$，总像素数为 $N$，归一化概率为
$
  p_(i)=n_(i)/N,
  quad
  sum_(i=0)^(L-1)p_(i)=1.
$

对候选阈值 $t$，两类分别为 $C_(0)={0,dots,t}$ 与 $C_(1)={t+1,dots,L-1}$。类概率为
$
  omega_(0)(t)=sum_(i=0)^t p_(i),
  quad
  omega_(1)(t)=1-omega_(0)(t).
$
类均值为
$
  mu_(0)(t)=1/omega_(0) sum_(i=0)^t i p_(i),
$
$
  mu_(1)(t)=1/omega_(1) sum_(i=t+1)^(L-1) i p_(i),
$
全局均值为 $mu_(T)=sum_(i=0)^(L-1)i p_(i)$。类间方差定义为
$
  sigma_(B)^2(t)=
  omega_(0)(mu_(0)-mu_(T))^2+
  omega_(1)(mu_(1)-mu_(T))^2.
$
利用 $mu_(T)=omega_(0)mu_(0)+omega_(1)mu_(1)$，还可写成
$
  sigma_(B)^2(t)=omega_(0)omega_(1)(mu_(0)-mu_(1))^2.
$
最佳阈值为使 $sigma_(B)^2(t)$ 最大的 $t$。总方差满足 $sigma_(T)^2=sigma_(W)^2+sigma_(B)^2$，因此最大化类间方差等价于最小化类内方差。

#tufted.theorem[Otsu 两种判据的等价性][对固定图像直方图，总方差 $sigma_(T)^2$ 与阈值 $t$ 无关，并且
$
  sigma_(T)^2=sigma_(W)^2(t)+sigma_(B)^2(t).
$
因此，使类间方差 $sigma_(B)^2(t)$ 最大的阈值，恰好也是使类内方差 $sigma_(W)^2(t)$ 最小的阈值。]

#tufted.proof[把每一类中的偏差分解为
$
  i-mu_(T)=(i-mu_(j))+(mu_(j)-mu_(T)).
$
对第 $j$ 类平方、按 $p_(i)$ 加权求和时，交叉项包含 $sum_(i in C_(j))p_(i)(i-mu_(j))=0$，只剩类内离差和类均值相对全局均值的离差。对全部类别求和便得到方差分解式。由于左端由完整直方图决定，不随阈值改变，所以两个优化目标等价。]

#figure(
  image("images/otsu-histogram.png", width: 68%, alt: "双峰直方图被阈值分成两个概率类的示意"),
  caption: [阈值 $T$ 将直方图划分为概率为 $omega_(0),omega_(1)$、均值为 $mu_(0),mu_(1)$ 的两类；Otsu 选择类间分离最大的阈值。]
)

为了 $O(L)$ 扫描全部阈值，可预先计算累计概率 $omega(t)$ 与累计一阶矩 $m(t)=sum_(i=0)^t i p_(i)$，不必为每个 $t$ 重新求和。若某一类概率为零，该候选阈值跳过。

=== a. 多阈值扩展

若图像包含 $q$ 个灰度类别，需要 $q-1$ 个有序阈值
$
  0<=t_(1)<t_(2)<dots<t_(q-1)<L-1.
$
令 $t_(0)=-1,t_(q)=L-1$，第 $j$ 类区间为 $t_(j)+1,dots,t_(j+1)$，其概率与均值为
$
  omega_(j)=sum_(i=t_(j)+1)^(t_(j+1))p_(i),
  quad
  mu_(j)=1/omega_(j) sum_(i=t_(j)+1)^(t_(j+1))i p_(i).
$
多类类间方差为
$
  sigma_(B)^2(t_(1),dots,t_(q-1))
  =sum_(j=0)^(q-1)omega_(j)(mu_(j)-mu_(T))^2.
$
选择使该式最大的阈值组合。三类时穷举 $(t_(1),t_(2))$ 需要约 $L^2/2$ 次组合；类别更多时组合数迅速增长，可用动态规划或专门的多 Otsu 实现。

#figure(
  image("images/threshold-series.png", width: 100%, alt: "全局Otsu平滑改进和三类多阈值结果的五幅图"),
  caption: [(a) 含渐变照明与噪声的三灰度区域；(b) 基本二类 Otsu；(c) 高斯平滑图；(d) 平滑后重新计算的二类 Otsu；(e) 最大化三类类间方差得到的多阈值结果。]
)

```python
def otsu_three_classes(gray: np.ndarray) -> tuple[int, int]:
    histogram = cv2.calcHist(
        [gray], [0], None, [256], [0, 256]
    ).ravel().astype(np.float64)
    probability = histogram / histogram.sum()
    omega = np.cumsum(probability)
    moment = np.cumsum(probability * np.arange(256))
    total_mean = moment[-1]

    best_score = -1.0
    best_thresholds = (0, 0)
    for first in range(1, 254):
        weight0 = omega[first]
        if weight0 <= 0:
            continue
        mean0 = moment[first] / weight0

        for second in range(first + 1, 255):
            weight1 = omega[second] - omega[first]
            weight2 = 1.0 - omega[second]
            if weight1 <= 0 or weight2 <= 0:
                continue
            mean1 = (moment[second] - moment[first]) / weight1
            mean2 = (total_mean - moment[second]) / weight2
            score = (
                weight0 * (mean0 - total_mean) ** 2
                + weight1 * (mean1 - total_mean) ** 2
                + weight2 * (mean2 - total_mean) ** 2
            )
            if score > best_score:
                best_score = score
                best_thresholds = (first, second)
    return best_thresholds
```

== 3. 阈值处理的改进

=== a. 使用图像平滑

噪声会让同一区域的直方图变宽并互相重叠。先用高斯或中值滤波缩小类内方差，再估计阈值，通常比对原噪声图直接阈值更稳定。但平滑也会混合边界两侧灰度，小目标可能被消除；核尺度应小于需要保留的最小结构。

=== b. 使用边缘

当大面积背景主导直方图时，可以先检测边缘，在边缘邻域中估计前景与背景的代表灰度或阈值。边缘带同时采到分界两侧，减少类别面积不平衡的影响。边缘本身若不可靠，估计也会偏差，因此通常先平滑，再用较宽的边缘带收集样本。

#figure(
  image("images/threshold-improvement-series.png", width: 100%, alt: "原始Otsu平滑Otsu和边缘辅助阈值的系列图"),
  caption: [(a) 噪声与渐变照明图；(b) 直接 Otsu；(c) 平滑后 Otsu；(d) 用于估计边界样本的边缘；(e) 根据边缘邻域灰度确定阈值的结果。]
)

若照明变化造成同一物体在不同位置灰度差异大于物体与背景差异，任何单一全局阈值都会失败，此时应做背景校正、分块阈值或自适应阈值，而不是继续微调一个全局数字。

#html.hr()
= 三、区域生长

#tufted.definition[区域生长][区域生长从一个或多个种子集合出发，反复把与当前区域邻接且满足同质性谓词的像素加入区域，直到没有候选像素。常见谓词比较候选灰度与种子灰度、区域均值或局部纹理特征。]

基本算法过程如下。

1. 选择位于目标内部的种子，建立队列并标记已接受像素。
2. 弹出一个区域像素，检查其四邻域或八邻域。
3. 对尚未访问的邻居计算同质性条件，例如 $abs(f(q)-mu_(R))<=T$。
4. 满足条件的邻居加入区域和队列，并更新区域统计量。
5. 队列为空时停止；对多个种子可分别生长，冲突时按距离或相似度决定标签。

若始终与固定种子灰度比较，结果不受生长顺序影响，但不能适应缓慢变化；若与动态区域均值比较，能跟随区域变化，却可能发生“泄漏”：均值逐步漂移后跨过弱边界。可同时限制局部梯度、最大路径代价或区域方差。

#figure(
  image("images/region-growing-series.png", width: 82%, alt: "区域生长在两个容差下的掩膜及叠加结果"),
  caption: [(a) 输入图像；(b) 从圆形内部种子以容差 8 生长；(c) 容差增至 18 后区域扩大，也更接近泄漏；(d) 将 (c) 以红色叠加，黄色点为种子。]
)

```python
from collections import deque


def region_grow(
    gray: np.ndarray,
    seed: tuple[int, int],
    tolerance: float,
) -> np.ndarray:
    seed_y, seed_x = seed
    reference = float(gray[seed_y, seed_x])
    accepted = np.zeros(gray.shape, dtype=np.uint8)
    queue = deque([(seed_y, seed_x)])
    accepted[seed_y, seed_x] = 255

    while queue:
        y, x = queue.popleft()
        for delta_y, delta_x in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            next_y = y + delta_y
            next_x = x + delta_x
            inside = (
                0 <= next_y < gray.shape[0]
                and 0 <= next_x < gray.shape[1]
            )
            if not inside or accepted[next_y, next_x] != 0:
                continue
            difference = abs(float(gray[next_y, next_x]) - reference)
            if difference <= tolerance:
                accepted[next_y, next_x] = 255
                queue.append((next_y, next_x))
    return accepted
```

#html.hr()
= 四、分水岭分割算法

== 1. 基础

分水岭把标量图像解释为地形：低值是谷底，高值是山脊。分割通常不直接使用原灰度，而使用梯度幅值，使物体内部成为低洼盆地，真实边界成为高脊。每个局部极小值都可能形成集水盆地，所以噪声会产生大量极小值并导致严重过分割。

#tufted.definition[集水盆地与分水线][在地形函数 $h(x,y)$ 上，沿最陡下降路径最终到达同一局部极小值的点构成一个集水盆地；相邻盆地之间无法唯一归属的分界构成分水线。]

== 2. 水坝

想象从每个极小值处打孔并缓慢注水。水位上升时，各盆地的已淹没区域向外扩张；当两个不同来源的水体即将相遇，就在接触处修建水坝。水位升到最高后，水坝集合就是分水线。

#figure(
  image("images/watershed-dam.png", width: 68%, alt: "两个地形盆地注水并在相遇位置建立水坝"),
  caption: [两个极小值对应不同集水盆地；水位上升到即将连通时，在中间山脊处建立水坝，阻止标签合并。]
)

数字实现可按高度从低到高处理像素，使用优先队列维护淹没前沿。一个未标记像素若只邻接一个盆地标签，就继承该标签；若邻接多个不同标签，则标为分水线。平台区域需要统一处理，否则扫描顺序会影响边界位置。

== 3. 算法过程

不带标记的基本分水岭过程为：

1. 计算平滑图像的梯度幅值 $h$。
2. 找出 $h$ 的全部局部极小区域，分别赋予盆地标签。
3. 按 $h$ 从小到大扩张各标签，相当于逐级升高水位。
4. 同一像素若被两个盆地同时到达，建立分水线。
5. 处理到最大高度后输出盆地标签和分水线。

因为梯度中的每个噪声凹点都可能成为极小值，实际很少直接接受基本结果。平滑可以减少极小值，但过强平滑会移动边界；更可靠的方法是由先验知识提供标记。

== 4. 标记

#tufted.definition[标记控制分水岭][标记控制分水岭预先指定一组前景标记和背景标记，并强制只有这些标记能够成为盆地源。算法在修改后的梯度地形上从标记扩张，从而抑制无意义的局部极小值。]

常见标记构造流程如下。

1. 对二值前景做开运算，删除噪声，得到较可靠的目标区域。
2. 膨胀得到确定背景 `sure_bg`。
3. 对前景做距离变换；距离局部最大处远离边界，以高阈值得到确定前景 `sure_fg`。
4. `sure_bg - sure_fg` 是未知边界带。
5. 对 `sure_fg` 做连通分量标记，标签整体加 1，把确定背景保留为标签 1；未知带设为 0。
6. 在原彩色图或梯度图上运行分水岭。OpenCV 以标签 $-1$ 表示最终分水线。

#figure(
  image("images/watershed-series.png", width: 100%, alt: "带标记分水岭从阈值到距离图标记和最终边界的六幅过程图"),
  caption: [(a) 输入图像；(b) 初始阈值前景；(c) 前景距离变换；(d) 距离阈值得到的确定前景；(e) 连通分量标记；(f) 分水岭结果，红色为分水线。]
)

```python
def marker_watershed(
    image_bgr: np.ndarray,
    binary: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    kernel = np.ones((3, 3), dtype=np.uint8)
    opened = cv2.morphologyEx(
        binary,
        cv2.MORPH_OPEN,
        kernel,
        iterations=2,
    )
    sure_background = cv2.dilate(opened, kernel, iterations=3)

    distance = cv2.distanceTransform(opened, cv2.DIST_L2, 5)
    _, sure_foreground = cv2.threshold(
        distance,
        0.48 * distance.max(),
        255,
        cv2.THRESH_BINARY,
    )
    sure_foreground = sure_foreground.astype(np.uint8)
    unknown = cv2.subtract(sure_background, sure_foreground)

    _, markers = cv2.connectedComponents(sure_foreground)
    markers = markers.astype(np.int32) + 1
    markers[unknown > 0] = 0

    markers = cv2.watershed(image_bgr.copy(), markers)
    overlay = image_bgr.copy()
    overlay[markers == -1] = (0, 0, 255)
    return markers, overlay
```

#tufted.remark[分水岭输入与标记必须同尺寸][`cv2.watershed` 要求三通道输入图像与 `int32` 标记矩阵具有完全相同的行列尺寸。标记值 0 表示待确定区域，正整数表示已知盆地，运算后 $-1$ 表示边界。若前景标记彼此粘连，分水岭无法再把它们拆开；若一个目标内有多个标记，则会被过分割。]

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
