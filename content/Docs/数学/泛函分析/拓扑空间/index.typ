#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted, overline
#show: template.with(
    title: "泛函分析（二）——拓扑空间",
    description: "",
)

#let close(x) = $overline(#x)$
#let cB = $cal(B)$

= 泛函分析（二）——拓扑空间

= 一、拓扑

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

在定义中已经说明了开集的概念，接下来就可以进一步引入其他集和点的概念。
- 若 $F subset X$ 是一集，其余集 $C F$ 是开集，那么 $F$ 是*闭集*。
- 设 $x in X$，则每一含 $x$ 的开集称为 $x$ 的*邻域*。
- 若 $x$ 的每一邻域都包含集 $E subset X$ 中的点，称 $x$ 为集 $E$ 的*接触点*。
- 若 $x$ 的每一邻域都包含集 $E subset X$ 中不同于 $x$ 的点，称 $x$ 为集 $E$ 的*极限点*。
- 集 $E$ 的接触点全体称为 $E$ 的*闭包*，记为 $close(E)$。
- 称包含在 $E$ 中的所有开集的并集为 $E$ 的*内部*，记为 $E^(0)$。
显然 $E^(0)$ 是 $E$ 的最大开集，$close(E)$ 是 $E$ 的最小闭集。

#tufted.theorem[闭集基本性质][
  + 全空间 $X$ 及空集 $emptyset$ 是闭集；
  + 任意个闭集的交集是闭集；
  + 任意有穷个闭集的并集是闭集。
]

#line()

= 二、拓扑基

#tufted.definition[拓扑基][
  设 $(X, tau)$ 是一个拓扑空间。若 $cB$ 是 $X$ 的子集族，使得 $X$ 中每一开集可以表示为 #cB 中集的并集，那么称 $cB$ 为 $(X, tau)$ 的*拓扑基*。
]

#tufted.theorem[][
  设 $(X, tau)$ 是一个拓扑空间，$cB$ 是 $X$ 的子集族。则 $cB$ 是 $(X, tau)$ 的拓扑基的充要条件是：
  + 任一点 $x in X$，都存在 $G in cB$ 使得 $x in G$；
  + 若 $x in G_(1) inter G_(2)$，其中 $G_(1), G_(2) in cB$，则存在 $G_(3) in cB$，使得 $x in G_(3) subset G_(1) inter G_(2)$。
]

#tufted.theorem[][
  集族 $cB in tau$ 是给定拓扑 $tau$ 的拓扑基的充要条件是：对任意 $G in tau$ 及每一点 $x in G$，存在 $G_(x) in cB$，使得 $x in G_(x) subset G$。
]

#tufted.corollary[][
  任意距离空间中，所有开球的全体构成空间的拓扑基。
]

若拓扑空间中存在一个由最多可数个集构成的拓扑基，则称该空间具有*可数基*#footnote[或者说，满足第二可数公理。]。具有可数基的距离空间是可分的。

#line()

= 三、连续映射与同胚

#tufted.definition[连续映射][
  设 $X, Y$ 是两个拓扑空间，$f: X -> Y$ 是一个映射，$x_(0) in X$。若对点 $y_(0) = f(x_(0))$ 的任意邻域 $U_(y_(0))$，存在点 $x_(0)$ 的邻域 $V_(x_(0))$，使得 $f(V_(x_(0))) subset U_(y_(0))$，则称 *$f$ 在点 $x_(0)$ 连续*。若 $f$ 在 $X$ 中每一点都连续，则称 $f$ 是*连续映射*。

  拓扑空间到数轴上的连续映射称为*连续函数*。
]

#tufted.theorem[][
  设 $X, Y$ 是两个拓扑空间，$f: X -> Y$，则 $f$ 是连续映射的充要条件是：对 $Y$ 中任意开集 $G$，其原像集 $f^(-1)(G)$ 是 $X$ 中的开集。
]

#tufted.corollary[][
  拓扑空间 $X$ 到拓扑空间 $Y$ 中的映射 $f$ 是连续的的充要条件是：$Y$ 中任意闭集的原像是 $X$ 中的闭集。
]

开集在连续映射下的像不一定是开集。若 $f: X -> Y$ 把 $X$ 中任一开集映为 $Y$ 中的开集，则称 $f$ 是*开映射*。

#tufted.theorem[复合函数的连续性][
  设 $X, Y, Z$ 是三个拓扑空间，$f: X -> Y$，$g: Y -> Z$ 是连续映射，则
  $
    h(x) = g(f(x)), wide (x in X)
  $
  是 $X$ 到 $Z$ 的连续映射。
]

#tufted.definition[同胚映射][
  设 $X, Y$ 是拓扑空间，$f: X -> Y$ 是双射，并且 $f$ 与 $f^(-1)$ 都是连续映射，则称 $f$ 是*同胚映射*。称 $X$ 与 $Y$ 是*同胚的*。
]

等距的两个距离空间是同胚的。

#line()

= 四、分离公理

#tufted.definition[$T_(1)$ 分离公理][
  在拓扑空间 $X$ 中任取 $x, y in X$，$x != y$，若存在 $x$ 的邻域 $U$ 不包含 $y$ 且存在 $y$ 的邻域 $V$ 不包含 $x$，则称 $X$ 满足*$T_(1)$ 分离公理*。
]

#tufted.theorem[][
  拓扑空间 $X$ 是 $T_(1)$ 的充要条件是：$X$ 中任一单点集是闭集。
]

#tufted.definition[$T_(2)$ 分离公理（Hausdorff 分离公理）][
  在拓扑空间 $X$ 中任取 $x, y in X$，$x != y$，若分别存在 $x$ 的邻域 $U$ 与 $y$ 的邻域 $V$，使得 $U inter V = emptyset$，则称 $X$ 是 $T_(2)$ 的，或称 $X$ 是*Hausdorff 空间*。
]

#tufted.definition[$T_(3)$ 分离公理][
  设 $X$ 是 $T_(1)$ 拓扑空间，若任取 $x in X$ 及不包含点 $x$ 的任一闭集 $A$，存在开集 $U, V$ 使得 $x in U, A subset V$ 且 $U inter V = emptyset$，则称 $X$ 是 $T_(3)$ 的。
]

#tufted.definition[$T_(4)$ 分离公理][
  设 $X$ 是 $T_(1)$ 拓扑空间，若任取两个不相交的闭集 $A, B$，存在不相交的开集 $U, V$ 使得 $A subset U, B subset V$，则称 $X$ 是 $T_(4)$ 的，或称为*正规拓扑空间*。
]

任意距离空间都是正规的。

#tufted.definition[距离化][
  设 $X$ 是拓扑空间，若 $X$ 上的拓扑 $tau$ 可由 $X$ 上的某个距离决定，则称 $(X, tau)$ 可*距离化*。
]

如果一个拓扑空间可距离化，那么它必须是正规的；但空间的正规性不保证可距离化。

#line()

= 五、紧性

#tufted.definition[列紧集与列紧空间][
  设 $A$ 是距离空间 $X$ 的子集，若 $A$ 中任意点列必包含一个在 $X$ 中的收敛子列，则称 $A$ 是*列紧集*。若 $X$ 是列紧集，称 $X$ 是*列紧空间*。
]

显然列紧集的子集是列紧的，并且列紧空间是完备的。

#tufted.definition[网与全有界集][
  设 $A, B$ 是距离空间 $X$ 中的点集，$epsilon > 0$。若对每一 $x in A$，存在 $y in B$，使得 $d(x, y) < epsilon$，则称 $B$ 是 $A$ 的一个*$epsilon$ 网*。

  设 $A subset X$，若对任意 $epsilon > 0$，$A$ 有有穷 $epsilon$ 网，则称 $A$ 是*全有界集*。
]

#tufted.theorem[全有界集的性质][
  设 $A$ 是全有界集，那么：
  + $A$ 是有界集；
  + 对于每一 $epsilon > 0$，$A$ 的有穷 $epsilon$ 网可取为 $A$ 的子集；
  + $A$ 是可分的#footnote[因此，如果距离空间是全有界的，则它具有可数基。]。
]

#tufted.theorem[][
  设 $A$ 是距离空间 $X$ 的列紧集，则 $A$ 是全有界集#footnote[一般距离空间中，有界集不一定是全有界集。]；若 $X$ 是完备的，则当 $A$ 是全有界集时，$A$ 必是列紧集。
]

#tufted.theorem[][
  设 $A$ 是距离空间 $X$ 中的子集。$A$ 是紧集的充要条件是：$A$ 是列紧闭集。
]


