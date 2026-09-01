#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "图像复原",
  description: "噪声模型、退化估计与逆问题复原",
)

#set math.mat(delim: "[", row-gap: 5pt, column-gap: 10pt)

#let ii = $upright(i)$

= 图像复原

#tufted.full-width[
  #image("../header.jpg") 
  _Illustrated by #link("https://www.pixiv.net/users/11461045")[GAloDos]（Pixiv），#link("https://www.pixiv.net/artworks/145975157")[Source]_
]

图像增强以“更适合观察或处理”为目标，并不要求解释图像为什么变差；图像复原则先建立退化模型，再利用关于成像系统和噪声的知识估计原图。若原图为 $f$，退化算子为 $cal(H)$，噪声为 $eta$，观测图像统一写成
$
  g=cal(H){f}+eta.
$
复原算法接收 $g$ 以及对 $cal(H)$、$eta$ 的估计，输出原图估计 $hat(f)$。同一幅模糊图可能由运动、离焦或大气扰动造成；退化原因不同，逆运算也不同。复原本质是一个反问题：即使已知 $g$ 和对 $cal(H)$、$eta$ 的估计，通常也不存在唯一且稳定的原图 $f$，因为退化会抹平细节，而噪声又混入观测。因此复原不能从“选哪个锐化滤波器”开始，而应从噪声模型、点扩散函数与先验约束开始。后文的逆滤波、维纳滤波和约束最小二乘，正是对“如何约束这个反问题”给出的三种不同回答。#cite(<dip-book>)

#figure(
  image("images/degradation-pipeline.png", width: 84%, alt: "原图经过退化系统并叠加噪声，再由复原滤波器估计原图的流程"),
  caption: [退化过程从 $f$ 经系统 $H$ 并叠加噪声 $eta$ 得到 $g$；复原算子 $R$ 利用模型与观测生成 $hat(f)$。]
)

图中的 $f(x,y)$ 是未知的清晰原图，$cal(H)$ 是造成模糊或几何失真的退化系统，$eta(x,y)$ 是成像过程中叠加的噪声，$g(x,y)$ 是传感器实际记录的退化图像。复原阶段并不能直接取得 $f$，只能依据对 $cal(H)$ 与 $eta$ 的认识设计复原算子 $cal(R)$，从 $g$ 得到原图估计 $hat(f)(x,y)$。因此，$hat(f)$ 通常只是满足模型和先验约束的估计，并不必然与 $f$ 完全相同。

#html.hr()
= 一、噪声模型

噪声模型描述随机灰度扰动可能取什么值、各值出现的概率，以及它是否依赖位置或原图。概率密度不是噪声图像本身：同一分布可产生许多不同样本，参数则决定均值、方差、偏斜程度和尾部。选定某种模型是假设而非事实——它以成像机制为依据，但必须通过平坦区样本或残差直方图检验；若实际噪声是混合型或位置相关，单一密度模型只是近似。

== 1. 高斯、瑞利、伽马噪声

#tufted.definition[高斯噪声][随机变量 $z$ 的高斯概率密度为
$
  p(z)=1/(sqrt(2 pi) sigma) exp(-(z-mu)^2/(2 sigma^2)),
$
其中 $mu$ 是均值，$sigma^2$ 是方差。加性高斯噪声模型写成 $g=f+eta$，常用于近似许多独立小扰动叠加形成的传感器与电子噪声。]

$mu=0$ 时噪声不系统改变平均亮度，但会增加局部方差；$sigma$ 越大，灰度扰动分布越宽。高斯模型允许任意实数值，所以加入有限范围图像后不应立刻裁剪，否则两端样本被堆到 0 与 255，实际分布不再是原高斯分布。

#tufted.definition[瑞利噪声][参数 $a$、$b>0$ 的瑞利概率密度为
$
  p(z)=cases(2/b(z-a) exp(-(z-a)^2/b) & z>=a, 0 & z<a).
$
其分布从 $a$ 开始、向右偏斜，均值为 $a+sqrt(pi b)/2$，方差为 $b(4-pi)/4$。]

瑞利分布只在一侧取值，适合描述由两个正交高斯分量合成的幅值型随机量。它与高斯噪声的对称钟形不同，不能仅用相同均值与方差就认为两者可互换。

#tufted.definition[伽马噪声][形状参数为正整数 $b$、率参数为 $a>0$ 的伽马密度为
$
  p(z)=cases(a^b z^(b-1) exp(-a z)/(b-1)! & z>=0, 0 & z<0).
$
其均值为 $b/a$，方差为 $b/a^2$。]

当形状参数改变时，伽马分布可从强烈右偏逐渐接近钟形。不同资料也会使用“尺度参数” $theta=1/a$，读取公式和代码时必须确认第二参数到底是率还是尺度。

#figure(
  image("images/noise-densities.png", width: 82%, alt: "高斯、瑞利和指数型噪声概率密度的典型形状"),
  caption: [对称、单侧偏斜和单调衰减的密度具有不同统计特征；仅观察一幅噪声样本可能难以直接分辨，需要结合直方图与成像机制。]
)

== 2. 指数、均匀、椒盐噪声

#tufted.definition[指数噪声][参数 $a>0$ 的指数密度为
$
  p(z)=cases(a exp(-a z) & z>=0, 0 & z<0).
$
其均值为 $1/a$，方差为 $1/a^2$。指数分布是形状参数为 1 的伽马分布。]

#tufted.definition[均匀噪声][区间 $[a,b]$ 上的均匀密度为
$
  p(z)=cases(1/(b-a) & a<=z<=b, 0 & "其他").
$
其均值为 $(a+b)/2$，方差为 $(b-a)^2/12$。区间内各噪声值等可能。]

#tufted.definition[椒盐噪声][椒盐噪声是双极脉冲噪声，其离散分布为
$
  P(z)=cases(P_(a) & z=a, P_(b) & z=b, 0 & "其他"),
$
通常 $a=0$ 表示黑色“椒”点，$b=L-1$ 表示白色“盐”点，其余像素以概率 $1-P_(a)-P_(b)$ 不受脉冲替换。]

椒盐噪声不是在原灰度上加一个小扰动，而是把少量像素直接替换成极端值，因此均值滤波往往会把极端值扩散到邻域；中值和自适应中值更符合这种离群点模型。只有盐噪声或只有椒噪声时，调和、逆调和均值与最大/最小值滤波可以有针对性地处理。

== 3. 周期噪声

#tufted.definition[周期噪声][二维周期噪声可以表示为一个或多个正弦分量之和：
$
  eta(x,y)=sum_(k) A_(k) cos(2 pi(u_(k) x+v_(k) y)+phi_(k)).
$
每个分量在中心化频谱的 $(u_(k),v_(k))$ 与 $(-u_(k),-v_(k))$ 产生一对共轭峰。]

周期噪声可能来自电气干扰、扫描机构振动或重复采样误差。它在空间域表现为规则条纹、波纹或网纹，在频域却集中到少数位置，所以频域陷波通常比大范围空间平滑更有选择性：空间低通会同时模糊真实边缘，陷波只压制已识别的噪声频率。

== 4. 噪声参数的估计

有原始无噪声图像时，可以直接用差值 $eta=g-f$ 估计噪声；实际更常见的是只有退化图像。此时应选取若干内容近似恒定的小区域，因为平坦区的灰度变化主要来自噪声，而不是物体纹理。

#figure(
  image("images/noise-estimation.png", width: 78%, alt: "从图像平坦区域选取样本并统计局部噪声直方图"),
  caption: [先选取缺少真实边缘与纹理的局部块，再从样本直方图、均值和方差估计噪声参数。]
)

对包含 $n$ 个样本 $z_(i)$ 的区域，样本均值和无偏方差为
$
  hat(mu)=1/n sum_(i) z_(i), quad
  hat(sigma)^2=1/(n-1)sum_(i)(z_(i)-hat(mu))^2.
$
若局部真实亮度未知，可以先减去局部均值；若怀疑含有脉冲离群值，可用中位数和中位绝对偏差
$
  "MAD"="median"(abs(z_(i)-"median"(z)))
$
得到稳健尺度估计，高斯情形常用 $hat(sigma) approx 1.4826 "MAD"$。

椒盐概率可由直方图在 0、$L-1$ 的异常计数估计，但真实图像本身也可能含纯黑或纯白区域，所以应结合空间孤立性与多个平坦块。周期噪声则在去除平滑背景后检查频谱峰值，其频率由峰相对中心的偏移估计，振幅可由峰值复系数估计。

```python
patch = gray[40:90, 120:180].astype(np.float64)
mean = patch.mean()
variance = patch.var(ddof=1)

median = np.median(patch)
mad = np.median(np.abs(patch - median))
robust_sigma = 1.4826 * mad
```

#html.hr()
= 二、使用空间滤波复原图像

空间复原假设噪声可由局部邻域统计削弱。窗口越大，随机波动平均得越充分，但边缘和细节损失也越严重。选择滤波器时应先匹配噪声模型，再决定窗口大小。

== 1. 均值滤波器

#tufted.definition[四种均值滤波器][设 $S_(x y)$ 是以 $(x,y)$ 为中心、含 $m n$ 个像素的窗口。算术平均、几何平均、调和平均和 $Q$ 阶逆调和平均分别为
$
  hat(f)_("arith")=1/(m n)sum_((s,t) in S_(x y))g(s,t),
$
$
  hat(f)_("geo")=(product_((s,t) in S_(x y))g(s,t))^(1/(m n)),
$
$
  hat(f)_("harm")=(m n)/(sum_((s,t) in S_(x y))1/g(s,t)),
$
$
  hat(f)_("contra")=(sum g(s,t)^(Q+1))/(sum g(s,t)^Q).
$]

算术平均适合零均值随机噪声，却会平滑边缘。几何平均对大值的影响弱于算术平均，通常保留细节稍好；实现时应对数求和，避免大量乘法溢出。调和平均能抑制盐噪声，但窗口内出现 0 时分母发散，不适合椒噪声。逆调和平均在 $Q>0$ 时消除椒噪声，在 $Q<0$ 时消除盐噪声；选错符号会强化相反类型的脉冲。

#figure(
  image("images/mean-filter-series.png", width: 100%, alt: "均值滤波器在高斯噪声与盐噪声上的七幅对比图"),
  caption: [(a) 无噪声参考图；(b) 高斯噪声图像；(c) 算术平均结果；(d) 几何平均结果；(e) 盐噪声图像；(f) 调和平均结果；(g) $Q=-1.5$ 的逆调和平均结果。]
)

```python
def geometric_mean_filter(image: np.ndarray, size: int) -> np.ndarray:
    padded = np.pad(image, size // 2, mode="reflect")
    windows = np.lib.stride_tricks.sliding_window_view(
        padded,
        (size, size),
    )
    safe = np.maximum(windows, 1e-6)
    return np.exp(np.mean(np.log(safe), axis=(-2, -1)))

def contraharmonic_mean_filter(
    image: np.ndarray,
    size: int,
    order: float,
) -> np.ndarray:
    padded = np.pad(image, size // 2, mode="reflect")
    windows = np.lib.stride_tricks.sliding_window_view(
        padded,
        (size, size),
    )
    safe = np.maximum(windows, 1e-6)
    numerator = np.sum(safe ** (order + 1.0), axis=(-2, -1))
    denominator = np.sum(safe**order, axis=(-2, -1))
    return numerator / np.maximum(denominator, 1e-12)
```

== 2. 统计排序滤波器

中值滤波取排序后的中间值，适合双极椒盐噪声。最大值滤波扩张亮区域、消除孤立椒点；最小值滤波扩张暗区域、消除孤立盐点。中点滤波取窗口最大值与最小值的平均
$
  hat(f)_("mid")=1/2(z_("max")+z_("min")),
$
更适合均匀或高斯型随机噪声，不适合大量脉冲，因为两个极端值恰好被保留。

修正阿尔法均值把 $m n$ 个样本排序，删除最低和最高各 $d/2$ 个，再对剩余 $m n-d$ 个求平均：
$
  hat(f)_("alpha")=1/(m n-d)sum_(z in S_(x y)^d)z.
$
$d=0$ 时退化为算术平均；$d=m n-1$ 时接近中值。它在高斯噪声与少量脉冲同时存在时提供折中。

#figure(
  image("images/rank-filter-series.png", width: 100%, alt: "六幅顺序统计滤波结果对比图"),
  caption: [(a) 椒盐噪声图像；(b) 中值滤波结果；(c) 最小值滤波结果；(d) 最大值滤波结果；(e) 中点滤波结果；(f) 修正阿尔法均值滤波结果。]
)

```python
kernel = np.ones((3, 3), dtype=np.uint8)
median = cv2.medianBlur(noisy_u8, 3)
minimum = cv2.erode(noisy_u8, kernel)
maximum = cv2.dilate(noisy_u8, kernel)
midpoint = 0.5 * (
    minimum.astype(np.float32)
    + maximum.astype(np.float32)
)
```

== 3. 自适应滤波器

#tufted.definition[自适应局部降噪滤波器][设局部均值、局部方差和已知噪声方差分别为 $m_(L)$、$sigma_(L)^2$、$sigma_(eta)^2$，自适应局部降噪输出为
$
  hat(f)=g-(min(sigma_(eta)^2,sigma_(L)^2)/sigma_(L)^2)(g-m_(L)).
$
]

在平坦区，$sigma_(L)^2$ 接近噪声方差，系数接近 1，输出趋向局部均值；在真实边缘处，局部方差远大于噪声方差，系数较小，输出更接近原像素。将比值限制到 1 可避免噪声方差估计略大于局部方差时产生反向增强。

自适应中值滤波逐步扩大奇数窗口。对窗口最小值 $z_("min")$、最大值 $z_("max")$、中值 $z_("med")$ 和中心像素 $z_(x y)$，算法分两层判断：

1. 若 $z_("min")<z_("med")<z_("max")$，说明中值不是脉冲，进入下一步；否则扩大窗口，直到最大尺寸。
2. 若 $z_("min")<z_(x y)<z_("max")$，中心不是脉冲，保留中心；否则以中值替换。

固定中值窗口在高密度脉冲下可能所有样本都被污染；自适应扩大窗口能找到未污染中值，又在低噪声区域保持较小窗口。

#figure(
  image("images/adaptive-filter-series.png", width: 82%, alt: "四幅自适应滤波前后对比图"),
  caption: [(a) 方差从左向右增大的高斯噪声；(b) 自适应局部降噪结果；(c) 高密度椒盐噪声；(d) 自适应中值滤波结果。]
)

```python
def adaptive_local_filter(
    image: np.ndarray,
    size: int,
    noise_variance: float,
) -> np.ndarray:
    source = image.astype(np.float32)
    mean = cv2.boxFilter(source, -1, (size, size))
    mean_square = cv2.boxFilter(source * source, -1, (size, size))
    variance = np.maximum(mean_square - mean * mean, 0.0)
    ratio = np.minimum(
        noise_variance / np.maximum(variance, 1e-6),
        1.0,
    )
    return source - ratio * (source - mean)


def adaptive_median_filter(
    image: np.ndarray,
    maximum_size: int = 7,
) -> np.ndarray:
    if maximum_size < 3 or maximum_size % 2 == 0:
        raise ValueError("maximum_size 必须是大于等于 3 的奇数")

    source = image.astype(np.uint8)
    output = source.copy()
    radius = maximum_size // 2
    padded = np.pad(source, radius, mode="reflect")

    for row in range(source.shape[0]):
        for col in range(source.shape[1]):
            center = source[row, col]

            for size in range(3, maximum_size + 1, 2):
                half = size // 2
                padded_row = row + radius
                padded_col = col + radius
                window = padded[
                    padded_row - half:padded_row + half + 1,
                    padded_col - half:padded_col + half + 1,
                ]
                minimum = int(window.min())
                maximum = int(window.max())
                median = int(np.median(window))

                # A 层：中值不是脉冲时，才检验中心像素。
                if minimum < median < maximum:
                    # B 层：中心不是脉冲则保留，否则换成中值。
                    output[row, col] = (
                        center
                        if minimum < center < maximum
                        else median
                    )
                    break

                # 到达最大窗口仍未通过 A 层，只能采用当前中值。
                if size == maximum_size:
                    output[row, col] = median

    return output
```

#html.hr()
= 三、使用频域滤波复原图像

周期噪声的能量集中于少数离散频率，而真实图像的大部分频谱仍可保留，因此频域陷波比空间窗口平均更有选择性。空间滤波需要为了压制整幅条纹而使用较大窗口，通常会模糊全部边缘；陷波只在噪声峰附近衰减。

== 1. 陷波滤波

设频谱高为 $P$、宽为 $Q$，则中心化后的零频位置为 $(floor(Q/2),floor(P/2))$。第 $k$ 个噪声峰相对中心的偏移为 $(u_(k),v_(k))$，到正、负共轭峰的距离分别为
$
  D_(k)^+(u,v)=sqrt((u-floor(Q/2)-u_(k))^2+(v-floor(P/2)-v_(k))^2),
$
$
  D_(k)^-(u,v)=sqrt((u-floor(Q/2)+u_(k))^2+(v-floor(P/2)+v_(k))^2).
$
高斯陷波带阻的一般形式可写为
$
  H_("NR")(u,v)=product_(k)
  (1-exp(-(D_(k)^+)^2/(2D_(0)^2)))
  (1-exp(-(D_(k)^-)^2/(2D_(0)^2))).
$
每个因子在对应峰中心为 0，远离峰时趋近 1；正负峰成对出现，保证对实图像的共轭对称性。陷波带通为 $H_("NP")=1-H_("NR")$，可先提取周期干扰，再从退化图像中减去。

下面的实际图像叠加两项周期噪声：一项产生偏移 $(0,plus.minus 48)$ 的峰，另一项产生 $(plus.minus 31,plus.minus 18)$ 的共轭峰。处理链完整展示了从空间诊断到复原的过程。

#figure(
  image("images/periodic-restoration-series.png", width: 100%, alt: "周期噪声从诊断到陷波复原的六幅过程图"),
  caption: [(a) 无噪声参考图；(b) 含两组周期噪声的退化图；(c) 中心化频谱及成对噪声峰；(d) 成对高斯陷波传递函数；(e) 陷波后的频谱；(f) 逆变换得到的复原图像。]
)

```python
def gaussian_notch_reject(
    shape: tuple[int, int],
    offsets: list[tuple[float, float]],
    sigma: float,
) -> np.ndarray:
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

spectrum = np.fft.fftshift(np.fft.fft2(noisy))
notch = gaussian_notch_reject(
    noisy.shape,
    offsets=[(0.0, 48.0), (31.0, 18.0)],
    sigma=2.6,
)
filtered = spectrum * notch
restored = np.fft.ifft2(np.fft.ifftshift(filtered)).real
```

== 2. 最优陷波滤波

普通陷波把指定频率固定衰减，却没有利用噪声在空间中的强弱变化。最优陷波先用陷波带通提取干扰估计 $hat(eta)$，再在每个局部区域选择权重 $w(x,y)$：
$
  hat(f)(x,y)=g(x,y)-w(x,y)hat(eta)(x,y).
$
令局部期望用窗口平均近似，使复原结果局部方差最小，可得
$
  w=(E[g hat(eta)]-E[g]E[hat(eta)])/
  (E[hat(eta)^2]-E[hat(eta)]^2).
$
分子是观测与噪声估计的局部协方差，分母是噪声估计的局部方差。噪声在某区域较强时权重增大，较弱时减小；分母过小时应令权重为 0 或加正则项，避免数值爆炸。

```python
def optimal_notch_subtraction(
    degraded: np.ndarray,
    noise_estimate: np.ndarray,
    window: int = 15,
) -> np.ndarray:
    g = degraded.astype(np.float32)
    n = noise_estimate.astype(np.float32)
    size = (window, window)

    mean_g = cv2.blur(g, size)
    mean_n = cv2.blur(n, size)
    covariance = cv2.blur(g * n, size) - mean_g * mean_n
    variance_n = cv2.blur(n * n, size) - mean_n * mean_n
    weight = covariance / np.maximum(variance_n, 1e-6)
    weight = np.clip(weight, 0.0, 1.5)
    return g - weight * n
```

#html.hr()
= 四、线性位置不变退化与退化函数的估计

== 1. 线性位置不变退化

#tufted.definition[线性位置不变退化][若退化系统既满足叠加性，又满足输入平移导致输出等量平移，则它由点扩散函数 $h(x,y)$ 完全描述：
$
  g(x,y)=h(x,y)*f(x,y)+eta(x,y).
$
频域中相应为
$
  G(u,v)=H(u,v)F(u,v)+N(u,v).
$]

$h$ 是一个理想点目标经过系统后形成的图样，所以称点扩散函数；$H$ 是光学传递函数。位置不变意味着同一个点目标放到图像不同位置时，扩散形状只发生平移。实际镜头边缘像差、景深变化和非刚性运动可能破坏这一假设，此时单一全局 $H$ 只能近似。

#figure(
  image("images/lsi-model.png", width: 82%, alt: "清晰信号经过位置不变退化并叠加噪声的模型"),
  caption: [点扩散函数把每个输入点扩展并叠加，噪声随后进入观测；频域中卷积转为 $H F$。]
)

== 2. 退化函数估计

=== a. 观察法

观察法在退化图像中寻找结构简单、原形状可推断的区域。例如孤立亮点的模糊形状近似 PSF，笔直边缘的边缘扩展函数求导后可估计线扩散函数。选区频谱 $G_(s)$ 与对理想选区的估计 $F_(s)$ 可给出
$
  hat(H)=G_(s)/F_(s).
$
分母接近 0 的频率不能可靠相除，选区也必须足够小，使退化近似位置不变。

=== b. 试验法

若能控制成像系统，可输入已知点源、细线、棋盘格或正弦图样。点源响应直接测量 PSF；不同空间频率正弦图样的幅度衰减和相位移动可逐点测量 $H$。试验法通常比仅观察未知图像可靠，但要求设备状态、焦距、曝光和运动条件与待复原图像一致。

=== c. 建模法

建模法从物理运动或光学过程推导 $H$。以曝光时间 $T$ 内的平面匀速运动为例，若相机与场景的相对位移为 $(x_(0)(t),y_(0)(t))$，时间平均观测为
$
  g(x,y)=1/T integral_(0)^T f(x-x_(0)(t),y-y_(0)(t)) dif t.
$
利用傅里叶平移性质，传递函数为
$
  H(u,v)=1/T integral_(0)^T
  exp(-ii 2 pi(u x_(0)(t)+v y_(0)(t))) dif t.
$
若总位移为 $(a,b)$，即 $x_(0)(t)=a t/T$、$y_(0)(t)=b t/T$，令 $s=u a+v b$，则
$
  H(u,v)&=integral_(0)^1 exp(-ii 2 pi s tau) dif tau\
  &=exp(-ii pi s) "sinc"(s),
$
其中 $"sinc"(s)=sin(pi s)/(pi s)$，$s=0$ 时极限为 1。幅度沿运动方向的频率坐标呈 sinc 形，并在非零整数 $s$ 处出现零点；相位因子对应模糊核中心位置。

#figure(
  image("images/motion-transfer.png", width: 83%, alt: "曝光期间的匀速线性运动轨迹及其 sinc 频率响应"),
  caption: [匀速直线路径产生线状点扩散函数，其频率响应沿相应方向出现周期零点；这些零点是逆滤波不稳定的根源。]
)

下面给出一个实际数值例子。令总运动长度为 $23$ 像素、方向角为 $18 degree$，则水平与竖直位移近似为
$
  a=23 cos(18 degree) approx 21.87,
  quad
  b=23 sin(18 degree) approx 7.11.
$
在曝光期间沿这条线段均匀采样并归一化，便得到线状 PSF；将其与清晰图像卷积，得到具有明显斜向拖影的运动模糊图像。再叠加标准差为 $3$ 个灰度级的零均值高斯噪声，得到后续复原算法共同使用的观测图像。这样，物理假设、模型参数、PSF 与实际退化结果便一一对应，而不只是停留在传递函数公式上。

#figure(
  image("images/motion-model-series.png", width: 100%, alt: "清晰图像经过给定匀速运动模型后产生模糊并叠加噪声的三幅实例图"),
  caption: [(a) 清晰参考图像；(b) 使用长度 $23$ 像素、方向角 $18 degree$ 的匀速运动 PSF 得到的无噪声模糊图像；(c) 在 (b) 上叠加标准差为 $3$ 的高斯噪声后得到的实际退化观测。]
)

```python
def uniform_motion_transfer(
    shape: tuple[int, int],
    displacement_x: float,
    displacement_y: float,
) -> np.ndarray:
    rows, cols = shape
    v = np.fft.fftfreq(rows)[:, None]
    u = np.fft.fftfreq(cols)[None, :]
    projection = u * displacement_x + v * displacement_y
    return np.sinc(projection) * np.exp(-1j * np.pi * projection)

motion_h = uniform_motion_transfer(
    gray.shape,
    displacement_x=22.0,
    displacement_y=7.0,
)
```

非匀速或曲线运动时，仍可对一般积分数值求和：在曝光区间采样轨迹点，计算每个点的相位因子并取平均。若轨迹未知，可以从陀螺仪、相邻视频帧、图像中直线拖影的长度与方向，或盲去卷积联合估计原图和 PSF。

#html.hr()
= 五、逆滤波

即使准确知道 $H$，也不能保证准确复原。由
$
  G=H F+N
$
直接相除得到
$
  hat(F)=G/H=F+N/H.
$
当 $H$ 很小，噪声项被 $1/H$ 巨大放大；当 $H=0$，该频率的原图信息已完全丢失，不存在有限逆；此外，PSF 参数的微小误差也会在小 $H$ 附近被放大。因此“知道退化函数”并不等于逆问题已经稳定。

截断逆滤波只在 $abs(H)>=epsilon$ 的位置相除，其余频率置零或不作逆补偿：
$
  hat(F)=cases(G/H & abs(H)>=epsilon, 0 & abs(H)<epsilon).
$
$epsilon$ 越小，恢复的频率更多，噪声放大也更严重；越大则稳定但模糊残留更多。

```python
def truncated_inverse(
    degraded: np.ndarray,
    transfer: np.ndarray,
    threshold: float,
) -> np.ndarray:
    spectrum = np.fft.fft2(degraded)
    inverse = np.zeros_like(transfer, dtype=np.complex128)
    stable = np.abs(transfer) >= threshold
    inverse[stable] = 1.0 / transfer[stable]
    return np.fft.ifft2(inverse * spectrum).real
```

#html.hr()
= 六、维纳滤波

维纳滤波不要求把退化完全反转，而是在噪声放大与去模糊之间最小化均方误差。以下推导把原图与加性噪声视为零均值、二阶平稳且互不相关的随机场，并假设退化系统线性位置不变。设使用线性频域估计 $hat(F)=A G$，目标为
$
  min_(A) E[abs(F-A G)^2].
$
代入 $G=H F+N$，展开期望并对 $A^ast$ 求极值，可得正规方程
$
  A(abs(H)^2 S_(f)+S_(eta))=H^ast S_(f),
$
其中 $S_(f)=E[abs(F)^2]$、$S_(eta)=E[abs(N)^2]$ 是信号和噪声功率谱。因此
$
  H_("W")=H^ast/(abs(H)^2+S_(eta)/S_(f)).
$

#tufted.definition[信噪比][信噪比定义为信号功率与噪声功率之比
$
  "SNR"=P_(f)/P_(eta),
$
常以分贝表示为 $10 log_(10)(P_(f)/P_(eta))$。频率相关的 $S_(f)(u,v)/S_(eta)(u,v)$ 描述各频率上的信噪比。]

在高信噪比频率，$S_(eta)/S_(f)$ 很小，维纳滤波接近逆滤波；在低信噪比或 $H$ 很小的位置，分母中的噪声项限制增益。未知功率谱时常用常数 $K approx S_(eta)/S_(f)$，但它只是白噪声与平均信号功率的粗略近似。

```python
def wiener_restore(
    degraded: np.ndarray,
    transfer: np.ndarray,
    noise_to_signal: float | np.ndarray,
) -> np.ndarray:
    spectrum = np.fft.fft2(degraded)
    numerator = np.conjugate(transfer)
    denominator = np.abs(transfer) ** 2 + noise_to_signal
    estimate = numerator / np.maximum(denominator, 1e-12) * spectrum
    return np.fft.ifft2(estimate).real
```

#figure(
  image("images/restoration-method-series.png", width: 100%, alt: "同一运动退化图像使用三种方法复原的六幅对比图"),
  caption: [(a) 清晰参考图像；(b) 无噪声运动模糊；(c) 叠加高斯噪声后的观测；(d) 截断逆滤波结果；(e) 维纳滤波结果；(f) 约束最小二乘结果。]
)

#html.hr()
= 七、约束最小二乘滤波

维纳滤波需要信号与噪声功率谱。约束最小二乘改用平滑先验：在观测残差符合噪声能量的条件下，让估计图像经过高通算子 $p$ 后的能量尽量小：
$
  min_(hat)(f) norm(p*hat(f))_(2)^2
  quad "subject to" quad
  norm(g-h*hat(f))_(2)^2<=epsilon^2.
$
用拉格朗日乘子把约束并入目标，并在频域对 $hat(F)^*$ 求导，得到
$
  (H^ast H+gamma P^ast P)hat(F)=H^ast G,
$
所以
$
  hat(F)=H^ast/(abs(H)^2+gamma abs(P)^2)G.
$
$P$ 常取离散拉普拉斯核的 DFT，使高频振荡受到更强惩罚。$gamma$ 小时接近逆滤波，细节多但噪声敏感；$gamma$ 大时更平滑、稳定，却可能过度模糊。$epsilon$ 若来自噪声方差估计，可用迭代调整 $gamma$，使最终残差能量与预期噪声能量相符。

```python
def constrained_least_squares(
    degraded: np.ndarray,
    transfer: np.ndarray,
    penalty: np.ndarray,
    gamma: float,
) -> np.ndarray:
    spectrum = np.fft.fft2(degraded)
    denominator = (
        np.abs(transfer) ** 2
        + gamma * np.abs(penalty) ** 2
    )
    estimate = (
        np.conjugate(transfer)
        / np.maximum(denominator, 1e-12)
        * spectrum
    )
    return np.fft.ifft2(estimate).real
```

#html.hr()
= 八、几何均值滤波

几何均值复原滤波器在逆滤波与维纳滤波之间作乘法插值：
$
  H_("GM")=
  (H^ast/abs(H)^2)^alpha
  (H^ast/(abs(H)^2+beta S_(eta)/S_(f)))^(1-alpha).
$
$alpha=1$ 时得到逆滤波，$alpha=0$、$beta=1$ 时得到维纳滤波；$beta$ 进一步调节噪声项强度。由于两个因子具有相同的 $H^ast$ 相位，更稳定的实现可合并为
$
  H_("GM")=H^ast/
  ((abs(H)^2)^alpha
  (abs(H)^2+beta S_(eta)/S_(f))^(1-alpha)).
$

```python
def geometric_mean_restore(
    degraded: np.ndarray,
    transfer: np.ndarray,
    noise_to_signal: float | np.ndarray,
    alpha: float,
    beta: float = 1.0,
) -> np.ndarray:
    power = np.abs(transfer) ** 2
    denominator = (
        np.maximum(power, 1e-12) ** alpha
        * np.maximum(
            power + beta * noise_to_signal,
            1e-12,
        ) ** (1.0 - alpha)
    )
    restoration = np.conjugate(transfer) / denominator
    estimate = restoration * np.fft.fft2(degraded)
    return np.fft.ifft2(estimate).real
```

#figure(
  image("images/geometric-mean-series.png", width: 82%, alt: "运动退化图像与几何均值复原结果的两幅对比图"),
  caption: [(a) 同时含运动模糊与高斯噪声的退化图像；(b) 取 $alpha=0.45$ 的几何均值滤波结果。]
)

#tufted.remark[复原结果如何评价][有参考原图时，可同时报告 MSE、PSNR、SSIM 与视觉伪影；无参考时，应检查噪声残差是否仍含结构、边缘周围是否振铃、亮度是否偏移，并验证结果对参数小变化是否稳定。最锐利的输出未必是最可信的复原，逆问题中的稳定性与模型一致性同样重要。]

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee", title: "References", full: true)
