#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#show: template.with(
    title: "概率论（六）——假设检验",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


= 概率论（六）——假设检验

#tufted.full-width[
    #image("header.jpg")
]

假设检验完全基于前一章#link("../概率论(五)——参数估计/")[参数估计]。我们只针对正态总体参数的假设检验讨论。

= 一、假设检验

对于某个正态分布，具有某些未知参数，例如均值 $ mu$ 。于是我们(可能根据经验)猜想均值为某个值 $ mu= mu_0$ ，那么这就产生了两个相互对立的假设：

$
H_0: mu= mu_0 quad quad H_1: mu != mu_0
$

称第一个假设为原假设或零假设，第二个假设为备择假设。为了确定我们应当选择哪个假设，我们测定出一组样本值 $x_1,x_2,...,x_n$ ，通过这组样本值推断哪个假设更加可能符合事实。

比如我们希望以 $1- alpha$ 的可能性确定假设 $H_0$ 是正确的，或者说希望只有 $ alpha$ 的可能性在假设 $H_0$ 是正确的情况下却选择了 $H_1$ ，称 $ alpha$ 为显著性水平。那么，构造样本均值的标准化变量 $ frac(overline(X)- mu_0, frac(sigma, sqrt(n)))$ ，“以 $1- alpha$ 的可能性确定假设 $H_0$ 是正确的”这句话就可以表示为：

$
P (  abs(frac(overline(X)- mu_0, frac(sigma, sqrt(n)))) <= z_(alpha/2)  )=1- alpha
$

#footnote[复习：在#link("../概率论(五)——参数估计/")[参数估计]中，我们称 $1- alpha$ 为置信水平。]

上式是遵从参数估计的写法来写的。事实上在假设检验中，我们常常是针对“只有 $ alpha$ 的可能性在假设 $H_0$ 是正确的情况下却选择了 $H_1$ ”的表述做文章。这句话我们简写为：

$
P(#text[当$H_0$为真时拒绝$H_0$]) <= alpha
$

在这个例子中，记标准化变量 $Z= frac(overline(X)- mu_0, frac(sigma, sqrt(n)))$ ，也称为检验统计量，上式化为：

$
P (  abs(Z) >= z_(alpha/2)  )= alpha
$

这样，我们就能根据 $Z$ 的取值 $z$ 确定我们应该取哪个假设。假如 $abs(z) >= z_(alpha/2)$ ，这显然是一个小概率事件，这便是在说我们有 $1- alpha$ 的把握拒绝 $H_0$ 而接受 $H_1$ 。反之，有 $1- alpha$ 的把握接受 $H_0$ 而拒绝 $H_1$ 。将拒绝 $H_0$ 时检验统计量的取值范围称为拒绝域，将拒绝域的边界点称为临界点。同时不妨将接受 $H_0$ 时检验统计量的取值范围称为接受域。显然拒绝域与接受域的并集是检验统计量的整个取值范围，交集为空，因此给出其中之一则知另一个。

在这个例子中，因为备择假设的取值落在 $ mu_0$ 的两边，因此称之为双边备择假设，相应的假设检验称为双边假设检验。双边假设检验实际就是在求参数的双边置信区间。相应地也有单边检验，分为左边检验和右边检验。左边检验形如：

$
H_0: mu >= mu_0 quad H_1: mu< mu_0
$

右边检验形如：

$
H_0: mu <= mu_0 quad H_1: mu> mu_0
$

单边检验实际就是在求参数的单边置信区间。接下来我们分析正态总体的参数的双边假设检验。

#html.hr()

= 二、正态总体的双边假设检验

== 1.单个总体 $N( mu, sigma^2)$ ，均值 $ mu$ 的检验

*(1)已知方差 $ sigma^2$ *

对于假设：

$
H_0: mu= mu_0 quad H_1: mu != mu_0
$

在接受 $H_0$ 的前提下，标准化变量服从标准正态分布：

$
Z= frac(overline(X)- mu_0, frac(sigma, sqrt(n))) ~ N(0,1)
$

于是：

$
P(#text[当$H_0$为真时拒绝$H_0$])=P(abs(Z) >= k)= alpha
$

由双边检验条件，得到 $k=z_(alpha/2)$ ，因而拒绝域为：

$
 abs(frac(overline(X)- mu_0, frac(sigma, sqrt(n)))) >= z_(alpha/2)
$

事实上，解接受域不等式，得到的就是这个情况下的置信水平为 $1- alpha$ 的双侧置信区间。

*(2)未知方差 $ sigma^2$ *

对于假设：

$
H_0: mu= mu_0 quad H_1: mu != mu_0
$

用样本方差 $S^2$ 代替 $ sigma^2$ ：

$
 frac(overline(X)- mu_0, frac(S, sqrt(n))) ~ t(n-1)
$

接受域为：

$
 abs(frac(overline(X)- mu_0, frac(S, sqrt(n))))<t_(alpha/2)(n-1)
$

解接受域得置信区间为：

$
 (  overline(X) plus.minus frac(S, sqrt(n))t_(alpha/2)(n-1)  )
$

拒绝域为：

$
 abs(frac(overline(X)- mu_0, frac(S, sqrt(n)))) >= t_(alpha/2)(n-1)
$

== 2.单个总体 $N( mu, sigma^2)$ ，方差 $ sigma^2$ 的检验

对于假设：

$
H_0: sigma^2= sigma^2_0 quad H_1: sigma^2 != sigma^2_0
$

使用 $ chi^2$ 分布：

$
 frac((n-1)S^2, sigma_0^2) ~ chi^2(n-1)
$

接受域为：

$
 chi_(1- alpha/2)^2(n-1)< frac((n-1)S^2, sigma_0^2)< chi_(alpha/2)^2(n-1)
$

置信区间为：

$
 (  frac((n-1)S^2, chi^2_(alpha/2)(n-1)) quad, quad  frac((n-1)S^2, chi^2_(1- alpha/2)(n-1))  )
$

拒绝域为：

$
 frac((n-1)S^2, sigma_0^2) <= chi_(1- alpha/2)^2(n-1) quad 或 quad frac((n-1)S^2, sigma_0^2) >= chi_(alpha/2)^2(n-1)
$

== 3.两个总体 $N( mu_1, sigma_1^2),N( mu_2, sigma_2^2)$ ，均值差 $ mu_1- mu_2$ 的检验

(1)*已知方差 $ sigma_1^2, sigma_2^2$ *

对于假设：

$
H_0: mu_1- mu_2= delta quad H_1: mu_1- mu_2 != delta
$

线性组合的标准化变量：

$
 frac(( overline(X)_1- overline(X)_2)- delta, sqrt( frac(sigma^2_1, n_1)+ frac(sigma^2_2, n_2))) ~ N(0,1)
$

接受域为：

$
 abs(frac(( overline(X)_1- overline(X)_2)- delta, sqrt( frac(sigma^2_1, n_1)+ frac(sigma^2_2, n_2))))< z_(alpha/2)
$

置信区间：

$
 (  delta plus.minus sqrt( frac(sigma^2_1, n_1)+ frac(sigma^2_2, n_2))z_(alpha/2)  )
$

拒绝域：

$
 abs(frac(( overline(X)_1- overline(X)_2)- delta, sqrt( frac(sigma^2_1, n_1)+ frac(sigma^2_2, n_2)))) >= z_(alpha/2)
$

(2)*未知方差但两个方差相等 $ sigma_1^2= sigma_2^2= sigma^2$ *

记 $S_W^2= frac((n_1-1)S_1^2+(n_2-1)S_2^2, n_1+n_2-2)$ ，对于假设：

$
H_0: mu_1- mu_2= delta quad H_1: mu_1- mu_2 != delta
$

有：

$
 frac(( overline(X)_1- overline(X)_2)- delta, S_w dot sqrt( frac(1, n_1)+ frac(1, n_2))) ~ t(n_1+n_2-2)
$

接受域：

$
t_(1- alpha/2)(n_1+n_2-2)< frac(( overline(X)_1- overline(X)_2)- delta, S_w dot sqrt( frac(1, n_1)+ frac(1, n_2)))<t_(alpha/2)(n_1+n_2-2)
$

置信区间：

$
 ( ( overline(X)_1- overline(X)_2) plus.minus S_W sqrt( frac(1, n_1)+ frac(1, n_2))t_(alpha/2)(n_1+n_2-2)  )
$

拒绝域：

$
 frac(( overline(X)_1- overline(X)_2)- delta, S_w dot sqrt( frac(1, n_1)+ frac(1, n_2))) <= t_(1- alpha/2)(n_1+n_2-2) quad 或 quad frac(( overline(X)_1- overline(X)_2)- delta, S_w dot sqrt( frac(1, n_1)+ frac(1, n_2))) >= t_(alpha/2)(n_1+n_2-2)
$

== 4.两个总体 $N( mu_1, sigma_1^2),N( mu_2, sigma_2^2)$ ，方差比 $ sigma_1^2/ sigma_2^2$ 的检验

注意这个情况下，我们检验的实际是 $ sigma_1^2, sigma_2^2$ 之间的大小。因此接受域的形式与置信区间稍有不同。对于假设：

$
H_0: sigma_1^2= sigma_2^2 quad H_1: sigma_1^2 != sigma_2^2
$

有：

$
 frac(S_1^2/S_2^2, sigma_1^2/ sigma_2^2) ~ F(n_1-1,n_2-1)
$

在接受假设 $H_0$ 的情况下，可以写为：

$
 frac(S_1^2, S_2^2) ~ F(n_1-1,n_2-1)
$

这样，接受域就是：

$
F_(1- alpha/2)(n_1-1,n_2-1)< frac(S_1^2, S_2^2)< F_(alpha/2)(n_1-1,n_2-1)
$

拒绝域就是：

$
 frac(S_1^2, S_2^2) <= F_(1- alpha/2)(n_1-1,n_2-1) quad 或 quad frac(S_1^2, S_2^2) >= F_(alpha/2)(n_1-1,n_2-1)
$

== 5.成对数据具有显著差异的检验

假设有 $n$ 对数据： $(X_1,Y_1),(X_2,Y_2),...,(X_n,Y_n)$ ，令 $D_i=X_i-Y_i$ ，并且 $D_i ~ N( mu_D, sigma_D^2)$ ，那么这些数据对不具有显著差异的条件显然就是在一定概率下 $ mu_D=0$ 。对于假设：

$
H_0: mu_D=0 quad H_1: mu_D !=0
$

显然这个检验可以归结为未知 $ sigma^2$ 的单个总体对均值 $ mu$ 的检验。也就是若记样本均值为 $ overline(d)$ ，样本方差为 $s$ ，那么：

$
 frac(overline(d), frac(s, sqrt(n))) ~ t(n-1)
$

因此接受域为：

$
 abs(frac(overline(d), frac(s, sqrt(n))))< t_(alpha/2)(n-1)
$

拒绝域为：

$
 abs(frac(overline(d), frac(s, sqrt(n)))) >= t_(alpha/2)(n-1)
$

#html.hr()

= 三、正态总体的单边假设检验

与双边假设检验完全类似，可以归结为对参数的置信区间的计算，因此不再赘述。



