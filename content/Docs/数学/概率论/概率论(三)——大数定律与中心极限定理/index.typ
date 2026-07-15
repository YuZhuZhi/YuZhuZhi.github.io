#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#show: template.with(
    title: "概率论（三）——大数定律与中心极限定理",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


= 概率论（三）——大数定律与中心极限定理

#tufted.full-width[
    #image("header.jpg")
]

= 一、弱大数定律

假设变量 $X_1,X_2,...$ 相互独立、且服从同一分布，那么记其期望为 $E(X_i)= mu$ 。作前 $n$ 个变量的算术平均 $ frac(1, n) sum X_i$ ，那么对于任意小的正数 $ epsilon.alt$ ，下式成立：

$
  lim_(n -> infinity)P ( abs(frac(1, n) sum_(i=1)^(n) X_i - mu)< epsilon.alt )=1
$

这是在说，当变量个数足够多的时候，它们的算术平均就会趋近于它们所服从分布的期望。

#html.hr()

= 二、伯努利大数定律

伯努利大数定律基于弱大数定律推出。假设 $f_A$ 表示在 $n$ 次试验中 $A$ 事件发生的次数，而 $A$ 事件发生的概率记为 $p$ 。那么对于任意小的正数 $ epsilon.alt$ ，下式成立：

$
  lim_(n -> infinity)P ( abs(frac(f_A, n)-p)< epsilon.alt )=1
$

这等价于：

$
  lim_(n -> infinity)P ( abs(frac(f_A, n)-p) >= epsilon.alt )=0
$

不难发现 $ frac(f_A, n)$ 就是指 $A$ 事件发生的*频率*。因此这个定律在说，当实验次数足够多的时候，可以用频率逼近概率。

#html.hr()

= 三、独立同分布的中心极限定理

接下来的内容都属于*中心极限定理*，大意是某些条件下的随机变量之和会趋于正态分布。实际上，这些内容的关键在于将变量标准化。

首先介绍*独立同分布*的中心极限定理。依据名字，假设变量 $X_1,X_2,...$ 相互独立、且服从同一分布，记其期望为 $E(X_i)= mu$ 、方差为 $D(X_i)= sigma^2$ 。那么对于*随机变量之和* $ sum_(i=1)^(n) X_i$ ，其具有标准化变量：

$
Y_n= frac(sum_(i=1)^(n) X_i-E (  sum_(i=1)^(n) X_i  ), sqrt(D (   sum_(i=1)^(n) X_i  )))= frac(sum_(i=1)^(n) X_i-n mu, sqrt(n) sigma)
$

而这个标准化变量在 $n -> infinity$ 时，趋近于标准正态分布：

$
  lim_(n -> infinity)F_n(x)= Phi(x)
$

$
Y_n= frac(sum_(i=1)^(n) X_i-n mu, sqrt(n) sigma) ~ N(0,1)
$

当然，我们也可以对 $Y_n$ 的分子分母同时除以 $n$ ，那么此时的研究对象就是*随机变量之均值* $ overline(X)= frac(1, n) sum_(i=1)^(n) X_i$ ，同样下式成立：

$
 frac(overline(X)- mu, sigma/ sqrt(n)) ~ N(0,1) quad, quad overline(X) ~ N( mu, sigma^2/n)
$

这同样印证了上面的*弱大数定律*。

#html.hr()

= 四、李雅普诺夫定理

假设变量 $X_1,X_2,...$ 相互独立(注意这里不要求服从同一分布)，记其期望为 $E(X_i)= mu_i$ 、方差为 $D(X_i)= sigma^2_i$ 。又记其方差之和为 $B_n^2= sum_(i=1)^(n)  sigma^2_i$ ，若存在正数 $ delta$ 使得下式成立：

$
  lim_(n -> infinity) frac(sum_(i=1)^(n)E(abs(X_k- mu_k)^(2+ delta)), B_n^(2+ delta))=0
$

那么*随机变量之和* $ sum_(i=1)^(n) X_i$ 的标准化变量在 $n -> infinity$ 时会趋近于正态分布：

$
Z_n= frac(sum_(i=1)^(n) X_i-E (  sum_(i=1)^(n) X_i  ), sqrt(D (   sum_(i=1)^(n) X_i  )))= frac(sum_(i=1)^(n) X_i- sum_(i=1)^(n)  mu_i, B_n) ~ N(0,1)
$

#html.hr()

= 五、棣莫弗-拉普拉斯定理

现在我们在二项分布的条件下应用独立同分布的中心极限定理。假设变量 $ eta_n ~ b(n,p)$ ，也即假设 $X_i ~ b(1,p), eta_n= sum X_i$ ，那么 $ eta_n$ 的标准化变量在 $n -> infinity$ 的情况下趋近于正态分布：

$
Y_n= frac(sum_(i=1)^(n) X_i-n mu, sqrt(n) sigma)= frac(eta_n-n p, sqrt(n p(1-p))) ~ N(0,1)
$

这称为*棣莫弗-拉普拉斯定理*。
