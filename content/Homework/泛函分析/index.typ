#import "../index.typ": template, tufted
#show: template.with(
    title: "泛函分析作业",
    description: "",
)

#let frasig(x) = $frac(#x, 1 + #x)$

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

若点列 ${x_(n)}$ 收敛到 $x$，则：
$ d(x_(n), x) = sup_(0 <= t <= 1) abs(x_(n)(t) - x(t)) + sup_(0 <= t <= 1) abs(x'_(n)(t) - x'(t)) -> 0. $

因此显然也有 
$sup_(0 <= t <= 1) abs(x_(n)(t) - x(t)) -> 0, sup_(0 <= t <= 1) abs(x'_(n)(t) - x'(t)) -> 0, $
即 ${x_(n)}(t), {x'_(n)}(t)$ 一致收敛到 $x(t), x'(t)$。

故 $D$ 中点列按距离收敛，等价于函数和导数一致收敛。

=== (3) 证明 $D$ 是完备的

设 ${x_(n)}$ 是柯西列。那么 $forall epsilon > 0$, $exists N$, 有 
$ n, m > N => d(x_(n), x_(m)) = sup_(0 <= t <= 1) abs(x_(n)(t) - x_(m)(t)) + sup_(0 <= t <= 1) abs(x'_(n)(t) - x'_(m)(t)) < epsilon. $

因此，$sup_(0 <= t <= 1) abs(x_(n)(t) - x_(m)(t)) < epsilon$，故 ${x_(n)}(t)$ 一致收敛于 $x(t)$。同理 ${x'_n}(t)$ 也一致收敛于 $y(t)$。

接下来证明 $y(t)$ 是 $x(t)$ 的导数 $x'(t)$。对任意 $t,t_(0) in [0,1]$，显然有：
$ x_(n)(t) - x_(n)(t_(0)) = integral_(t_(0))^(t) x'_(n)(s) d s, $
当 $n -> infinity$ 时：
$ "左边" = x_(n)(t) - x_(n)(t_(0)) -> x(t) - x(t_(0)) $
$ "右边" = integral_(t_(0))^(t) x'(s) d s -> integral_(t_(0))^(t) y(s) d s $
右边的过程是因为在一致收敛时，积分与极限可以交换。因此：
$ x(t) - x(t_(0)) = integral_(t_(0))^(t) y(s) d s $
故 $y(t)$ 是 $x(t)$ 的导数，即 $y(t) = x'(t)$。

因此，$x$ 在 $[0, 1]$ 区间上具有连续导数，故 $x in D$。另一方面，显然有
$ d(x_(n), x) = sup_(0 <= t <= 1) abs(x_(n)(t) - x(t)) + sup_(0 <= t <= 1) abs(x'_(n)(t) - x'(t)) -> 0, $
这说明 ${x_(n)}$ 收敛。因此 $D$ 是完备的。

== 习题一之 2 <Homework1-2>

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
  + $d = sum_(k=1)^(infinity) frac(1, 2^k) dot frac(d_(k), 1 + d_(k))$
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
  =& sum d_(i)^(2)(x,z) + sum d_(i)^(2)(z,y) + 2 sqrt(sum d_(i)^(2)(x,z)) dot sqrt(sum d_(i)^(2)(z,y)) \
  >=& sum d_(i)^(2)(x,z) + sum d_(i)^(2)(z,y) + 2 sum d_(i)(x,z) d_(i)(z,y) \
  =& sum { d_(i)(x,z) + d_(i)(z,y) }^2  \
  >=& sum d_(i)^(2)(x,y) \
  =& d^(2)(x,y)
$

=== (3) 证明 $d = sum_(k=1)^(infinity) frac(1, 2^k) dot frac(d_(k), 1 + d_(k))$ 是距离

$
  & d(x,z) + d(z,y) \
  =& sum frac(1, 2^k) dot frac(d_(k)(x,z), 1 + d_(k)(x,z)) + sum frac(1, 2^k) dot frac(d_(k)(z,y), 1 + d_(k)(z,y)) \
  =& sum frac(1, 2^k) dot { frac(d_(k)(x,z), 1 + d_(k)(x,z)) + frac(d_(k)(z,y), 1 + d_(k)(z,y)) } \
$
由 @Homework1-2 可知：
$
  & d(x,z) + d(z,y) \
  >=& sum frac(1, 2^k) dot frac(d_(k)(x,y), 1 + d_(k)(x,y)) \
  =& d(x,y)
$

#html.hr()

= 第二次作业：习题一之 5、6、7、12

== 习题一之 5

#tufted.problem[
  在距离空间中，半径为4的开球可以是半径为3的开球的真子集吗？
]

构造距离空间 $X = {x, y, z}$，且 $d(x, y) = 2$，$d(y, z) = 2$，$d(x, z) = 4$。

那么，$S(x, 4) = {x, y}$，$S(y, 3) = {x, y, z}$，因此是存在的。

== 习题一之 6

#tufted.problem[
  证明在距离空间中，如果一个半径为7的开球包含在一个半径为3的开球中，则这两个球重合。
]

只需证明不存在一个点 $x$，同时满足 $x in S(x_(i), 3)$ 且 $x in.not S(x_(j), 7)$。

如果该点符合此条件，那么存在 $d(x, x_(i)) < 3$ 且 $d(x, x_(j)) >= 7$。而对第一式使用三角不等式，有：
$
  d(x, x_(j)) + d(x_(j), x_(i)) < 3
$
由距离的非负性，这与 $d(x, x_(j)) >= 7$ 矛盾。故不存在这样的点 $x$，因此两个球重合。

== 习题一之 7

#tufted.problem[
  证明在空间 $s$ 中，按距离收敛等价于按坐标收敛。
]

#let absk7 = $abs(x_(n)^((i)) - x^((i)))$

先证明 按距离收敛 $=>$ 按坐标收敛。此时，
$
  d(x_(n), x) = sum_(i) frac(1, 2^(i)) frasig(absk7) -> 0.
$
故对任意$i$，
$
  frasig(absk7) <= d(x_(n), x) -> 0.
$
而函数$frasig(x)$在$[0, +infinity)$上单调递增且连续，所以亦有$absk7 -> 0 => x_(n)^((i)) -> x^((i))$，从而得证。

接下来证明 按坐标收敛 $=>$ 按距离收敛。此时，$forall i, absk7 -> 0$。同时由于 $x > frasig(x) > 0$，亦有 $frasig(absk7) -> 0$。

由于求和 $sum frac(1, 2^k) = 1$ 收敛，则 $forall epsilon > 0$， $exists N_(0)$ 使 $sum_(i=N_(0) + 1) frac(1, 2^(i)) < frac(epsilon, 2)$。

而 $absk7 -> 0$，所以存在 $N_1$ 使得 $i > N_1$ 时，$absk7 < frac(epsilon, 2)$。进一步由于 $x > frasig(x)$ 则 $frasig(absk7) < frac(epsilon, 2)$。于是：
$
  &d(x_(n), x) \
  =& sum_(i) frac(1, 2^(i)) frasig(absk7) \
  =& sum_(i=1)^(N_(0)) frac(1, 2^(i)) frasig(absk7) + sum_(i=N_(0) + 1)^(infinity) frac(1, 2^(i)) frasig(absk7) \
  <& frac(epsilon, 2) + sum_(i=N_(0) + 1)^(infinity) frac(1, 2^(i)) dot frac(epsilon, 2) \
  <& frac(epsilon, 2) + frac(epsilon, 2) = epsilon
$
则 $d(x_(n), x) -> 0$，从而得证。

== 习题一之 12

#tufted.problem[
  设 $(X, d)$ 是距离空间，$A subset X$，令
  $
    f(x) = inf_(y in A) d(x, y) quad quad (x in X),
  $
  证明 $f(x)$ 是 $X$ 上的连续函数。
]

设 $x, x_(0) in X$，及 $y in A$，有
$
  &d(x, y) <= d(x, x_(0)) + d(x_(0), y) \
  =>& inf d(x, y) <= inf {d(x, x_(0)) + d(x_(0), y)} \
  =>& f(x) <= d(x, x_(0)) + f(x_(0)) \
  =>& f(x) - f(x_(0)) <= d(x, x_(0))
$
同理 $f(x_(0)) - f(x) <= d(x_(0), x)$，即 $|f(x) - f(x_(0))| <= d(x, x_(0))$。因此 $forall epsilon>0$，只需取 $delta = epsilon$，即可有 $d(x, x_(0)) < delta$ 时，$|f(x) - f(x_(0))| < epsilon$。这便说明 $f(x)$ 在任意 $x_(0) in X$ 处连续。

= 习题一之 9、10、11、14、15

== 习题一之 9

#tufted.problem[
  证明距离空间中每个 Cauchy 列是有界集。
]

== 习题一之 10

#tufted.problem[
  证明距离空间的完备子空间是闭子空间。
]

== 习题一之 11

#tufted.problem[
  证明如果距离空间是可分的，则它的任意子空间也是可分的；反之，如果距离空间不可分，它的子空间是否也不可分？
]


== 习题一之 14

#tufted.problem[
  设 $X$ 是距离空间，证明：若在 $X$ 中，任一半径趋于零的闭球套具有非空交，则空间 $X$ 是完备的。
]


== 习题一之 15

#tufted.problem[
  设 $X$ 是完备距离空间，$cal(F)$ 是 $X$ 上的实连续函数族且具有性质：对于每一 $x in X$，存在常数 $M_x>0$ 使得对每一 $F in cal(F)$ 有 $|F(x)| <= M_x$。证明：存在开集 $U$ 及常数 $M>0$，使得对于每一 $x in U$ 及所有 $F in cal(F)$，有 $|F(x)| <= M$。
]
