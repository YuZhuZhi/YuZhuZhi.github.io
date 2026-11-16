#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted, overline
#show: template.with(
    title: "泛函分析（三）——赋范线性空间",
    description: "",
)

#let nd = $norm(dot)$
#let nx = $norm(x)$
#let dt = $dif t$
#let bR = $bb(R)$

= 泛函分析（三）——赋范线性空间

= 一、赋范空间

#tufted.definition[范数与赋范空间][
  设 $X$ 是域 $bb(K)$ （实数域或复数域）上的线性空间，函数 $norm(dot): X -> bb(R)$ 满足条件：
  + 对任意 $x in X$，$norm(x) >= 0$；且 $norm(x) = 0$ 当且仅当 $x = 0$；
  + 对任意 $x in X$ 及 $alpha in bb(K)$，$norm(alpha x) = abs(alpha) norm(x)$ （齐次性）；
  + 对任意 $x, y in X$，$norm(x + y) <= norm(x) + norm(y)$ （三角不等式）。
  称 $norm(dot)$ 为 $X$ 上的一个*范数*，$X$ 上定义了范数 $norm(dot)$ 称为*赋范（线性）空间*，记为 $(X, nd)$，可简记为 $X$。
]

可以通过范数定义距离：
$
  d(x, y) = norm(x - y), wide x, y in X,
$
这个距离易证是符合距离空间的定义的，从而范数空间亦是距离空间。称该距离为*由范数诱导的距离*，且一般情况下都认为这就是赋范空间的距离。

设 ${x_(n)}$ 是赋范空间 $X$ 中的点列，$x in X$，若 $norm(x_n - x) -> 0 (n -> infinity)$，则称 ${x_(n)}$ *强收敛于*#footnote[或称*按范收敛于*] $x$，记为 
$
  x_n -> x (n -> infinity)
$
或
$
  x = lim_(n -> infinity) x_n.
$
若赋范空间是完备的则称其为 *Banach 空间*。

#tufted.theorem[][
  设 $(X, nd)$ 是赋范空间，则：
  + 范数是连续函数，即当 $x_n -> x (n -> infinity)$ 时，有 $norm(x_n) -> norm(x) (n -> infinity)$。
  + 线性运算是连续的，即当 $x_n -> x (n -> infinity)$，$y_n -> y (n -> infinity)$ 时，有 $x_n + y_n -> x + y (n -> infinity)$；当 $x_n -> x (n -> infinity)$，$alpha_n -> alpha (n -> infinity)$ 时，有 $alpha_n x_n -> alpha x (n -> infinity)$。
]

#tufted.theorem[][
  设 $(X, nd)$ 是完备的赋范空间，且级数
  $
    sum_(k=1)^(infinity) norm(x_(k)) = norm(x_(1)) + norm(x_(2)) + ... + norm(x_(n)) + ...
  $ <eq:范数求和>
  收敛，则级数
  $
    sum_(k=1)^(infinity) x_(k) = x_(1) + x_(2) + ... + x_(n) + ...
  $ <eq:向量求和> #footnote[若 @eq:向量求和 的部分和 $s_(n) = x_(1) + x_(2) + ... + x_(n)$ 收敛，即存在 $s in X$ 使得 $s_n -> s (n -> infinity)$，则称 $s$ 为该级数的和，记为 $s = sum_(k=1)^(infinity) x_(k)$。]
  亦收敛，且
  $
    norm(sum_(k=1)^(infinity) x_(k)) <= sum_(k=1)^(infinity) norm(x_(k)).
  $
  反之，若在一赋范空间中任意 @eq:范数求和 的无穷级数收敛必有 @eq:向量求和 收敛，则该赋范空间是完备的、即为 Banach 空间。
]

#let tV = $limits("V")$

以下给出一些典型的赋范空间。
+ 在 $bb(R)^(n)$ 中，定义 $nx = (sum_(k=1)^(n) abs(xi_(k))^(2))^(1/2)$，$x = (xi_(1), xi_(2), ..., xi_(n)) in bb(R)^(n)$。$bb(R)^(n)$ 是一个可分的 Banach 空间。
  - $bb(R)^(n)$ 中也可以定义范数 $nx_(1) = max_(1 <= k <= n) abs(xi_(k))$ 或 $nx_(2) = sum_(k=1)^(n) abs(xi_(k))$。
+ 在 $C[a, b]$ 中，定义 $nx = max_(a <= t <= b) abs(x(t))$。$C[a, b]$ 是一个可分的 Banach 空间。
+ 在 $l^(infinity)$ #footnote[复习：即有界数列 $x = {xi_(k)}$ 的全体按坐标定义线性运算构成的线性空间]中，定义 $nx = sup_(k >= 1) abs(xi_(k))$。$l^(infinity)$ 是一个不可分的 Banach 空间。
+ $V[a, b]$ 是 $[a, b]$ 上所有有界变差函数全体按通常方式规定线性运算构成的线性空间，对每个有界变差函数 $x(t)$ 定义范数 $nx = abs(x(a)) + tV_(a)^(b)(x)$，
  其中 $tV_(a)^(b)(x)$ 是 $x(t)$ 在 $[a, b]$ 上的全变差。$V[a, b]$ 是一个 Banach 空间。

#line()

= 二、$L^(p) (p>=1)$

== 1. Hölder 不等式与 Minkowski 不等式

#tufted.lemma[][
  设 $p,q$ 是正数且满足
  $
    frac(1, p) + frac(1, q) = 1,
  $
  则对任意数 $a, b$，有
  $
    abs(a b) <= frac(abs(a)^(p), p) + frac(abs(b)^(q), q).
  $
]

#tufted.lemma[Hölder 不等式][
  设 $E$ 是 Lebesgue 可测集，$x(t), y(t)$ 是 $E$ 上的可测函数，且 $p, q$ 满足 $frac(1, p) + frac(1, q) = 1$，则
  $
    integral_E abs(x(t) y(t)) dt <= ( integral_E abs(x(t))^p dt )^(1/p) ( integral_E abs(y(t))^q dt )^(1/q).
  $
]

#tufted.lemma[Minkowski 不等式][
  设 $E$ 是 Lebesgue 可测集，$x(t), y(t)$ 是 $E$ 上的可测函数，且 $p >= 1$，则
  $
    ( integral_E abs(x(t) + y(t))^p dt )^(1/p) <= ( integral_E abs(x(t))^p dt )^(1/p) + ( integral_E abs(y(t))^p dt )^(1/p).
  $
]

== 2. $L^(p)(E) (p >= 1)$ 空间

现在来说明什么是 $L^(p)(E)$ 空间。其中 $E$ 是 $bR$ 上的 Lebesgue 可测集，$p >= 1$，$x(t)$ 是 $E$ 上的可测函数。若 $abs(x(t))^(p)$ 在 $E$ 上可积，则称 $x(t)$ 是 $E$ 上的 $p$ 次可积函数。记所有 $E$ 上的 $p$ 次可积函数全体为 $L^(p)(E)$，并且按通常方式定义线性运算，范数定义为
$
  nx = ( integral_E abs(x(t))^p dt )^(1/p),
$
易证它是一个赋范线性空间，并且是 Banach 空间。更特殊地，$L^(p)[a, b] (p >= 1)$ 还是可分的空间。

如果存在可测子集 $E_0 subset E$ 使得 $m E_(0) = 0$ 且 $x(t)$ 在 $E \\ E_(0)$ 上是有界的，称 $x(t)$ 在 $E$ 上是*本质有界*的，而当 $p = infinity$ 时 $L^(infinity)(E)$ 即表示 $E$ 上的本质有界函数全体按通常方式规定线性运算构成的线性空间，范数定义为
$
  nx = inf_(m E_(0) = 0 \ E_(0) subset E) sup_(E \\ E_(0)) abs(x(t)).
$
它是一个不可分的 Banach 空间。

== 3. $l^(p) (p >= 1)$ 空间

若将 $L^(p)(E)$ 离散化，即得到 $l^(p)$ 空间。具体来说，假设数列 $x = {xi_(k)}$ 并满足条件
$
  sum_(k=1)^(infinity) abs(xi_(k))^p < infinity,
$
那么该数列就是 $l^(p)$ 空间中的一个元素。$l^(p)$ 空间按坐标定义线性运算，范数定义为
$
  nx = (sum_(k=1)^(infinity) abs(xi_(k))^p)^(1/p).
$
$l^(p) (p >= 1)$ 是可分的 Banach 空间。

#line()

= 三、赋范空间的性质

易证的是：赋范空间的任一完备子空间是闭子空间，Banach 空间的任一闭子空间是 Banach 空间。

例如空间 $c$ 是所有收敛数列之全体、按坐标规定线性运算，并定义范数
$
  nx = sup_(n) abs(xi_(n)).
$
那么它是 $l^(infinity)$ 的闭子空间，因此它也是 Banach 空间。进一步地，$c_(0)$ 是所有收敛于零的数列之全体，它又是 $c$ 的闭子空间，因此它也是 Banach 空间。




