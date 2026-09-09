#import "../index.typ": template, tufted
#show: template.with(
    title: "泛函分析作业",
    description: "",
)

= 泛函分析作业

= 第一次作业：习题一之 1 、2、3

== 习题一之 1

#tufted.problem[
  设 $D$ 是 $[0, 1]$ 区间上具有连续导数（在端点 $t=1, t=0$ 分别具有左右导数）的实函数全体，在 $D$ 上定义
  $ d(x,y) = sup_(0 <= t <= 1) abs(x(t) - y(t)) + sup_(0 <= t <= 1) abs(x'(t) - y'(t)). $
  + 证明 $D$ 是距离空间；
  + 指出 $D$ 中点列按距离收敛的意义；
  + 证明 $D$ 是完备的。
]

=== (1) 证明 $D$ 是距离空间

易证非负性与对称性。现在证明三角不等式。

$
  d(x,z) + d(z,y) &= { sup_(0 <= t <= 1) abs(x(t) - z(t)) + sup_(0 <= t <= 1) abs(x'(t) - z'(t)) } + { sup_(0 <= t <= 1) abs(z(t) - y(t)) + sup_(0 <= t <= 1) abs(z'(t) - y'(t)) } \ 
  &= { sup_(0 <= t <= 1) abs(x(t) - z(t)) + sup_(0 <= t <= 1) abs(z(t) - y(t)) } + { sup_(0 <= t <= 1) abs(x'(t) - z'(t)) + sup_(0 <= t <= 1) abs(z'(t) - y'(t)) } \
  &>= sup_(0 <= t <= 1){ abs(x(t) - z(t)) + abs(z(t) - y(t)) } + sup_(0 <= t <= 1){ abs(x'(t) - z'(t)) + abs(z'(t) - y'(t)) } \
  &>= sup_(0 <= t <= 1) abs(x(t) - y(t)) + sup_(0 <= t <= 1) abs(x'(t) - y'(t)) \
  &= d(x,y)
$

#tufted.theorem[上确界的一个性质][
  若 $f(x), g(x)$ 是定义在集合 $X$ 上的有界函数，则有
  $ sup_(x in X) f(x) + sup_(x in X) g(x) >= sup_(x in X) {f(x) + g(x)}. $
]

=== (2) 指出 $D$ 中点列按距离收敛的意义

若点列 ${x_n}$ 收敛到 $x$，则：
$ d(x_n, x) = sup_(0 <= t <= 1) abs(x_n(t) - x(t)) + sup_(0 <= t <= 1) abs(x_n'(t) - x'(t)) -> 0. $

因此显然也有 
$sup_(0 <= t <= 1) abs(x_n(t) - x(t)) -> 0, sup_(0 <= t <= 1) abs(x_n'(t) - x'(t)) -> 0, $
即 ${x_n}(t), {x_n}'(t)$ 一致收敛到 $x(t), x'(t)$。

故 $D$ 中点列按距离收敛，等价于函数和导数一致收敛。

=== (3) 证明 $D$ 是完备的

设 ${x_n}$ 是柯西列。那么 $forall epsilon > 0$, $exists N$, 有 
$ n, m > N => d(x_n, x_m) = sup_(0 <= t <= 1) abs(x_(n)(t) - x_(m)(t)) + sup_(0 <= t <= 1) abs(x_(n)'(t) - x_(m)'(t)) < epsilon. $

因此，$sup_(0 <= t <= 1) abs(x_(n)(t) - x_(m)(t)) < epsilon$，故 ${x_n}(t)$ 一致收敛于 $x(t)$。同理 ${x'_n}(t)$ 也一致收敛于 $y(t)$。

接下来证明 $y(t)$ 是 $x(t)$ 的导数 $x'(t)$。对任意 $t,t_(0) in [0,1]$，显然有：
$ x_(n)(t) - x_(n)(t_(0)) = integral_(t_(0))^(t) x'_(n)(s) d s, $
当 $n -> infinity$ 时：
$ "左边" = x_(n)(t) - x_(n)(t_(0)) -> x(t) - x(t_(0)) $
$ "右边" = integral_(t_(0))^(t) x'(s) d s -> integral_(t_(0))^(t) y(s) d s $
右边的过程是因为在一致收敛时，积分与极限可以交换。因此：
$ x(t) - x(t_(0)) = integral_(t_(0))^(t) y(s) d s $
故 $y(t)$ 是 $x(t)$ 的导数，即 $y(t) = x'(t)$。

因此，$x$ 在 $[0, 1]$ 区间上具有连续导数，故 $x in D$。另一方面，显然有
$ d(x_n, x) = sup_(0 <= t <= 1) abs(x_n(t) - x(t)) + sup_(0 <= t <= 1) abs(x_n'(t) - x'(t)) -> 0, $
这说明 ${x_n}$ 收敛。因此 $D$ 是完备的。

== 习题一之 2

#tufted.problem[
  证明如果 $d$ 是集 $X$ 上的距离，则 $d_1 = frac(d, 1 + d)$ 也是 $X$ 上的距离。
]

非负性：由于 $d >= 0$，所以 $d_1 = frac(d, 1 + d) = frac(1, 1 + frac(1, d)) >= 0$。

对称性：由于 $d(x,y) = d(y,x)$，所以 $d_1(x,y) = frac(d(x,y), 1 + d(x,y)) = frac(d(y,x), 1 + d(y,x)) = d_1(y,x)$。

三角不等式：
$
  d_1(x,z) + d_1(z,y) &= frac(d(x,z), 1 + d(x,z)) + frac(d(z,y), 1 + d(z,y)) \
  &= frac(d(x,z) + d(z,y) + 2 d(x,z) d(z,y), 1 + d(x,z) + d(z,y) + d(x,z) d(z,y)) \
  &>= frac(d(x,z) +  d(z,y), 1 + d(x,z) + d(z,y)) \
  &>= frac(d(x,y), 1 + d(x,y)) \
  &= d_1(x,y)
$

== 习题一之 3

#tufted.problem[
  设 $d_1, d_2, dots, d_m, dots$ 是集 $X$ 上的距离，证明
  + $d = sup_(1 <= i <= m) d_(i)$；
  + $d = sqrt(d_1^2 + d_2^2 + dots + d_m^2)$；
  + $d = sum_(k=1)^(infinity) frac(1, 2^k) dot frac(d_k, 1 + d_k)$
  中的每一个也是 $X$ 上的距离。
]

以下只证明三角不等式。

=== (1) 证明 $d = sup_(1 <= i <= m) d_(i)$ 是距离

$
  d(x,z) + d(z,y) &= sup_(1 <= i <= m) d_(i)(x,z) + sup_(1 <= j <= m) d_j(z,y) \
  &>= sup_(1 <= i <= m) { d_(i)(x,z) + d_(i)(z,y) } \
  &>= sup_(1 <= i <= m) d_(i)(x,y) \
  &= d(x,y)
$

=== (2) 证明 $d = sqrt(d_1^2 + d_2^2 + dots + d_m^2)$ 是距离

要证明 $d(x,z) + d(z,y) >= d(x,y)$，即证 ${d(x,z) + d(z,y)}^2 = d^(2)(x,z) + d^(2)(z,y) + 2d(x,z)d(z,y) >= d^(2)(x,y)$。

$
  &d^(2)(x,z) + d^(2)(z,y) + 2d(x,z)d(z,y) \
  =& sum d_(i)^(2)(x,z) + sum d_(i)^(2)(z,y) + 2 sum d_(i)^(2)(x,z) d_(i)^(2)(z,y) \
  =& sum { d_(i)^(2)(x,z) + d_(i)^(2)(z,y) + 2 d_(i)(x,z) d_(i)(z,y) } + 2 sum_(i != j) d_(i)(x,z) d_(j)(z,y) \
  =& sum { d_(i)(x,z) + d_(i)(z,y) }^2 + 2 sum_(i != j) d_(i)(x,z) d_(j)(z,y) \
  >=& sum { d_(i)(x,z) + d_(i)(z,y) }^2  \
  >=& sum d_(i)^(2)(x,y) \
  =& d^(2)(x,y)
$
