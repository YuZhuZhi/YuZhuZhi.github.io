#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted, overline
#show: template.with(
    title: "泛函分析（一）——距离空间",
    description: "",
)

#let frasig(x) = $frac(#x, 1 + #x)$
#let miabs(x, y, idx) = $abs(attach(#x, b: #idx) - attach(#y, b: #idx))$
#let close(x) = $overline(#x)$

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

将定义中的 $<$ 改为 $<=$，就非常自然地得到了*闭球*，记为 $close(B)(x_0, r)$。

显然，只要一个集能够被一个开球或闭球完全围住，那么该开球或闭球就划定了这个集的上下界，即有界。因此：
#tufted.definition[有界集][
  设 $(X, d)$ 是一个距离空间，$A subset X$。若存在开球 $B(x_0, r)$，使得
  $
    A subset B(x_0, r),
  $
  则称 $A$ 是*有界集*。
]

反过来，如果要判定某个点是否在某个集的内部，就可用过开球是否是集的子集来判定：
#tufted.definition[内点][
  设 $A subset (X, d)$，$x in A$。若存在开球 $B(x, r)$，使得
  $
    B(x, r) subset A,
  $
  则称 $x$ 是 $A$ 的一个*内点*。
]
因此，内点必然不会在集的边界上。有了内点的概念，就可以进一步定义*开集*，思想是简单的：既然开集不包含自己的边界，那么开集中的每一个点都是内点：
#tufted.definition[开集][
  设 $A subset (X, d)$。若 $A$ 中的每一个点都是 $A$ 的内点，则称 $A$ 是一个*开集*。
]
#tufted.corollary[][
  每个开球都是一个开集。
]

那么要如何判定一个集的内部？我们首先使用开子集的并集来定义*内部*：
#tufted.definition[内部][
  设 $A subset (X, d)$。所有 $A$ 的开子集的并集称为 $A$ 的*内部*，记为 $A^0$。
]
但这种定义太诘屈聱牙，不如换一种说法：
#tufted.corollary[][
  $A$ 的内部 $A^0$ 是 $A$ 的所有内点的集合。
  #footnote[另一方面，$A^0$ 是开集，且是包含在 $A$ 中的最大开集。]
]

接下来就可以进一步放宽限制，定义*邻域*：
#tufted.definition[邻域][
  空间中的任一点 $x$，包含 $x$ 的任一开集称为 $x$ 的一个*邻域*。

  开球，或开集 $B(x, r)$ 称为 $x$ 的一个*球邻域*。
]



#tufted.theorem(label: <theo:开集的性质>)[开集的性质][
  设 $(X, d)$ 是一个距离空间。则：
  1. 空集 $emptyset$ 与全空间 $X$ 都是开集；
  2. 任意多个开集#footnote[指 $X$ 中的开集，下同]的并仍然是开集；
  3. 有限多个开集的交仍然是开集。
]

#tufted.definition[接触点与闭包][
  若 $A subset (X, d)$，$x in X$。对任意 $epsilon > 0$，都有
  $
    B(x, epsilon) inter A != emptyset,
  $
  则称 $x$ 是 $A$ 的一个*接触点*。
  
  而所有 $A$ 的接触点的集合称为 $A$ 的*闭包*，记为 $close(A)$。
]
通俗地说，只要以该点为球心的开球中总有$A$ 中的点，则该点就是接触点。这颇有一种从外向内的感觉，当某点从外靠近 $A$ 时，到达边界时就使判定条件为真了，且继续向内时条件也总为真。即 $A$ 中的点都是接触点；除此之外，$A$ 的边界上的点也是接触点。以开集为例，它的闭包就是它本身并上它的边界。

另一方面，如果改为从内向外，就有*极限点*的概念：
#tufted.definition[极限点][
  若 $A subset (X, d)$，$x in X$。对任意 $epsilon > 0$，都有
  $
    B(x, epsilon) inter A - {x} != emptyset,
  $
  则称 $x$ 是 $A$ 的一个*极限点*#footnote[有时也称为*聚点*]。
]
通俗地说，极限点与接触点的判定条件之间，只有唯一一个区别：开球是否是_去心的_。因此，极限点必然是接触点，而接触点不一定是极限点。而那些不是极限点的接触点，称为*孤立点*
#footnote[具体例子如 $(1, 2) union {0}$，其中 $0$ 是孤立点，$[1, 2]$ 是极限点。]
，这一概念与极限点是互斥的，即必然有 $"极限点" inter "孤立点" = emptyset$，$"接触点" = "极限点" union "孤立点"$。

#tufted.theorem[闭包的性质][
  设 $A, B subset (X, d)$，则有：
  1. $A subset close(A)$；
  2. $close(close(A)) = close(A)$；
  3. $close(A union B) = close(A) union close(B)$；
  4. $close(emptyset) = emptyset$；
  5. 闭包 $close(A)$ 是闭集，且是包含 $A$ 的最小闭集。
]

如果某个集等于它自己的闭包，那么这个集就是*闭集*。闭集具有以下性质：
#tufted.theorem[闭集的性质][
  设 $(X, d)$ 是一个距离空间。则：
  1. 空集 $emptyset$ 与全空间 $X$ 都是闭集；
  2. 任意多个闭集的交仍然是闭集；
  3. 有限多个闭集的并仍然是闭集。
]
可以与 @theo:开集的性质 对照，可以发现全空间与空集都既是开集又是闭集#footnote[既是开集又是闭集的集不是唯二的，而是受空间结构的影响。]。因此，开集与闭集的概念不是互斥的。


== 3.极限与收敛


