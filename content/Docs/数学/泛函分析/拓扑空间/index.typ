#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted, overline
#show: template.with(
    title: "泛函分析（二）——拓扑空间",
    description: "",
)

#let frasig(x) = $frac(#x, 1 + #x)$
#let miabs(x, y, idx) = $abs(attach(#x, b: #idx) - attach(#y, b: #idx))$
#let close(x) = $overline(#x)$

= 泛函分析（二）——拓扑空间

= 一、

#tufted.definition[拓扑空间][
  设 $X$ 是任一集，$tau$ 是 $X$ 的子集构成的集族，其满足条件：
  + $X$ 与 $emptyset$ 属于 $tau$；
  + $tau$ 中任意个集的并仍属于 $tau$；
  + $tau$ 中任意有穷个集的交仍属于 $tau$。
  则称 $tau$ 为 $X$ 上的一个*拓扑*，称 $(X, tau)$ 为一个*拓扑空间*，不混淆时可简记为 $X$。凡是 $tau$ 中的集称为*开集*。
]

在同一集 $X$ 上，可以定义不同的拓扑，例如 $tau_(1), tau_(2)$。如果 $tau_(1) subset tau_(2)$，则称 $tau_(1)$ 比 $tau_(2)$ *弱*，或 $tau_(2)$ 比 $tau_(1)$ *强*。例如，$tau_(0) = {X, emptyset}$ 是所有拓扑中最弱的拓扑，而 $tau_(infinity)$ 即 $X$ 的幂集
#footnote[即 $X$ 所有子集构成的集族，可见于#link("../../离散数学/集合与计数")[集合与计数]。]
是最强的拓扑。

若从 $X$ 中选取了子集 $A subset X$，那么取 $tau_(A) = {A inter G : G in tau}$ 即是 $A$ 上的一个拓扑，称为*诱导拓扑*或*相对拓扑*。并称 $(A, tau_(A))$ 为 $(X, tau)$ 的*子空间*。






