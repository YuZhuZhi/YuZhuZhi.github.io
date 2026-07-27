#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#show: template.with(
    title: "离散数学（三）——集合与计数",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


= 离散数学（三）——集合与计数

= 一、集合的基本计算

#tufted.definition[集合族][
假设有两个集合 $A,B$，以及一个集合族 $cal(A)$。所谓集合族，是指一个以集合为元素的集合。
]

== 1.集合交

两个集合的*交*记为 $A inter B$ ，其中的元素满足：

$
A inter B= { x|x in A  and x in B  }
$

也即元素需要同时属于这两个集合。

一个*集合族*具有*广义交*，记为 $ inter.big cal(A)$ ，定义如下：

$
 inter.big cal(A)= {x| forall S(S in cal(A) -> x in S) }
$

在常见的情况下，集合族表示为 $ cal(A)= {A_1,A_2,...,A_n }$ ，此时可以写为：

$
 inter.big cal(A)= inter.big_(i=1)^n A_i=A_1 inter A_2 inter ... inter A_n
$

集合交显然具有交换律、结合律、幂等律：

$
A inter B=B inter A
$

$
(A inter B) inter C=A inter (B inter C)
$

$
A inter A=A
$

同时，集合之交与子集的关系有：

$
A inter B subset.eq A quad, quad A inter B subset.eq B
$

$
C subset.eq A inter B quad "当且仅当" quad C subset.eq A and C subset.eq B
$

== 2.集合并

两个集合的*并*记为 $A inter B$ ，其中的元素满足：

$
A union B= { x|x in A  or x in B  }
$

也即元素只需属于这两个集合中的某一个即可。

一个*集合族*具有*广义并*，记为 $ union.big cal(A)$ ，定义如下：

$
 union.big cal(A)= {x| exists S(S in cal(A) and x in S) }
$

在常见的情况下，集合族表示为 $ cal(A)= {A_1,A_2,...,A_n }$ ，此时可以写为：

$
 union.big cal(A)= union.big_(i=1)^n A_i=A_1 union A_2 union ... union A_n
$

集合交显然具有交换律、结合律、幂等律：

$
A union B=B union A
$

$
(A union B) union C=A union (B union C)
$

$
A union A=A
$

同时，集合之交与子集的关系有：

$
A subset.eq A union B quad, quad B subset.eq A union B
$

$
A inter B subset.eq C quad "当且仅当" quad A subset.eq C and B subset.eq C
$

== 3.集合差与补

两个集合的*差*记为 $A-B$ ，其中的元素满足：

$
A-B= { x|x in A  and x in.not B  }
$

集合差显然是不满足交换律、结合律、幂等律的。在集合差的基础上，可以引出集合补的定义。全集 $U$ 与集合 $A$ 的差称为集合 $A$ 的*绝对补*，一般简称为*补*，记为 $ overline(A)$ ：

$
 overline(A)= {x|x in.not A }
$

集合差满足下述等式：

$
(A-B)-C=(A-C)-B=(A-C)-(B-C)
$

== 4.集合对称差

集合的*对称差*是将两个集合的并剔除掉其集合交之后的集合，记为 $A plus.o B$ ：

$

    A plus.o B&=(A union B)-(A inter B)\
    &=(A-B) union (B-A)\
    &= {x|(x in A and x in.not B) or(x in.not A and x in B) }

$

集合的对称差显然满足交换律、结合律，即：

$
A plus.o B=B plus.o A
$

$
(A plus.o B) plus.o C=A plus.o (B plus.o C)
$

== 5.幂集

一个集合 $A$ 的*幂集*是一个*集合族*，记为 $ \u{2118}(A)$ 或 $2^A$ 。集合 $A$ 的*幂集*中的元素是集合 $A$ 的所有子集，即：

$
 \u{2118}(A)= {S|S subset.eq A }
$

这意味着对于任何集合来说，*空集及其本身都是其幂集的元素*(注意是*元素*不是子集)，空集 $ diameter$ 这个*元素*需要*显式*地写出来。比如集合 $A= {1,2,3 }$ ，其幂集是：

$
 \u{2118}(A)= { diameter, {1 }, {2 }, {3 }, {1,2 }, {1,3 }, {2,3 }, {1,2,3 } }
$

空集是一个特殊的集合，关于它有一些注意事项：

$
 \u{2118}( diameter)= { diameter } quad, quad  \u{2118}( \u{2118}( diameter))= { diameter, { diameter } }
$

$
 diameter subset.eq \u{2118}( diameter) quad, quad diameter in \u{2118}( diameter)
$

$
 { diameter } subset.eq \u{2118}( diameter) quad, quad { diameter } in.not \u{2118}( diameter)
$

$
 { diameter } subset.eq \u{2118}( \u{2118}( diameter)) quad, quad { diameter } in \u{2118}( \u{2118}( diameter))
$

$
 { { diameter } } subset.eq \u{2118}( \u{2118}( diameter)) quad, quad { { diameter } } in.not \u{2118}( \u{2118}( diameter))
$

可以看到在空集的幂集中，“属于”比“子集”要严格得多。

*幂集运算会保持子集关系*，这是说若 $A subset.eq B$ ，那么 $ \u{2118}(A) subset.eq  \u{2118}(B)$ 。

另外，对集合 $A$ 的幂集使用*广义并*，可以使其恢复为集合 $A$ 。这是因为集合本身必是幂集的元素，而幂集中的其他元素都是这个集合的子集：

$
 union.big \u{2118}(A)=A
$

#tufted.remark[为什么幂集可以记作 $2^A$？][
用 $abs(A)$ 表示集合中的元素个数。生成 $A$ 的幂集时，可以用二进制串标记每个元素是否出现：不出现记为 $0$，出现记为 $1$。

例如 $A={1,2,3}$ 时，二进制串 $001$ 对应子集 ${3}$，$000$ 对应空集。遍历全部长度为 $abs(A)$ 的二进制串，恰好生成 $A$ 的所有子集。因此：
$
abs(\u{2118}(A))=abs(2^A)=2^(abs(A))
$
]

== 6.划分

将一个集合 $A$ 划分为几个互不相交的部分，每个部分自成一个集合，那么这些集合就可以形成一个集合族，称为 $A$ 的*划分*，记为 $ cal(F)$ 。划分中的每一个集合称为一个*划分块*。显然地有：

划分中的元素——是一个集合——不是空集，即任意 $S in  cal(F)$ 都有 $S !=  diameter$ ；划分中的任意两个元素都不相交，即交集为空集： $S_1 inter S_2= diameter$ ；划分的各个部分可以合成为原集合，也就是划分的广义并为原集合本身： $ union.big cal(F)=A$ 。

#html.hr()

= 二、集合等式与子集关系

== 1.集合等式

集合运算与逻辑运算间极其相似。集合与可以看做逻辑与，集合并可以看做逻辑或，集合补可以看做逻辑非，全集可以看做真，空集可以看做假。在此基础上，我们可以给出关于集合的基本等式：

(1)*同一律*

$
A inter U=A
$

$
A union  diameter=A
$

(2)*零律*

$
A union U=U
$

$
A inter  diameter= diameter
$

(3)*矛盾律*

$
A inter overline(A)= diameter
$

(4)*排中律*

$
A union overline(A)=U
$

(5)*双重否定律*

$
 overline( overline(A))=A
$

(6)*幂等律*

$
A inter A=A
$

$
A union A=A
$

(7)*交换律*

$
A inter B=B inter A
$

$
A union B=B union A
$

(8)*结合律*

$
(A inter B) inter C=A inter (B inter C)
$

$
(A union B) union C=A union (B union C)
$

(9)*分配律*

$
A inter(B union C)=(A inter B) union(A inter C)
$

$
A union(B inter C)=(A union B) inter(A union C)
$

(10)*吸收律*

$
A inter(A union B)=A
$

$
A union(A inter B)=A
$

(11)*德摩根律*

$
 overline(A inter B)= overline(A) union overline(B)
$

$
 overline(A union B)= overline(A) inter overline(B)
$

(12)*集合差等式*

$
A-B=A inter overline(B)
$

(13)*相对德摩根律*

$
A-(B inter C)=(A-B) union(A-C)
$

$
A-(B union C)=(A-B) inter(A-C)
$

其中，相对德摩根律有一点分配律的样子，但需要注意相对德摩根律会使交和并互换。

== 2.子集关系

子集关系其实已经在之前陈述过，这里再统一说明一次：

(1)*集合交*：

两个集合的交集必是两个集合的子集：

$
A inter B subset.eq A quad, quad A inter B subset.eq B
$

两个集合的交集的子集必是两个集合的子集：

$
C subset.eq A inter B quad "当且仅当" quad C subset.eq A and C subset.eq B
$

交运算保持子集关系：

$
A subset.eq B -> A subset.eq(A inter B)
$

因此可用下式判断子集关系：

$
A subset.eq B quad "当且仅当" quad A inter B=A
$

(2)*集合并*：

两个集合必是两个集合的并集的子集：

$
A subset.eq A union B quad, quad B subset.eq A union B
$

两个集合的并集是另一集合的子集，则两个集合必是另一集合的子集：

$
A inter B subset.eq C quad "当且仅当" quad A subset.eq C and B subset.eq C
$

并运算保持子集关系：

$
A subset.eq B -> A subset.eq(A union B)
$

因此可用下式判断子集关系：

$
A subset.eq B quad "当且仅当" quad A union B=B
$

(3)*集合差*：

两集合之差必是前一个集合的子集：

$
A-B subset.eq A
$

因此可用下式判断子集关系：

$
A subset.eq B quad "当且仅当" quad A-B= diameter
$

这实际等价于：

$
A subset.eq B quad "当且仅当" quad overline(B) subset.eq overline(A)
$

(4)*幂集*：

幂集运算保持子集关系：

$
A subset.eq B ->  \u{2118}(A) subset.eq  \u{2118}(B)
$

两个集合的幂集之并，是两个集合之并的幂集的子集(反之则不一定)：

$
 \u{2118}(A) union \u{2118}(B) subset.eq \u{2118}(A union B)
$

两个集合之交的幂集，是两个集合的幂集之交：

$
 \u{2118}(A inter B)= \u{2118}(A) inter \u{2118}(B)
$

#html.hr()

= 三、计数

现在我们讨论集合中元素个数的问题，也就是组合数学中的计数问题。

== 1.加法原理

对于集合 $A$ ，有的时候给出它的一个划分 $ cal(F)= {A_1,A_2,...,A_n }$ 会更简单，那么 $A$ 中的元素个数就是划分中的所有集合中元素个数之和，即：

$
abs(A)=abs(A_1)+abs(A_2)+...+abs(A_n)
$

== 2.乘法原理

假设有集合 $A_1,A_2,...,A_n$ ，那么由这些集合的笛卡尔积形成的集合 $A=A_1 times A_2 times ... times A_n$ 中的元素是一个 $n$ 元组 $ chevron.l a_1,a_2,...,a_n chevron.r$ ，那么能生成的 $n$ 元组个数，也就是 $A$ 中元素的个数是：

$
abs(A)=abs(A_1) times abs(A_2) times ... times abs(A_n)
$

== 3.减法原理

在任意有穷集的情况下，两个集合 $A,B$ 之间有：

$
abs(A-B)=abs(A)-abs(A inter B)
$

在 $B subset.eq A$ 的特殊情况下上式就是减法原理：

$
abs(A)=abs(U)-abs(overline(A))=abs(U)-abs(U-A)
$

这也可以表述为：已知 $A subset.eq U$ ，那么为了得到 $A$ 的元素个数，显然可以通过从全集中剔除掉不属于 $A$ 的元素来计数。

== 4.除法原理

假设有两个集合 $A,B$ ，对任意 $A$ 中元素总有 $k$ 个 $B$ 中元素与之对应，那么显然有：

$
abs(A)=abs(B)/m
$

在特殊情况下，也就是一一对应的情况，那么就有：

$
abs(A)=abs(B)
$

== 5.容斥原理

最简单的情况下，两个集合 $A,B$ 的容斥原理是：

$
abs(A union B)=abs(A)+abs(B)-abs(A inter B)
$

三个集合时：

$
abs(A union B union C)=abs(A)+abs(B)+abs(C)-abs(A inter B)-abs(A inter C)-abs(B inter C)+abs(A inter B inter C)
$

当然也可以进一步扩展为 $n$ 个集合的情况：

$

      abs(union.big_(i=1)^n A_i)&=abs(A_1 union A_2 union ... union A_n)\
    &= sum_(i=1)^n abs(A_i)- sum_(1 <= i < j <= n) abs(A_i inter A_j)+\
    & quad sum_(1 <= i < j < k <= n) abs(A_i inter A_j inter A_k)-...+(-1)^(n-1) abs(A_1 inter A_2 inter ... inter A_n)

$

== 6.鸽笼原理

我们直接介绍广义鸽笼原理。若要将 $N$ 个物品放入 $k$ 个盒子，那么至少有一个盒子至少有 $ ceil(N/k)$ 个物品。将这个数称为最小容量。因此：

$
"最小容量"= ceil("物品数"/"盒子数")
$

$
"物体数最小值"=("最小容量"-1) times "盒子数"+1
$

$
"盒子数最大值"= floor(("物体数"-1)/("最小容量"-1))
$
