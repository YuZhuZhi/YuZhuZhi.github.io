#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#show: template.with(
    title: "概率论（四）——抽样分布",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


= 概率论（四）——抽样分布

#tufted.full-width[
    #image("header.jpg")
]

= 一、基本概念

假设有一个整体 $X$ ，从中选取一组样本 $X_1,X_2,...,X_n$ ，由这些随机变量组成的函数 $g(X_1,X_2,...,X_n)$ 亦是一个随机变量，称为*统计量*。

而若这些随机变量的*样本值*分别取值为 $x_1,x_2,...,x_n$ ，那么将这些样本值代入统计量函数中，统计量也会落入一个确定的值中，这个值称为*观察值*。

一些常用的统计量是：

(1)*样本均值*

$
 overline(X)=  frac(1, n) sum_(i=1)^(n)X_i
$

(2)*样本方差*

$
S^2=  frac(1, n-1) sum_(i=1)^(n)(X_i- overline(X))^2= frac(1, n-1) (  sum_(i=1)^(n)X_i^2-n overline(X)^2  )
$

(3)*样本标准差*

$
S=  sqrt(S^2)= sqrt( frac(1, n-1) sum_(i=1)^(n)(X_i- overline(X))^2)
$

(4)*样本 $k$ 阶(原点)矩*

$
A_k=  frac(1, n) sum_(i=1)^(n)X_i^k
$

(5)*样本 $k$ 阶中心矩*

$
B_k=  frac(1, n) sum_(i=1)^(n)(X_i- overline(X))^k
$

#footnote[值得注意的是，*样本方差*及标准差与随机变量的方差标准差有些区别。在随机变量中，方差前乘的是 $ frac(1, n)$ ，而样本方差则是 $ frac(1, n-1)$ 。随机变量的二阶中心矩是它的方差，而统计量的样本二阶中心矩不是它的样本方差。]

总体 $X$ 不仅具有理论分布函数 $F(x)$ ，由于样本的选取还会产生*经验分布函数*。假设从总体本身有 $n$ 个观察值 $x_1,x_2,...,x_n$ (注意是观察值不是样本值)，以符号 $\#(x_i <= x)$ 表示这组观察值中小于等于 $x$ 的值的个数，那么经验分布函数 $F_(n)(x)$ 就写为：

$
F_(n)(x)= frac(\#(x_i <= x), n) quad, quad- infinity<x<+ infinity
$

当样本容量趋于正无穷时，实际就是在用频率趋近概率。此时经验分布函数也会逼近理论分布函数。

#html.hr()

= 二、 $ chi^2$ 分布

假设 $X_1,X_2,...,X_n$ 都是来自*标准正态分布* $N(0,1)$ 的样本，那么统计量：

$
 chi^2=X_1^2+X_2^2+...+X_n^2
$

服从*自由度*为 $n$ 的 $ chi^2$ *分布*，简记为 $ chi^2 ~ chi^2(n)$ 。 $ chi^2$ 分布的概率密度函数为：

$
f(x)= cases(
     frac(x^(frac(n, 2)-1)e^(- frac(x, 2)), 2^(frac(n, 2)) italic(Gamma)( frac(n, 2))) quad &x>0,
    0 & "Other Cases"
)
$

 $ chi^2$ 分布的期望和方差很简单，分别是 $E( chi^2)=n,D( chi^2)=2n$ 。 $ chi^2$ 分布还具有可加性，若有两个相互独立的 $ chi^2$ 变量： $ chi^2_1 ~ chi^2(n_1), chi^2_2 ~ chi^2(n_2)$ ，那么这两个变量之和依旧服从 $ chi^2$ 分布：

$
 chi^2_1+ chi^2_2 ~ chi^2(n_1+n_2)
$

 $ chi^2$ 分布的上 $ alpha$ 分位数记为 $ chi^2_ alpha(n)$ ，需要同时给出 $ alpha,n$ 的值才能确定其值。当 $n$ 充分大时，可以利用标准正态分布的上 $ alpha$ 分位数 $z_ alpha$ 来估算之：

$
 chi^2_ alpha (n) approx frac(1, 2)(z_ alpha+ sqrt(2n-1))^2
$

#tufted.remark[上 $ alpha$ 分位数][
复习：*上 $ alpha$ 分位数*，是指下式中：
$
P(X>z_ alpha)= alpha quad, quad 0< alpha<1
$
当 $X$ 服从某种分布，那么 $z_ alpha$ 就称为这种分布的上 $ alpha$ 分位数。特别地，总以 $z_ alpha$ 代表标准正态分布的上 $ alpha$ 分位数， $ chi^2_alpha (n)$ 代表 $ chi^2$ 分布的上 $ alpha$ 分位数。
]

#html.hr()

= 三、 $t$ 分布

若两随机变量分别服从标准正态分布与 $ chi^2$ 分布： $X ~ N(0,1)  ,  Y ~ chi^2(n)$ ，那么随机变量：

$
t= frac(X, sqrt( frac(Y, n)))
$

服从自由度为 $n$ 的 $t$ *分布*，又称为*学生氏分布*，简记为 $t ~ t(n)$ 。其概率密度函数 $h(t)$ 是一个类似于正态分布的以 $y$ 轴为轴的*轴对称图形*，因此定义域是整个实数域：

$
h(t)= frac(italic(Gamma)( frac(n+1, 2)), sqrt( pi n) italic(Gamma)( frac(n, 2))) ( 1+ frac(t^2, n)  )^(- frac(n+1, 2))
$

当 $n ->+ infinity$ 时，上式就趋于*标准正态分布*。在实用时，当 $n>45$ 就以标准正态分布来近似之。

由于其轴对称性，其上 $ alpha$ 分位数具有性质 $t_(1- alpha)(n)=-t_alpha (n)$ 。当 $n>45$ 时，取 $t_alpha (n) approx z_ alpha$ 。

#html.hr()

= 四、 $F$ 分布

若两个相互独立的随机变量都服从 $ chi^2$ 分布： $X  ~ chi^2(n_1)  ,  Y ~ chi^2(n_2)$ ，那么随机变量：

$
F= frac(frac(X, n_1), frac(Y, n_2))
$

服从自由度为 $(n_1,n_2)$ 的 $F$ *分布*，简记为 $F ~ F(n_1,n_2)$ 。其概率密度函数：

$
 psi(x)= cases(
     frac(italic(Gamma)( frac(n_1|n_2, 2))( frac(n_1, n_2))^(frac(n_1, 2))x^(frac(n_1, 2)-1), italic(Gamma)( frac(n_1, 2)) italic(Gamma)( frac(n_2, 2))(1+ frac(n_1x, n_2))^(frac(n_1+n_2, 2))) quad& x>0,
    0 & "Other Cases"
)
$

由此，若 $F ~ F(n_1,n_2)$ ，那么 $ frac(1, F) ~ F(n_2,n_1)$ 。同样，对于 $F$ 分布的上 $ alpha$ 分位数 $F_(alpha)(n_1,n_2)$ ，也有 $F_(1- alpha)(n_1,n_2)= frac(1, F_(alpha)(n_2,n_1))$ 。

#html.hr()

= 五、正态总体的样本均值与样本方差的分布

对于总体 $X$ (*不限定*其分布)，若其有期望和方差 $E(X)= mu,D(X)= sigma^2$ ，而其一个样本 $X_1,X_2,...,X_n$ 的样本均值和样本方差分别为 $ overline(X),S^2$ ，那么：

$
E( overline(X))= mu quad D( overline(X))= frac(sigma^2, n) quad E(S^2)= sigma^2
$

现在我们限定总体 $X$ 服从*正态分布* $N( mu, sigma^2)$ 。其样本均值与样本方差是相互独立的。那么：

$
 overline(X) ~ N ( mu, frac(sigma^2, n) )
$

$
 frac((n-1)S^2, sigma^2) ~  chi^2(n-1)
$

$
 frac(overline(X)- mu, frac(sigma, sqrt(n))) ~ t(n-1)
$

现在我们再限定样本 $X_(1 ~ n_1),Y_(1 ~ n_2)$ 分别来自正态分布 $N( mu_1, sigma_1^2),N( mu_2, sigma_2^2)$ 且相互独立，这两组样本的样本均值和样本方差分别记为 $ overline(X), overline(Y),S_1^2,S_2^2$ 。那么：

$
 frac(S_1^2/S_2^2, sigma_1^2/ sigma_2^2) ~ F(n_1-1,n_2-1)
$

而当 $ sigma_1^2= sigma_2^2= sigma^2$ 时，记 $S_W^2= frac((n_1-1)S_1^2+(n_2-1)S_2^2, n_1+n_2-2)$ ，还有：

$
 frac(( overline(X)- overline(Y))-( mu_1- mu_2), S_w dot sqrt( frac(1, n_1)+ frac(1, n_2))) ~ t(n_1+n_2-2)
$

