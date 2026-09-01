#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "数字图像基础",
  description: "数字图像的矩阵表示、像素关系与基本数学运算",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

= 数字图像基础

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

经典成像模型把场景在像平面上的光学分布当作连续函数，计算机真正保存和处理的却是有限数组。连续坐标被空间采样限制到离散网格，连续强度又被灰度量化限制到有限数值；这两个步骤决定了原始信息以什么方式进入数字系统，也决定了后文所有运算的输入到底是什么。本章先建立数字图像的矩阵模型与坐标约定，再说明像素之间的邻接、连通、区域与边界，最后按“输出像素依赖什么”这一点把图像运算分为单像素、邻域、几何空间与变换四类。后续各章反复要回答的是同一个问题：一个算法的输出像素究竟依赖什么。#cite(<dip-book>)

#html.hr()
= 一、数字图像的表示

== 1. 从连续函数到矩阵

#tufted.definition[数字图像][一幅二维数字图像是定义在有限离散坐标集合上的函数
$
  f:{0,1,dots,N-1} times {0,1,dots,M-1} -> cal(L),
$
其中 $N$、$M$ 分别是水平、垂直方向的采样数，$cal(L)$ 是允许的像素值集合。灰度图的函数值是一个标量，彩色图的函数值通常是由多个通道组成的向量。]

把所有函数值按行排列，就得到 $M times N$ 矩阵。数学坐标写作 $f(x,y)$，其中 $x$ 是水平方向、$y$ 是垂直方向；NumPy 数组却先写行再写列，因此访问同一像素用 `image[y, x]`。书中图像坐标写成 $(x,y)$，数组坐标写成 `(y, x)`，二者只在 $x=y$ 时才一致。混淆两套记号会让宽高、平移方向与坐标点全部交换，所以本章及后续各章都固定采用这一约定。

#figure(
  image("images/image-matrix.png", width: 62%, alt: "数字图像矩阵中的横纵坐标与像素索引"),
  caption: [横轴 $x$ 对应数组列，纵轴 $y$ 对应数组行；高亮像素的几何坐标为 $(2,1)$，NumPy 索引为 `[1, 2]`。]
)

本章规定图像坐标原点位于左上角，$x$ 向右增加、$y$ 向下增加。这与解析几何中 $y$ 轴向上的直角坐标系不同。若图像宽为 `width`、高为 `height`，合法坐标满足 $0<=x<"width"$、$0<=y<"height"$；右下角像素是 `(width - 1, height - 1)`。后文提到方向时都沿用这个坐标方向，不再重复声明。

```python
import cv2

image = cv2.imread("input.png", cv2.IMREAD_COLOR)
if image is None:
    raise FileNotFoundError("input.png")

height, width, channels = image.shape
blue, green, red = image[20, 35]
print(width, height, channels)
```

OpenCV 读取的普通彩色图像形状为 `(height, width, channels)`，默认通道顺序是 BGR 而非 RGB。灰度读取结果只有 `(height, width)` 两维。文件编码中的 PNG、JPEG 与内存中的数组也不是同一事物：`imread` 负责解码和颜色组织，后续算法面对的是解码后的矩阵。

== 2. 灰度级与数据类型

#tufted.definition[灰度级与灰度级数][灰度图像中一个像素能够取得的离散强度值称为灰度级。若使用 $b$ 位无符号整数表示像素，则通常有 $L=2^b$ 个灰度级，取值为 $0,1,dots,L-1$；$b$ 称为每像素位数或灰度位深。]

8 位灰度图共有 256 个灰度级，惯例上 0 表示黑，255 表示白。更高位深并不必然让显示器看起来更亮，而是让相邻可表示强度之间的间隔更小。医学影像、科学成像和高动态范围处理中常保留 `uint16` 或浮点数据；若过早转成 `uint8`，细小差异可能在后续增强之前已经丢失。

彩色图像不能简单说有“256 个颜色”。一个 8 位三通道像素各通道有 256 种取值，组合数为 $256^3$。通道的物理含义由颜色空间决定：BGR/RGB 表示三种颜色分量，HSV 将色相、饱和度与明度分离，某些相机数据还可能是线性光强或 Bayer 阵列。读取数组后必须同时确认 `dtype`、通道数和颜色空间。

== 3. 空间分辨率与灰度分辨率

#tufted.definition[空间分辨率][空间分辨率描述图像区分空间细节的能力。对固定视场，采样网格越密、单位长度内像素越多，能够表达的空间细节通常越丰富。仅给出矩阵尺寸并不能完全描述空间分辨率，还需要知道图像覆盖的实际范围或采样间距。]

#tufted.definition[灰度分辨率][灰度分辨率描述区分强度细微变化的能力，通常由量化级数 $L$ 或位深 $b=log_(2) L$ 表示。位深越高，相邻可表示强度之间的间隔越小，但前提是传感器噪声和成像链路确实提供了相应有效精度。]

#figure(
  image("images/sampling-quantization.png", width: 80%, alt: "不同密度的空间采样网格与有限灰度量化级"),
  caption: [左、中的采样网格密度不同；右侧将连续亮度压到八个离散灰度级。空间采样和灰度量化是两个独立步骤。]
)

降低空间分辨率会造成细线消失、锯齿和混叠；降低灰度分辨率会出现色带或伪轮廓。前者改变“在哪里取样”，后者改变“每个样本允许取什么值”。把一张 8 位图像简单放大到更多像素，只是插值出更密的数组，不会凭空恢复原场景中未被采集的细节。

#tufted.theorem[均匀量化误差界][若把区间宽度为 $R$ 的连续强度均匀量化为 $L$ 级，并把每个区间映射到其中点，则量化步长为 $Delta=R/L$，任一样本的量化误差绝对值不超过 $Delta/2$。增加量化级数会减小这一上界，但不会消除传感器噪声。]

```python
import cv2

gray = cv2.imread("input.png", cv2.IMREAD_GRAYSCALE)
levels = 8
step = 256 // levels
quantized = (gray // step) * step + step // 2
quantized = quantized.clip(0, 255).astype("uint8")
```

这里先用整数除法确定量化区间，再映射到区间中点。真实图像处理流程若需要继续计算，往往先转成 `float32` 并归一化到 `[0,1]`，最后输出时才重新量化。

#html.hr()
= 二、像素

== 1. 邻域、邻接与连通

像素不是孤立数值。边缘、区域和纹理都来自像素之间的空间关系，因此必须先说明哪些像素被视为邻居。

#tufted.definition[四邻域、对角邻域与八邻域][设像素 $p=(x,y)$。其四邻域为
$
  N_(4)(p)={(x-1,y),(x+1,y),(x,y-1),(x,y+1)},
$
对角邻域为
$
  N_(D)(p)={(x-1,y-1),(x+1,y-1),(x-1,y+1),(x+1,y+1)},
$
八邻域为 $N_(8)(p)=N_(4)(p) union N_(D)(p)$。超出图像边界的坐标不属于实际邻域。]

#figure(
  image("images/pixel-neighborhood.png", width: 70%, alt: "中心像素的四邻域、对角邻域和八邻域"),
  caption: [橙色为中心像素；三个面板依次高亮四邻域、对角邻域和八邻域。]
)

“邻居”只说明几何位置接近，“邻接”还要加入像素值条件。设 $V$ 是允许参与连接的灰度集合，例如二值图像中取 $V={1}$。两个值都属于 $V$ 的像素若互为四邻域，称四邻接；若互为八邻域，称八邻接。

八邻接可能产生对角线两侧的连接歧义。混合邻接规定：对角相邻像素只有在它们的共同四邻域中没有属于 $V$ 的像素时才邻接。它既允许必要的对角连接，又避免一个小方块中出现两条竞争路径。

#tufted.definition[路径与连通][在给定邻接规则下，若像素序列 $p_(0),p_(1),dots,p_(n)$ 中每一对相邻像素都彼此邻接，则它构成从 $p_(0)$ 到 $p_(n)$ 的路径。若像素集合 $S$ 中任意两点之间都存在完全位于 $S$ 内的路径，则称 $S$ 连通；极大的连通子集称为连通分量。]

下面用 BFS 标记二值图像中的四连通分量。队列保存已经发现但尚未展开邻居的像素；一个像素在入队时立刻写入标签，避免被多个邻居重复加入。

```python
from collections import deque
import numpy as np

def label_components(binary: np.ndarray) -> tuple[np.ndarray, int]:
    foreground = binary != 0
    labels = np.zeros(binary.shape, dtype=np.int32)
    component = 0
    height, width = binary.shape

    for y in range(height):
        for x in range(width):
            if not foreground[y, x] or labels[y, x] != 0:
                continue

            component += 1
            labels[y, x] = component
            queue = deque([(x, y)])

            while queue:
                px, py = queue.popleft()
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nx, ny = px + dx, py + dy
                    inside = 0 <= nx < width and 0 <= ny < height
                    if inside and foreground[ny, nx] and labels[ny, nx] == 0:
                        labels[ny, nx] = component
                        queue.append((nx, ny))
    return labels, component
```

实际项目可直接调用 `cv2.connectedComponents` 或 `cv2.connectedComponentsWithStats`，并通过 `connectivity=4` 或 `8` 选择邻接规则。手写实现的意义在于看清：连通性并非像素值自身携带的属性，而是由前景集合与邻接规则共同定义。

== 2. 区域与边界

#tufted.definition[区域、内部与边界][在给定邻接规则下，区域是图像中的连通像素集合 $R$。若 $p in R$ 的全部指定邻居也属于 $R$，则 $p$ 是内部像素；若 $p in R$ 至少有一个指定邻居不属于 $R$，则 $p$ 是边界像素。所有边界像素组成区域边界 $partial R$。]

#figure(
  image("images/region-boundary.png", width: 52%, alt: "像素区域的内部与离散边界"),
  caption: [橙色像素接触背景，构成离散边界；绿色像素的四邻域均在区域内，属于内部。边界会随四邻域或八邻域约定改变。]
)

区域是像素集合，边界则依赖邻域定义。对角接触的两个前景块在八邻接下可能属于同一区域，在四邻接下却是两个分量；相应的边界也会改变。讨论“一个目标有几个区域”“轮廓是否闭合”时，必须先固定前景值和连通规则。

二值图像的内部边界可以通过原图减去一次腐蚀得到。腐蚀只保留结构元素能够完全放入前景的像素，因此被移除的部分正是相对于该结构元素的边缘层。

```python
import cv2
import numpy as np

binary = cv2.imread("mask.png", cv2.IMREAD_GRAYSCALE)
_, binary = cv2.threshold(binary, 0, 255, cv2.THRESH_BINARY)
kernel = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
interior = cv2.erode(binary, kernel)
boundary = cv2.subtract(binary, interior)
```

十字结构元素对应四邻域意义下的局部检查；换成全 1 的 $3 times 3$ 方形结构元素，更接近八邻域约束。这里使用 `cv2.subtract`，是因为输入为 `uint8`，OpenCV 会做饱和减法。

== 3. 像素间距离

#tufted.definition[三种常用像素距离][对 $p=(x,y)$、$q=(s,t)$，欧氏距离为 $D_(E)(p,q)=sqrt((x-s)^2+(y-t)^2)$；城市街区距离为 $D_(4)(p,q)=abs(x-s)+abs(y-t)$；棋盘距离为 $D_(8)(p,q)=max(abs(x-s),abs(y-t))$。]

$D_(4)$ 的单位步对应四邻域移动，$D_(8)$ 的单位步允许八邻域移动，因此命名与邻接规则相呼应。距离变换、最近目标搜索和形态学处理中应选择与几何假设一致的度量，不能只因欧氏距离最熟悉就默认使用它。

#html.hr()
= 三、数学运算

== 1. 对应元素运算

#tufted.definition[图像的对应元素运算][设两幅图像 $f,g$ 定义在相同坐标域上，二元标量运算 $⊙$ 所诱导的图像运算定义为
$
  h(x,y)=f(x,y) ⊙ g(x,y).
$
除非特别说明，本章所说图像加、减、乘、除和逻辑运算均指同一坐标处元素之间的运算，而不是线性代数中的矩阵乘法。多通道图像通常对各通道独立执行。]

这个约定要求两幅图像具有相同尺寸和兼容通道。NumPy 的广播虽然允许 `(H,W,3)` 与 `(3,)` 运算，但广播是数组语言提供的扩展，并不改变图像运算的基本定义。若两幅图像拍摄视角不同，即使数组尺寸相同，相同下标也未必对应场景中的同一点；在相加或相减之前通常要先配准。

== 2. 算术运算

=== a. 加法与加权相加

图像相加可叠加不同成分，加权相加则用于混合、曝光融合和时间平均：
$
  h(x,y)=alpha f(x,y)+beta g(x,y)+gamma.
$
若多幅观测包含相互独立、均值为零的随机噪声，对配准后的图像求平均可以削弱噪声；但场景或相机移动会先造成重影，所以“相加降噪”隐含了几何对齐假设。

```python
blend = cv2.addWeighted(image_a, 0.7, image_b, 0.3, 0.0)
```

=== b. 减法

相减突出两幅图像的差异，可用于背景减除、运动检测、模板残差和校正固定图样噪声。方向具有意义：`a - b` 与 `b - a` 不同；若只关心变化幅度，应使用 `cv2.absdiff` 或在有符号/浮点类型中相减后取绝对值。

```python
difference = cv2.absdiff(current_frame, background)
gray_difference = cv2.cvtColor(difference, cv2.COLOR_BGR2GRAY)
_, changed = cv2.threshold(gray_difference, 25, 255, cv2.THRESH_BINARY)
```

=== c. 乘法与除法

对应元素乘法可施加浮点掩膜、空间增益或照明衰减。二值掩膜若用 0 与 1 表示，`image * mask` 保留目标区域并把其余位置归零。除法可用于比值图像和照明校正，例如观测近似满足 $f(x,y)=r(x,y)i(x,y)$ 时，用估计照明 $i$ 去除可近似恢复反射分量 $r$。分母接近零会放大噪声，必须设下界或只在有效掩膜内相除。

```python
import numpy as np

source = image.astype(np.float32) / 255.0
gain = np.linspace(0.6, 1.0, image.shape[1], dtype=np.float32)
gain = gain[None, :, None]
corrected = np.clip(source * gain, 0.0, 1.0)

illumination = np.maximum(illumination.astype(np.float32), 1.0)
ratio = image.astype(np.float32) / illumination
```

=== d. 溢出、回绕与饱和

8 位无符号像素只能表示 0 到 255。数学上 `250 + 10 = 260`，但输出仍为 `uint8` 时必须规定越界策略。OpenCV 的 `cv2.add`、`cv2.subtract` 等核心数组运算通常执行饱和转换，把 260 截到 255、把负值截到 0；NumPy 直接对 `uint8` 使用 `+` 或 `-` 则按模 256 回绕。#cite(<opencv-arrays>)

```python
import cv2
import numpy as np

x = np.array([250], dtype=np.uint8)
y = np.array([10], dtype=np.uint8)
print(cv2.add(x, y)[0])  # 255：饱和
print((x + y)[0])        # 4：模 256 回绕

signed_difference = x.astype(np.int16) - y.astype(np.int16)
```

需要保留真实中间结果时，应先提升到 `int16`、`float32` 等更宽类型，完成运算和归一化后再显式裁剪并转换回输出类型。不要等错误回绕发生后再转浮点，因为信息已经丢失。OpenCV 的对应元素乘除、加减与多通道独立处理语义可查阅官方数组运算文档。#cite(<opencv-arrays>)

== 3. 集合运算

二值图像可以解释为集合的指示函数：非零像素的坐标属于集合，零像素属于背景。在这种表示下，两掩膜的交集保留同时属于两者的区域，并集保留至少属于一个的区域，差集保留属于第一个而不属于第二个的区域。

集合运算的价值在于组合空间条件。例如“道路区域且不在阴影中”可写成道路掩膜与阴影补集的交；“红色目标或蓝色目标”可写成两个颜色掩膜的并；“检测框内部但排除隐私区域”则是框掩膜减去隐私掩膜。

```python
intersection = cv2.bitwise_and(mask_a, mask_b)
union = cv2.bitwise_or(mask_a, mask_b)
difference = cv2.bitwise_and(mask_a, cv2.bitwise_not(mask_b))
```

这里掩膜应保持同一尺寸，并统一使用 0 表示假、255 表示真。若一个掩膜用 0/1、另一个用 0/255，逻辑真假仍可能成立，但后续显示、乘法和阈值会产生不一致，最好在入口处规范化。

== 4. 逻辑运算

逻辑与、或、非、异或作用于二值命题；OpenCV 的 `bitwise_and`、`bitwise_or`、`bitwise_not`、`bitwise_xor` 实际逐位作用于整数像素。对值仅为 0 和 255 的二值图像，逐位逻辑与集合逻辑一致；对普通灰度值，它处理的是每个二进制位，结果不等于比较亮度大小。

异或可检测两个二值掩膜中归属发生变化的位置；非运算可交换前景与背景；与运算还常结合 `mask` 参数只处理指定区域。若意图是判断 `gray > 128`，应先用比较或阈值得到布尔掩膜，而不是对灰度值直接做按位运算。

```python
_, bright = cv2.threshold(gray, 128, 255, cv2.THRESH_BINARY)
selected = cv2.bitwise_and(image, image, mask=bright)
changed_membership = cv2.bitwise_xor(mask_before, mask_after)
```

== 5. 空间运算

空间运算直接在图像平面上定义，可以按照输出像素依赖的输入范围分为单像素运算、邻域运算和几何空间变换。

#figure(
  image("images/operation-scales.png", width: 88%, alt: "单像素映射、邻域汇聚和几何坐标变换"),
  caption: [左：每个灰度独立映射；中：一个输出由局部邻域决定；右：输出坐标通过几何关系回到输入图像取样。]
)

=== a. 单像素运算

单像素运算满足 $g(x,y)=T(f(x,y))$，输出只依赖同一坐标的输入值。反相、阈值、对数和伽马变换都属于此类。它们不查看周围像素，因此无法直接判断边缘或纹理。

```python
negative = cv2.bitwise_not(gray)
_, binary = cv2.threshold(gray, 128, 255, cv2.THRESH_BINARY)
```

=== b. 邻域运算

邻域运算令 $g(x,y)$ 依赖 $(x,y)$ 周围窗口中的多个像素。均值滤波用邻域平均抑制快速起伏，梯度算子用邻域差分响应边缘，中值滤波用邻域排序去除脉冲噪声。窗口到达图像边缘时会伸出数组，所以必须规定边界扩展方式，例如常数填充、复制边缘或镜像。

```python
smoothed = cv2.blur(gray, (5, 5), borderType=cv2.BORDER_REFLECT)
median = cv2.medianBlur(gray, 5)
```

邻域运算的权重、卷积与相关将在空间滤波章节展开。此处最重要的区分是：单像素运算可独立并行处理每个位置，邻域运算必须读取周围数据。

=== c. 几何空间变换

几何变换改变像素所在坐标，包括平移、旋转、缩放、仿射和透视变换。若直接把每个输入像素向前投到输出位置，离散坐标取整后可能出现空洞；实践中通常对每个输出坐标反向求对应输入位置，再用最近邻、双线性或更高阶方法插值。超出输入范围的位置还要使用边界模式填充。#cite(<opencv-geometric>)

```python
height, width = image.shape[:2]
center = (width / 2.0, height / 2.0)
matrix = cv2.getRotationMatrix2D(center, 20.0, 1.0)

rotated = cv2.warpAffine(
    image,
    matrix,
    (width, height),
    flags=cv2.INTER_LINEAR,
    borderMode=cv2.BORDER_REFLECT,
)
```

仿射变换用 $2 times 3$ 矩阵表达线性变换与平移，可以保持直线和平行关系；透视变换用齐次坐标中的 $3 times 3$ 矩阵，可以描述近大远小。OpenCV 还提供 `remap` 接受逐像素映射表，用于镜头畸变校正和一般非线性重映射。#cite(<opencv-affine>)

== 6. 图像变换

#tufted.definition[图像变换][图像变换把图像从一种表示域映射到另一种表示域。若空间域图像为 $f(x,y)$，变换算子 $cal(T)$ 产生系数表示 $F(u,v)=cal(T){f(x,y)}$；逆变换再由系数重建空间图像。]

这里的“图像变换”不要与上一节的“几何变换”混淆。几何变换改变内容在空间中的位置，输出仍是一幅按 $(x,y)$ 排列的图像；傅里叶变换、离散余弦变换和小波变换则改变表示基底，让平滑变化、周期结构或局部尺度信息以系数形式出现。

二维离散傅里叶变换把空间图像分解为不同频率的复指数分量。低频描述缓慢变化的背景和大结构，高频包含快速变化、细节、边缘与部分噪声。变换本身不等于滤波：只有修改频域系数并逆变换，才形成频域滤波流程。

```python
import cv2
import numpy as np

gray32 = np.float32(gray)
spectrum = cv2.dft(gray32, flags=cv2.DFT_COMPLEX_OUTPUT)
spectrum = np.fft.fftshift(spectrum, axes=(0, 1))

magnitude = cv2.magnitude(spectrum[:, :, 0], spectrum[:, :, 1])
display_spectrum = np.log1p(magnitude)
display_spectrum /= display_spectrum.max()

restored = np.fft.ifftshift(spectrum, axes=(0, 1))
restored = cv2.idft(restored, flags=cv2.DFT_SCALE | cv2.DFT_REAL_OUTPUT)
```

频谱是复数数组，直接显示其幅值时动态范围通常过大，所以示例用 `log1p` 压缩显示范围；这一步只为可视化，不应混进等待逆变换的原始系数。只做正变换再逆变换，理论上应恢复原图，实际差异来自浮点舍入。

#tufted.remark[从本章到后续章节][灰度变换研究单像素映射，空间滤波研究邻域运算，频域滤波研究变换系数的选择与修改，形态学则以集合和结构元素研究区域形状。本章的分类不是并列罗列术语，而是在回答每种算法的输出像素究竟依赖什么。]

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
