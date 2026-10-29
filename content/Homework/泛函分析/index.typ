#import "../index.typ": template, tufted
#show: template.with(
    title: "泛函分析作业",
    description: "",
)

#let frasig(x) = $frac(#x, 1 + #x)$
#let close(x) = $overline(#x)$

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

#html.hr()

= 第三次作业：习题一之 9、10、11、14、15

== 习题一之 9

#tufted.problem[
  证明距离空间中每个 Cauchy 列是有界集。
]

设 ${x_(n)}$ 是 Cauchy 列，则 $forall epsilon > 0$，$exists N$，使得 $n, m >= N => d(x_(n), x_(m)) < epsilon$。取 $epsilon = epsilon_0$，则存在 $N_0$，使得 $n, m > N_0 => d(x_(n), x_(m)) < epsilon_0$。不妨直接取 $n=N_0$，则对任意 $m >= N_0$，有 $d(x_(N_0), x_(m)) < epsilon_0$，所以尾项 ${x_(N_0), x_(N_0 + 1), ...}$ 是有界的。而当 $m < N_0$ 时，前项 ${x_(1), x_(2), ..., x_(N_0 - 1)}$ 元素有限，则必然也是有界的。于是有限集之并 ${x_(1), x_(2), ..., x_(N_0 - 1), x_(N_0), x_(N_0 + 1), ...}$ 是有界的。

== 习题一之 10

#tufted.problem[
  证明距离空间的完备子空间是闭子空间。
]

设 $Y$ 是距离空间 $X$ 的完备子空间，$x in close(Y)$。则存在点列 ${y_(n)} subset Y$，使得 $y_(n) -> x$。由于 ${y_(n)}$ 是收敛列，则它是 Cauchy 列。由于 $Y$ 是完备的，则 ${y_(n)}$ 收敛于 $Y$ 中某点 $y$。而收敛列的极限唯一，则有 $x = y in Y$。因此 $close(Y) subset Y$，即 $Y$ 是闭集。

== 习题一之 11

#tufted.problem[
  证明如果距离空间是可分的，则它的任意子空间也是可分的；反之，如果距离空间不可分，它的子空间是否也不可分？
]

首先证明前半部分。假设 $(X,d)$ 可分，以及可数稠密集 $D = {x_(1), x_(2), x_(3), ...} subset X$。任取子空间 $Y subset X$，对 $n in bb(N)$ 考虑 $B(x_(k), frac(1, n)), k=1,2,3,...$。若开球与 $Y$ 有交集，则在交集中任取一点记为 $y_(k,n) in B(x_(k), frac(1, n)) inter Y$，并纳入到集合 $E = {y_(k,n) : k, n in bb(N)}$ 中。显然，由于 $bb(N) times bb(N)$ 可数，则 $E$ 可数。

现在证明 $E$ 在 $Y$ 中稠密。任取 $y in Y$ 及 $epsilon > 0$，并令 $n$ 足够大使 $frac(2, n) < epsilon$。而 $D$ 在 $X$ 中稠密，则必然存在 $x_(k) in D$ 使得 $d(y, x_(k)) < frac(1, n)$，即 $y in B(x_(k), frac(1, n))$。由三角不等式，
$
  d(y, y_(k,n)) <= d(y, x_(k)) + d(x_(k), y_(k,n)) < frac(1, n) + frac(1, n) = frac(2, n) < epsilon,
$
意味着 $Y$ 中任一点可被 $E$ 中的点任意逼近，即 $close(E) = Y$，故 $E$ 在 $Y$ 中稠密且可分，所以 $Y$ 可分。

现在说明后半部分。不妨设定不可数集 $X$ 中，使用离散距离定义。那么每个点都是孤立点，则稠密子集必然只能是 $X$ 自身。但 $X$ 不可数，所以不可分。如果在 $X$ 中任取可数集 $Y$ 作为子空间，那么 $Y$ 对于自身稠密且可数，则是可分的。故不可分空间的子空间不一定不可分。

== 习题一之 14

#tufted.problem[
  设 $X$ 是距离空间，证明：若在 $X$ 中，任一半径趋于零的闭球套具有非空交，则空间 $X$ 是完备的。
]

现证明 $X$ 中任意 Cauchy 列 ${x_n}$ 收敛。对任意 $k in bb(N)$ 总存在 $N_(k)$ 使 $m,n >= N_(k)$ 时有 $d(x_(m), x_(n)) < frac(1, 2^(k+1))$。

#let cB = $close(B)$

取子列 ${x_(n_(k))}$ 使 $n_(1) < n_(2) < n_(3) < ...$ 且 $d(x_(n_(k)), x_(n_(k+1))) < frac(1, 2^(k+1))$，作闭球 $cB_(k) = cB(x_(n_(k)), frac(1, 2^(k)))$，那么 ${cB_k}$ 是闭球套，且半径 $2^(-k) -> 0$。

题目条件给出 $inter.big_(k=1)^(infinity) cB_(k) != emptyset$，那么取 $x in inter.big_(k) cB_(k)$，对每个 $k$ 有 $d(x, x_(n_k)) <= 2^(-k) -> 0$，故子列 ${x_(n_(k))}$ 收敛到 $x$，因为 ${x_n}$ 是 Cauchy 列则其本身也收敛到 $x$。

因此 $X$ 中任意 Cauchy 列都收敛，则 $X$ 是完备的。

== 习题一之 15

#tufted.problem[
  设 $X$ 是完备距离空间，$cal(F)$ 是 $X$ 上的实连续函数族且具有性质：对于每一 $x in X$，存在常数 $M_x>0$ 使得对每一 $F in cal(F)$ 有 $|F(x)| <= M_x$。证明：存在开集 $U$ 及常数 $M>0$，使得对于每一 $x in U$ 及所有 $F in cal(F)$，有 $|F(x)| <= M$。
]

对每个 $n in bb(N)$，令 $E_(n) = {x in X : |F(x)| <= n, forall F in cal(F)}$，因每个 $F$ 连续，则 ${x in X : |F(x)| <= n} = F^(-1)([-n, n])$ 是闭集，所以 $E_(n)$ 也是闭集。

由题目条件每个 $x in X$ 存在 $M_(x) > 0$，使一切 $F in cal(F)$ 有 $abs(F(x)) <= M_(x)$，那么取 $n > M_(x)$，则 $x in E_(n)$。故 $X = union.big_(n=1)^(infinity) E_(n)$。而 $X$ 是第二纲集，则至少一个 $E_(n_(0))$ 有非空内部，即存在非空开集 $U subset E_(n_(0))$。

取 $M = n_(0) > 0$，于是任意 $x in U$ 有 $x in E_(n_(0))$，从而对一切 $F in cal(F)$，有 $|F(x)| <= n_(0) = M$。如此，存在开集 $U$ 和常数 $M > 0$，使得对于每一 $x in U$ 及所有 $F in cal(F)$，有 $|F(x)| <= M$。

= 第四次作业：习题一之 16、17、18、19

== 习题一之 16

#tufted.problem[
  举例说明，在压缩映射原理中，
  + 空间完备性条件不可少；
  + 映射 $T$ 所满足的条件不能代之以条件：
  $ d(T x, T y) < d(x, y) quad quad (x != y) $
]

取 $X = (0, 1]$，$d(x, y) = abs(x - y)$。则 $X$ 不完备。定义 $T x = x / 2$。则 $T: X -> X$，且
$ d(T x, T y) = abs(x / 2 - y / 2) = frac(1, 2) d(x, y). $
所以 $T$ 是压缩映射。但方程 $x = x / 2$ 只有解 $x = 0$，而 $0 in.not X$。因此 $T$ 在 $X$ 上无不动点。这说明压缩映射原理中空间完备性条件不可少。

取 $X = [1, +infinity)$，$d(x, y) = abs(x - y)$。则 $X$ 是完备距离空间。定义 $T x = x + 1 / x$。显然 $T: X -> X$。对任意 $x != y$，由中值定理，
$ abs(T x - T y) = abs((x + 1 / x) - (y + 1 / y)) = abs(x - y) abs(1 - 1 / xi^2), $
其中 $xi$ 在 $x, y$ 之间。由于 $xi >= 1$，故 $abs(1 - 1 / xi^2) < 1$，所以
$ d(T x, T y) < d(x, y) quad (x != y), $
但是 $T x = x + 1 / x > x$，故不存在 $x in X$ 使 $T x = x$。因此 $T$ 无不动点。这说明仅仅满足 $d(T x, T y) < d(x, y)$ 不足以推出不动点存在。

== 习题一之 17

#tufted.problem[
  证明：存在闭区间 $[0,1]$ 上的连续函数 $x(t)$，使得
  $ x(t) = frac(1, 2) sin x(t) - a(t), $
  其中 $a(t)$ 是给定的 $[0,1]$ 上的连续函数。
]

首先，易证 $C[0, 1]$ 是完备距离空间。

定义映射
$
(T x)(t) = frac(1, 2) sin x(t) - a(t).
$
由于 $a$ 连续，若 $x$ 连续，则 $T x$ 连续，所以 $T: C[0, 1] -> C[0, 1]$。

对任意 $x, y in C[0, 1]$，有
$
|(T x)(t) - (T y)(t)| = frac(1, 2) |sin x(t) - sin y(t)| <= frac(1, 2) |x(t) - y(t)|.
$
因此 $d(T x, T y) <= frac(1, 2) d(x, y)$。故 $T$ 是压缩映射，压缩常数为 $1/2$。由压缩映射原理，存在唯一的 $x in C[0, 1]$，使得 $T x = x$，即
$
x(t) = frac(1, 2) sin x(t) - a(t)。
$
所以存在闭区间 $[0, 1]$ 上的连续函数 $x(t)$ 满足所给方程。

== 习题一之 18

#tufted.problem[
  设 $X$ 是完备距离空间，$T$ 是 $X$ 上到自身的映射，在闭球 $close(B) = {x in X : d(x_(0), x) <= r}$ 上，$d(T x, T y) <= theta d(x, y)$ 且 $d(x_(0), T x_(0)) < (1 - theta) r$，其中 $0 <= theta < 1$。证明 $T$ 在 $close(B)$ 上有唯一不动点。
]

设$overline(B) = {x in X: d(x_0, x) <= r}$。先证明 $T(overline(B)) subset overline(B)$。对任意 $x in overline(B)$，有
$
d(x_0, T x) <=& d(x_0, T x_0) + d(T x_0, T x) \
  <=& d(x_0, T x_0) + theta d(x_0, x) \
  <=& d(x_0, T x_0) + theta r \
  <& (1 - theta) r + theta r = r .
$
所以 $T x in overline(B)$。因此 $T: overline(B) -> overline(B)$。

又因为 $X$ 完备，$overline(B)$ 是 $X$ 的闭子集，所以 $overline(B)$ 也是完备距离空间。在 $overline(B)$ 上，$T$ 满足
$
d(T x, T y) <= theta d(x, y), quad 0 <= theta < 1.
$
故 $T$ 是 $overline(B)$ 上的压缩映射。由压缩映射原理，$T$ 在 $overline(B)$ 上有唯一不动点。

== 习题一之 19

#tufted.problem[
  设 $(t_(0), s_(0)) in bb(R)^2$，$f(t,s)$ 在 $(t_(0), s_(0))$ 的邻域 $N$ 中连续，$s_(0) = f(t_(0), s_(0))$，$f'_(s)(t,s)$ 在 $N$ 中存在且在 $(t_(0), s_(0))$ 连续并且 $f'_(s)(t_(0), s_(0)) = 0$。用压缩映射原理证明：存在 $delta > 0, x(t) in C[t_(0) - delta, t_(0) + delta]$，使得 $s_(0) = x(t_(0)), x(t) = f(t, x(t)), t in [t_(0) - delta, t_(0) + delta]$。
]

由题设，$f(t, s)$ 在 $(t_0, s_0)$ 的邻域 $N$ 中连续，且 $s_0 = f(t_0, s_0), quad f'_s(t_0, s_0) = 0$。由于 $f'_s(t, s)$ 在 $N$ 中存在且在 $(t_0, s_0)$ 连续，取足够小的  $delta_1 > 0, rho_1 > 0$，使得
$
Q = [t_0 - delta_1, t_0 + delta_1] times [s_0 - rho_1, s_0 + rho_1] subset N,
$
并且$|f'_s(t, s)| <= frac(1, 2), quad (t, s) in Q$。
于是对任意 $s_1, s_2 in [s_0 - rho_1, s_0 + rho_1]$，有
$
|f(t, s_1) - f(t, s_2)| <= frac(1, 2) |s_1 - s_2|.
$

又因为 $f(t, s_0)$ 连续且 $f(t_0, s_0) = s_0$，可取 $0 < delta <= delta_1$，使得当 $|t - t_0| <= delta$ 时，$|f(t, s_0) - s_0| <= frac(rho_1, 2)$。令 $I = [t_0 - delta, t_0 + delta], quad rho = rho_1$，考虑空间
$
M = {x in C(I): x(t_0) = s_0, |x(t) - s_0| <= rho, t in I},
$
则 $M$ 是 $C(I)$ 中的闭子集，从而是完备距离空间。

在 $M$ 上定义映射 $(T x)(t) = f(t, x(t))$。若 $x in M$，则 $(T x)(t_0) = f(t_0, x(t_0)) = f(t_0, s_0) = s_0$，并且对任意 $t in I$，
$
|(T x)(t) - s_0| =& |f(t, x(t)) - f(t_0, s_0)| \
  <=& |f(t, x(t)) - f(t, s_0)| + |f(t, s_0) - s_0| \
  <=& frac(1, 2) |x(t) - s_0| + frac(rho, 2) \
  <=& frac(1, 2) rho + frac(rho, 2) = rho。
$
所以 $T x in M$，即 $T: M -> M$。

对任意 $x, y in M$，有
$
|(T x)(t) - (T y)(t)| = |f(t, x(t)) - f(t, y(t))| <= frac(1, 2) |x(t) - y(t)|。
$
故 $d(T x, T y) <= frac(1, 2) d(x, y)$。因此 $T$ 是 $M$ 上的压缩映射。由压缩映射原理，存在唯一的 $x in M$，使得 $T x = x$，即
$
x(t) = f(t, x(t)), quad t in [t_0 - delta, t_0 + delta]，
$
且 $x(t_0) = s_0$。证毕。

#html.hr()

= 第五次作业：习题一之 8、21、22、23、24、25

== 习题一之 8

#tufted.problem[
  试举一例说明有界集不是全有界集。
]

设距离空间 $X = bb(N)$ 且定义离散距离。对任意 $m, n in X$，总有 $d(m, n) <= 1$，因此 $X$ 是有界集。但若取 $epsilon = 1/2$，总有 $B(n, epsilon) = {n}$。而 $X$ 是无限集，无法以有限个开球覆盖。故 $X$ 不是全有界集。

== 习题一之 21

#tufted.problem[
  设 $X={a,b}, tau = {X, emptyset, {b}}$，证明：
  + $tau$ 是 $X$ 上的一个拓扑；
  + ${a}$ 是闭集；
  + $close({b}) = X$。
]

=== (1) $tau$ 是 $X$ 上的一个拓扑

根据拓扑的定义，需要验证三个条件。 首先，显然有 $X in tau, quad emptyset in tau$；其次，由于 $tau$ 仅包含 $X,emptyset,{b}$，它们的任意并集仍属于 $tau$。最后，任意两个元素的交集也属于 $tau$，且 $ X inter {b}= {b },wide X inter emptyset = emptyset,wide {b }inter emptyset = emptyset . $

因此，$tau$ 对有限交封闭。 综上，$tau$ 满足拓扑的全部公理，故它是 $X$ 上的一个拓扑。

=== (2) ${a}$ 是闭集

由于 $X without {a}= {b }in tau$，即 ${a}$ 的补集是开集，因此 ${a}$ 是闭集。

=== (3) $close({b}) = X$

由闭包的定义，$x in close({b})$ 当且仅当 $x$ 的每个开邻域都与 ${b}$ 相交。 对于 $a$，其唯一的开邻域是 $X$，且 $X inter {b} = {b} != emptyset$。对于 $b$，其任意开邻域显然都包含 $b$。 因此，$a,b in close({b})$，从而 $close({b}) = X$。

== 习题一之 22

#tufted.theorem(label: <习题一之22>)[][
  设 $X$ 是任一集，$cal(B)$ 是 $X$ 的子集构成的集族，则 $cal(B)$ 是 $X$ 上某一拓扑基，当且仅当 $cal(B)$ 有以下性质：
  + 任一点 $x in X$，存在 $G in cal(B)$，使得 $x in G$；
  + 如果 $x in G_(1) inter G_(2)$，其中 $G_(1), G_(2) in cal(B)$，则存在 $G_(3) in cal(B)$，使得 $x in G_(3) subset G_(1) inter G_(2)$。
]

#tufted.problem[
  设 $X$ 是任一集，$cal(B)_(1), cal(B)_(2)$ 是 $X$ 的子集构成的集族，它们都满足 @习题一之22 中的条件，设 $tau_(1), tau_(2)$ 分别是由它们决定的 $X$ 上的拓扑。证明：$tau_(1) subset tau_(2)$，当且仅当对于每一 $G_(1) in cal(B)_(1)$ 及任一点 $x in G_(1)$，存在 $G_(2) in cal(B)_(2)$，使得 $x in G_(2) subset G_(1)$。
]

*必要性*：

假设 $tau_(1)subset tau_(2)$。 任取 $G_(1)in cal(B)_(1)$ 及 $x in G_(1)$。 由于 $cal(B)_(1)$ 是 $tau_(1)$ 的基，因此 $G_(1)in tau_(1) subset tau_(2)$。又因为 $cal(B)_(2)$ 是 $tau_(2)$ 的基，所以存在 $G_(2)in cal(B)_(2)$，使得 $ x in G_(2)subset G_(1). $

*充分性*：

假设对于任意 $G_(1)in cal(B)_(1)$ 及 $x in G_(1)$，都存在 $G_(2)in cal(B)_(2)$，满足 $x in G_(2) subset G_(1)$。任取 $U in tau_(1)$。 由于 $cal(B)_(1)$ 是 $tau_(1)$ 的基，对于任意 $x in U$，存在 $G_(1)in cal(B)_(1)$，使得 $x in G_(1) subset U$。根据假设，存在 $G_(2)in cal(B)_(2)$，使得
$
x in G_(2) subset G_(1) subset U .
$
因此，$U$ 中的每个点都有一个包含于 $U$ 的 $tau_(2)$ 基元素。 由拓扑基的定义，$U in tau_(2)$。 故 $tau_(1) subset tau_(2)$。

== 习题一之 23

#tufted.problem[
  试举以拓扑空间的例，它是 $T_(2)$ 的但不是 $T_(3)$ 的。
]

取 $ X = RR,wide K = { 1/n: n in NN^(+) } . $

令 $cal(B)$ 为所有通常开区间 $(a,b)$ 以及集合 $(a,b)without K$ 构成的集族。容易验证 $cal(B)$ 满足拓扑基条件，因此它生成一个拓扑 $tau$。现证明 $(X,tau)$ 是 $T_(2)$ 空间。由于 $tau$ 包含通常的欧氏拓扑，对任意不同的 $x,y in RR$，取 $epsilon = frac(abs(x-y), 3)$。则 $ U = (x - epsilon,x + epsilon), wide V = (y - epsilon,y + epsilon) $

都是 $tau$ 中的开集，并且 $ x in U,wide y in V,wide U inter V = emptyset . $

因此，$(X,tau)$ 是 $T_(2)$ 空间。 （2）证明 $(X,tau)$ 不是 $T_(3)$ 空间。 注意到 $RR without K$ 是 $tau$ 中的开集，因此 $K$ 是闭集，且 $0 in.not K$。 任取包含 $0$ 的开集 $U$ 和包含 $K$ 的开集 $V$。 由拓扑基的构造，存在 $epsilon > 0$，使得 $(- epsilon,epsilon) without K subset U$。

选取充分大的 $n$，使得 $1/n < epsilon$。因为 $1/n in K subset V$，且 $V$ 是开集，所以存在 $delta > 0$，使得 $(1/n- delta, 1/n + delta) subset V$。由于该区间中存在不属于 $K$ 且属于 $(-epsilon,epsilon)$ 的点，故 $U inter V != emptyset$。因此，无法用不相交的开集分离点 $0$ 与闭集 $K$，即该空间不是正则空间。 所以 $(X,tau)$ 是 $T_(2)$ 空间，但不是 $T_(3)$ 空间。

== 习题一之 24

#tufted.problem[
  设 $X$ 是 $T_(1)$ 拓扑空间，证明点 $x$ 是 $X$ 中集 $E$ 的极限点，当且仅当 $x$ 的任意邻域中包含 $E$ 中的无穷多点。如不假设 $X$ 是 $T_(1)$ 的，结论是否成立？
]

*必要性*：

设 $x$ 是 $E$ 的极限点。 反设存在 $x$ 的某个开邻域 $U$，使得 $U inter E$ 是有限集。 记
$
(U inter E)without {x } = {x_(1),x_(2),...,x_(n)}.
$
由于 $X$ 是 $T_(1)$ 空间，每个单点集 ${x_(i)}$ 都是闭集，所以 $V = U without {x_(1),...,x_(n)}$是包含 $x$ 的开邻域。 但 $V inter (E without {x })= emptyset$，这与 $x$ 是 $E$ 的极限点矛盾。 因此，$x$ 的任意邻域都包含 $E$ 中的无穷多点。

*充分性*：

假设 $x$ 的任意邻域都包含 $E$ 中的无穷多点。 则任意邻域 $U$ 中，必然存在 $y in E$，使得 $y != x$，即 $U inter (E without {x })!= emptyset$，根据极限点的定义，$x$ 是 $E$ 的极限点。 综上，$x in E ' <=> $ $x$ 的任意邻域含有 $E$ 中无穷多点。

*反例*：

取 $X = {a,b },wide tau = {emptyset,X,{b }}$。并令 $E = {b}$。 对于点 $a$，其唯一的开邻域是 $X$，且 $X inter (E without {a })= {b }!= emptyset$。因此，$a$ 是 $E$ 的极限点。 但是 $X inter E = {b}$ 仅包含一个点，而不是无穷多点。 所以不假设 $T_(1)$ 时，该结论不一定成立。

== 习题一之 25

#tufted.problem[
  设拓扑空间 $(X, tau)$ 满足第二可数公理，证明从 $X$ 的任意开覆盖中可选出由最多可数个集构成的子覆盖。
]

由于 $X$ 满足第二可数公理，存在一个可数拓扑基 $cal(B) = {B_(1),B_(2),... }$。任取 $X$ 的一个开覆盖
$
cal(U) = {U_(alpha): alpha in A }, wide X = union.big_(alpha in A)U_(alpha).
$
对每个能够包含于某个 $U_(alpha)$ 的基元素 $B_(n)$，选取一个这样的 $U_(alpha_(n))$，使得 $B_(n) subset U_(alpha_(n))$。由于基元素至多可数，所选取的开集族 $cal(U) '= {U_(alpha_(n))}$ 也是至多可数的。

下面证明 $cal(U) '$ 覆盖 $X$。 任取 $x in X$。 因为 $cal(U)$ 是 $X$ 的开覆盖，存在 $U_(alpha) in cal(U)$，使得 $x in U_(alpha)$。又因为 $cal(B)$ 是拓扑基，存在 $B_(n)in cal(B)$，满足 $x in B_(n)subset U_(alpha)$。根据前面的选取规则，存在 $U_(alpha_(n))in cal(U) '$，使得
$
x in B_(n) subset U_(alpha_(n)).
$
因此，每个 $x in X$ 都属于 $cal(U) '$ 的某个元素，从而 $X = union.big_(U in cal(U) ')U$。故 $cal(U) '$ 是原开覆盖的一个至多可数的子覆盖。

#html.hr()

= 第六次作业：习题二之 1、2、5、6、8、9

#let iff = $" 当且仅当 "$

== 习题二之 1

#tufted.problem[
  设 $(X, norm(dot))$ 是赋范空间，对于 $x,y in X$ 令
  $
    d_(1) = cases(
      0 ", " & x = y,
      norm(x - y) + 1 ", " & x != y
    )
  $
  证明 $d_(1)$ 是 $X$ 上的距离但不是由范数诱导的距离。
]

首先证明 $d_1$ 是距离。
+ *正定性*：显然 $d_1(x,y) >= 0$，且$d_1(x,y) = 0 iff x = y$。
+ *对称性*：由范数的性质，$d_1(x,y) = d_1(y,x)$。
+ *三角不等式*：任取 $x,y,z in X$。若 $x = z$，则不等式显然成立；若 $x = y$ 或 $y = z$，则等号成立。

当 $x,y,z$ 两两不同时，由范数的三角不等式，
$
  d_1(x,z)
  &= norm(x-z) + 1 \
  &<= norm(x-y) + norm(y-z) + 1 \
  &<= d_1(x,y) + d_1(y,z).
$
因此 $d_1$ 是 $X$ 上的距离。

下面证明 $d_1$ 不是由范数诱导的距离。设 $X != {0}$，反设存在范数 $norm(dot)_(*)$，使得$d_1(x,y) = norm(x-y)_(*)$。任取 $x != 0$，由范数的齐次性，$norm(2x)_(*) = 2 norm(x)_(*)$。但由 $d_1$ 的定义，
$
  norm(x)_(*) = norm(x) + 1,
  quad norm(2x)_(*) = 2 norm(x) + 1.
$
从而 $2 norm(x) + 1 = 2 norm(x) + 2$，矛盾。故 $d_1$ 不是由范数诱导的距离。

== 习题二之 2

#tufted.problem[
  在 $l^(infinity)$ 中，按坐标定义线性运算且对 $x in l^(infinity), x = {xi_(k)}$ 定义
  $
    norm(x) = sup_(n) abs(xi_(n)),
  $
  证明 $l^(infinity)$ 是一个赋范空间。
]

首先证明 $l^(infinity)$ 是线性空间。任取 $x = (xi_n), y = (eta_n) in l^(infinity)$ 及标量 $alpha, beta$，由
$
  sup_n abs(alpha xi_n + beta eta_n)
  <= abs(alpha) sup_n abs(xi_n) + abs(beta) sup_n abs(eta_n)
  < infinity,
$
可知 $alpha x + beta y in l^(infinity)$，故 $l^(infinity)$ 是线性空间。

下面验证范数的三个条件。

+ *正定性*：显然 $norm(x) >= 0$，且
$
  norm(x) = 0
  iff sup_n abs(xi_n) = 0
  iff xi_n = 0, quad forall n
  iff x = 0.
$
+ *齐次性*：对任意标量 $alpha$，
$
  norm(alpha x)
  &= sup_n abs(alpha xi_n) \
  &= abs(alpha) sup_n abs(xi_n) \
  &= abs(alpha) norm(x).
$
+ *三角不等式*：对任意 $x,y in l^(infinity)$，
$
  norm(x+y)
  &= sup_n abs(xi_n + eta_n) \
  &<= sup_n (abs(xi_n) + abs(eta_n)) \
  &<= sup_n abs(xi_n) + sup_n abs(eta_n) \
  &= norm(x) + norm(y).
$

综上，$(l^(infinity), norm(dot))$ 是赋范空间。

== 习题二之 5

#tufted.problem[
  设 $(X, norm(dot))$ 是赋范空间，$X_(0)$ 是 $X$ 中的稠密子集，证明：对于每一 $x in X$ 存在 ${x_(n)} subset X_(0)$，使得 $x = sum_(n=1)^infinity x_(n)$ 且 $sum_(n=1)^infinity norm(x_(n)) < infinity$。
]

任取 $x in X$。由于 $X_0$ 在 $X$ 中稠密，可递归选取 $x_n in X_0$，使得
$
  norm(x - sum_(k=1)^n x_k) < 2^(-n).
$

具体地，先取 $x_1 in X_0$，满足 $norm(x-x_1) < 1/2$。假设已取 $x_1, dots, x_(n-1)$，记
$
  r_(n-1) = x - sum_(k=1)^(n-1) x_k.
$
由 $X_0$ 的稠密性，可取 $x_n in X_0$，使得$norm(r_(n-1)-x_n) < 2^(-n)$。令 $r_n = x - sum_(k=1)^n x_k$，则 $norm(r_n) < 2^(-n)$，故
$
  norm(x - sum_(k=1)^n x_k) -> 0.
$
因此
$
  x = sum_(n=1)^infinity x_n.
$

下面证明级数绝对收敛。对 $n >= 2$，由三角不等式，
$
  norm(x_n)
  &= norm(r_(n-1)-r_n) \
  &<= norm(r_(n-1)) + norm(r_n) \
  &< 2^(-(n-1)) + 2^(-n).
$
因而
$
  sum_(n=1)^infinity norm(x_n)
  &<= norm(x_1) + sum_(n=2)^infinity (2^(-(n-1)) + 2^(-n)) \
  &< infinity.
$

综上，存在 ${x_n} subset X_0$，使得
$
  x = sum_(n=1)^infinity x_n,
  quad sum_(n=1)^infinity norm(x_n) < infinity.
$


== 习题二之 6

#tufted.problem[
  设 $(X, norm(dot))$ 是赋范空间，$X != {0}$，证明：$X$ 是 Banach 空间，当且仅当 $X$ 中的单位球面 $S = {x in X: norm(x) = 1}$ 是完备的。
]

（1）*必要性*：设 $X$ 是 Banach 空间。由于范数连续，单位球面 $S = {x in X: norm(x) = 1}$ 是 $X$ 中的闭集。完备距离空间的闭子集仍完备，故 $S$ 完备。

（2）*充分性*：设 $S$ 完备。任取 $X$ 中的 Cauchy 列 ${x_n}$。

由反三角不等式，$abs(norm(x_n)-norm(x_m)) <= norm(x_n-x_m)$，可知 ${norm(x_n)}$ 是实数域上的 Cauchy 列。由实数的完备性，存在 $a >= 0$，使得 $norm(x_n) -> a$。若 $a = 0$，则 $norm(x_n-0) = norm(x_n) -> 0$，故 $x_n -> 0$。

若 $a > 0$，则当 $n$ 充分大时 $norm(x_n) > 0$。令 $y_n = x_n / norm(x_n) in S$。对充分大的 $n,m$，有
$
  norm(y_n-y_m)
  &= norm(x_n / norm(x_n) - x_m / norm(x_m)) \
  &<= norm(x_n-x_m) / norm(x_n) \
  &quad + norm(x_m) abs(1/norm(x_n) - 1/norm(x_m)).
$
由于 ${x_n}$ 是 Cauchy 列，且 $norm(x_n) -> a > 0$，故
$
  norm(y_n-y_m) -> 0 quad (n,m -> infinity).
$
因此 ${y_n}$ 是 $S$ 中的 Cauchy 列。

由 $S$ 完备，存在 $y in S$，使得 $y_n -> y$。又因为 $x_n = norm(x_n) y_n$，所以 $x_n -> a y in X$。因此 $X$ 中任意 Cauchy 列均收敛，即 $X$ 完备。

综上，
$
  X " 是 Banach 空间 " iff S " 完备".
$


== 习题二之 8

#tufted.problem[
  设 $(X_(n), norm(dot)_(n))$ 是一列赋范空间，$x  = {x_(n)}, x_(n) in X_(n) (n = 1,2,...)$ 且满足条件 $sum_(k=1)^infinity norm(x_(k))^(p) < infinity$，用 $X$ 表示所有 $x$ 的全体，按坐标定义线性运算构成的线性空间，在 $X$ 中定义
  $
    norm(x) = (sum_(n=1)^infinity norm(x_(n))^(p))^(1/p) quad (p >= 1),
  $
  证明 $(X, norm(dot))$ 是一个赋范空间。
]

首先证明 $X$ 是线性空间。

任取 $x=(x_n), y=(y_n) in X$ 及标量 $alpha,beta$。由范数的三角不等式及
$
  (a+b)^p <= 2^(p-1)(a^p+b^p), quad a,b >= 0,
$
得
$
  norm(alpha x_n+beta y_n)_n^p
  &<= (abs(alpha) norm(x_n)_n + abs(beta) norm(y_n)_n)^p \
  &<= 2^(p-1)(abs(alpha)^p norm(x_n)_n^p
    + abs(beta)^p norm(y_n)_n^p).
$
两边对 $n$ 求和，由 $x,y in X$ 可知
$
  sum_(n=1)^infinity norm(alpha x_n+beta y_n)_n^p < infinity.
$
因此 $alpha x+beta y in X$，故 $X$ 是线性空间。

下面验证范数的三个条件。

+ *正定性*：显然 $norm(x) >= 0$，且
$
  norm(x) = 0
  &iff sum_(n=1)^infinity norm(x_n)_n^p = 0 \
  &iff norm(x_n)_n = 0, quad forall n \
  &iff x_n = 0, quad forall n \
  &iff x = 0.
$
+ *齐次性*：对任意标量 $alpha$，
$
  norm(alpha x)
  &= (sum_(n=1)^infinity norm(alpha x_n)_n^p)^(1/p) \
  &= (abs(alpha)^p sum_(n=1)^infinity norm(x_n)_n^p)^(1/p) \
  &= abs(alpha) norm(x).
$
+ *三角不等式*：由各 $X_n$ 中的三角不等式及 Minkowski 不等式，
$
  norm(x+y)
  &= (sum_(n=1)^infinity norm(x_n+y_n)_n^p)^(1/p) \
  &<= (sum_(n=1)^infinity (norm(x_n)_n+norm(y_n)_n)^p)^(1/p) \
  &<= (sum_(n=1)^infinity norm(x_n)_n^p)^(1/p)
    + (sum_(n=1)^infinity norm(y_n)_n^p)^(1/p) \
  &= norm(x)+norm(y).
$

综上，$(X,norm(dot))$ 是赋范空间。

== 习题二之 9

#tufted.problem[
  证明：
  + 离散情形的 Hölder 不等式与 Minkowski 不等式;
  + $l^(p) (p >= 1)$ 是可分的 Banach 空间。
]

=== (1) 离散 Hölder 不等式

设 $1 < p,q < infinity$，且 $1/p + 1/q = 1$。对任意 $(a_n) in l^p$、$(b_n) in l^q$，证明
$
  sum_(n=1)^infinity abs(a_n b_n)
  <= (sum_(n=1)^infinity abs(a_n)^p)^(1/p)
     (sum_(n=1)^infinity abs(b_n)^q)^(1/q).
$

记
$
  A = (sum_(n=1)^infinity abs(a_n)^p)^(1/p),
  quad
  B = (sum_(n=1)^infinity abs(b_n)^q)^(1/q).
$
若 $A=0$ 或 $B=0$，结论显然成立。

当 $A,B > 0$ 时，令
$
  u_n = abs(a_n)/A,
  quad
  v_n = abs(b_n)/B.
$
由 Young 不等式，
$
  u_n v_n <= u_n^p/p + v_n^q/q.
$
两边求和，得到
$
  sum_(n=1)^infinity u_n v_n
  &<= 1/p sum_(n=1)^infinity u_n^p
     + 1/q sum_(n=1)^infinity v_n^q \
  &= 1/p + 1/q = 1.
$
因此 $sum_(n=1)^infinity abs(a_n b_n) <= A B$。

当 $p=1,q=infinity$ 时，由
$
  sum_(n=1)^infinity abs(a_n b_n)
  <= sup_n abs(b_n) sum_(n=1)^infinity abs(a_n)
$
可知端点情形同样成立。

=== (2) 离散 Minkowski 不等式

对 $p >= 1$，证明
$
  (sum_(n=1)^infinity abs(a_n+b_n)^p)^(1/p)
  <= (sum_(n=1)^infinity abs(a_n)^p)^(1/p)
   + (sum_(n=1)^infinity abs(b_n)^p)^(1/p).
$

当 $p=1$ 时，由三角不等式直接成立。

当 $p>1$ 时，令 $q=p/(p-1)$。先对有限项证明。由三角不等式，
$
  sum_(n=1)^N abs(a_n+b_n)^p
  &<= sum_(n=1)^N (abs(a_n)+abs(b_n)) abs(a_n+b_n)^(p-1) \
  &= sum_(n=1)^N abs(a_n) abs(a_n+b_n)^(p-1) \
  &quad + sum_(n=1)^N abs(b_n) abs(a_n+b_n)^(p-1).
$

对右端两项分别应用 Hölder 不等式，并利用 $(p-1)q=p$，得到
$
  sum_(n=1)^N abs(a_n+b_n)^p
  &<= ((sum_(n=1)^N abs(a_n)^p)^(1/p)
     + (sum_(n=1)^N abs(b_n)^p)^(1/p)) \
  &quad dot (sum_(n=1)^N abs(a_n+b_n)^p)^((p-1)/p).
$

若左端为零，结论显然；否则两边除以最后一个因子，得
$
  (sum_(n=1)^N abs(a_n+b_n)^p)^(1/p)
  <= (sum_(n=1)^N abs(a_n)^p)^(1/p)
   + (sum_(n=1)^N abs(b_n)^p)^(1/p).
$
令 $N -> infinity$，即得 Minkowski 不等式。


=== (3) $l^p$ 是 Banach 空间

设 ${x^(m)}$ 是 $l^p$ 中的 Cauchy 列，其中 $x^(m) = (xi_1^(m), xi_2^(m), dots)$。由于
$
  abs(xi_n^(m)-xi_n^(k))
  <= norm(x^(m)-x^(k))_p,
$
故对任意固定的 $n$，${xi_n^(m)}_m$ 是标量域中的 Cauchy 列。

由标量域的完备性，存在 $xi_n$，使得 $xi_n^(m) -> xi_n quad (m -> infinity)$。记 $x=(xi_1,xi_2,dots)$。

因为 ${x^(m)}$ 是 Cauchy 列，所以对任意 $epsilon>0$，存在 $M$，使得当 $m,k >= M$ 时，$norm(x^(m)-x^(k))_p < epsilon$。因而对任意正整数 $N$，
$
  sum_(n=1)^N abs(xi_n^(m)-xi_n^(k))^p < epsilon^p.
$

固定 $m >= M$，令 $k -> infinity$，得 $sum_(n=1)^N abs(xi_n^(m)-xi_n)^p <= epsilon^p$。再令 $N -> infinity$，得到
$
  sum_(n=1)^infinity abs(xi_n^(m)-xi_n)^p <= epsilon^p.
$

因此 $x-x^(m) in l^p$。又因为 $x^(m) in l^p$，故 $x in l^p$，并且 $norm(x^(m)-x)_p <= epsilon quad (m >= M)$。

于是 $x^(m) -> x$，即 $l^p$ 中任意 Cauchy 列均收敛，所以 $l^p$ 是 Banach 空间。

=== (4) $l^p$ 是可分空间

先考虑实数域上的 $l^p$。令 $D = {x=(r_n): r_n in QQ, "且仅有有限个非零项"}$。由于 $D$ 是有限维有理数序列集合的可数并，故 $D$ 可数。

下面证明 $D$ 在 $l^p$ 中稠密。任取 $x=(xi_n) in l^p$ 及 $epsilon>0$。由于 $sum_(n=1)^infinity abs(xi_n)^p < infinity$，存在正整数 $N$，使得
$
  sum_(n=N+1)^infinity abs(xi_n)^p < epsilon^p/2.
$

由于 $QQ$ 在 $RR$ 中稠密，对 $1 <= n <= N$，可取 $r_n in QQ$，使得
$
  abs(xi_n-r_n) < frac(epsilon, (2N)^(1/p)).
$

令 $y=(r_1,dots,r_N,0,0,dots) in D$。则
$
  norm(x-y)_p^p
  &= sum_(n=1)^N abs(xi_n-r_n)^p
     + sum_(n=N+1)^infinity abs(xi_n)^p \
  &< N dot epsilon^p/(2N) + epsilon^p/2 \
  &= epsilon^p.
$
因而 $norm(x-y)_p < epsilon$。

故 $D$ 是 $l^p$ 中的可数稠密子集，$l^p$ 可分。对复数域上的 $l^p$，只需将 $QQ$ 换成 $QQ+i QQ$，证明相同。

综上，$l^p$（$1 <= p < infinity$）是可分的 Banach 空间。

#html.hr()

= 第七次作业：习题二之 3、12、13、14、17、18

== 习题二之 3

#tufted.problem[
  设 $M$ 是空间 $l^(infinity)$ 中除又穷个坐标之外为 $0$ 的元之全体构成的子空间，证明 $M$ 不是闭子空间。
]

考虑 $l^(infinity)$ 中的元素 $x = (1, 1/2, 1/3, dots, 1/n, dots)$，显然 $x in l^(infinity)$，但 $x$ 有无穷多个非零坐标，因此 $x in.not M$。

对每个正整数 $n$，令 $x^(n) = (1, 1/2, dots, 1/n, 0, 0, dots)$。由于 $x^(n)$ 仅有有限个非零坐标，故 $x^(n) in M$。

又因为
$
  norm(x^(n)-x)_infinity
  = sup_(k>n) 1/k
  = 1/(n+1) -> 0,
$
所以 $x^(n) -> x$。因此 $M$ 中存在收敛序列，其极限不属于 $M$，故 $M$ 不是闭子空间。

== 习题二之 12

#tufted.problem[
  设 $E$ 是直线上的 Lebesgue 可测集，且 $m(E) < infinity$，用 $norm(dot)_(p)$ 表示 $L^(p)(E) (p >= 1)$ 中的范数，$norm(dot)_(infinity)$ 表示 $L^(infinity)(E)$ 的范数。证明： 对于每一 $x in L^(infinity)(E)$，
  $
    lim_(p -> infinity) norm(x)_(p) = norm(x)_(infinity).
  $
]

设 $x in L^(infinity)(E)$，记
$
  M = norm(x)_infinity
  = limits(op("ess sup"))_(t in E) abs(x(t)).
$
由于 $m(E)<infinity$，对任意 $p>=1$，有
$
  norm(x)_p^p
  = integral_E abs(x(t))^p dif t
  <= M^p m(E).
$
因此 $norm(x)_p <= M m(E)^(1/p)$。令 $p -> infinity$，得
$
  limsup_(p->infinity) norm(x)_p <= M.
$

另一方面，若 $M=0$，则 $x=0$ 几乎处处成立，结论显然。

若 $M>0$，任取 $epsilon in (0,M)$，由本性上确界的定义，集合 $E_epsilon = {t in E: abs(x(t)) > M-epsilon}$ 满足 $m(E_epsilon)>0$。

于是
$
  norm(x)_p^p
  &= integral_E abs(x(t))^p dif t \
  &>= integral_(E_epsilon) abs(x(t))^p dif t \
  &>= (M-epsilon)^p m(E_epsilon).
$
因此 $norm(x)_p >= (M-epsilon) m(E_epsilon)^(1/p)$。令 $p -> infinity$，由于 $0<m(E_epsilon)<infinity$，得到 $liminf_(p->infinity) norm(x)_p >= M-epsilon$。由 $epsilon$ 的任意性，$liminf_(p->infinity) norm(x)_p >= M$。

结合上下极限，得到
$
  lim_(p->infinity) norm(x)_p
  = M = norm(x)_infinity.
$

== 习题二之 13

#tufted.problem[
  设 $(X_(1), norm(dot)_(1)), (X_(2), norm(dot)_(2))$ 是赋范空间，在乘积线性空间 $X_(1) times X_(2)$ 中定义
  $
    norm(z)_(1) = norm(x_(1))_(1) + norm(x_(2))_(2); quad norm(z)_(2) = max(norm(x_(1))_(1), norm(x_(2))_(2)),
  $
  其中 $z in X_(1) times X_(2), z=(x_(1), x_(2))$。证明：$norm(z)_(1), norm(z)_(2)$ 是 $X_(1) times X_(2)$ 上的等价范数。
]

任取 $z=(x_1,x_2) in X_1 times X_2$，记 $A = norm(x_1)_1, B = norm(x_2)_2$。则
$
  norm(z)_1 = A+B, quad norm(z)_2 = max(A,B).
$

首先验证二者均为范数。首先非负性与正定性显然。然后，对任意标量 $alpha$，由各分量范数的齐次性，
$
  norm(alpha z)_1
  &= abs(alpha) A + abs(alpha) B \
  &= abs(alpha) norm(z)_1,
$
$
  norm(alpha z)_2
  &= max(abs(alpha) A, abs(alpha) B) \
  &= abs(alpha) norm(z)_2.
$

再任取 $w=(y_1,y_2)$，由分量范数的三角不等式，
$
  norm(z+w)_1
  &= norm(x_1+y_1)_1+norm(x_2+y_2)_2 \
  &<= norm(x_1)_1+norm(y_1)_1
  +norm(x_2)_2+norm(y_2)_2 \
  &= norm(z)_1+norm(w)_1.
$
同时，
$
  norm(z+w)_2
  &<= max(norm(x_1)_1+norm(y_1)_1,
           norm(x_2)_2+norm(y_2)_2) \
  &<= max(norm(x_1)_1,norm(x_2)_2)
     +max(norm(y_1)_1,norm(y_2)_2) \
  &= norm(z)_2+norm(w)_2.
$
故二者都是范数。

下面证明等价性。由于 $A,B>=0$，
$
  max(A,B) <= A+B <= 2 max(A,B).
$
即 $norm(z)_2 <= norm(z)_1 <= 2 norm(z)_2$。因此存在常数 $c=1$、$C=2$，使得
$
  c norm(z)_2 <= norm(z)_1 <= C norm(z)_2.
$
故 $norm(dot)_1$ 与 $norm(dot)_2$ 是等价范数。

== 习题二之 14

#tufted.problem[
  设 $X$ 是区间 $[a,b]$ 上所有连续函数全体按通常方式定义线性运算所成的线性空间，对于 $x in X$ 定义
  $
    norm(x) = sup_(a <= t <= b) abs(x(t)); quad norm(x)_(1) = integral_a^b abs(x(t)) d t.
  $
  证明：$norm(dot), norm(dot)_(1)$ 是 $X$ 上两个不等价的范数。
]

首先证明两个函数都是 $X=C[a,b]$ 上的范数。对于一致范数 $norm(x)=sup_(a<=t<=b) abs(x(t))$，其正定性、齐次性及三角不等式均由绝对值的相应性质直接得到。

对于积分范数 $norm(x)_1 = integral_a^b abs(x(t)) dif t$，显然 $norm(x)_1>=0$。

若 $norm(x)_1=0$，由于 $abs(x(t))$ 连续且非负，必有 $x(t)=0$ 对所有 $t in [a,b]$ 成立，否则由连续性可找到一个正长度的区间，使其积分严格大于零。因此 $norm(x)_1=0 iff x=0$。

此外，对任意标量 $alpha$，
$
  norm(alpha x)_1
  &= integral_a^b abs(alpha x(t)) dif t \
  &= abs(alpha) norm(x)_1.
$
对任意 $x,y in X$，
$
  norm(x+y)_1
  &= integral_a^b abs(x(t)+y(t)) dif t \
  &<= integral_a^b (abs(x(t))+abs(y(t))) dif t \
  &= norm(x)_1+norm(y)_1.
$
故 $norm(dot)_1$ 也是范数。

下面证明二者不等价。

由 $abs(x(t)) <= norm(x)$，可得 $norm(x)_1 <= (b-a) norm(x)$。若两个范数等价，则还存在常数 $c>0$，使得对所有 $x in X$，$norm(x)_1 >= c norm(x)$。

构造函数列
$
  x_n(t) = (1-(t-a)/(b-a))^n.
$
显然 $x_n in C[a,b]$，且 $norm(x_n)=1$。另一方面，
$
  norm(x_n)_1
  &= integral_a^b (1-(t-a)/(b-a))^n dif t \
  &= (b-a)/(n+1) -> 0.
$

于是
$
  norm(x_n)_1/norm(x_n) -> 0,
$
与存在统一的常数 $c>0$ 矛盾。

因此两个范数不等价。

== 习题二之 17

#tufted.problem[
  设 $(X, norm(dot))$ 是赋范空间，如果对任意 $x,y in X, x != y$ 且 $norm(x) = norm(y) = 1$ 必有 $norm(x+y) < 2$，称 $(X, norm(dot))$ 是*严格凸赋范空间*。
  + 证明赋范空间 $(X, norm(dot))$ 是严格凸的，当且仅当对任意 $x,y in X, norm(x+y) = norm(x) + norm(y)$ 必有 $x = alpha y (alpha > 0)$。
  + 证明在严格凸赋范空间中，对于每一个 $x in X$，$x$ 关于任意子空间 $Y$ 的最佳逼近是唯一的。
]

=== (1) 严格凸的等价条件

先证明必要性。设 $X$ 严格凸，任取非零向量 $x,y$，且 $norm(x+y)=norm(x)+norm(y)$。

令
$
  u=x/norm(x),
  quad v=y/norm(y),
$
则 $norm(u)=norm(v)=1$。

再令
$
  lambda=norm(x)/(norm(x)+norm(y)),
$
显然 $0<lambda<1$，并且
$
  norm(lambda u+(1-lambda)v)
  &= norm((x+y)/(norm(x)+norm(y))) \
  &= 1.
$

若 $u!=v$，由严格凸性及三角不等式的等号条件可知，单位球面上两个不同点的非平凡凸组合范数严格小于 $1$，与上式矛盾。

故 $u=v$，即
$
  x/norm(x)=y/norm(y).
$
因此
$
  x=norm(x)/norm(y) y=alpha y,
  quad alpha>0.
$

再证明充分性。设上述等号条件成立。

任取 $x,y in X$，满足 $norm(x)=norm(y)=1, x!=y$。由三角不等式，$norm(x+y)<=2$。若 $norm(x+y)=2$，根据假设，存在 $alpha>0$，使得 $x=alpha y$。由 $norm(x)=norm(y)=1$，可得 $alpha=1$，即 $x=y$，矛盾。

因此 $norm(x+y)<2$。故 $X$ 严格凸。

综上，两个条件等价。

=== (2) 最佳逼近的唯一性

设 $X$ 是严格凸赋范空间，$Y$ 是 $X$ 的任意线性子空间。

任取 $x in X$，假设 $y_1,y_2 in Y$ 均为 $x$ 的最佳逼近，即
$
  norm(x-y_1)=norm(x-y_2)=d,
$
其中 $d=inf_(y in Y) norm(x-y)$。

若 $d=0$，则 $x=y_1=y_2$，唯一性显然成立。

若 $d>0$，反设 $y_1!=y_2$，令
$
  u=(x-y_1)/d,
  quad v=(x-y_2)/d.
$
则 $norm(u)=norm(v)=1, u!=v$。由严格凸性，$norm((u+v)/2)<1$。

又因为 $Y$ 是线性子空间，$(y_1+y_2)/2 in Y$。于是
$
  norm(x-(y_1+y_2)/2)
  &= norm(((x-y_1)+(x-y_2))/2) \
  &= d norm((u+v)/2) \
  &< d.
$

这与 $d$ 是 $x$ 到 $Y$ 的最小距离矛盾。因此 $y_1=y_2$。

故在严格凸赋范空间中，任意子空间上的最佳逼近若存在，则必唯一。

== 习题二之 18

#tufted.problem[
  设 $(X, norm(dot))$ 是赋范空间。如果对任意 $epsilon > 0$，存在 $delta > 0$，当 $norm(x-y) >= epsilon$，$norm(x) = norm(y) = 1$ 时必有 $norm(x+y) <= 2 - delta$，称 $(X, norm(dot))$ 是*一致凸的*。证明：
  + $C[a,b]$ 不是一致凸的。
  + $L^(1)[a,b]$ 不是一致凸的。
  + 一致凸赋范空间必是严格凸的。
]

=== (1) $C[a,b]$ 不是一致凸的

设 $a<b$，考虑 $C[a,b]$ 上的一致范数
$
  norm(x)_infinity = max_(t in [a,b]) abs(x(t)).
$

构造两个函数
$
  x(t)=1,
  quad
  y(t)=1-2(t-a)/(b-a).
$
显然 $x,y in C[a,b]$，且 $norm(x)_infinity=norm(y)_infinity=1$。

由于 $y(b)=-1$，有 $norm(x-y)_infinity=2$。但在 $t=a$ 处，$x(a)+y(a)=2$，因此 $norm(x+y)_infinity=2$。

取 $epsilon=1$，则对于任意 $delta>0$，上述 $x,y$ 均满足 $norm(x-y)_infinity>=epsilon$，但 $norm(x+y)_infinity=2>2-delta$。

故 $C[a,b]$ 不是一致凸空间。


=== (2) $L^1[a,b]$ 不是一致凸的

设 $a<b$，取两个不相交且具有正测度的可测子集
$
  A=[a,(a+b)/2],
  quad B=((a+b)/2,b].
$

定义
$
  f(t)=1/m(A) bb(1)_A(t),
  quad
  g(t)=1/m(B) bb(1)_B(t),
$
其中 $bb(1)_A, bb(1)_B$ 为示性函数。

由于 $A inter B=emptyset$，且 $m(A),m(B)>0$，
$
  norm(f)_1=integral_a^b abs(f(t)) d t=1,
  quad
  norm(g)_1=integral_a^b abs(g(t)) d t=1.
$

又由于 $f,g$ 的支集不相交，
$
  norm(f-g)_1
  &= integral_a^b abs(f(t)-g(t)) dif t \
  &= norm(f)_1+norm(g)_1=2.
$
同时，
$
  norm(f+g)_1
  &= integral_a^b abs(f(t)+g(t)) dif t \
  &= norm(f)_1+norm(g)_1=2.
$

取 $epsilon=1$，则对任意 $delta>0$，都有
$
  norm(f-g)_1>=epsilon,
  quad norm(f+g)_1=2>2-delta.
$
这与一致凸性的定义矛盾。

因此 $L^1[a,b]$ 不是一致凸空间。


=== (3) 一致凸空间必严格凸

设 $X$ 是一致凸赋范空间。

任取 $x,y in X$，满足
$
  norm(x)=norm(y)=1,
  quad x!=y.
$
由于 $x!=y$，有 $epsilon=norm(x-y)>0$。

由一致凸性，存在 $delta>0$，使得 $norm(x+y)<=2-delta<2$。

因此对于任意两个不同的单位向量，都有 $norm(x+y)<2$。

故 $X$ 是严格凸赋范空间。
