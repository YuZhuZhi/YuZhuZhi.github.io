#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "频域滤波",
  description: "频域滤波流程、低通、高通与选择性滤波器",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

#let ii = $upright(i)$

= 频域滤波

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

傅里叶变换把图像分解为不同空间频率的复指数分量，频域滤波则决定每种分量应保留、衰减还是增强。它并非把频谱图当作普通灰度图随意涂改，而是构造一个与频谱同尺寸的复数乘法因子：每个频率位置的系数同时作用于该频率的幅度和相位，最后经逆变换回到空间域。#cite(<dip-book>)

需要先说明频域滤波能够成立的前提：变换只是换了一组基底，本身不创造也不删除任何信息；滤波要有意义，目标信号与要抑制的成分必须落到不同的频带上。若真实细节与噪声占据同一频率范围，无论传递函数设计得多精巧，频域都无法把它们分开。这是判断“设计滤波器能否解决问题”的第一条标准，也是后文讨论振铃、截断与噪声放大的出发点。

本章沿用上一章的二维 DFT 约定。设填充频谱高为 $P$、宽为 $Q$；$u$ 是水平频率索引，$v$ 是垂直频率索引。经过 `fftshift` 后，零频位置为 $(floor(Q/2),floor(P/2))$，径向距离记为
$
  D(u,v)=sqrt((u-floor(Q/2))^2+(v-floor(P/2))^2).
$
实际数组索引和数学频率坐标要始终配套：数学上的 $H(u,v)$ 在数组中写作 `H[v, u]`。若频谱已经 `fftshift`，滤波器中心也必须位于上述数组位置；若频谱未中心化，零频位于数组原点，而视觉上相邻的低频会分布在四个角部。

#html.hr()
= 一、频域滤波基础

== 1. 基本滤波公式

#tufted.definition[频域滤波][设填充后的图像为 $f_(p)(x,y)$，其二维 DFT 为 $F(u,v)$。给定与频谱同尺寸的函数 $H(u,v)$，频域滤波定义为
$
  G(u,v)=H(u,v)F(u,v),
$
$
  g_(p)(x,y)="Re"{cal(F)^(-1)[G(u,v)]}.
$
裁去填充区域后得到最终图像 $g(x,y)$。$H$ 称为滤波器的频率响应或传递函数。]

这个公式包含三层意义。第一，乘法是频率位置一一对应的元素乘法，不是矩阵乘法。第二，对实数且非负的零相位响应，$H(u,v)=1$ 表示该频率原样通过，$H=0$ 表示完全阻断，$0<H<1$ 表示衰减，$H>1$ 表示增强；一般复数 $H$ 的模控制增益，辐角控制相位移动。第三，逆变换的理论结果在共轭对称条件下应为实数，代码中出现极小虚部通常来自浮点舍入，可以取实部，但较大的虚部往往说明掩膜破坏了共轭对称或中心化步骤不一致。

#figure(
  image("images/image-spectrum-series.png", width: 82%, alt: "测试图像与其中心化对数幅度谱的两幅系列图"),
  caption: [(a) 用于频谱计算的灰度测试图像；(b) 对 (a) 计算二维 FFT 后得到的中心化对数幅度谱。中心亮斑来自平均亮度和缓慢变化，外围亮线对应方向性结构。]
)

频谱图显示的是 $log(1+abs(F))$ 的归一化结果。使用对数是因为直流与低频幅值常比其他频率大几个数量级；这个显示变换不能覆盖用于滤波的原复数频谱，也不能把显示图再次送入 IDFT。

#figure(
  image("images/frequency-pipeline.png", width: 100%, alt: "从输入图像、边界扩展与填充、傅里叶变换、中心化、传递函数逐点乘法、逆中心化、逆变换到裁剪输出的完整流程"),
  caption: [完整的频域滤波流程。上行从空间域输入 $f(x,y)$ 得到中心化过滤频谱 $G_(c)(u,v)$；下行撤销中心化并逆变换，最后裁剪得到 $g(x,y)$。]
)

图中的字母不是互不相关的步骤缩写，而是同一幅图像在处理链中的不同数学对象。用算子形式可以把整条流程写成
$
  f_(p)&=cal(P){f},\
  F&=upright("DFT"){f_(p)},\
  F_(c)&=cal(S){F},\
  G_(c)&=H ⊙ F_(c),\
  G&=cal(S)^(-1){G_(c)},\
  g_(p)&=upright("IDFT"){G},\
  g&=cal(C){g_(p)}.
$
其中 $⊙$ 表示同一频率坐标上的逐元素乘法。各符号的含义如下。

1. $f(x,y)$ 是原始的 $M times N$ 空间域图像。$cal(P)$ 表示边界扩展和零填充操作；它产生尺寸为 $P times Q$ 的 $f_(p)(x,y)$。下标 $p$ 表示 padded，即该数组仍包含稍后需要裁去的扩展区域。
2. $F(u,v)$ 是 $f_(p)$ 的二维离散傅里叶变换。$u,v$ 是频率索引，而不是原图中的空间坐标 $x,y$。
3. $cal(S)$ 表示中心化排列，例如 `fftshift`。它把零频从数组角部移动到中央，得到 $F_(c)(u,v)$；下标 $c$ 表示 centered。中心化只重排频率系数，不改变其数值。
4. $H(u,v)$ 是人为设计或由空间核推导出的频率响应。圆圈中的 $⊙$ 表明在每个 $(u,v)$ 上计算 $G_(c)(u,v)=H(u,v)F_(c)(u,v)$，而不是进行矩阵乘法。$G_(c)$ 是过滤后的中心化复数频谱。
5. $cal(S)^(-1)$ 表示逆中心化，例如 `ifftshift`，它把 $G_(c)$ 恢复为逆变换所需的排列 $G(u,v)$。随后 IDFT 得到仍带填充区域的空间域结果 $g_(p)(x,y)$。
6. $cal(C)$ 是裁剪算子，从 $g_(p)$ 中取回与原始图像对应的 $M times N$ 区域，得到最终输出 $g(x,y)$。只有在显示或保存时，才应根据目标数据类型对 $g$ 进行灰度裁剪和量化。

因此，流程的频域核心虽然仍是 $G_(c)=H ⊙ F_(c)$，但它成立的前提是 $F_(c)$ 与 $H$ 使用完全相同的尺寸和中心化坐标约定。若省略逆中心化、混淆 $F$ 与 $F_(c)$，或在 IDFT 前把复数频谱替换成显示用的对数幅度图，最后的空间域结果都会失去原本含义。

== 2. 频域滤波的步骤

频域滤波不能从“计算 FFT 后乘一个圆形掩膜”直接开始。中心化、填充尺寸、逆中心化和裁剪若有一步与前面不一致，结果就会平移、环绕或改变尺度。

中心化有两种等价思路。对偶数尺寸图像，在变换前乘
$
  (-1)^(x+y)
$
会把零频平移到频谱中心；实际数组程序更常先执行 FFT，再用 `fftshift` 循环交换象限。逆变换前必须执行 `ifftshift`。中心化只改变频谱的排列方式，便于设计以中心为原点的径向滤波器，不改变频率内容。

零填充至少有两个不同目的。

1. 若使用频域乘法精确实现一幅 $M times N$ 图像与 $A times B$ 空间核的完整线性卷积，DFT 尺寸至少应为 $(M+A-1) times (N+B-1)$。尺寸不足时，循环卷积越过边界的部分会绕回另一侧，形成交叠错误。
2. 对直接按频率公式设计的低通、高通滤波器，不存在一个有限空间核直接给出最小尺寸。常见做法是把图像补到至少 $2M times 2N$，让图像的周期副本彼此分开，减轻左右、上下边界突然相接造成的环绕影响，逆变换后再裁取原区域。这与上一章为完整线性卷积而零填充目的不同：后者是为了消除数学卷积的循环回绕，这里是为了减弱图像自身周期延拓造成的边界混叠。

零填充不会创造新的图像信息。它使频率网格采样更密，并为非周期边界或完整卷积结果提供空间；若输入边界本身不适合补零，也可以先按镜像、复制等规则扩展，再补到便于 FFT 的尺寸。

一个完整流程如下。

1. 将输入提升为 `float32` 或 `float64`，记录原尺寸。
2. 根据用途确定填充尺寸，并把原图放入填充数组的左上区域。
3. 计算二维 DFT；若滤波器以中心为原点，则中心化频谱。
4. 在同一坐标约定下生成 $H(u,v)$，检查其形状与频谱完全一致。
5. 计算 $G=H F$，不要丢弃复数相位。
6. 撤销中心化并执行 IDFT，按库的归一化约定缩放。
7. 取实部，裁回原尺寸；仅在最终显示或保存时裁剪到 0—255。

下面的辅助函数让中心化成为显式选项，并把裁剪尺寸一并返回。

```python
import cv2
import numpy as np

def forward_frequency(
    image: np.ndarray,
    padded_shape: tuple[int, int] | None = None,
    centered: bool = True,
) -> tuple[np.ndarray, tuple[int, int]]:
    source = np.asarray(image, dtype=np.float64)
    rows, cols = source.shape

    if padded_shape is None:
        padded_shape = (rows, cols)
    if padded_shape[0] < rows or padded_shape[1] < cols:
        raise ValueError("padded shape cannot be smaller than the image")

    padded = np.zeros(padded_shape, dtype=np.float64)
    padded[:rows, :cols] = source
    spectrum = np.fft.fft2(padded)

    if centered:
        spectrum = np.fft.fftshift(spectrum)
    return spectrum, (rows, cols)

def inverse_frequency(
    spectrum: np.ndarray,
    original_shape: tuple[int, int],
    centered: bool = True,
) -> np.ndarray:
    work = np.fft.ifftshift(spectrum) if centered else spectrum
    padded = np.fft.ifft2(work)
    rows, cols = original_shape
    return padded.real[:rows, :cols]
```

#figure(
  image("images/spectrum-centering-series.png", width: 82%, alt: "同一频谱在中心化前后的两幅排列对比图"),
  caption: [(a) 未中心化的频谱，低频分布在四角；(b) 使用 `fftshift` 后的中心化频谱，低频位于中央。两图包含相同的频率系数，仅索引排列不同。]
)

== 3. 频域滤波的作用

直流项 $F(0,0)$ 等于全部像素之和；除以像素数后就是平均灰度。将直流项置零，会让重建图像均值接近 0，但不会自动得到“边缘图”。为了显示含负值的结果，往往还要临时归一化到 0—255；这种归一化改变了物理灰度，只适合观察。

低通滤波保留中心附近的缓慢空间变化，抑制远离中心的快速变化，结果是噪声与细节减少、边缘变宽。高通滤波阻断低频并保留高频，突出边缘、细纹理和快速噪声；高通响应本身通常正负并存，若用于锐化，应按适当系数加回原图，而不是直接把负值截成 0。

下面不只比较输出，而是把一次高斯低通的频域处理链完整展开。原图先变换为中心化频谱；高斯传递函数在中心接近 1、向外平滑衰减；二者相乘后，频谱外围的高频亮线被压暗；最后逆变换得到平滑图像。

#figure(
  image("images/lowpass-process-series.png", width: 100%, alt: "高斯低通频域滤波从输入到输出的五幅过程图"),
  caption: [(a) 输入图像；(b) 中心化频谱；(c) 高斯低通传递函数；(d) 频谱与传递函数相乘后的过滤频谱；(e) 对 (d) 逆变换得到的低通结果。]
)

高斯高通使用同一个低通函数的互补 $H_("HP")=1-H_("LP")$。其中心为 0，远离中心逐渐接近 1；相乘后直流和低频亮斑消失，只剩边缘与细纹理所对应的外围频率。高通逆变换包含正负响应，因此最后一幅图为观察细节而做了最小—最大归一化，不能把其灰度当作原图的绝对亮度。

#figure(
  image("images/highpass-process-series.png", width: 100%, alt: "高斯高通频域滤波从输入到输出的五幅过程图"),
  caption: [(a) 输入图像；(b) 中心化频谱；(c) 互补高通传递函数；(d) 频谱与传递函数相乘后的过滤频谱；(e) 对 (d) 逆变换并归一化显示的高通空间响应。]
)

去除直流项也可以纳入同一链条：令传递函数除中心单点为 0 外全部为 1，再与频谱相乘。它只删除平均灰度，而不像高通滤波那样抑制一片低频邻域。其重建结果为显示归一化后如下。

#figure(
  image("images/dc-removed.png", width: 56%, alt: "仅去除中心直流频率后的空间域结果"),
  caption: [仅令直流系数为 0 后，图像均值消失，但低频照明变化和大尺度结构仍然存在。]
)

#tufted.remark[相角为什么不能丢弃][频谱写成 $F=abs(F)exp(ii phi)$。幅度决定各频率的权重，相角 $phi$ 决定这些分量在空间中怎样对齐。只保留幅度而把相位置零，能量仍在，却很难恢复原有物体位置；只保留单位幅度而保留相位，轮廓关系反而仍可辨认。下面两幅图均由同一测试图像的真实频谱逆变换得到，并分别为显示做了归一化。]

#figure(
  image("images/magnitude-phase-series.png", width: 82%, alt: "仅保留频谱幅度和仅保留频谱相位的两幅重建图"),
  caption: [(a) 保留原频谱幅度并将相位置零的重建，结构被对齐到统一相位；(b) 保留原频谱相位并将幅度统一为 1 的重建，空间轮廓仍然较清楚。]
)

== 4. 空间域滤波与频域滤波的关系

空间卷积定理给出
$
  g=f*h quad "对应" quad G=F H.
$
因此空间核 $h(x,y)$ 的 DFT 就是它的传递函数 $H(u,v)$。从一个已知空间核得到适用于频域乘法的传递函数，需要依次完成：

1. 确定图像与核的线性卷积尺寸，至少为 $(M+A-1) times (N+B-1)$。
2. 将核补到该尺寸。核数组中“锚点”通常在中心，而 DFT 把索引 `(0, 0)` 当作空间原点，所以要用 `ifftshift` 或循环平移把锚点移到左上角。
3. 对移位、填充后的核做 DFT，得到 $H$。不要对 $H$ 单独取幅度，否则会丢掉非对称核的相位与空间偏移。
4. 用相同尺寸计算图像 DFT，逐点相乘，再 IDFT 和裁剪。

#figure(
  image("images/kernel-transfer.png", width: 82%, alt: "空间核经过原点移动、零填充和 DFT 得到传递函数"),
  caption: [核的锚点先移到数组原点，再补零并变换。若省略锚点移动，频域结果会带上线性相位，输出发生循环平移。]
)

```python
def kernel_transfer_function(
    kernel: np.ndarray,
    transform_shape: tuple[int, int],
) -> np.ndarray:
    kernel = np.asarray(kernel, dtype=np.float64)
    if kernel.shape[0] > transform_shape[0]:
        raise ValueError("kernel has too many rows")
    if kernel.shape[1] > transform_shape[1]:
        raise ValueError("kernel has too many columns")

    padded = np.zeros(transform_shape, dtype=np.float64)
    padded[:kernel.shape[0], :kernel.shape[1]] = kernel
    anchor_y = kernel.shape[0] // 2
    anchor_x = kernel.shape[1] // 2
    padded = np.roll(padded, -anchor_y, axis=0)
    padded = np.roll(padded, -anchor_x, axis=1)
    return np.fft.fft2(padded)
```

#tufted.remark[核锚点的稳妥处理][代码显式计算锚点，再分别 `roll(-anchor_y, -anchor_x)`，使锚点准确移动到数组原点。对偶数核或非中心锚点，应由调用者明确传入锚点，而不能默认使用整数除法选定的中心；否则输出会出现一个像素量级的平移歧义。]

空间域直接卷积每个像素约需 $A B$ 次乘加，复杂度为 $O(M N A B)$。频域方法需要若干次 FFT 和一次逐点乘法，约为 $O(P Q log(P Q))$，并占用复数频谱和填充数组。核很小时，空间卷积省去变换、填充和内存开销，通常更快；核很大、需要重复使用同一传递函数，或滤波器本来就按频率公式定义时，频域方法更有优势。“FFT 渐近复杂度更低”不等于任何尺寸下都更快。

#html.hr()
= 二、低通滤波器与平滑

== 1. 理想与高斯低通滤波器

#tufted.definition[理想低通滤波器][给定截止距离 $D_(0)>0$，理想低通传递函数为
$
  H_("ILPF")(u,v)=cases(1 & D(u,v)<=D_(0), 0 & D(u,v)>D_(0)).
$]

理想低通在截止圆内完全通过、圆外完全阻断，频率选择看似最干净，但响应在 $D_(0)$ 处不连续。频域突变对应空间域中缓慢衰减并正负振荡的冲激响应，因此强边缘附近容易出现明暗交替的振铃。截止越低，平滑越强，振铃范围也可能更明显。

#tufted.definition[高斯低通滤波器][高斯低通传递函数为
$
  H_("GLPF")(u,v)=exp(-D(u,v)^2/(2 D_(0)^2)).
$
它从中心的 1 平滑下降，在 $D=D_(0)$ 处取 $exp(-1/2)$。]

高斯响应没有突变，其空间域对应物仍是高斯函数，所以通常不产生理想滤波器那样明显的振铃。$D_(0)$ 不是“保留圆内、删除圆外”的硬边界，而是控制衰减速度的尺度。

#figure(
  image("images/lowpass-responses.png", width: 83%, alt: "理想、高斯和巴特沃斯低通滤波器的径向响应"),
  caption: [理想低通突然截断；高斯响应平滑衰减；巴特沃斯通过阶数在两者之间调节过渡陡峭程度。]
)

```python
def radial_distance(shape: tuple[int, int]) -> np.ndarray:
    rows, cols = shape
    y, x = np.ogrid[:rows, :cols]
    return np.sqrt(
        (y - rows // 2) ** 2
        + (x - cols // 2) ** 2
    )

def ideal_lowpass(shape: tuple[int, int], cutoff: float) -> np.ndarray:
    distance = radial_distance(shape)
    return (distance <= cutoff).astype(np.float64)

def gaussian_lowpass(shape: tuple[int, int], cutoff: float) -> np.ndarray:
    if cutoff <= 0:
        raise ValueError("cutoff must be positive")
    distance = radial_distance(shape)
    return np.exp(-(distance**2) / (2.0 * cutoff**2))
```

== 2. 巴特沃斯低通滤波器

#tufted.definition[巴特沃斯低通滤波器][截止距离为 $D_(0)$、阶数为正整数 $n$ 的巴特沃斯低通传递函数为
$
  H_("BLPF")(u,v)=1/(1+(D(u,v)/D_(0))^(2n)).
$
在 $D=D_(0)$ 处响应为 $1/2$。]

巴特沃斯滤波器在中心附近较平坦，远处逐渐趋近 0。阶数 $n$ 越大，过渡带越窄，响应越接近理想低通，也越可能出现振铃；低阶响应较平滑，却会更早衰减截止附近的细节。$D_(0)$ 与 $n$ 必须一起说明，仅说“使用巴特沃斯低通”不足以确定滤波器。

```python
def butterworth_lowpass(
    shape: tuple[int, int],
    cutoff: float,
    order: int,
) -> np.ndarray:
    if cutoff <= 0:
        raise ValueError("cutoff must be positive")
    if order < 1:
        raise ValueError("order must be at least one")

    distance = radial_distance(shape)
    return 1.0 / (1.0 + (distance / cutoff) ** (2 * order))

def apply_centered_filter(
    image: np.ndarray,
    transfer: np.ndarray,
) -> np.ndarray:
    spectrum, shape = forward_frequency(
        image,
        padded_shape=transfer.shape,
        centered=True,
    )
    return inverse_frequency(spectrum * transfer, shape, centered=True)

padded_shape = (2 * gray.shape[0], 2 * gray.shape[1])
transfer = butterworth_lowpass(padded_shape, cutoff=45.0, order=2)
smoothed = apply_centered_filter(gray, transfer)
smoothed_u8 = np.clip(smoothed, 0, 255).astype(np.uint8)
```

低通适用于削弱细小噪声、压制纹理和得到缓慢变化的背景估计，但它无法区分“高频噪声”和“高频真实边缘”。若目标就是细线或小字符，过低截止频率会把目标与噪声一起删除。

#html.hr()
= 三、高通滤波器与锐化

== 1. 使用低通滤波器获得理想、高斯、巴特沃斯高通滤波器

若低通响应 $H_("LP")$ 的直流增益为 1，则互补高通定义为
$
  H_("HP")(u,v)=1-H_("LP")(u,v).
$
因此不必重新记忆三套高通公式：分别用理想、高斯或巴特沃斯低通代入，就得到对应高通。理想高通在截止圆内为 0、圆外为 1；高斯高通从中心的 0 平滑上升；巴特沃斯高通的过渡陡峭程度仍由阶数控制。

高通响应可用于边缘与细纹理检测、照明背景去除、缺陷增强，也可作为锐化掩膜。但它会同时增强随机噪声；理想高通的硬截止还会产生明显振铃。应用前要先判断目标结构的尺度和噪声频带，不能把“更锐”简单等同于“截止距离越大或增益越高”。

```python
ideal_high = 1.0 - ideal_lowpass(padded_shape, 35.0)
gaussian_high = 1.0 - gaussian_lowpass(padded_shape, 35.0)
butterworth_high = 1.0 - butterworth_lowpass(
    padded_shape,
    cutoff=35.0,
    order=2,
)

high_response = apply_centered_filter(gray, gaussian_high)
display_high = cv2.normalize(
    high_response,
    None,
    0,
    255,
    cv2.NORM_MINMAX,
).astype(np.uint8)
```

== 2. 拉普拉斯重顾

连续二维拉普拉斯为
$
  nabla^2 f=frac(partial^2 f, partial x^2)+frac(partial^2 f, partial y^2).
$
采用以“每单位距离的周数”为变量的傅里叶变换约定时，二阶导数性质给出
$
  cal(F){frac(partial^2 f, partial x^2)}=-(2 pi u)^2F(u,v),
$
$
  cal(F){frac(partial^2 f, partial y^2)}=-(2 pi v)^2F(u,v).
$

#tufted.theorem[拉普拉斯的频域传递函数][二维拉普拉斯算子的连续频域传递函数为
$
  H_(nabla^2)(u,v)=-4 pi^2(u^2+v^2),
$
即
$
  cal(F){nabla^2 f}=-4 pi^2(u^2+v^2)F(u,v).
$]

#tufted.proof[对 $x$ 的一阶偏导做分部积分，在边界项消失的条件下得到 $cal(F){frac(partial f, partial x)}=ii 2 pi u F$；再次求导得到 $(ii 2 pi u)^2F=-(2 pi u)^2F$。对 $y$ 同理，两项相加即得结论。]

#figure(
  image("images/laplacian-transfer.png", width: 78%, alt: "拉普拉斯频率响应随径向频率平方增长"),
  caption: [拉普拉斯在直流处为 0，响应幅度随 $u^2+v^2$ 增长；离散核的 DFT 具有相同的高频增强趋势，但受离散周期频率限制。]
)

空间锐化采用 $g=f-c nabla^2 f$ 时，相应总传递函数为
$
  H_("sharp")(u,v)=1+4 pi^2 c(u^2+v^2).
$
这里存在标定问题：数组索引距离不是物理频率。如果直接把 $u,v$ 取为像素索引，最高频响应会随图像尺寸平方增长，同一个 $c$ 在不同尺寸图像上产生完全不同的锐化强度。应把坐标归一化为每像素周数，或先将 $D^2$ 除以其最大值，再用可解释的增益参数。

```python
def normalized_laplacian_transfer(
    shape: tuple[int, int],
) -> np.ndarray:
    rows, cols = shape
    fy = np.fft.fftshift(np.fft.fftfreq(rows))
    fx = np.fft.fftshift(np.fft.fftfreq(cols))
    u, v = np.meshgrid(fx, fy)
    response = -4.0 * np.pi**2 * (u**2 + v**2)
    scale = np.max(np.abs(response))
    return response / scale if scale > 0 else response

laplacian_h = normalized_laplacian_transfer(padded_shape)
sharpening_h = 1.0 - 0.9 * laplacian_h
laplacian_sharp = apply_centered_filter(gray, sharpening_h)
laplacian_sharp = np.clip(laplacian_sharp, 0, 255).astype(np.uint8)
```

若目标是严格复现某个离散 $3 times 3$ 拉普拉斯核，应直接把该核按上一节方法补零、移动锚点并计算 DFT；连续 $-4 pi^2D^2$ 与离散核响应在低频附近相符，但在接近奈奎斯特频率时并不完全相同。

== 3. 钝化掩蔽、高提升滤波与高频强调滤波

设低通图像为 $f_("LP")$，高频掩膜为
$
  m=f-f_("LP").
$
钝化掩蔽把掩膜加回原图：
$
  g=f+k m.
$
在频域中，$M=(1-H_("LP"))F=H_("HP")F$，所以整个锐化滤波器为
$
  H_("unsharp")=1+k H_("HP").
$
$k=1$ 是经典钝化掩蔽，$k>1$ 提供更强的细节增益。

高提升滤波常写为
$
  g=A f-f_("LP"), quad A>1,
$
其传递函数为
$
  H_("HB")=A-H_("LP")=(A-1)+H_("HP").
$
它既保留一部分原图基线，又提升高频。不同教材对“高提升”的参数记号略有差异，判断实际作用时应展开原图与低通图的系数。

更一般的高频强调滤波写作
$
  H_("HFE")=a+b H_("HP"), quad a>=0, b>a.
$
$a$ 控制低频背景保留量，$b$ 控制高频增强量。它常与后续直方图增强结合：先在频域提升细节，再在空间域调整整体对比度。若 $a$ 过小，背景会变暗；若 $b$ 过大，噪声和振铃会被同步放大。

```python
low = butterworth_lowpass(padded_shape, cutoff=42.0, order=2)
high = 1.0 - low

unsharp_h = 1.0 + 1.1 * high
highboost_h = 1.8 - low
emphasis_h = 0.65 + 1.7 * high

unsharp = apply_centered_filter(gray, unsharp_h)
highboost = apply_centered_filter(gray, highboost_h)
emphasized = apply_centered_filter(gray, emphasis_h)
```

#html.hr()
= 四、选择性滤波

选择性滤波不只区分“低频”与“高频”，而是针对某一段径向频带或若干离散频率位置。它适合抑制周期干扰、保留特定尺度纹理，但前提是目标与干扰在频谱上确实能够分离。

== 1. 带阻与带通滤波器

#tufted.definition[带阻与带通滤波器][设阻带中心半径为 $D_(c)$、带宽为 $W$。理想带阻滤波器在
$
  D_(c)-W/2<=D(u,v)<=D_(c)+W/2
$
内取 0，其余位置取 1。互补带通滤波器定义为
$
  H_("BP")=1-H_("BR").
$]

带阻删除位于一圈径向频率上的成分，适合周期长度相近但方向分散的干扰；带通只保留该尺度范围，可用于纹理分析或提取特定大小的结构。理想环形边界会产生振铃，实际常用巴特沃斯或高斯形式平滑过渡。

一种巴特沃斯带阻形式为
$
  H_("BBR")=1/(1+(D W/(D^2-D_(c)^2))^(2n)).
$
当 $D$ 接近 $D_(c)$ 时分母中的比值增大，响应趋近 0；远离中心频带时响应趋近 1。实现要单独处理 $D^2=D_(c)^2$ 的位置，避免除零。

```python
def butterworth_bandreject(
    shape: tuple[int, int],
    center: float,
    width: float,
    order: int,
) -> np.ndarray:
    distance = radial_distance(shape)
    denominator = distance**2 - center**2

    ratio = np.empty_like(distance)
    np.divide(
        distance * width,
        denominator,
        out=ratio,
        where=denominator != 0,
    )
    ratio[denominator == 0] = np.inf
    return 1.0 / (1.0 + np.abs(ratio) ** (2 * order))

bandreject = butterworth_bandreject(
    padded_shape,
    center=70.0,
    width=16.0,
    order=2,
)
bandpass = 1.0 - bandreject
```

== 2. 陷波滤波器

#tufted.definition[陷波滤波器][陷波滤波器只在一个或若干狭小频率邻域内强烈衰减，其余频率基本通过。阻断指定频率称陷波带阻；只保留这些小邻域称陷波带通。]

周期噪声常在中心化频谱中表现为远离中心的孤立亮点或小簇。对实值图像，频谱具有共轭对称性，所以噪声峰通常成对出现在 $(u_(k),v_(k))$ 与 $(-u_(k),-v_(k))$。只删除其中一个峰会破坏共轭对称，使逆变换出现不可忽略的虚部；陷波必须成对设置。

#figure(
  image("images/selective-masks.png", width: 84%, alt: "带通、带阻和成对陷波掩膜"),
  caption: [前两种掩膜按中心距离选择整段频带；陷波只在共轭对称的离散峰值附近开出小阻断区域。]
)

设计陷波的过程是：先观察中心化对数幅度谱；排除由图像真实规则纹理产生的峰；记录一个半平面中的噪声峰坐标；为每个坐标同时添加关于中心对称的阻断点；最后从较小半径开始，检查噪声是否消失以及真实细节是否被误删。

下面给出平滑高斯陷波带阻。每个陷波中心的距离越小，`1 - exp(-D²/(2σ²))` 越接近 0；离开中心后趋近 1。所有成对因子相乘，得到多陷波传递函数。

```python
def gaussian_notch_reject(
    shape: tuple[int, int],
    offsets: list[tuple[float, float]],
    sigma: float,
) -> np.ndarray:
    if sigma <= 0:
        raise ValueError("sigma must be positive")

    rows, cols = shape
    y, x = np.ogrid[:rows, :cols]
    center_y = rows // 2
    center_x = cols // 2
    transfer = np.ones(shape, dtype=np.float64)

    for offset_y, offset_x in offsets:
        for sign in (-1.0, 1.0):
            notch_y = center_y + sign * offset_y
            notch_x = center_x + sign * offset_x
            distance2 = (y - notch_y) ** 2 + (x - notch_x) ** 2
            transfer *= 1.0 - np.exp(
                -distance2 / (2.0 * sigma**2)
            )
    return transfer

```

陷波半径过大会挖掉邻近真实频率，产生条纹、模糊或振铃；半径过小则只能削弱峰尖，无法删除扩散的噪声能量。若周期干扰的频率随位置变化，频谱峰会拉宽甚至成为曲线，单纯固定陷波可能不再适用，需要局部或自适应方法。

#tufted.remark[频域滤波的检查清单][滤波前确认填充尺寸和中心化约定；构造 $H$ 后检查直流增益、取值范围和共轭对称；滤波后同时观察空间图像与频谱，并保留浮点结果检查负值和虚部；最后才为显示裁剪。低通、高通、带阻和陷波都只是对频率的选择，是否改善任务取决于目标信息与噪声能否在频率上分离。]

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
