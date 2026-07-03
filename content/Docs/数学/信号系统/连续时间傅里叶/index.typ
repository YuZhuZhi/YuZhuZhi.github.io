#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#let dt = $d t$
#let Ev = $"Ev"$
#let Od = $"Od"$
#let leftrightarrow(body) = $limits(stretch(arrow.l.r)^#body)$
#show: template.with(
    title: "信号系统（三）——连续时间傅里叶",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$
#let tj = $"j"$

#let st = $s t$
#let dt = $d t$
#let kx = $k x$
#let kt = $k t$
#let nx = $n x$
#let nt = $n t$

= 信号系统（三）——连续时间傅里叶

将函数分解为*基本函数*的加权和，是研究函数十分重要的方法之一。比如上一篇中我们将函数分解为了*单位冲激函数*的加权和(对于离散时间信号是这样，连续信号则是卷积积分)，就是将单位冲激函数作为了基本函数。再例如，如果将幂函数作为基本函数，那就是*泰勒展开*；而以三角函数作为基本函数，那就是本篇的重点——*傅里叶展开*了。

#tufted.remark[][
    或者，由于三角函数可以进一步分解为复指数函数，傅里叶展开也可以认为是以复指数函数作为基本函数。以下，对复指数信号的分析，也可视作对三角函数的分析。
]

= 一、复指数信号的特殊性

为什么复指数函数可以作为基本函数呢？这主要是因为复指数信号在经过线性时不变系统输出后，*只会产生幅值上的变化*。也就是说，假设复指数信号 $te^(st)$ ，其中 $s$ 是任意复数，那么：

$
te^(st) -> H(s)te^(st)
$

幅值会产生 $H(s)$ 倍的变化，而且这个幅值还由 $s$ 唯一确定！我们将这种经过系统作用之后的输出只是输入的常数倍的信号称为*特征函数*，而这个常数称为*特征值*。

#tufted.proof[
为了证明以上结论，首先假设系统的单位冲激响应为 $h(t)$ ，。那么系统对 $x(t)$ 的响应就是：
$
    y(t)&=x(t)*h(t)\
    &=  integral_(- infinity)^(+ infinity)x( tau)h(t- tau)d tau\
    &= integral_(- infinity)^(+ infinity)x(t- tau)h( tau)d tau\
    &= integral_(- infinity)^(+ infinity)te^(s(t- tau))h( tau)d tau\
    &=te^(st) integral_(- infinity)^(+ infinity)te^(-s tau)h( tau)d tau\
$
记 $H(s)=  integral_(- infinity)^(+ infinity)te^(-s tau)h( tau)d tau$ ，假定这个积分收敛，那么上述结论得证。并且结论对离散时间信号亦成立。
]

因此，若信号可以被分解为*复指数信号*的加权和：
$
    x(t)&=a_0te^(s_0t)+a_1te^(s_1t)+a_2te^(s_2t)+ dots\
    &=  sum a_i te^(s_i t)
$

显然输出可以直接确定为：

$
    y(t)&=H(s_0)a_0te^(s_0t)+H(s_1)a_1te^(s_1t)+H(s_2)a_2te^(s_2t)+ dots\
    &=  sum H(s_i)a_i te^(s_i t)
$

这就为研究系统带来了极大的便利，正如上篇文章中那般，只要确定单位冲激响应就能完全确定线性时不变系统对任意信号的响应，现在只要确定 $H(s)$ 也能完全确定线性时不变系统对*某些*信号的响应。

#html.hr()

= 二、傅里叶级数的计算

在看到将函数分解为复指数函数带来便利之后，我们的下一个问题是：如何将一个函数分解为复指数函数的加权和？首先需要注意到复指数函数是周期信号，因此“只有”*周期函数*可以被展开。以下内容都事先默认假定要展开的函数是周期函数。

== 1.以三角函数作为基底

在高等数学中我们学习过傅里叶级数、三角展开，就是将一个函数变换为另一些函数的线性组合——而如果将函数视为向量的话，“另一些函数”的函数簇中的函数两两正交，那么就是将原函数在这些函数张成的无限维空间中正交分解罢了。傅里叶展开所选的正交基是三角函数系 $[1,cos  kx, sin  kx],k=1,2,...$ ，这其中任取两不同函数，其积在 $[- pi, pi]$ 上的 $2-$ 范数都等于 $0$ ，也即两两正交：

$
    integral_(- pi)^(pi)cos  kx=  integral_(- pi)^(pi)sin  kx   d x=0\
     integral_(- pi)^(pi)cos  kx dot sin  nx   d x=0, quad k != n\
     integral_(- pi)^(pi)cos  kx dot cos  nx   d x=0, quad k != n\
     integral_(- pi)^(pi)sin  kx dot sin  nx   d x=0, quad k != n\
$

注意到我们要求三角函数系中 $k$ 为整数，这就要求 $2 pi$ 必须是这些三角函数的周期。这只是为了后续书写计算方便，之后会逐步放开限制。假设某周期为 $2 pi$ 的函数 $x(t)$ 可以傅里叶展开为：

$
x(t)= frac(a_0, 2)+ sum_(k=1)^(+ infinity)a_k cos  kt+b_k sin  kt
$

直接对上式两边在 $[- pi,+ pi]$ 区间上积分，注意到上面提到的 $  integral_(- pi)^(pi)cos  kx=  integral_(- pi)^(pi)sin  kx   d x=0$ ，那么：

$

      integral_(- pi)^(pi)x(t)dt&= integral_(- pi)^(pi) frac(a_0, 2)  dt+ sum_(k=1)^(+ infinity)a_k integral_(- pi)^(pi)cos  kt  dt+b_k integral_(- pi)^(pi)sin  kt  dt\
    &= integral_(- pi)^(pi) frac(a_0, 2)  dt\
    &=a_0 pi

$

因此得到 $a_0$ 的计算式：

$
a_0= frac(1, pi)  integral_(- pi)^(pi)x(t)dt
$

类似地，将 $x(t)$ 乘上 $cos  nt$ 后做同样的操作，并注意三角函数系的性质：

$

      integral_(- pi)^(pi)x(t)cos  nt  dt&= integral_(- pi)^(pi) frac(a_0, 2)cos  nt  dt+ sum_(k=1)^(+ infinity)a_k integral_(- pi)^(pi)cos  kt dot cos  nt  dt+b_k integral_(- pi)^(pi)sin  kt dot cos  nt  dt\
    &=a_n integral_(- pi)^(pi)cos^2nt  dt\
    &=a_n pi

$

于是：

$
a_n= frac(1, pi)  integral_(- pi)^(pi)x(t)cos  nt  dt
$

将 $x(t)$ 乘上 $sin  nt$ 后做同样的操作：

$

      integral_(- pi)^(pi)x(t)sin  nt  dt&= integral_(- pi)^(pi) frac(a_0, 2)sin  nt  dt+ sum_(k=1)^(+ infinity)a_k integral_(- pi)^(pi)cos  kt dot sin  nt  dt+b_k integral_(- pi)^(pi)sin  kt dot sin  nt  dt\
    &=b_n integral_(- pi)^(pi)sin^2nt  dt\
    &=b_n pi

$

于是：

$
b_n= frac(1, pi)  integral_(- pi)^(pi)x(t)sin  nt  dt
$

综上，我们得到了周期为 $2 pi$ 的函数 $x(t)$ 的*傅里叶三角项级数*的计算式：

$
 cases(
    a_n= frac(1, pi)  integral_(- pi)^(pi)x(t)cos  nt  dt,
    b_n= frac(1, pi)  integral_(- pi)^(pi)x(t)sin  nt  dt,
)
$

那么，若 $x(t)$ 的周期不为 $2 pi$ 呢？不必重新计算，因为只是相当于做了*时间伸缩变换*。假设周期为 $T= frac(2 pi, omega_0)$ ，那么首先将 $x(t)$ 重新映射为周期 $2 pi$ 的函数，也就是只对 $x(t)$ 做变换 $t -> frac(t, omega_0)$ ，那么傅里叶级数还能照原样计算：

$
 cases(
    a_n= frac(1, pi)  integral_(- pi)^(pi)x ( frac(t, omega_0) )cos  nt  dt,
    b_n= frac(1, pi)  integral_(- pi)^(pi)x ( frac(t, omega_0) )sin  nt  dt,
)
$

上式不甚好看，因此对其整体再重新做一次变换 $t -> omega_0t$ ，于是：

$
 cases(
    a_n= frac(omega_0, pi)  integral_(- frac(pi, omega_0))^(frac(pi, omega_0))x(t)cos  n omega_0t  dt,
    b_n= frac(omega_0, pi)  integral_(- frac(pi, omega_0))^(frac(pi, omega_0))x(t)sin  n omega_0t  dt,
)
$

或者，由于 $T= frac(2 pi, omega_0)$ ，进一步化为：

$
 cases(
    a_n= frac(2, T)  integral_(- frac(T, 2))^(frac(T, 2))x(t)cos  n omega_0t  dt,
    b_n= frac(2, T)  integral_(- frac(T, 2))^(frac(T, 2))x(t)sin  n omega_0t  dt,
)
$

上式是教科书上常给的形式。似乎#highlight[既不好看，也不好记]。

== 2.以复指数函数作为基底

在信号系统中，为了克服三角项级数既不好看也不好记的缺点，我们实际更常使用复指数函数作为基底。从三角项级数当然可以直接推出指数项级数的计算式，但这里不妨还是重新推导一下。现在我们直接取消掉 $x(t)$ 的周期为 $2 pi$ 的限制，直接设置为 $2T$ ，且 $T= frac(2 pi, omega_0)$ 。

首先，函数的指数项展开不像三角项展开那样繁复，十分简洁：

$
x(t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0t)
$

这样复指数函数簇 $[te^(tj k omega_0t)],k=0, plus.minus 1, plus.minus 2, dots$ 的基波周期就是 $T= frac(2 pi, omega_0)$ 。注意到：

$
      integral_(T)te^(tj k omega_0t) dot overline(te^(tj n omega_0t))  dt&= integral_(T)te^(tj k omega_0t) dot te^(-tj n omega_0t)  dt\
    &= integral_(T)te^(tj(k-n) omega_0t)  dt\
    &= cases(
        0 &","quad n != k,
        T &"," quad n=k,
    )
$

其中 $ overline(te^(tj n omega_0t))$ 表示对 $te^(tj n omega_0t)$ 取*共轭*，实际就是简单地将 $tj$ 设为 $-tj$ 即可。所以：

$
      integral_(T)x(t)te^(-tj n omega_0t)dt&= sum_(k=- infinity)^(+ infinity)c_k integral_(T)te^(tj k omega_0t) dot te^(-tj n omega_0t)dt\
    &= sum_(k=- infinity)^(+ infinity)c_k integral_(T)te^(tj(k-n) omega_0t)dt\
    &=c_n T\
$

因此：

$
c_n= frac(1, T)  integral_(T)x(t)te^(-tj n omega_0t)dt
$

这与从三角项级数计算公式中推出的一样。同时，不像三角项级数中那样分别要算 $x(t)cos  nt,x(t)sin  nt$ 的积分，这里一个式子即可涵盖所有情况。今后，*傅里叶级数系数*直指指数项级数 $c_n$ 而非三角项级数 $a_n,b_n$ 。傅里叶级数系数也称为*频谱系数*，因为这些系数描述了每一个谐波分量的大小。其中，称 $c_0$ 称为*直流分量*。

== 3.傅里叶级数收敛的条件

在假定信号 $x(t)$ 能用复指数信号加权和 $x^*(t)= sum c_k te^(tj k omega_0t)$ 拟合的情况下，频谱系数就是拟合效果最好的选择。但所谓“拟合效果最好”，并不是指能在任意 $t=t_0$ 时刻实现拟合函数的值无限趋近于实际值即 $x^*(t_0) -> x(t_0)$ ，而是指两者的*误差函数* $e(t)=x(t)-x^*(t)$ 在*任意周期*内的能量趋于零，即：
$
 integral_(T)abs(e(t))^2dt=0
$

或者说，拟合函数和原信号在能量上并没有差距。这样，
#tufted.theorem[傅里叶级数收敛的条件][
只要保证*原信号在任意周期内的能量收敛到有限值*，那么傅里叶级数一定是收敛的。
#footnote[也就是只要保证 $integral_(T)abs(x(t))^2dt< infinity$ 即可。]
]
以上是判定傅里叶级数收敛的其中一种方法。另一种方法是使用*狄利克雷条件*判断，而狄利克雷条件实际又包含三个条件、并要求这些条件同时成立：
#tufted.theorem[狄利克雷条件][
1. 在任意周期内，原信号的*最大值和最小值*的数量是有限的；
2. 在任意区间内，原信号的*不连续点的数量是有限的*，并且在不连续点上的*取值亦是有限的*。
3. 在任意周期内，原信号是*绝对可积*的，也就是：
$
  integral_(T)abs(x(t))dt< infinity
$
]

== 4.吉布斯现象

*吉布斯现象*指的是，拟合函数会在原信号的*不连续点*附近出现*高频的振荡*，并且不论拟合函数的精度有多高，拟合函数的峰值相比原信号总有不超过约 $9\%$ 的超量。

#tufted.remark[吉布斯现象的条件][
需要注意，出现吉布斯现象的条件是原信号存在*不连续点*，而不是存在*不光滑点*#footnote[复习：连续的定义是左极限和右极限相等]。例如，方波信号：
$
x(t)= cases(
    -1 &", "- frac(T, 2) <= t <=0,
    1 &", "0 <= t <= frac(T, 2),
)
$
会在 $t=0$ 处出现吉布斯现象，而三角波信号：
$
x(t)=abs(t) quad,-T <= t <= T
$
则不会出现吉布斯现象。
]

== 5.帕塞瓦尔定理

#tufted.theorem[帕塞瓦尔定理][
    对于信号 $x(t)$ 及其傅里叶级数系数而言，下式成立：
    $
    frac(1, T) integral_(T)abs(x(t))^2dt= sum_(k=- infinity)^(+ infinity)abs(c_k)^2
    $
]
其意义是，在*任意周期*中，原信号的*平均功率*是*所有谐波分量*的平均功率之和。

#tufted.remark[][
谐波分量的平均功率是：
$
P_k=  frac(1, T) integral_(T)abs(c_k te^(tj k omega_0t))^2dt= frac(1, T) integral_(T)abs(c_k)^2dt=abs(c_k)^2
$
]

#html.hr()

= 三、傅里叶级数的性质

为了方便描述，以下用符号：

$
x(t)limits(stretch(arrow.r))^(cal(F S))c_k
$

表示信号与其傅里叶级数系数的关系。

== 1.时间平移

假设信号 $x(t)$ 的时间发生平移 $t -> t-t_0$ ，那么其傅里叶级数可以重新计算如下：

$
    c'_n&= frac(1, T)  integral_(T)x(t-t_0)te^(-tj n omega_0t)dt\
    &= frac(1, T) integral_(T)x(t)te^(-tj n omega_0(t+t_0))dt\
    &=te^(-tj n omega_0t_0) frac(1, T) integral_(T)x(t)te^(-tj n omega_0t)dt\
    &=te^(-tj n omega_0t_0)c_n
$

因此，若 $x(t)limits(stretch(arrow.r))^(cal(F S))c_k$ ，那么：

$
x(t-t_0)limits(stretch(arrow.r))^(cal(F S))te^(-tj n omega_0t_0)c_k
$

== 2.时间反演 <级数时间反演>

现在假设发生时间反演 $t ->-t$ ，仿照上述计算：

$
    c'_n&= frac(1, T)  integral_(T)x(-t)te^(-tj n omega_0t)dt\
    &=- frac(1, T) integral_(-T)x(t)te^(tj n omega_0t)dt\
    &= frac(1, T) integral_(T)x(t)te^(-tj(-n) omega_0t)dt\
    &=c_(-n)
$

因此，若 $x(t)limits(stretch(arrow.r))^(cal(F S))c_k$ ，那么：

$
x(-t)limits(stretch(arrow.r))^(cal(F S))c_(-k)
$

由此可以引发对奇偶信号的讨论。若信号为奇信号即 $x(-t)=-x(t)$ ，由上述结论显然可得 $c_(-k)=-c_k$ 。而对于偶信号 $x(-t)=x(t)$ ，则有 $c_(-k)=c_k$ 。

== 3.时间伸缩

假设时间发生伸缩变换 $t -> alpha t$ ，其中要求 $ alpha>0$ ，那么根据：

$
x(t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0t)
$

$
 => x( alpha t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0 dot alpha t)= sum_(k=- infinity)^(+ infinity)c_k te^(tj k( alpha omega_0)t)
$

也就是说，傅里叶级数系数本身*不发生改变*，只是修改了谐波分量的*基波频率*，时间的伸缩倍率可以看做作用在基波频率上。

#tufted.remark[由时间伸缩到时间反演][
当然另一方面，当 $ alpha=-1$ 时此伸缩变换就可以看做时间反演，而此时这个取负操作视作作用在 $k$ 上：
$

    x(-t)&=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0 dot(-t))\
    &= sum_(k=- infinity)^(+ infinity)c_k te^(tj(-k) omega_0t)\
    &= sum_(k=- infinity)^(+ infinity)c_(-k)te^(tj k omega_0t)\

$
这就为上一小节 @级数时间反演 做了一个更简短的证明。同时也允许了 $alpha<0$ 的情况。基于此，之后对时间反演不再单独讨论，因为这可以直接体现在对时间伸缩变换中。
]

== 4.信号共轭

假如将信号取共轭即 $x(t) -> overline(x(t))$ ，那么傅里叶级数如何变换？还是通过处理下式：

$
x(t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0t)
$

两边同时取共轭可得：

$
     overline(x(t))&=  sum_(k=- infinity)^(+ infinity) overline(c_k te^(tj k omega_0t))\
    &= sum_(k=- infinity)^(+ infinity) overline(c_k) dot overline(te^(tj k omega_0t))\
    &= sum_(k=- infinity)^(+ infinity) overline(c_k) dot te^(-tj k omega_0t)\
    &= sum_(k=- infinity)^(+ infinity) overline(c_(-k)) dot te^(tj k omega_0t)\
$

因此：

$
    x(t)&limits(stretch(arrow.r))^(cal(F S))c_k\
     => overline(x(t))&limits(stretch(arrow.r))^(cal(F S)) overline(c_(-k))
$

根据这个结论，我们可以对实信号进行讨论。因为实信号 $ overline(x(t))=x(t)$ ，显然可得 $ overline(c_(-k))=c_k$ ，由此可得以下四式：

$
 cases(
     cal(Re) {c_(k) }= cal(Re) {c_(-k) },
     cal(Im) {c_(k) }=- cal(Im) {c_(-k) },
    abs(c_(k))=abs(c_(-k)),
    arg(c_(k))=-arg(c_(-k))
)
$

== 5.信号相加(线性)

假设两个具有*相同周期*的信号#footnote[务必注意周期相同的条件是非常重要的，在这一节说明傅里叶级数的性质时，取两个信号总默认其周期相同]：

$
 cases(
    x(t)limits(stretch(arrow.r))^(cal(F S))a_k,
    y(t)limits(stretch(arrow.r))^(cal(F S))b_k,
)
$

而 $z(t)= alpha x(t)+ beta y(t)$ ，那么其傅里叶级数系数 $c_n$ 为：

$

    c_n&= frac(1, T)  integral_(T)( alpha x(t)+ beta y(t))te^(-tj n omega_0t)dt\
    &= alpha frac(1, T)  integral_(T)x(t)te^(-tj n omega_0t)dt+ beta frac(1, T)  integral_(T)y(t)te^(-tj n omega_0t)dt\
    &= alpha a_n+ beta b_n

$

因此 $z(t)limits(stretch(arrow.r))^(cal(F S)) alpha a_k+ beta b_k$ 。

== 6.信号相乘(系数卷积)

同样还是取：

$
 cases(
    x(t)limits(stretch(arrow.r))^(cal(F S))a_k,
    y(t)limits(stretch(arrow.r))^(cal(F S))b_k,
)
$

而 $z(t)=x(t)y(t)$ 。这里我们不再直接计算 $c_n= frac(1, T)  integral_(T)x(t)y(t) te^(-tj n omega_0t)dt$ ，而是换一种思路——既然存在：

$
 cases(
    x(t)=  limits(display(sum))_(k=- infinity)^(+ infinity)a_k te^(tj k omega_0t),
    y(t)=  limits(display(sum))_(l=- infinity)^(+ infinity)b_l te^(tj l omega_0t),
)
$

所以：

$

    z(t)&=  sum_(k=- infinity)^(+ infinity)a_k te^(tj k omega_0t) dot sum_(l=- infinity)^(+ infinity)b_l te^(tj l omega_0t)\
    &= sum_(k=- infinity)^(+ infinity) sum_(l=- infinity)^(+ infinity)a_k b_l te^(tj(k+l) omega_0t)\
    &= sum_(n=- infinity)^(+ infinity) {  sum_(k=- infinity)^(+ infinity)a_k b_(n-k)  }te^(tj n omega_0t)\

$

也就是说：

$
c_n=  sum_(k=- infinity)^(+ infinity)a_k b_(n-k)
$

注意到上式其实就是一个*卷积*，因此也可以简写为 $c_n=a_n*b_n$ ——但需要注意，这样的写法实际将 $a_n,b_n$ 看做一个离散序列，而非孤立的值。

== 7.信号卷积(系数相乘)

设 $z(t)$ 是下述两信号在一个周期上的卷积：

$
 cases(
    x(t)limits(stretch(arrow.r))^(cal(F S))a_k,
    y(t)limits(stretch(arrow.r))^(cal(F S))b_k,
)
$

即 $z(t)=  integral_(T)x( tau)y(t- tau)d tau$ ，代入 $c_n= frac(1, T)  integral_(T)z(t)te^(-tj n omega_0t)dt$ 可得：

$
    c_n&= frac(1, T)  integral_(T) { integral_(T)x( tau)y(t- tau)d tau } te^(-tj n omega_0t)dt\
    &= frac(1, T) integral_(T) integral_(T)x( tau)y(t- tau)te^(-tj n omega_0t)  d tau dt\
    &= frac(1, T) integral_(T)x( tau)  d tau integral_(T)y(t- tau)te^(-tj n omega_0t)dt\
$

注意到后半部分积分其实就是 $y(t)$ 的傅里叶级数系数计算式，只是有 $ tau$ 的时间平移、并相差一个 $T$ 的倍数关系。故利用上面已经得到的*时间平移*结论：

$

    c_n&= frac(T b_n, T)  integral_(T)x( tau) te^(-tj n omega_0 tau)  d tau\
    &= frac(T^2a_n b_n, T)\
    &=T a_n b_n

$

又恰好可以组成 $x(t)$ 的傅里叶级数系数计算式！从而得到以下结论：

$
    integral_(T)x( tau)y(t- tau)d tau limits(stretch(arrow.r))^(cal(F S))T a_n b_n
$

== 8.信号微分

若对信号 $x(t)limits(stretch(arrow.r))^(cal(F S))c_k$ 求导，那么根据：

$
x(t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0t)
$

两边求导，立即可得：

$
 frac(d x(t), dt)=  sum_(k=- infinity)^(+ infinity)j k omega_0c_k te^(tj k omega_0t)
$

因此：

$
    x(t)&limits(stretch(arrow.r))^(cal(F S))c_k\
     => frac(d x(t), dt)&limits(stretch(arrow.r))^(cal(F S))j k omega_0c_k
$

== 9.信号积分

同样，若取 $z(t)=  integral_(- infinity)^(t)x(t)dt$ ，按同样的计算：

$
  integral_(- infinity)^(t)x(t)dt= sum_(k=- infinity)^(+ infinity) frac(c_k, j k omega_0)te^(tj k omega_0t)
$

故：

$

    x(t)&limits(stretch(arrow.r))^(cal(F S))c_k\
     =>  integral_(- infinity)^(t)x(t)dt&limits(stretch(arrow.r))^(cal(F S)) frac(c_k, j k omega_0)

$

== 10.信号奇偶

这里我们要求信号 $x(t)$ 是实信号，这样才能满足 $ overline(c_(-k))=c_k$ 的条件。将信号分解为偶部和奇部：

$
 cases(
     cal(Ev) {x(t) }= frac(1, 2)(x(t)+x(-t)),
     cal(Od) {x(t) }= frac(1, 2)(x(t)-x(-t)),
)
$

于是利用线性性质，对于偶部：

$
 cal(Ev) {x(t) }limits(stretch(arrow.r))^(cal(F S)) frac(1, 2)(c_k+c_(-k))= cal(Re) {c_k }
$

对于奇部：

$
 cal(Od) {x(t) }limits(stretch(arrow.r))^(cal(F S)) frac(1, 2)(c_k-c_(-k))=tj cal(Im) {c_k }
$

#html.hr()

= 四、傅里叶变换的计算

以上内容中，为了将信号分解为复指数信号的加权和，我们一直要求待分解信号是*周期信号*。并且我们也能发现，信号被分解之后，各分量之间是谐波关系，也即频率的取值是*离散的、分立的、成倍的*。现在我们不禁想问：非周期信号，是否也能展开为“傅里叶级数”？

== 1.非周期信号的傅里叶变换(狭义傅里叶变换)

答案是肯定的，但此时并不能说是将其展开为傅里叶级数，而是*做傅里叶变换*。注意到傅里叶级数系数的计算公式：

$
c_n= frac(1, T)  integral_(T)x(t)te^(-tj n omega_0t)dt
$

于是下式恒成立：

$
    x(t)&=  frac(1, T) sum_(k=- infinity)^(+ infinity)  integral_(T)x(t)te^(-tj k omega_0t)dt dot te^(tj k omega_0t)\
    &= frac(1, 2 pi) sum_(k=- infinity)^(+ infinity) integral_(T)x(t)te^(-tj k omega_0t)dt dot te^(tj k omega_0t) dot omega_0\
$

其中 $2T$ 是信号的周期。非周期信号为什么不可以看做*周期为无穷大*的周期信号呢？在此思想下，显然有 $T -> infinity, omega_0 ->0$ ，此时 $k omega_0$ 可以视作连续变量 $ omega$ ，并将 $ omega_0$ 重新记为 $d omega$ ：

$
x(t)=  frac(1, 2 pi) sum_(k=- infinity)^(+ infinity) integral_(- infinity)^(+ infinity)x(t) te^(-tj omega t)dt dot te^(tj dot k d omega dot t)d omega
$

其中 $  integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt$ 的结果显然是关于新连续变量 $ omega$ 的函数，或者一般认为是 $tj omega$ 的函数，记为 $X(tj omega)$ 或 $ cal(F) {x(t) }$ ，称为*频谱函数*。于是上式又能化为黎曼积分：
#tufted.definition[非周期信号的傅里叶逆变换式/综合公式][
$
x(t)=  frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj omega) dot te^(tj omega t)d omega
$
该式可记为 $ cal(F)^(-1) {X(tj omega) }$ 。
]
这样我们就将非周期信号 $x(t)$ 也表示成了复指数函数的加权和——但由于*非周期信号的频谱连续*，所以实际应写成积分的形式。必须要指出，虽然上式与下式#footnote[一个是对非周期信号、一个是对周期信号]：
$
x(t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0t)
$
看起来大有不同，但本质是相同的，无非一个连续、一个离散而已。而傅里叶级数系数计算式：
$
c_n= frac(1, T)  integral_(T)x(t)te^(-tj n omega_0t)dt
$

和*傅里叶变换式*：
#tufted.definition[傅里叶变换式][
$
X(tj omega)= cal(F) {x(t) }=  integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt
$
]
虽然不能划等号，但本质也是相同的。其中的区别会在下一小节讲述。

== 2.周期信号的傅里叶变换(广义傅里叶变换)

上一小节中说明了对于非周期信号来说如何计算其傅里叶变换，但同样的计算方法却无法适用于*周期信号*。由于前半部分已经说明周期信号可以表示为*成谐波*的复指数信号的加权和，现在为了说明上一小节导出的计算方法不能适用于周期信号，只需分析基本复指数信号 $x(t)=te^(tj omega_0t)$ 即可。对其傅里叶变换：

$
X(tj omega)=  integral_(- infinity)^(+ infinity)te^(tj omega_0t) dot te^(-tj omega t)dt= integral_(- infinity)^(+ infinity)te^(tj( omega_0- omega)t)dt
$

这个积分无论如何都*不收敛*！这似乎导向了一个令人沮丧的结论，即所有周期信号都不能傅里叶变换；甚至含有周期信号的非周期信号也不能傅里叶变换。幸运的是，如果对奇异函数 $ delta(t)$ 即*单位冲激函数*做傅里叶变换，可以得到如下结果：

$

     cal(F) { delta(t) }&=  integral_(- infinity)^(+ infinity) delta(t) dot te^(-tj omega t)dt\
    &= integral_(- infinity)^(+ infinity) delta(t) dot te^(0)dt\
    &=1

$

按照这个变换式来定义原本不收敛的傅里叶逆变换式：

$
 cal(F)^(-1) {1 }= delta(t)=  frac(1, 2 pi) integral_(- infinity)^(+ infinity)1 dot te^(tj omega t)d omega
$

也就是我们定义 $  integral_(- infinity)^(+ infinity)te^(tj omega t)d omega=2 pi delta(t)$ ，而这等价于 $  integral_(- infinity)^(+ infinity)te^(-tj omega t)dt=2 pi delta( omega)$ ，相当于又定义了如下傅里叶变换：

$
 cal(F) {1 }=2 pi delta( omega)
$

这样我们就能利用此变换并结合傅里叶变换的性质，求出任意*周期信号*的傅里叶变换了。假定周期信号 $x(t)$ 具有傅里叶级数形式：

$
x(t)=  sum_(k=- infinity)^(+ infinity)c_k te^(tj k omega_0t)
$

那么其傅里叶变换就是：
#tufted.theorem[周期信号的傅里叶变换][
$
X(tj omega)=2 pi  sum_(k=- infinity)^(+ infinity)c_k delta( omega-k omega_0)
$
]
也就是说，周期函数的频谱函数实际就是按其傅里叶级数系数排列的*冲激串*，但在强度上还需要放大 $2 pi$ 倍。

#tufted.remark[][
在未定义 $1$ 的傅里叶变换时、无法求出周期信号的频谱函数 $X(tj omega)$ 的本质原因，就是因为周期信号的频谱是*离散*的、而非周期信号的频谱则是连续的。在未引入单位冲激函数时，*连续函数* $X(tj omega)$ 天然地不具备表达离散函数的能力，直到我们定义 $ cal(F) {1 }=2 pi delta( omega)$ 从而引入单位冲激函数，便可以解决这个问题。
]

#html.hr()

= 五、傅里叶变换的性质

由于傅里叶变换式：

$
X(tj omega)= cal(F) {x(t) }=  integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt
$

和傅里叶级数系数计算式：

$
c_n= frac(1, T)  integral_(T)x(t)te^(-tj n omega_0t)dt
$

之间相差并不多，只是一个系数 $ frac(1, T)$ 、参数 $ omega,n omega_0$ 以及积分上下限不同，因此傅里叶级数系数的性质基本都可以挪用于此处。仿照之前傅里叶级数部分的写法，下述符号：

$
x(t)limits(stretch(arrow.r))^(cal(F))X(tj omega)
$

表示原信号 $x(t)$ 与其频谱函数 $X(tj omega)$ 的对应关系。

== 1.时间平移

当发生*时间平移* $t -> t-t_0$ ：

$

    X'(tj omega)&=  integral_(- infinity)^(+ infinity)x(t-t_0)te^(-tj omega t)dt\
    &= integral_(- infinity)^(+ infinity)x(t)te^(-tj omega(t+t_0))dt\
    &=te^(-tj omega t_0) integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt\
    &=te^(-tj omega t_0)X(tj omega)

$

因此：

$

    x(t)&limits(stretch(arrow.r))^(cal(F))X(tj omega)\
     => x(t-t_0)&limits(stretch(arrow.r))^(cal(F))te^(-tj omega t_0)X(tj omega)\

$

== 2.时间伸缩(频域伸缩)

当发生*时间伸缩* $t ->  alpha t$ ：

$

    X'(tj omega)&=  integral_(- infinity)^(+ infinity)x( alpha t)te^(-tj omega t)dt\
    &= frac(1, abs(alpha)) integral_(- infinity)^(+ infinity)x(t)te^(-tj omega frac(t, alpha))dt\
    &= frac(1, abs(alpha)) integral_(- infinity)^(+ infinity)x(t)te^(-tj frac(omega, alpha)t)dt\
    &= frac(1, abs(alpha))X ( frac(tj omega, alpha) )

$

因此：

$

    x(t)&limits(stretch(arrow.r))^(cal(F))X(tj omega)\
     => x( alpha t)&limits(stretch(arrow.r))^(cal(F)) frac(1, abs(alpha))X ( frac(tj omega, alpha) )\
     => x(-t)&limits(stretch(arrow.r))^(cal(F))X(-tj omega)\

$

== 3.频域平移

若*频域发生平移* $ omega -> omega- omega_0$ ，那么可以计算傅里叶逆变换：

$

    x'(t)&=  frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(j( omega- omega_0))te^(tj omega t)d omega\
    &= frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj omega)te^(tj( omega+ omega_0) t)d omega\
    &=te^(tj omega_0 t) frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj omega)te^(tj omega t)d omega\
    &=te^(tj omega_0 t)x(t)

$

因此：

$

    x(t)&limits(stretch(arrow.r))^(cal(F))X(tj omega)\
     => te^(tj omega_0 t)x(t)&limits(stretch(arrow.r))^(cal(F))X(j( omega- omega_0))\

$

== 4.信号共轭

考虑取信号的*共轭* $x(t) -> overline(x(t))$ ，那么将傅里叶变换式两边同时取共轭：

$

     overline(X(tj omega))&= overline(integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt)\
    &= integral_(- infinity)^(+ infinity) overline(x(t)te^(-tj omega t))dt\
    &= integral_(- infinity)^(+ infinity) overline(x(t)) dot overline(te^(-tj omega t))dt\
    &= integral_(- infinity)^(+ infinity) overline(x(t)) dot te^(tj omega t)dt\

$

因此 $ overline(X(-tj omega))=  integral_(- infinity)^(+ infinity) overline(x(t)) dot te^(-tj omega t)dt= cal(F) { overline(x(t)) }$ ，故：

$

    x(t)&limits(stretch(arrow.r))^(cal(F))X(tj omega)\
     =>  overline(x(t))&limits(stretch(arrow.r))^(cal(F)) overline(X(-tj omega))\

$

根据这个结论，我们又可以展开对*实信号*的讨论。类似在傅里叶级数中的结论，实信号首先有*共轭对称性*，即 $ overline(X(tj omega))=X(-tj omega)$ ，于是：

$
 cases(
     cal(Re) {X(tj omega) }= cal(Re) {X(-tj omega) },
     cal(Im) {X(tj omega) }=- cal(Im) {X(-tj omega) },
)
$

== 5.信号相加(线性)

对于 $z(t)= alpha x(t)+ beta y(t)$ ，显然：

$

    Z(tj omega)&=  integral_(- infinity)^(+ infinity)( alpha x(t)+ beta y(t))te^(-tj omega t)dt\
    &= alpha integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt+ beta integral_(- infinity)^(+ infinity)y(t)te^(-tj omega t)dt\
    &= alpha X(tj omega)+ beta Y(tj omega)

$

故：

$
 alpha x(t)+ beta y(t)limits(stretch(arrow.r))^(cal(F)) alpha X(tj omega)+ beta Y(tj omega)
$

值得注意的是，相比傅里叶级数部分，这里取消了 $x(t),y(t)$ 应有相同周期的限制——毕竟傅里叶变换的作用对象本就是非周期函数。

== 6.信号微分

将傅里叶逆变换式两边求导可得：

$
x(t)=  frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj omega)te^(tj omega t)d omega
$

$

     => frac(d x(t), dt)&=  frac(1, 2 pi) frac(d, dt) integral_(- infinity)^(+ infinity)X(tj omega)te^(tj omega t)d omega\
    &= frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj omega) dot  frac(d(te^(tj omega t)), dt)d omega\
    &= frac(1, 2 pi) integral_(- infinity)^(+ infinity)tj omega X(tj omega) dot te^(tj omega t)d omega\

$

故：

$
 frac(d x(t), dt)limits(stretch(arrow.r))^(cal(F))tj omega X(tj omega)
$

== 7.信号积分

将傅里叶逆变换式两边求积可得：
$
      integral_(- infinity)^(t)x(t)dt&= frac(1, 2 pi) integral_(- infinity)^(t) integral_(- infinity)^(+ infinity)X(tj omega)te^(tj omega t)d omega dt\
    &= frac(1, 2 pi) integral_(- infinity)^(t)te^(tj omega t)dt integral_(- infinity)^(+ infinity)X(tj omega)d omega\
    &= frac(1, 2 pi) integral_(- infinity)^(+ infinity) frac(1, tj omega)X(tj omega)te^(tj omega t)d omega\
$

故：
$
  integral_(- infinity)^(t)x(t)dt limits(stretch(arrow.r))^(cal(F)) frac(1, tj omega)X(tj omega)
$

#tufted.remark[与教科书的区别][
假设已知 $x(t)limits(stretch(arrow.r))^(cal(F))X(tj omega)$ ，并且 $x(t)=y'(t)$ ，现在我们尝试求 $y(t)$ 的傅里叶变换。在这里值得注意的是：由于求导会使常数项归零，因此我们应当假设 $y(t)$ 中存在常数项；即，仅认为 $y(t)=  integral_(- infinity)^(t)x(t)dt$ 是不全面的，而应是 $y(t)=  integral_(- infinity)^(t)x(t)dt+C$ 。后面这个常数项会带来 $2 pi C delta( omega)$ 的冲激。但因为前面一项即 $ frac(1, tj omega)X(tj omega)$ 已经使 $ omega=0$ 的取值成为不可能，因此这个冲激可以略去不计。

当然，在奥本海姆的教科书上给出的傅里叶变换积分性质是：
$
  integral_(- infinity)^(t)x(t)dt limits(stretch(arrow.r))^(cal(F)) frac(1, tj omega)X(tj omega)+ pi X(0) delta( omega)
$
这大抵是利用了 $  integral_(- infinity)^(t)x(t)dt=x(t)*u(t)$ 的性质之后，结合 $ cal(F) {u(t) }= frac(1, tj omega)+ pi delta( omega)$ 和之后要讲的*卷积性质*导出的。
]

== 8.信号奇偶

类似于傅里叶级数中的讨论，我们还是要求信号为*实信号*以符合共轭对称性 $ overline(X(tj omega))=X(-tj omega)$ 。这样结合线性性质可得以下结论：

$
 cases(
     cal(Ev) {x(t) }limits(stretch(arrow.r))^(cal(F)) cal(Re) {X(tj omega) },
     cal(Od) {x(t) }limits(stretch(arrow.r))^(cal(F))tj cal(Im) {X(tj omega) },
)
$

== 9.时域相乘(频域卷积)

傅里叶变换极其重要的性质之一，就是原信号*相乘*，那么其频谱函数则是原先两个频谱函数的*卷积*。设 $z(t)=x(t)y(t)$ ，那么：

$
    z(t)&=  frac(1, 4 pi^2) integral_(- infinity)^(+ infinity)X(tj phi)te^(tj phi t)d phi dot integral_(- infinity)^(+ infinity)Y(tj psi)te^(tj psi t)d psi\
    &= frac(1, 4 pi^2) integral_(- infinity)^(+ infinity) integral_(- infinity)^(+ infinity)X(tj phi)Y(tj psi)te^(tj( phi+ psi) t)  d phi d psi\
$

现在令 $ omega= phi+ psi$ ，所以：

$
    z(t)&=  frac(1, 4 pi^2) integral_(- infinity)^(+ infinity) integral_(- infinity)^(+ infinity)X(tj phi)Y(j( omega- phi))te^(tj omega t)  d phi d omega\
    &= frac(1, 2 pi) integral_(- infinity)^(+ infinity) {  frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj phi)Y(tj( omega- phi))  d phi  }te^(tj omega t) d omega\
$

从而可以看出 $Z(tj omega)=  frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj phi)Y(tj( omega- phi))  d phi= frac(1, 2 pi)X(tj phi)*Y(tj phi)$ 。故：

$
x(t)y(t)limits(stretch(arrow.r))^(cal(F)) frac(1, 2 pi)X(tj omega)*Y(tj omega)
$

== 10.时域卷积(频域相乘)

傅里叶变换的另一重要性质，就是原信号*卷积*，那么其频谱函数则是原先两个频谱函数的*乘积*。设 $z(t)=x(t)*y(t)$ ，那么：

$

    Z(tj omega)&=  integral_(- infinity)^(+ infinity) {  integral_(- infinity)^(+ infinity)x( tau)y(t- tau)d tau  }te^(-tj omega t)dt\
    &= integral_(- infinity)^(+ infinity)x( tau)d tau  integral_(- infinity)^(+ infinity)y(t- tau)te^(-tj omega t)dt\
    &=Y(tj omega) integral_(- infinity)^(+ infinity)x( tau)te^(-tj omega tau)d tau\
    &=X(tj omega)Y(tj omega)

$

故：

$
x(t)*y(t)limits(stretch(arrow.r))^(cal(F))X(tj omega)Y(tj omega)
$

== 11.频域微分

对傅里叶变换式两边求导可得：

$
X(tj omega)=  integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt
$

$
     => frac(d X(tj omega), d omega)&=  frac(d, d omega) integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt\
    &= integral_(- infinity)^(+ infinity)x(t) frac(d(te^(-tj omega t)), d omega)dt\
    &= integral_(- infinity)^(+ infinity)-tj t x(t)te^(-tj omega t)dt\
$

故：

$
-tj t x(t)limits(stretch(arrow.r))^(cal(F)) frac(d X(tj omega), d omega)
$

当然，由于 $- frac(1, tj)=tj$ ，上式我们更一般写为：

$
t x(t)limits(stretch(arrow.r))^(cal(F))tj frac(d X(tj omega), d omega)
$

== 12.对偶性

*对偶性*指的是，傅里叶变换式和傅里叶逆变换式在形式上有极大的相似性：

$
 cases(
    X(tj omega)= cal(F) {x(t) }=  integral_(- infinity)^(+ infinity)x(t)te^(-tj omega t)dt,
    x(t)= cal(F)^(-1) {X(tj omega) }=  frac(1, 2 pi) integral_(- infinity)^(+ infinity)X(tj omega) dot te^(tj omega t)d omega,
)
$

这导致了：如果信号 $x(t)$ 在傅里叶变换之后得到频谱函数 $X(tj omega)$ ，再对频谱函数做变量替换、记 $y(t)=X(j t)$ ，那么 $Y(tj omega)$ 在形式上又会与 $x(t)$ 有极大的相似性！典型的例子是 $1$ 与单位冲激函数 $ delta(t)$ 的傅里叶变换对，可以参考这个例子琢磨一下“对偶性”究竟为何物：

$
 cases(
    1&limits(stretch(arrow.r))^(cal(F))2 pi delta( omega),
     delta(t)&limits(stretch(arrow.r))^(cal(F))1,
)
$

当然您可能也已经注意到了：譬如时域相乘相当于频域卷积，反过来也成立——时域卷积相当于频域相乘；时域微分和频域微分导出的结果竟也差不多……这也是对偶性的体现之一。

#html.hr()

= 六、基本傅里叶变换表

以下给出一些基本信号的傅里叶变换表：

#figure(
    table(
        columns: 3,
        align: left,

        [*信号*$x(t)$], [*傅里叶变换*$X(j omega)=cal(F){x(t)}$], [*条件或说明*],
        [$1$], [$2 pi delta(omega)$], [---],
        [$te^(tj k omega_0 t)$], [$2 pi delta(omega-k omega_0)$], [---],
        [$display(sum)_(k=-infinity)^(+infinity) a_k te^(tj k omega_0 t)$], [$2 pi display(sum)_(k=-infinity)^(+infinity) a_k delta(omega-k omega_0)$], [---],
        [$delta(t)$], [$1$], [---],
        [$delta(t-t_0)$], [$te^(-tj omega t_0)$], [---],
        [$u(t)$], [$1/(tj omega)+pi delta(omega)$], [---],
        [$display(sum)_(k=-infinity)^(+infinity) delta(t-k T)$], [$frac(2 pi, T) display(sum)_(k=-infinity)^(+infinity) delta(omega-(2 k pi)/T)$], [---],
        [$cos(omega_0 t)$], [$pi(delta(omega-omega_0)+delta(omega+omega_0))$], [---],
        [$sin(omega_0 t)$], [$pi/tj (delta(omega-omega_0)-delta(omega+omega_0))$], [---],
        [$te^(-a t) u(t)$], [$1/(a+tj omega)$], [$cal(R e){a}>0$],
        [$t te^(-a t) u(t)$], [$1/(a+tj omega)^2$], [$cal(R e){a}>0$],
        [$t^(n-1)/(n-1)! te^(-a t) u(t)$], [$1/(a+tj omega)^n$], [$cal(R e){a}>0$],
        [$sin(W t)/(pi t)$], [$cases(1", " abs(omega)<W, 0", " abs(omega)>W)$], [---],
        [$cases(1", " abs(t)<T_1, 0", " abs(t)>T_1)$], [$frac(2 sin(omega T_1), omega)$], [---],
        [$cases(1", " abs(t)<T_1, 0", " T_1<abs(t)<=T/2, x(t+T)=x(t))$], [$display(sum)_(k=-infinity)^(+infinity) (2 sin(k omega_0 T_1))/k delta(omega-k omega_0)$], [---],
    ),
    caption: [基本傅里叶变换表],
)
