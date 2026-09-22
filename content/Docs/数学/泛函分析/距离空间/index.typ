#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#show: template.with(
    title: "泛函分析（一）——距离空间",
    description: "",
)

#let frasig(x) = $frac(#x, 1 + #x)$
#let miabs(x, y, idx) = $abs(attach(#x, b: #idx) - attach(#y, b: #idx))$

= 泛函分析（一）——距离空间

= 一、距离空间

#tufted.definition[距离空间][
  在任一非空集合 $X$ 中，若任意两个点 $x, y in X$ 都有一个实数 $d(x, y)$ 与之对应，并且满足以下条件：
  1. 非负性与同一性：$d(x, y) >= 0$；且 $d(x, y) = 0$ 当且仅当 $x = y$；
  2. 对称性：$d(x, y) = d(y, x)$；
  3. 三角不等式：$d(x, z) <= d(x, y) + d(y, z)$。
  则称 $d(x, y)$ 为 $X$ 中的一个*距离*； $(X, d)$ 是一个*距离空间*，不引起混淆的情况下可以简记为 $X$。
]

这些距离的性质是符合我们在经典数学中对距离的直觉理解的。以下给出一些典型距离空间。

== 1.典型距离空间

欧几里得空间 $bb(R)^(n)$，它是 $n$ 元实数组的全体。其距离定义为
$
  d(x,y) = sqrt(sum_(k=1)^(n) (x_i - y_i)^2),
$
其中 $x = (x_1, x_2, ..., x_n)$，$y = (y_1, y_2, ..., y_n)$。

$C[a,b]$ 是闭区间 $[a,b]$ 上的连续函数的全体。其距离定义为
$
  d(x,y) = max_(t in [a,b]) |x(t) - y(t)|,
$
其中 $x, y in C[a,b]$。

$s$ 是所有实数列 $x = {x_k} = (x_1, x_2, ..., x_n, ...)$ 的全体。其距离定义为
$
  d(x,y) = sum_(k=1)^(infinity) frac(1, 2^k) frasig(miabs(x, y, k)),
$
其中 $x = {x_k}$，$y = {y_k}$。

设 $E subset bb(R)$ 是一个勒贝格可测集，且 $0<m(E)<infinity$。$E$ 上几乎处处有穷的可测函数全体记为 $S$，定义距离为
$
  
  d(x,y) = integral_E frasig(miabs(x, y, t)) d t.
$

离散空间 $D$ 中，定义距离为
$
  d(x,y) = cases(
    0"," quad& x = y ,
    1"," & x eq.not y 
  )
$

== 2.球、集与领域

既然在空间中已经有了距离的概念，那么很自然就可以想到继续在距离空间中定义与区间类似的“关于某一点与某点距离”的概念。

首先定义*开球*：
#tufted.definition[开球][
  设 $(X, d)$ 是一个距离空间，$x_0 in X$，$r > 0$ 是实数。定义
  $
    B(x_0, r) = {x in X : d(x, x_0) < r}
  $
  为以 $x_0$ 为中心、$r$ 为半径的*开球*#footnote[在教材中，使用 $S(x_0, r)$ 表示开球]。
]

将定义中的 $<$ 改为 $<=$，就非常自然地得到了*闭球*，记为 $overline{B}(x_0, r)$。

显然，只要一个集能够被一个开球或闭球完全围住，那么该开球或闭球就划定了这个集的上下界，即有界。因此：
#tufted.definition[有界集][
  设 $(X, d)$ 是一个距离空间，$A subset X$。若存在开球 $B(x_0, r)$，使得
  $
    A subset B(x_0, r),
  $
  则称 $A$ 是*有界集*。
]



== 3.极限与收敛


