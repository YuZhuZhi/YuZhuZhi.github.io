#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "彩色图像",
  description: "彩色模型、颜色变换与假彩色处理",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

= 彩色图像

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

灰度图像用一个数表示像素亮暗，彩色图像则必须同时描述亮度与色彩。最直接的做法是记录红、绿、蓝三个分量，但 RGB 数值既依赖设备，又把亮度和色度混在一起：一个 RGB 三元组未必能在另一台显示器或打印机上产生相同视觉结果；只想增强亮度时，分别修改三个通道还可能改变色相。因此彩色图像处理先要回答两个问题：颜色用什么坐标表示，以及当前任务应在哪个颜色空间中完成。“颜色空间”是一种坐标系选择而非自然事实，答案取决于数据从哪里来、将送往哪里以及要做什么运算：需要跨设备传递时选设备无关空间，需要分开明暗与色调时选感知式分解，需要实际显示或打印时则回到设备相关空间。

#tufted.definition[彩色图像][设图像定义域为 $Omega$，具有 $n$ 个颜色分量的彩色图像是向量值函数
$
  bold(f):Omega arrow.r RR^n,
  quad
  bold(f)(x,y)=(f_(1)(x,y),dots,f_(n)(x,y)).
$
分量的含义由颜色模型及其编码约定共同规定。例如 RGB 图像的三个分量给出红、绿、蓝基色坐标；只有在线性 RGB 中，它们才与相应光强成正比。CIELAB 的三个分量则近似对应明度、红绿方向和黄蓝方向。]

彩色处理既可以逐分量进行，也可以把像素视作颜色空间中的向量统一变换。前者实现简单，却容易破坏分量之间的比例；后者能够显式保持色相、白点或感知色差。本章从设备相关的 RGB、CMYK 出发，经由 HSI 的感知式分解进入设备无关的 CIE 模型，最后讨论校色、直方图处理和假彩色映射。#cite(<dip-book>)

#html.hr()
= 一、彩色图像的表示

颜色模型不是给同一种颜色随意换三个名称，而是在一个坐标系中规定“哪些数值对应哪些颜色”。选择模型时要看数据从哪里来、将送往哪里以及要执行什么运算：摄像机和显示器通常围绕 RGB 工作，印刷使用 CMYK，基于色相的交互调整适合 HSI/HSV，而跨设备测量和色差计算更适合 XYZ、CIELAB。

== 1. RGB 彩色模型

#tufted.definition[RGB 彩色模型][RGB 是加色模型。归一化颜色写成
$
  bold(c)=(R,G,B), quad 0<=R,G,B<=1.
$
三个坐标分别表示红、绿、蓝基色的相对强度；$(0,0,0)$ 为黑，$(1,1,1)$ 为白，任意颜色对应单位立方体中的一点。]

RGB 之所以称为“加色”，是因为光能量相加：红光与绿光叠加产生黄色，绿光与蓝光叠加产生青色，红光与蓝光叠加产生品红，三者共同达到最大值产生白色。RGB 立方体从黑色顶点到白色顶点的主对角线满足 $R=G=B$，表示全部无彩色灰度。

#figure(
  image("images/rgb-cube.png", width: 76%, alt: "RGB 单位立方体的八个颜色顶点"),
  caption: [RGB 颜色立方体。三个坐标轴分别增加红、绿、蓝光；对角线 $R=G=B$ 从黑色连接到白色。]
)

数字图像通常把每个分量量化为 8 位无符号整数，因此共有 $256^3=16,777,216$ 种三元组。这里的“约一千六百万种数值组合”不等于人眼能可靠区分同样多种颜色，也不保证这些三元组在任意设备上具有相同的色度。RGB 只给出坐标形式；要确定真实颜色，还必须知道基色的色度、白点和传递函数。例如常见 sRGB 在存储前施加非线性编码，数值 0.5 并不表示线性光强恰好为最大值的一半。

#tufted.remark[OpenCV 中的颜色顺序与数组形状][OpenCV 的 `imread` 默认返回 BGR，而不是通常书写的 RGB。更容易混淆的是，普通 OpenCV 彩色图像采用通道后置布局，形状为 `[M, N, 3]`：$M$ 是图像高度即行数，$N$ 是宽度即列数，最后一维依次存放 B、G、R。因而 `image[y, x]` 得到一个 BGR 像素，`image[y, x, 0]` 才是该像素的蓝色分量；`image[0]` 表示第一行，绝不是整个蓝通道。`cv2.split(image)` 返回三个形状均为 `[M, N]` 的二维数组。只有显式执行 `transpose(2, 0, 1)`，数组才变成机器学习框架常见的通道前置布局 `[3, M, N]`。]

具体而言，OpenCV 中常见的数组布局如下：

1. 灰度图像的形状是 `[M, N]`，没有长度为 1 的通道轴。
2. 默认彩色图像的形状是 `[M, N, 3]`，末轴顺序为 B、G、R。
3. 使用 `cv2.IMREAD_UNCHANGED` 读取带透明通道的 PNG 时，形状可能是 `[M, N, 4]`，末轴顺序为 B、G、R、A。
4. Matplotlib、Pillow 等工具通常按 RGB 解释三通道数组，所以显示前应使用 `cv2.cvtColor(image, cv2.COLOR_BGR2RGB)`。
5. 部分深度学习接口要求 `[3, M, N]` 或批量形式 `[B, 3, M, N]`；这是张量接口的布局要求，不是 OpenCV 图像本身的默认格式。

下面把同一图像拆成三个加色通道。单通道图不是简单画成灰度，而是只保留对应基色，使“该通道在哪里贡献较大”可以直接观察。

#figure(
  image("images/rgb-channel-series.png", width: 82%, alt: "彩色图像及其红绿蓝三个加色通道"),
  caption: [(a) 原彩色图像；(b) 仅保留红通道；(c) 仅保留绿通道；(d) 仅保留蓝通道。]
)

```python
from pathlib import Path

import cv2
import numpy as np


image_bgr = cv2.imread(str(Path("color-scene.png")))
if image_bgr is None:
    raise OSError("图像读取失败")

height, width, channel_count = image_bgr.shape
assert channel_count == 3

# 普通索引顺序是 [行 y, 列 x, 通道 c]。
y, x = 40, 70
blue_value = image_bgr[y, x, 0]
green_value = image_bgr[y, x, 1]
red_value = image_bgr[y, x, 2]

blue, green, red = cv2.split(image_bgr)
zeros = np.zeros_like(red)

red_only = cv2.merge([zeros, zeros, red])
green_only = cv2.merge([zeros, green, zeros])
blue_only = cv2.merge([blue, zeros, zeros])

# 给按 RGB 解释数组的绘图库使用，形状仍是 [M, N, 3]。
image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

# 若神经网络明确要求通道前置，再转换为 [3, M, N]。
image_chw = np.transpose(image_rgb, (2, 0, 1))
image_chw = np.ascontiguousarray(image_chw)
```

== 2. CMY 与 CMYK 彩色模型

#tufted.definition[CMY 彩色模型][CMY 是减色模型。对于归一化、处于同一编码约定下的 RGB 值，理想转换为
$
  mat(C;M;Y)=mat(1;1;1)-mat(R;G;B).
$
青、品红、黄颜料分别吸收红、绿、蓝光；白纸未着墨时接近白色，叠加墨量后反射光逐渐减少。]

理想情况下 $C=M=Y=1$ 应产生黑色，但真实油墨的光谱吸收不理想，三色叠印通常得到偏褐且耗墨的暗色。因此印刷系统单独加入黑色通道 $K$。一种常见的数学分解是
$
  K&=min(C,M,Y),\
  C'&=(C-K)/(1-K),\
  M'&=(M-K)/(1-K),\
  Y'&=(Y-K)/(1-K),
$
其中 $K=1$ 时令 $C'=M'=Y'=0$。这只是“灰成分替换”的基础形式；实际色彩管理还要使用设备 ICC 特性文件、总墨量限制和黑版生成曲线，不能把任意 RGB 图像按上述公式直接当作印刷终稿。

#figure(
  image("images/cmyk-model.png", width: 73%, alt: "青品红黄三种减色基色叠加并抽取黑色分量"),
  caption: [CMY 通过吸收互补基色减少反射光；公共灰成分可转移到独立的黑色通道 $K$。]
)

#figure(
  image("images/cmyk-series.png", width: 88%, alt: "彩色图像和青品红黄黑各印刷分量的系列图"),
  caption: [(a) 原彩色图像；(b) 青色分量；(c) 品红分量；(d) 黄色分量；(e) 黑色分量。分量越强，对应油墨覆盖量越大。]
)

```python
rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB).astype(np.float32)
rgb /= 255.0

cmy = 1.0 - rgb
black = np.min(cmy, axis=2)
denominator = np.maximum(1.0 - black, 1e-6)

cyan = (cmy[..., 0] - black) / denominator
magenta = (cmy[..., 1] - black) / denominator
yellow = (cmy[..., 2] - black) / denominator

fully_black = black >= 1.0 - 1e-6
cyan[fully_black] = 0.0
magenta[fully_black] = 0.0
yellow[fully_black] = 0.0
```

== 3. HSI 彩色模型

RGB 适合生成和存储颜色，却把色相、饱和程度与总体数值尺度耦合在三个基色坐标中。HSI 将三者重新参数化为色相 $H$、饱和度 $S$ 与强度 $I$，便于分别讨论这些属性；这种分解是计算模型，不等同于完整的人类颜色感知模型。

#tufted.definition[HSI 彩色模型][色相 $H$ 是颜色在色轮上的角度，饱和度 $S$ 表示颜色偏离灰轴的相对程度，强度 $I$ 是三个 RGB 分量的算术平均。对归一化 RGB，
$
  I=(R+G+B)/3,
  quad
  S=1-3 min(R,G,B)/(R+G+B),
$
其中 $R+G+B=0$ 时约定 $S=0$。]

色相来自 RGB 向量绕灰轴的方向。令
$
  theta=arccos(
    ((R-G)+(R-B)) /
    (2 sqrt((R-G)^2+(R-B)(G-B)))
  ),
$
则
$
  H=cases(theta & B<=G, 2pi-theta & B>G).
$
当 $R=G=B$ 时，像素位于灰轴上，色相没有定义；程序中通常把 $H$ 置零，同时通过 $S=0$ 表明该角度不应被解释。接近灰轴时，极小噪声也可能使色相剧烈变化，所以不能在低饱和区域盲目增强色相。

这里的 $I$ 是否能解释为物理光强，取决于输入 RGB 是否已经线性化。若直接把带有 sRGB 非线性编码的数值代入公式，$I$ 只是编码值的平均，不是辐射度或光度学亮度；用于定量成像前必须先说明数据的传递函数。

#figure(
  image("images/hsi-geometry.png", width: 60%, alt: "HSI 空间中强度轴、饱和度半径和色相角的几何关系"),
  caption: [HSI 的 $I$ 沿黑白轴变化，$S$ 是离开灰轴的距离，$H$ 是绕灰轴旋转的角度。]
)

#tufted.theorem[整体光强缩放下的 HSI 性质][若 $R',G',B'=lambda(R,G,B)$ 且 $lambda>0$、缩放后没有裁剪，则 $H'=H$、$S'=S$、$I'=lambda I$。]

#tufted.proof[代入强度公式立即得到 $I'=lambda I$。饱和度中的分子 $min(R,G,B)$ 与分母 $R+G+B$ 同时乘以 $lambda$，比值不变。色相公式的分子含一次齐次项、分母平方根内含二次齐次项，正比例因子约去，因此角度不变。若数值被裁剪到 0 或 1，这个结论不再成立。]

```python
def rgb_to_hsi(rgb_u8: np.ndarray) -> np.ndarray:
    rgb = rgb_u8.astype(np.float64) / 255.0
    red, green, blue = cv2.split(rgb)

    intensity = (red + green + blue) / 3.0
    total = red + green + blue
    saturation = np.zeros_like(intensity)
    non_black = total > 1e-12
    saturation[non_black] = 1.0 - (
        3.0 * np.minimum.reduce([red, green, blue])[non_black]
        / total[non_black]
    )

    numerator = 0.5 * ((red - green) + (red - blue))
    denominator = np.sqrt(
        (red - green) ** 2
        + (red - blue) * (green - blue)
    )
    cosine = numerator / np.maximum(denominator, 1e-12)
    theta = np.arccos(np.clip(cosine, -1.0, 1.0))
    hue = np.where(blue <= green, theta, 2.0 * np.pi - theta)
    hue[denominator <= 1e-12] = 0.0

    return np.dstack([hue, saturation, intensity])
```

#tufted.remark[HSI 不等于 OpenCV 的 HSV][HSI 的强度是 $(R+G+B)/3$，HSV 的 $V$ 是 $max(R,G,B)$，HSL 的 $L$ 又是最大值与最小值的平均。它们的色相形式相近，但饱和度定义也不同。`cv2.COLOR_BGR2HSV` 不能代替上述 HSI 公式。]

== 4. 设备无关彩色模型

设备 RGB 的坐标由具体基色和传递函数决定。为了在相机、显示器、打印机之间传递颜色，需要先进入以标准观察者实验为基础的 CIE XYZ。XYZ 的 $Y$ 分量与亮度相关，且能通过线性矩阵承接线性 RGB；但 XYZ 中的欧氏距离并不近似等于视觉色差，于是又有非线性变换得到 CIELAB。#cite(<cie-lab>)

#tufted.definition[CIE 色度坐标][对三刺激值 $X,Y,Z$，令
$
  x=X/(X+Y+Z),
  quad
  y=Y/(X+Y+Z),
  quad
  z=Z/(X+Y+Z).
$
当分母非零时 $x+y+z=1$，所以通常只用 $(x,y)$ 描述色度，再用 $Y$ 单独描述亮度。]

#tufted.theorem[色度坐标的尺度不变性][若 $lambda>0$，则 $(lambda X,lambda Y,lambda Z)$ 与 $(X,Y,Z)$ 具有相同的 $(x,y,z)$ 色度坐标。]

#tufted.proof[每个分子的缩放因子 $lambda$ 与分母中的公共因子 $lambda$ 相消。因此色度记录三个刺激值的比例，而不记录总体能量。]

以 D65 白点为例，线性 sRGB 到 XYZ 的常用矩阵为
$
  mat(X;Y;Z)=
  mat(
    0.4124564, 0.3575761, 0.1804375;
    0.2126729, 0.7151522, 0.0721750;
    0.0193339, 0.1191920, 0.9503041
  )
  mat(R_("lin");G_("lin");B_("lin")).
$
这里必须先去除 sRGB 的非线性编码。直接把 8 位 sRGB 数值乘矩阵会把编码值误当成光强。

CIELAB 以参考白点 $(X_(n),Y_(n),Z_(n))$ 归一化：
$
  L^*&=116 f(Y/Y_(n))-16,\
  a^*&=500(f(X/X_(n))-f(Y/Y_(n))),\
  b^*&=200(f(Y/Y_(n))-f(Z/Z_(n))),
$
其中 $delta=6/29$，
$
  f(t)=cases(t^(1/3) & t>delta^3, t/(3delta^2)+4/29 & t<=delta^3).
$
$L^*$ 表示明度，$a^*$ 的正负方向大致对应红与绿，$b^*$ 的正负方向大致对应黄与蓝。CIELAB 被设计为近似感知均匀空间，基础色差可写为 $Delta E_("ab")^*=sqrt((Delta L^*)^2+(Delta a^*)^2+(Delta b^*)^2)$，但高精度应用还会使用 CIEDE2000 等改进公式。

#figure(
  image("images/device-independent.png", width: 94%, alt: "设备 RGB 经线性化和矩阵变换进入 XYZ 再按参考白点进入 CIELAB 的流程"),
  caption: [设备相关 RGB 先依据其特性转换到标准 XYZ，再结合参考白点转换到近似感知均匀的 CIELAB。]
)

```python
def srgb_to_xyz(rgb_u8: np.ndarray) -> np.ndarray:
    encoded = rgb_u8.astype(np.float64) / 255.0
    linear = np.where(
        encoded <= 0.04045,
        encoded / 12.92,
        ((encoded + 0.055) / 1.055) ** 2.4,
    )
    matrix = np.array(
        [
            [0.4124564, 0.3575761, 0.1804375],
            [0.2126729, 0.7151522, 0.0721750],
            [0.0193339, 0.1191920, 0.9503041],
        ]
    )
    return linear @ matrix.T


def xyz_to_lab(xyz: np.ndarray) -> np.ndarray:
    white_d65 = np.array([0.95047, 1.0, 1.08883])
    ratio = xyz / white_d65
    delta = 6.0 / 29.0
    transformed = np.where(
        ratio > delta ** 3,
        np.cbrt(ratio),
        ratio / (3.0 * delta ** 2) + 4.0 / 29.0,
    )
    fx, fy, fz = cv2.split(transformed)
    return np.dstack(
        [
            116.0 * fy - 16.0,
            500.0 * (fx - fy),
            200.0 * (fy - fz),
        ]
    )
```

#html.hr()
= 二、彩色变换

彩色变换可分为两类。第一类只改变坐标表达而尽量保持视觉颜色，例如 RGB 转 XYZ；第二类有意改变颜色，例如白平衡、色调调整或直方图增强。二者的判据是“是否要求颜色外观在变换前后保持不变”，而不是“是否改动了数值”——即便是坐标转换，若忽略编码函数或参考白点，数值虽变、外观却未必保持。无论哪一类，都必须明确输入的编码范围、参考白点和通道顺序，否则公式正确也可能得到错误结果。

== 1. 色彩空间的转换

若两个空间都是线性三刺激空间，转换可写成逐像素矩阵乘法 $bold(c)'=M bold(c)$。若空间含有伽马编码、分段函数或柱坐标，则转换通常由“解码—线性变换—非线性重编码”组成。以 sRGB 到 CIELAB 为例，完整顺序是：

1. 把 8 位整数除以 255，得到 $[0,1]$ 编码值。
2. 逆 sRGB 传递函数，恢复线性 RGB。
3. 依据 sRGB 基色和 D65 白点乘 $3 times 3$ 矩阵，得到 XYZ。
4. 以同一参考白点归一化 XYZ，施加 CIELAB 分段非线性函数。

逆变换必须按相反次序执行，并在最终量化前裁剪。中间步骤尽量使用浮点数；反复在 8 位空间之间转换会积累舍入和裁剪误差。OpenCV 的 `cvtColor` 支持大量常见转换，但不同数据类型对应的数值范围不同，例如 8 位 HSV 的色相常编码到 $[0,180)$，因此使用前必须查明约定。#cite(<opencv-color>)

```python
rgb_u8 = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

# 浮点 Lab 转换应先归一化到 [0, 1]。
rgb_f32 = rgb_u8.astype(np.float32) / 255.0
lab_f32 = cv2.cvtColor(rgb_f32, cv2.COLOR_RGB2LAB)

# 变回 RGB 后才量化，避免中间步骤反复损失精度。
reconstructed = cv2.cvtColor(lab_f32, cv2.COLOR_LAB2RGB)
reconstructed_u8 = np.clip(
    np.rint(reconstructed * 255.0),
    0,
    255,
).astype(np.uint8)
```

== 2. 色轮与补色

#tufted.definition[补色][在指定颜色模型中，若两个颜色混合后得到该模型的中性色，则称二者互为补色。RGB 加色模型中，$bold(c)$ 的补色可定义为 $bold(1)-bold(c)$；色相模型中常把色相旋转 $pi$，同时保持饱和度和亮度分量。两种定义只有在相应编码和混合假设下才成立。]

#figure(
  image("images/color-wheel.png", width: 55%, alt: "色轮上相差一百八十度的两个互补色方向"),
  caption: [色轮把色相组织为周期变量；直径两端相差 $pi$，构成一组色相补色。]
)

色相是圆周量，不能用普通算术平均处理。例如 $1 degree$ 与 $359 degree$ 的平均方向应接近 $0 degree$，而不是 $180 degree$。稳妥做法是把角度转成单位向量 $(cos H,sin H)$，先平均向量再用 `atan2` 求方向。补色也不能脱离用途：为了屏幕反相可以使用 $255-c$；为了设计配色可旋转感知色相；为了印刷套色则应通过 CMYK 与设备特性文件计算。

```python
def circular_mean(hue_radians: np.ndarray) -> float:
    x = np.cos(hue_radians).mean()
    y = np.sin(hue_radians).mean()
    return float(np.mod(np.arctan2(y, x), 2.0 * np.pi))


def hsv_complement(image_bgr: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    result = hsv.copy()
    # 8 位 OpenCV HSV 以 0..179 表示完整色相圆周。
    result[..., 0] = (result[..., 0].astype(np.int16) + 90) % 180
    return cv2.cvtColor(result, cv2.COLOR_HSV2BGR)
```

== 3. 色调、彩色校正与彩色平衡

=== a. 色调与通道变换

最一般的逐像素彩色映射写作
$
  s_(k)=T_(k)(r_(1),r_(2),r_(3)), quad k=1,2,3.
$
若每个输出只依赖同名输入，便是逐通道曲线；若输出同时依赖多个通道，则可完成颜色旋转、串扰补偿或色盲模拟。曝光式亮度调整应尽量在线性光空间进行，而用于显示外观的 gamma 曲线可以在归一化编码值上实现 $s=r^gamma$。$gamma<1$ 提亮暗部，$gamma>1$ 压暗，但裁剪后的高光和阴影信息无法由反向 gamma 恢复。

=== b. 白平衡与彩色平衡

白平衡试图让场景中本应中性的物体满足 $R approx G approx B$。若图像有可靠的白色或灰色参照，可测量该区域三通道均值并缩放到共同目标。没有参照时，灰度世界假设整幅场景的平均反射近似无彩色：
$
  g_(R)=bar(m)/m_(R),
  quad
  g_(G)=bar(m)/m_(G),
  quad
  g_(B)=bar(m)/m_(B),
$
其中 $m_(R),m_(G),m_(B)$ 是通道均值，$bar(m)$ 是三者平均。该方法对颜色分布丰富的普通场景有效，但在整幅图本来就由单一颜色主导时会过度校正。

彩色平衡比白平衡更广，它还可以分别调整阴影、中间调和高光中的通道比例。实际工作流应先修正白点和曝光，再做审美性色调；否则后续调整会掩盖光源偏色，难以维持中性色。

#figure(
  image("images/color-correction-series.png", width: 82%, alt: "曝光校正和灰度世界白平衡的四幅前后对比图"),
  caption: [(a) 欠曝光图像；(b) 反向 gamma 提亮结果；(c) 带暖色偏的图像；(d) 以左上角白色参考块估计通道增益后的白平衡结果。]
)

```python
def gamma_correct(image: np.ndarray, gamma: float) -> np.ndarray:
    source = image.astype(np.float32) / 255.0
    corrected = source ** gamma
    return np.clip(255.0 * corrected, 0, 255).astype(np.uint8)


def gray_world_balance(image_bgr: np.ndarray) -> np.ndarray:
    source = image_bgr.astype(np.float32)
    means = source.reshape(-1, 3).mean(axis=0)
    target = means.mean()
    gains = target / np.maximum(means, 1e-6)
    balanced = source * gains[None, None, :]
    return np.clip(balanced, 0, 255).astype(np.uint8)


def reference_patch_balance(
    image_bgr: np.ndarray,
    reference_mask: np.ndarray,
) -> np.ndarray:
    source = image_bgr.astype(np.float32)
    reference = source[reference_mask].mean(axis=0)
    target = reference.max()
    gains = target / np.maximum(reference, 1e-6)
    balanced = source * gains[None, None, :]
    return np.clip(balanced, 0, 255).astype(np.uint8)
```

#tufted.remark[校正矩阵的工作空间][相机的 $3 times 3$ 颜色校正矩阵通常作用于去黑电平、归一化并线性化后的传感器 RGB，而不是带有 sRGB gamma 的 JPEG。对编码后的 8 位图直接乘矩阵，既改变预期色度，也更容易发生裁剪。]

== 4. 直方图处理

彩色图像不能简单地把灰度均衡化算法独立用于三个通道。三个 RGB 通道的累积分布通常不同，分别均衡化会为它们建立三条不同映射；原本中性的 $R=G=B$ 可能被映射成三个不同数值，从而产生假色。更稳妥的思路是转换到亮度与色度分离的空间，只处理明度分量，再保留色度分量。

以 CIELAB 为例：

1. 将 BGR 转换为 Lab，分离 $L^*,a^*,b^*$。
2. 只对 $L^*$ 做全局均衡化或 CLAHE，得到 $L'^*$。
3. 将 $L'^*$ 与原来的 $a^*,b^*$ 合并。
4. 转回 BGR，并检查高饱和区域是否因色域边界发生裁剪。

全局均衡化可能把局部噪声一并增强；CLAHE 先在小块中限制直方图峰值，再对相邻块映射插值，适合照明不均的彩色照片。无论使用哪种方法，“只改亮度”也不意味着视觉色相绝对不变，因为转换回有限 RGB 色域时仍可能裁剪。#cite(<opencv-hist>)

#figure(
  image("images/color-histogram-series.png", width: 82%, alt: "彩色低对比图像分别按 RGB 通道和 Lab 明度均衡化的结果"),
  caption: [(a) 原彩色图像；(b) 人为压缩动态范围后的低对比图；(c) 三个 BGR 通道分别均衡化，颜色比例被改变；(d) 仅均衡化 Lab 明度通道，色度关系更稳定。]
)

```python
def equalize_lab_luminance(image_bgr: np.ndarray) -> np.ndarray:
    lab = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2LAB)
    luminance, a_channel, b_channel = cv2.split(lab)
    equalized = cv2.equalizeHist(luminance)
    merged = cv2.merge([equalized, a_channel, b_channel])
    return cv2.cvtColor(merged, cv2.COLOR_LAB2BGR)


def clahe_lab_luminance(
    image_bgr: np.ndarray,
    clip_limit: float = 2.0,
    tile_size: int = 8,
) -> np.ndarray:
    lab = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2LAB)
    luminance, a_channel, b_channel = cv2.split(lab)
    clahe = cv2.createCLAHE(
        clipLimit=clip_limit,
        tileGridSize=(tile_size, tile_size),
    )
    enhanced = clahe.apply(luminance)
    merged = cv2.merge([enhanced, a_channel, b_channel])
    return cv2.cvtColor(merged, cv2.COLOR_LAB2BGR)
```

#html.hr()
= 三、假彩色

#tufted.definition[假彩色][假彩色是把单通道灰度或其他标量场通过人为规定的颜色映射变成彩色图像。输出颜色不表示物体原本可见颜色，而用于突出数值区间、结构或异常。]

假彩色与“伪造颜色”不是同义词。温度、深度、海拔、压力、医学扫描强度本来就是标量，把它们映射到颜色能利用人眼的色相分辨能力显示更多层次。但颜色映射同时也是编码规则：没有色标、范围和单位，读者无法由颜色恢复数值含义；同一幅热图若改变归一化上下限，也会呈现完全不同的视觉结论。

== 1. 强度分层

强度分层把灰度轴划分为若干区间，并为每个区间指定一种颜色。若阈值为 $0=t_(0)<t_(1)<dots<t_(m)=L$，颜色表为 $bold(c)_(0),dots,bold(c)_(m-1)$，则
$
  bold(P)(r)=bold(c)_(k),
  quad
  t_(k)<=r<t_(k+1).
$
它的优势是区间边界清楚，适合土地等级、组织类别或风险分级；缺点是在阈值处产生不连续颜色边界，可能把连续变化误读成真实轮廓。阈值应来自任务含义或数据分布，而不是只为画面鲜艳。

```python
def intensity_slicing(
    gray: np.ndarray,
    thresholds: np.ndarray,
    colors_bgr: np.ndarray,
) -> np.ndarray:
    if len(colors_bgr) != len(thresholds) + 1:
        raise ValueError("颜色数量必须比阈值数量多 1")

    indices = np.digitize(gray, thresholds, right=False)
    return colors_bgr[indices]


thresholds = np.array([43, 86, 128, 171, 214])
colors = np.array(
    [
        [70, 25, 15],
        [155, 70, 30],
        [205, 175, 45],
        [65, 190, 90],
        [40, 215, 235],
        [245, 245, 245],
    ],
    dtype=np.uint8,
)
colored = intensity_slicing(gray, thresholds, colors)
```

== 2. 连续灰度到彩色变换

连续映射为每个灰度 $r$ 指定颜色向量
$
  bold(P)(r)=(T_(R)(r),T_(G)(r),T_(B)(r)).
$
最简单的实现是长度为 256 的查找表；三个通道的曲线可以由若干控制点分段线性插值。与强度分层相比，连续映射保留平滑变化，适合显示连续物理量。

颜色映射的选择影响读数。亮度单调的色图使数值增加时视觉明暗也大体单调，更适合定量数据；周期性色图适合方向角或相位；发散色图适合围绕零点的正负偏差。传统彩虹色图在黄色和青色附近的感知变化不均匀，还可能制造并不存在的边界，不应仅因“颜色多”而默认采用。

#figure(
  image("images/pseudocolor-series.png", width: 82%, alt: "同一灰度图像采用分层和两种连续色图得到的假彩色结果"),
  caption: [(a) 原灰度图像；(b) 六级强度分层；(c) Turbo 连续色图；(d) Inferno 连续色图。不同映射使用相同灰度数据，却强调不同的数值范围。]
)

```python
def continuous_colormap(
    gray: np.ndarray,
    control_colors_bgr: np.ndarray,
) -> np.ndarray:
    positions = np.linspace(0.0, 255.0, len(control_colors_bgr))
    samples = np.arange(256, dtype=np.float64)
    lookup = np.empty((256, 3), dtype=np.uint8)

    for channel in range(3):
        lookup[:, channel] = np.clip(
            np.interp(
                samples,
                positions,
                control_colors_bgr[:, channel],
            ),
            0,
            255,
        ).astype(np.uint8)

    return lookup[gray]


# OpenCV 内置色图也是查找表映射。
turbo = cv2.applyColorMap(gray, cv2.COLORMAP_TURBO)
inferno = cv2.applyColorMap(gray, cv2.COLORMAP_INFERNO)
```

#tufted.remark[假彩色图必须携带色标][展示科学数据时，应同时给出颜色条、数值上下限、单位、无效值颜色以及归一化方式。若不同图像需要比较，应固定同一数值范围，不能分别按各自最小值和最大值拉伸后再比较颜色。]

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
