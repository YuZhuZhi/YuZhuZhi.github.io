#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#show: template.with(
    title: "概率论（二）——二维随机变量",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


= 概率论（二）——二维随机变量

#tufted.full-width[
    #image("header.jpg")
]

= 一、二维随机变量

对于同一个样本空间，不同的随机变量可能衡量不同的方面。但因为这些随机变量都来自于同一个样本空间，它们之间极有可能存在某些联系。在最简单的情况下，取两个随机变量 $X,Y$ ，它们构成一个随机变量 $(X,Y)$ ，这个整体称为*二维随机变量*。

== 1.联合分布函数

类似于一维随机变量中的情况，无论离散抑或连续，都能用分布函数来描述概率。对于二维随机变量，其分布函数定义为：

$
F(x,y)=P((X <= x) inter(Y <= y))=P(X <= x,Y <= y)
$

称为随机变量 $X$ 和 $Y$ 的*联合分布函数*。例如利用之计算如下概率：

$
P(x_1<X <= x_2,y_1<Y <= y_2)=F(x_2,y_2)-F(x_1,y_2)-F(x_2,y_1)+F(x_1,y_1)
$

与一维随机变量中一样，联合分布函数是关于 $x$ 或 $y$ 的非严格递增的非负函数。并且：

$
F(x,- infinity)=F(- infinity,y)=F(- infinity,- infinity)=0   F(+ infinity,+ infinity)=1
$

当然，在离散型二维随机变量的情况下，我们会更常以离散的形式 $P(X=x_i,Y=y_j)=p_(i j)$ 、或表格的形式来给出分布律，此时称为*联合分布律*。于是根据联合分布函数的定义，离散型二维随机变量的联合分布函数可以从联合分布律中求出：

$
F(x,y)=  sum_(x_i <= x) sum_(y_j <= y)p_(i j)
$

== 2.联合概率密度

与一维随机变量类似，将离散化为连续，就能得到连续型的概率密度函数。将上式化为黎曼积分：

$
F(x,y)=  integral_(- infinity)^(y) integral_(- infinity)^(x)f(u,v)  d u d v
$

函数 $f(x,y)$ 就称为随机变量 $X$ 和 $Y$ 的*联合概率密度*。在连续的情况下，上式连续分别对 $X$ 和 $Y$ 做偏导即得：

$
f(x,y)= frac(partial^2 F(x,y), partial x partial y)
$

而由概率的*归一性*，应有：

$
  integral_(- infinity)^(+ infinity) integral_(- infinity)^(+ infinity)f(x,y)   d x d y=F(+ infinity,+ infinity)=1
$

== 3.边缘分布函数

联合分布函数综合考量了两个变量间的联系，但有时我们希望只考察其中一个变量。从联合分布函数可以轻松地得到各变量自身的分布函数：

$
F_(X)(x)=P(X <= x)=P(X <= x,Y <= + infinity)=F(x,+ infinity)
$

同理 $F_(Y)(y)=F(+ infinity,y)$ ，即只需要在联合分布函数中令其余变量趋于正无穷即可。上述的符号 $F_(X)(x),F_(Y)(y)$ 称为各自变量的*边缘分布函数*。

而对于离散型变量，在已知联合分布律的情况下，也有以下两式：

$
P(X=x_i)=  sum_(j=1)^(+ infinity)p_(i j)=p_(i dot)\\
P(Y=y_j)=  sum_(i=1)^(+ infinity)p_(i j)=p_(dot j)
$

其中 $p_(i dot),p_(dot j)$ 称为各自变量的*边缘分布律*。

== 4.边缘概率密度

从*边缘分布函数*出发，我们可以得到*边缘概率密度*。由于：

$
F_(X)(x)=F(x,+ infinity)=  integral_(- infinity)^(x) [ integral_(- infinity)^(+ infinity)f(x,y)   d y ] d x
$

因此中括号中的内容，也可以看成是一种概率密度！我们定义：

$
  f_(X)(x)= integral_(- infinity)^(+ infinity)f(x,y)   d y\\
f_(Y)(y)= integral_(- infinity)^(+ infinity)f(x,y)   d x
$

将 $f_(X)(x),f_(Y)(y)$ 称为各自变量的*边缘概率密度*。

#html.hr()

= 二、条件分布

== 1.离散型的条件分布

由条件概率的定义式，可以非常简单地得到离散型二维随机变量的条件分布。即：

$
P(X=x_i|Y=y_j)= frac(P(X=x_i,Y=y_j), P(Y=y_j))= frac(p_(i j), p_(dot j))
$

同理 $P(Y=y_j|X=x_i)= frac(p_(i j), p_(i dot))$ 。这两条式子分别称为在 $Y=y_j$ ， $X=x_i$ 情况下各自变量的*条件分布律*。

== 2.连续型的条件概率密度

与离散型随机变量具有类比性，可以直接写出两条式子：

$
f_(X|Y)(x,y)= frac(f(x,y), f_(Y)(y)) \
f_(Y|X)(y,x)= frac(f(x,y), f_(X)(x))
$

 $f_(X|Y)(x,y),f_(Y|X)(y,x)$ 分别称为在 $Y=y$ ， $X=x$ 条件下各自变量的*条件概率密度*。

#tufted.remark[连续型条件概率密度的导出][
事实上，由于在连续型随机变量中， $P(X=x)=P(Y=y)=0$ ，是无法直接从 $P(X=x|Y=y)$ 的定义式中直接导出上式的。以 $Y=y$ 为条件为例，我们采取的方法是考虑 $Y$ 在 $[y,y+ epsilon.alt]$ 的极小区间内的概率、及 $X$ 在 $(- infinity,x]$ 内的概率。即：
$
  P(X <= x|y <= Y <= y+ epsilon.alt)= frac(integral_(- infinity)^(x) integral_(y)^(y+ epsilon.alt)f(x,y)   d y d x, integral_(y)^(y+ epsilon.alt)f_(Y)(y)   d y)
$
利用微分的近似式 $f'(x)= frac(d y, d x) =>  d y=f'(x) d x$ ，上式可以化为：
$
  P(X <= x|y <= Y <= y+ epsilon.alt)= frac(epsilon.alt integral_(- infinity)^(x)f(x,y)   d x, epsilon.alt f_(Y)(y))
$
上式的分子分母同时消去小量 $ epsilon.alt$ 之后，由于 $f_(Y)(y)$ 与 $x$ 无关，显然对于分子的积分来说它相当于“常数”，可以直接合并到积分号中：
$
  P(X <= x|y <= Y <= y+ epsilon.alt)= integral_(- infinity)^(x) frac(f(x,y), f_(Y)(y))   d x
$
由形式推断， $ frac(f(x,y), f_(Y)(y))$ 显然是一种概率密度，称为条件概率密度。
]

从*条件概率密度*可以推出*条件分布函数*：

$
F_(X|Y)(x,y)=  P(X <= x|Y=y)= integral_(- infinity)^(x)f_(X|Y)(x|y)   d x\\
F_(Y|X)(y,x)= integral_(- infinity)^(y)f_(Y|X)(y|x)   d y
$

#html.hr()

= 三、变量间的关系

== 1.变量间相互独立

假若二维随机变量 $(X,Y)$ 的联合分布函数恰好可以拆为各自变量的边缘分布函数的乘积，即：

$
F(x,y)=F_(X)(x)F_(Y)(y)
$

那么称随机变量 $X$ 和 $Y$ 是*相互独立的*。这对于离散型随机变量来说，即：

$
P(X=x_i,Y=y_i)=P(X=x_i) dot P(Y=y_i)
$

而对于连续型随机变量来说，即：

$
f(x,y)=f_(X)(x)f_(Y)(y)
$

== 2.协方差与相关系数

在上篇文章#link("数学/概率论/概率论(一)——一维随机变量的分布、期望与方差/")[一维随机变量的分布、期望与方差]中，我们知道两个随机变量之和的方差需要如下计算：

$
D(X+Y)=D(X)+D(Y)+2 "Cov"(X,Y)
$

其中 $"Cov"(X,Y)$ 称为 $X,Y$ 的*协方差*，它本身如下计算：
#tufted.definition[协方差][
$
"Cov"(X,Y)=E[(X-E(X)) dot (Y-E(Y))]=E(X Y)-E(X)E(Y)
$
]
由期望相关内容可知，当 $X,Y$ 相互独立的时候，因 $E(X Y)=E(X)E(Y)$ ，因此此时协方差为 $0$ 。这说明协方差可以刻画变量间的独立性。同时，再定义*相关系数*：
#tufted.definition[相关系数][
$
 rho = frac("Cov"(X,Y), sqrt(D(X)) dot sqrt(D(Y)))
$
]
*相关系数*描述的是两个随机变量间的*线性相关性*(就是线性回归问题中的线性相关性！)。当相关系数为 $0$ 时，称两个变量间*不相关*；当相关系数为 $1$ 时，说明两个变量间一定存在线性关系。

观察发现相关系数的分子就是协方差，这意味着相关系数与协方差若有一者为 $0$ 、则另一者也必为 $0$ (不考虑方差为 $0$ 的情况)。但是，这*不说明独立与不相关有必然联系*！
#footnote[
这其中的关系是：如果两个变量间独立，那么协方差必为 $0$ ，相关系数也必为 $0$ ，因此两个变量间不相关；
但协方差为 $0$ *不代表*两个变量间独立！以离散型为例，根据独立性的定义， $X,Y$ 必须要在每一对任意的取值 $(x_i,y_j)$ 上都满足 $P(X=x_i,Y=y_j)=P(X=x_i) dot P(Y=y_j)$ 才称为相互独立，这是比协方差为 $0$ 要严格得多的条件！
也就是说，变量间相互独立可以推出变量间不相关，但变量间不相关*不能*推出变量间相互独立！
]

#html.hr()

= 四、两个随机变量的函数的分布

这一部分亦是概率论中的一大难点。与一维随机变量的情况相似，只需记住“分布函数是概率与概率密度之间的桥梁”即可。

== 1.$Z=X+Y$的分布

若 $Z=X+Y$ ，那么：

$

    F_(Z)(z)&=P(Z <= z)=  integral.double_(x+y <= z)f(x,y)   d x d y\
    &= integral_(- infinity)^(+ infinity) integral_(- infinity)^(z-y)f(x,y)   d x  d y\
    &=^(x=u-y) integral_(- infinity)^(+ infinity) integral_(- infinity)^(z)f(u-y,y)  d u  d y\
    &= integral_(- infinity)^(z) integral_(- infinity)^(+ infinity)f(u-y,y)   d y  d u

$

两端求导即得：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity)f(z-y,y)   d y
$

在二重积分展开为累次积分时交换积分次序，也可以得到：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity)f(x,z-x)   d x
$

当然，在变量相互独立的情况下，也能拆为：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity)f_(X)(x)f_(Y)(z-x)   d x= integral_(- infinity)^(+ infinity)f_(X)(z-y)f_(Y)(y)   d y
$

== 2.$Z=X Y$的分布

接下来不再演示推导。当 $Z=X Y$ ：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity) frac(1, abs(x))f (x, frac(z, x) )   d x
$

在变量相互独立的情况下：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity) frac(1, abs(x))f_(X)(x)f_(Y) ( frac(z, x) )   d x
$

== 3.$Z=X/Y$的分布

当 $Z= frac(X, Y)$ ：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity)abs(x)f(x, x/z)   d x
$

在变量相互独立的情况下：

$
f_(Z)(z)=  integral_(- infinity)^(+ infinity)abs(x)f_(X)(x)f_(Y)(x/z)   d x
$

== 4.$Z=max{X,Y}$的分布

在这里我们要求 $X,Y$ *相互独立*。当 $Z=max {X,Y }$ ：

$
F_(Z)(z)=F_(X)(z)F_(Y)(z)
$

如果有 $n$ 个相互独立的变量 $X_1,X_2,...,X_n$ ，若 $Z=max {X_1,X_2,...,X_n }$ ：

$
F_(Z)(z)=F_(X_1)(z) dot F_(X_2)(z) dot ... dot F_(X_n)(z)
$

如果这 $n$ 个变量具有*相同的*分布函数，那么：

$
F_(Z)(z)=F_(X)^n(z)
$

== 5.$Z=min{X,Y}$的分布

同样要求 $X,Y$ *相互独立*。当 $Z=min {X,Y }$ ：

$
F_(Z)(z)=1-[1-F_(X)(z)][1-F_(Y)(z)]
$

如果有 $n$ 个相互独立的变量 $X_1,X_2,...,X_n$ ，若 $Z=min {X_1,X_2,...,X_n }$ ：

$
F_(Z)(z)=1-(1-F_(X_1)(z))(1-F_(X_2)(z)) ... (1-F_(X_n)(z))
$

如果这 $n$ 个变量具有*相同的*分布函数，那么：

$
F_(Z)(z)=1-[1-F_(X)(z)]^n
$

#html.hr()

= 五、二维随机变量的期望

严格来说我们要求的并不是“二维随机变量”这个整体的期望，而是“两个随机变量的函数”的期望。假设两个随机变量 $X,Y$ ，它们的联合概率密度是 $f(x,y)$ ，那么由函数生成的一维(连续型)随机变量 $Z=g(X,Y)$ 的期望如下计算：

$
E(Z)=E(g(X,Y))=  integral_(- infinity)^(+ infinity) integral_(- infinity)^(+ infinity)g(x,y)f(x,y)   d x d y
$

与之类似，在离散情况下：

$
E(Z)=E(g(X,Y))=  sum_(i=1)^(+ infinity) sum_(j=1)^(+ infinity)g(x_i,y_j)p_(i j)
$

变量相互独立情况下， $E(X+Y)=E(X)+E(Y) quad, quad E(X Y)=E(X)E(Y)$ 就是依据上述证明。

#html.hr()

= 六、二维正态分布

到目前为止，以上的所有内容都可以推广到 $n$ 维随机变量中。在这里顺便简单介绍多维正态分布中最简单的*二维正态分布*。二维正态分布的概率密度为：

$
f(x,y)= frac(1, 2 pi sigma_1 sigma_2 sqrt(1- rho^2)) dot exp( - frac(1, 2(1- rho^2)) dot ( frac((x- mu_1)^2, sigma_1^2)+ frac((y- mu_2)^2, sigma_2^2)-2 rho dot frac((x- mu_1)(y- mu_2), sigma_1 sigma_2) ) )
$

在这里，显然 $ mu_1, sigma_1, mu_2, sigma_2, rho$ 分别是 $X$ 的期望与方差、 $Y$ 的期望与方差、 $X,Y$ 的相关系数。容易求得各变量的边缘分布函数为：

$
f_(X)(x)= frac(1, sqrt(2 pi) sigma_1)te^(- frac((x- mu_1^2), 2 sigma_1^2)) \
f_(Y)(y)= frac(1, sqrt(2 pi) sigma_2)te^(- frac((y- mu_2^2), 2 sigma_2^2))
$

这显然是各自变量的一维正态分布。由于一维正态分布中不含相关系数 $ rho$ ，显然 $f(x,y) != f_(X)(x)f_(Y)(y)$ ，只有在 $ rho=0$ 即变量不相关的情况下才存在 $f(x,y)= f_(X)(x)f_(Y)(y)$ ，这也说明变量相互独立。
#footnote[这里似乎与之前所说“变量间不相关不能推出变量间相互独立”矛盾？实际上对于二维正态分布来说，*变量间不相关*与*变量间相互独立*确是等价的概念。]

#html.hr()

= 七、矩与协方差矩阵

这部分只是简单的扩展，之于本节而言并不重要。

== 1.矩

首先简单介绍*矩*的概念。在所求量存在的情况下：
#tufted.definition[各阶矩][
(1) $E(X^k)$ 称为 $X$ 的 $k$ *阶原点矩*，简称 $k$ *阶矩*；\
(2) $E((X-E(X))^k)$ 称为 $X$ 的 $k$ *阶中心矩*；\
(3) $E(X^k Y^l)$ 称为 $X$ 和 $Y$ 的 $k+l$ *阶混合矩*；\
(4) $E((X-E(X))^k (Y-E(Y))^l)$ 称为 $X$ 和 $Y$ 的 $k+l$ *阶混合中心矩*。
]
数学期望是一阶原点矩，方差是二阶中心矩，协方差是二阶混合中心矩。

== 2.协方差矩阵

接下来简单给出*协方差矩阵*的概念。假设有 $n$ 维随机变量 $X_1,X_2,...,X_n$ ，那么任意两个变量间的二阶混合中心矩(协方差)记为：

$
c_(i j)="Cov"(X_i,X_j)
$

显然这个 $n$ 维随机变量有 $n times n=n^2$ 个二阶混合中心矩，这可以构成一个 $n$ 阶的方阵，称为*协方差矩阵*，即：

$
bold(C)= mat(
    c_(11) , c_(12) ,  dots , c_(1n);
    c_(21) , c_(22) ,  dots , c_(2n);
     dots.v ,  dots.v ,  dots.down ,  dots.v;
    c_(n 1) , c_(n 2) ,  dots , c_(n n);
)
$

这显然是一个对称矩阵。这样，如果用列向量分别标记随机变量和对应的期望，即：

$
 bold(X)= mat(
    x_1 ;  x_2 ;   dots.v ;  x_n;
) quad, quad
bold(mu)= mat(
     mu_1 ;   mu_2 ;   dots.v ;   mu_n;
)
$

那么 $n$ 维正态分布就能非常简单地记为：

$
f(x_1,x_2,...,x_n)= frac(1, (2 pi)^(frac(n, 2)) dot sqrt(abs(bold(C)))) dot exp( - frac(1, 2)( bold(X)-bold(mu))^T bold(C)^(-1)( bold(X)-bold(mu)) )
$




