#import "@preview/physica:0.9.8": *
// #import "@preview/equate:0.3.3": equate

#import "../../index.typ": template, tufted
#show: template.with(
    title: "量子计算（八）——QAOA算法",
    description: "量子近似优化算法（Quantum Approximate Optimization Algorithm，QAOA）是一种混合量子–经典架构的变分算法，即用经典优化器迭代训练一个含参量子线路，主要用于求解组合优化问题。所谓组合优化问题，典型的如旅行商问题、背包问题等，是在有限且离散的解空间中寻找最优解的优化问题，这一解空间会随着问题规模指数增长，因此一般是NP-hard的。",
)

#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#set math.equation(numbering: "(1)")

#let bH = $bold(cal(H))$
#let bHC = $bold(cal(H))_(cal(C))$
#let bHB = $bold(cal(H))_(B)$
#let gabe = $gamma, beta$
#let bgabe = $bold(gamma), bold(beta)$
#let negbgabe = $-bold(gamma), -bold(beta)$

#let bU = $bold(U)$
#let tdiff = $frac(upright(d), upright(d)t)$

#let EI(content) = $upright(e)^(upright(i) content)$
#let negEI(content) = $upright(e)^(- upright(i) content)$

//-------------------------------------------------------//
#let cancel(body) = context{
  let s = measure(body)
  box({
    body
    place(line(start: (s.width, 0pt), end: (0pt, -s.height), stroke: 0.5pt))
    })
}

//-------------------------------------------------------//

= 量子计算（八）——QAOA算法

#tufted.full-width[
    #image("header.jpg")
]

量子近似优化算法（Quantum Approximate Optimization Algorithm，QAOA）是一种混合量子–经典架构的变分算法，即用经典优化器迭代训练一个含参量子线路，主要用于求解组合优化问题。所谓组合优化问题，典型的如旅行商问题、背包问题等，是在有限且离散的解空间中寻找最优解的优化问题，这一解空间会随着问题规模指数增长，因此一般是NP-hard的，可以给出数学模型为：
$
  min quad & cal(C)(x) \ "s.t." quad & cal(U)(x)>= 0 \ & x in bb(D)
$ <eq-chap9-CombinatorialOptimizationModel>
其中 $cal(C)(x)$ 是代价函数， $cal(U)(x)$ 是约束条件， $bb(D) $ 表示离散空间。在量子算法中，还会进一步要求 $x $ 是二值的。

量子绝热算法（Quantum Adiabatic Algorithm，QAA）指出，通过设计哈密顿量的演化过程，量子系统可以从易制备的初始基态绝热演化至问题哈密顿量的基态，从而获得问题的一个近似解。而QAOA借鉴于这一物理图像，将连续的绝热演化过程，经由Trotter分解处理，离散化为多层的参数化量子门序列，从而在有限的电路深度下近似求解组合优化问题。

QAOA一般要求问题的数学模型要进一步约化到二次无约束二值优化（Quadratic Unconstrained Binary Optimization，QUBO）问题，即要求代价函数 $cal(C)(x)$ 是最高次项不超过2的多项式，变量 $x $ 取值为0或1，并且没有任何约束条件。实际上，QAOA亦可直接应用于多项式无约束二值优化（Polynomial Unconstrained Binary Optimization，PUBO）问题。相较于仅包含二次项的QUBO问题，PUBO问题推广了交互项的阶数，能够编码包含高阶关联的复杂目标函数。本节将从QUBO和PUBO问题的数学模型入手，详细说明QAOA算法的构造步骤与运行原理。

#html.hr()

== 一、伊辛模型，QUBO问题与PUBO问题 <subsec-chap9-伊辛模型.QUBO问题与PUBO问题>

伊辛模型 @Ising1925-Beitrag-zur-Theorie-des-Ferromagnetismus 是统计物理中最具代表性的模型之一，用于研究自旋系统中的相变行为。伊辛模型定义在一个离散格点系综上，系统的总能量由*伊辛哈密顿量*给出：
$
  cal(H) = - J sum_(chevron.l i,j chevron.r) s_(i) s_(j) - h sum_(i) s_(i)
$ <eq-chap9-OriginIsingModel>
其中， $chevron.l i,j chevron.r $ 表示所有相邻格点对的集合； $J $ 为耦合常数，决定自旋之间的相互作用强度和类型；每个格点 $i $ 上的自旋变量 $s_(i)$ 只能取 $+ 1 $ （向上）或 $- 1 $ （向下）两种状态。*自旋变量* $s $ 的取值与计算机中常用的0-1布尔变量 $b $ 不相同，但可以使用 $s = 2 b - 1 $ 相互转换。注意到式 @eq-chap9-OriginIsingModel 中的次数为2，如果该次数能取更大的值，那么称模型为高阶伊辛模型。 在组合优化和量子计算中，许多 NP-hard 问题都可以转化为寻找等效伊辛模型的基态。
QAOA算法由Edward Farhi在2014年提出时 @farhi2014QuantumApproximateOptimizationAlgorithm，就已经用在了有界度数图的最大割问题中。该问题是典型的QUBO问题，即其代价函数具有数学形式：
$
  cal(C)(bold(x)) := bold(x)^(top) bold(Q) bold(x), quad bold(x) in {0,1 }^(n),
$ <eq-chap9-QUBOCostFuncQuadraticForm>
其中问题中有 $n $ 个变量， $bold(x) $ 是一个具有 $n $ 个元素的0-1向量， $bold(Q) $ 是 $n times n $ 的实数矩阵。这显然是一个二次型，但由于对任意二进制变量 $b $ 都有 $b^(2)= b $ ，因此 $bold(Q) $ 的对角线元素在QUBO问题中可以特指一次项系数。有时候式 @eq-chap9-QUBOCostFuncQuadraticForm 会被写成求和的形式：
$
  cal(C)(x) = sum_(i,j = 1 \ i <= j)^(n) Q '_(i j) x_(i) x_(j) + sum_(i = 1)^(n) c_(i) x_(i),
$ <eq-chap9-QUBOCostFuncSumForm>
从而更加方便地转换为伊辛模型。需要注意：
  + 式 @eq-chap9-QUBOCostFuncSumForm 中的 $Q '_(i j)$ 不一定等于式 @eq-chap9-QUBOCostFuncQuadraticForm 中二次型矩阵 $bold(Q) $ 的第 $i $ 行第 $j $ 列元素 $Q_(i j)$ ，而应视 $bold(Q) $ 的形式决定。例如，若 $bold(Q) $ 是对称矩阵，那么 $Q '_(i j)= 2 Q_(i j)$ 。
  + $Q '_(i j)$ 允许 $i = j $ ，这似乎会造成与一次项求和部分的冗余。但允许 $i = j $ 会使之后转换伊辛模型的计算更加简单。事实上，可以令 $Q '_(i i)= 0,c_(i)= Q_(i i)$ 以消除冗余，此时求和号下 $i <= j $ 改为 $i < j $ 不影响结果。

为了将代价函数转换为伊辛模型，只需将布尔变量 $x_(i)$ 转换为自旋变量 $s_(i)$ 。通过代入变换关系 $x_(i) = frac(s_(i) + 1, 2)$ ，即可得到伊辛哈密顿量： /* Begin subequations */
 <eq-chap9-IsingHamiltonianWithConst>
$
  cal(H)(s) &= sum_(i,j = 1 \ i <= j)^(n) frac(Q '_(i j), 4)(s_(i) + 1)(s_(j) + 1) + sum_(i = 1)^(n) frac(c_(i), 2)(s_(i) + 1) \
  & = sum_(i,j = 1 \ i < j)^(n) frac(Q '_(i j), 4) s_(i) s_(j) + sum_(i = 1)^(n) 1/2(c_(i) + sum_(j = 1)^(n)Q '_(i j)) s_(i) + #cancel[$display( sum_(i = 1)^(n) 1/2(c_(i) + sum_(j = 1)^(n)frac(Q '_(i j), 2)) )$].
$ <eq-chap9-IsingHamiltonianWithConstB>

/* End subequations */
由于式 @eq-chap9-IsingHamiltonianWithConstB 的最后一个求和项为常数，不影响优化问题的解，因此常常略去。令 $J_(i j) = - frac(Q '_(i j), 4), h_(i) = - 1/2(c_(i) + sum_(j = 1)^(n)Q '_(i j)) $ ，就成功转化为伊辛哈密顿量：
$
  cal(H)(s) = - sum_(i,j = 1)^(n) J_(i j) s_(i) s_(j) - sum_(i = 1)^(n) h_(i) s_(i) .
$ <eq-chap9-IsingHamiltonianQuadratic>

当实际问题具有约束的时候，一般会通过添加惩罚项的方式将问题转换为QUBO问题。例如式 @eq-chap9-CombinatorialOptimizationModel 所示的原始问题，将会被转化为:
$
  min  cal(C)(x) + lambda cal(P)(x),
$
其中 $cal(P)(x)$ 是约束条件 $cal(U)(x)$ 对应的惩罚函数； $lambda > 0 $ 是任取的惩罚系数，一般不应取太小。表@tab-chap9-约束条件及其对应惩罚函数 给出了一些典型约束条件应转换到的惩罚函数。

#figure(
  caption: [约束条件及其对应惩罚函数],
)[
#table(
    columns: (3),
    align: (left),
    table.hline(),
    [*序号*], [*约束条件*], [*惩罚函数*],
    table.hline(),
    [1], [ $x_(1) + x_(2) <= 1 $ ], [ $x_(1) x_(2)$ ],
    table.hline(),
    [2], [ $x_(1) + x_(2) >= 1 $ ], [ $1 - x_(1) - x_(2) + x_(1) x_(2)$ ],
    table.hline(),
    [3], [ $x_(1) + x_(2) = 1 $ ], [ $1 - x_(1) - x_(2) + 2 x_(1) x_(2)$ ],
    table.hline(),
    [4], [ $x_(1) = x_(2)$ ], [ $x_(1) + x_(2) - 2 x_(1) x_(2)$ ],
    table.hline(),
    [5], [ $x_(1) <= x_(2)$ ], [ $x_(1) - x_(1) x_(2)$ ],
    table.hline(),
    [6], [ $x_(1) + x_(2) + x_(3) <= 1 $ ], [ $x_(1)x_(2) + x_(1)x_(3) + x_(2)x_(3)$ ],
    table.hline(),
)

] <tab-chap9-约束条件及其对应惩罚函数>

以QUBO问题为基础，若不限定代价函数中最高次项的次数，则问题扩展为PUBO问题。此时代价函数可以写为：
$
  cal(C)(x) &= sum_(i_(1))T_(i_(1))x_(i_(1)) + sum_(i_(1) < i_(2))T_(i_(1)i_(2))x_(i_(1))x_(i_(2)) + sum_(i_(1) < i_(2) < i_(3))T_(i_(1)i_(2)i_(3))x_(i_(1))x_(i_(2))x_(i_(3)) + ... \
  &= sum_(delta =(delta_(1),...,delta_(n)) in {0,1 }^(n)) T_(delta)product_(i = 1)^(n)x_(i)^(delta_(i)),
$
其中 $n $ 是变量的数量。通过变量代换、添加约束并转换为惩罚项的方式，PUBO问题总能被归约为QUBO问题。相关算法在文献#cite(<dattani-2019-QuadratizationDiscreteOptimizationQuantum>)中有详尽的总结。利用变换式 $s = 2 x - 1 $ 能将PUBO问题转换为高阶伊辛模型。

#html.hr()

== 二、将问题编码为厄米矩阵

在#ref(<subsec-chap9-伊辛模型.QUBO问题与PUBO问题>)节中已提到，使用自旋变量 $s $ 与布尔变量 $x $ 的变量代换 $s = 2 x - 1 $ 即可将QUBO问题或PUBO问题转换为伊辛模型（包括高阶伊辛模型）。要应用QAOA算法，下一步就是将伊辛模型编码为厄米矩阵。现假设已经得到的伊辛哈密顿量为：
$
  cal(H)(s) = sum_(delta =(delta_(1),...,delta_(n)) in {0,1 }^(n)) h_(delta)product_(i = 1)^(n)s_(i)^(delta_(i)),
$ <eq-chap9-IsingHamiltonianPolynomial>
那么只需做一点改动，即可得到对应的厄米矩阵形式哈密顿量，称为*问题哈密顿量*：
$
  bHC = sum_(delta =(delta_(1),...,delta_(n)) in {0,1 }^(n)) h_(delta)times.o.big_(i = 1)^(n)bold(Z)_(i)^(delta_(i)),
$ <eq-chap9-QuestionHamiltonian>
其中 $bold(Z) $ 即泡利Z矩阵，且 $bold(Z)^(0)= bold(Z)^(2)= bold(I) $ 、 $bold(Z)^(1)= bold(Z) $ ， $bold(Z)_(i)$ 等价于将在第 $i $ 量子比特上作用Z门。之所以这样替换，是因为可以自然地将物理可观测量——自旋沿 $z $ 轴的分量，即泡利 Z 矩阵与自旋变量 $s $ 对应起来。针对问题哈密顿量 $bHC$ ，有以下定理：

#tufted.theorem[问题哈密顿量的特征向量和特征值#cite(<Grange2023-An-introduction-to-variational-quantum-algorithms-for-combinatorial-optimization-problems>)][
  问题哈密顿量 $bHC$ 的特征向量是从 $ket(0)$ 到 $lr(| 2^(n)- 1 chevron.r)$ 的计算基态，且每个特征向量 $ket(x)$ 对应的特征值是代价函数在相应解 $x $ 下的函数值 $cal(C)(x)$ （在不忽略常数项的情况下）。
]

#tufted.proof[
  由于：
  $
    bold(I) = mat(delim: "[", 1, 0 ; 0, 1), quad bold(Z) = mat(delim: "[", 1, 0 ; 0, - 1)
  $
  都是对角矩阵， $times.o.big_(i = 1)^(n)bold(Z)_(i)^(delta_(i))$ 自然也是对角矩阵，相应地求累加后 $bHC$ 还是对角的，故 $bHC$ 的对角元素就是特征值。同时，由于 $bold(I),bold(Z) $ 在计算基下可选 ${ ket(0),lr(| 1 chevron.r) }$ 作为共同特征向量，故任意矩阵 $bold(U) in { bold(I),bold(Z) }^(times.o n)$ 都可选 ${ ket(0),lr(| 1 chevron.r) }^(times.o n)$ 即所有计算基态作为特征向量，进一步地 $bHC$ 作为 ${ bold(I),bold(Z) }^(times.o n)$ 中矩阵的实系数线性组合也能以所有计算基态作为特征向量。

  另一方面，将特征向量 $ket(x)$ 写为二进制形式 $lr(| x_(1)... x_(n) chevron.r)$ 并令 $s_(i)= 2 x_(i)- 1 $ 。一个显然的结果是对于任意 $delta in {0,1 }^(n)$ 有：
  $
    (times.o.big_(i = 1)^(n)bold(Z)_(i)^(delta_(i))) ket(x) =(product_(i = 1)^(n)s_(i)^(delta_(i))) ket(x),
  $
  因为每有一个 $x_(i)= 1 $ 且 $delta_(i)= 1 $ 就会使 $ket(x)$ 乘一次 $- 1 $ 。那么：
  $
    bHC ket(x) =(sum_(delta) h_(delta)times.o.big_(i = 1)^(n)bold(Z)_(i)^(delta_(i))) ket(x) =(sum_(delta) h_(delta)product_(i = 1)^(n)s_(i)^(delta_(i))) ket(x) = cal(H)(s) ket(x).
  $
  在不忽略常数项的情况下， $cal(H)(s) = cal(C)(x)$ ，所以 $bHC ket(x) = cal(C)(x) ket(x)$ ，故 $ket(x)$ 对应的特征值就是相应的代价 $cal(C)(x)$ 。
]

显然一种求解此组合优化问题的方法就是从 $bHC$ 中找到最小的特征值，再以此求出对应特征向量。但必须指出， $bHC$ 是 $2^(n)$ 阶的，因此该方法并没有摆脱指数增长带来的困难。然而另一方面，对于一个哈密顿量，其最小特征值对应的特征向量正是量子系统的基态。因此，量子绝热算法基于量子绝热定理，通过设计一条演化路径，将一个易于制备基态的哈密顿量连续地演化为问题哈密顿量。若演化足够缓慢且满足绝热条件，最终系统将处于问题哈密顿量的基态，此时对该态进行测量，即可得到优化问题的解。而QAOA借鉴量子绝热算法，以参数化量子电路来分段近似模拟绝热演化。

#tufted.theorem[量子绝热定理][
  对于一个缓慢变化的、无简并的哈密顿量，如果系统初始处于其基态或某个瞬时能级的本征态，则系统在随时间演化的过程中将始终保持在相应的瞬时能级态上，而不会跃迁到其他能级。
]

#html.hr()

== 三、分段近似模拟绝热演化

接下来首先给出QAOA的整体结构与电路图，之后再分模块介绍。QAOA的算法过程可以用下式完整表示：
$
  ket(bgabe) = underbrace(U(bHB, beta_(p))U(bHC, gamma_(p)), #text[第$p$层]) ... underbrace(U(bHB, beta_(2))U(bHC, gamma_(2)), "第2层") underbrace(U(bHB, beta_(1))U(bHC, gamma_(1)), "第1层") ket(s),
$
其对应量子电路如图@fig-chap9-QAOAGlobal 所示。其中， $bHC$ 即前文所述的问题哈密顿量， $bHB$ 是*混合哈密顿量*，定义为：
$
  bHB = sum_(i = 1)^(n) bold(X)_(i),
$
$bold(X)_(i)$ 等价于将在第 $i $ 量子比特上作用X门。 $bold(gamma) =(gamma_(1),...,gamma_(p)),thin bold(beta) =(beta_(1),...,beta_(p))$ 分别是包含 $p $ 个角度参数的参数向量，称参数 $p $ 为*深度*。由图@fig-chap9-QAOAGlobal 可知 $ket(s)$ 正是初态 $ket(0)^(times.o n)$ 被作用 $H^(times.o n)$ 之后得到的均匀叠加态 $ket(+)^(times.o n)$ 。而：
$
  U(bold(cal(H)), theta) = upright(e)^(- upright(i) theta bold(cal(H)))
$ <eq-chap9-QAOAUnitaryOperatorDefine>
是一个酉算子，接受一个矩阵和角度作为输入，输出一个酉矩阵。简便起见，将任意一层记为酉算子 $L_(i)(gamma_(i), beta_(i)) = U(bHB, beta_(i))U(bHC, gamma_(i))$ ，所有层记为酉算子 $L(bgabe) = product_(i = p)^(1) L_(i)(gamma_(i), beta_(i))$ 。

#figure(
  image("images/QAOA-overall.png"),
  caption: [QAOA量子电路示意],
) <fig-chap9-QAOAGlobal>

若在式 @eq-chap9-QAOAUnitaryOperatorDefine 中代入 $bHB$ 与 $beta $ ，那么可做如下计算： /* Begin subequations */
$
  U(bHB, beta) &= upright(e)^(- upright(i) beta sum_(i = 1)^(n) bold(X)_(i)) \
  &= product_(i = 1)^(n) upright(e)^(- upright(i) beta bold(X)_(i)) \
  &= times.o.big_(i = 1)^(n) upright(e)^(- upright(i) beta bold(X)) \
  &= times.o.big_(i = 1)^(n)(cos(beta)bold(I) - upright(i) sin(beta)bold(X)) \
  &= times.o.big_(i = 1)^(n) R X_(i)(2 beta),
$

/* End subequations */
这说明混合酉算子 $U(bHB, beta)$ 的作用就是在每一个量子比特上都作用一个 $R X(2 beta)$ 门，如图@fig-chap9-MixerUnitaryOperatorEffect 所示。 $R X(theta)$ 门是： 
$
  R X(theta) = mat(delim: "[", cos theta/2, - upright(i) sin theta/2 ; - upright(i) sin theta/2, cos theta/2)
$
因此，在量子电路图@fig-chap9-QAOAGlobal 中，唯一会随着问题而变的结构是问题酉算子 $U(bHC, gamma_(*))$ ，故只要研究清楚问题哈密顿量 $bHC$ 会如何构建量子电路，QAOA的电路构建就手到擒来了。

#figure(
  image("images/UHB-equiv.png"),
  caption: [混合酉算子 $U (bHB, beta)$ 的作用],
) <fig-chap9-MixerUnitaryOperatorEffect>

观察式 @eq-chap9-QuestionHamiltonian，注意到 ${ bold(I), bold(Z) }^(times.o n)$ 中的矩阵是两两对易的，因此在式 @eq-chap9-QAOAUnitaryOperatorDefine 中代入问题哈密顿量 $bHC$ 与其对应角度参数 $gamma $ 即得： /* Begin subequations */
$
  U(bHC, gamma) &= upright(e)^(- upright(i) gamma sum_(delta) h_(delta)times.o.big_(i = 1)^(n) bold(Z)_(i)^(delta_(i))) \
  &= product_(delta) upright(e)^(- upright(i)(h_(delta) gamma) times.o.big_(i = 1)^(n)bold(Z)_(i)^(delta_(i))).
$ <eq-chap9-QuestionUnitaryOperatorEffectWithCoeffientB>

/* End subequations */
 显然可以认为系数是角度参数的一部分，之后再回过头来处理。上式主要透露出的信息是：只需要考虑 $upright(e)^(- upright(i) gamma times.o.big_(i = 1)^(n)bold(Z)_(i)^(delta_(i)))$ 最终能转换成什么电路，就解决了QAOA整体电路构建的问题。现给出以下定理：

#tufted.theorem[ $Z_(i_(1))$ 与 $Z_(i_(1))times.o Z_(i_(2))$ 对应的酉算子及其量子电路][
  若算子 $bold(cal(H)) = bold(Z)_(i_(1))$ ，那么其对应酉算子是 $U(bold(cal(H)), gamma) = upright(e)^(- upright(i) gamma bold(Z)_(i_(1))) = R Z_(i_(1))(2 gamma)$ ，即在第 $i_(1)$ 量子比特上作用 $R Z(2 gamma)$ 门，
  // 如图#ref(<fig-chap9-SingleCoupleFoldZGate-QuantumCircuit>)
  之左图所示。 $R Z(theta)$ 门是： $ R Z(theta) = mat(delim: "[", upright(e)^(- upright(i) theta/2), 0 ; 0, upright(e)^(upright(i) theta/2)) $

  若算子 $bold(cal(H)) = bold(Z)_(i_(1))times.o Z_(i_(2))$ ，那么其对应酉算子是 $upright(e)^(- upright(i) gamma bold(Z)_(i_(1))times.o Z_(i_(2))) = "CNOT"_(i_(2))^(i_(1))dot R Z_(i_(2))(2 gamma)dot "CNOT"_(i_(2))^(i_(1))$ ，其量子电路如图
  // #ref(<fig-chap9-SingleCoupleFoldZGate-QuantumCircuit>)
  之右图所示， $"CNOT"_(i_(2))^(i_(1))$ 表示以第 $i_(1)$ 量子比特为控制位、第 $i_(2)$ 量子比特为受控位。

  #figure(
    box({image("images/UZ-circuit.png", width: 50%)
    image("images/UZZ-circuit.png", width: 50%)}),
    // caption: [$Z_(i_(1))$与$Z_(i_(1))times.o Z_(i_(2))$对应的量子电路]
  )
//  #align(center)[
//  /* Begin quantikz */
// column sep=0.4cm /* \lstick */$q_(i_(1))$ & /* \gate */RZ(2gamma ) &
// /* End quantikz */
//       /* Begin quantikz */
// column sep=0.4cm /* \lstick */$q_(i_(1))$ & /* \ctrl */1 & & /* \ctrl */1 & \  /* \lstick */$q_(i_(2))$ & /* \targ */ & /* \gate */RZ(2gamma ) & /* \targ */ &
// /* End quantikz */
//  /* \captionof */figure$Z_(i_(1))$与$Z_(i_(1))times.o Z_(i_(2))$对应的量子电路
// ] <fig-chap9-SingleCoupleFoldZGate-QuantumCircuit>

]<theo-chap9-SingleCoupleFoldZGate-QuantumCircuit>

#tufted.proof[
  首先当 $bold(cal(H)) = bold(Z) $ 时做如下计算： /* Begin subequations */
  $
    U(bold(cal(H)), gamma) &= upright(e)^(- upright(i) gamma bold(Z)) \
    &= cos(beta)bold(I) - upright(i) sin(beta)bold(Z) \
    &= op("diag") upright(e)^(- upright(i) gamma), upright(e)^(upright(i) gamma) \
    &= R Z(2 gamma)
  $

  /* End subequations */
  在考虑将要作用到的量子比特后，易证定理的第一部分。而当 $bold(cal(H)) = bold(Z) times.o Z $ 时，计算如下： /* Begin subequations */
  $
    U(bold(cal(H)), gamma) &= upright(e)^(- upright(i) gamma bold(Z) times.o bold(Z)) \
    &= op("diag") {- upright(e)^(upright(i) gamma), upright(e)^(upright(i) gamma), upright(e)^(upright(i) gamma), upright(e)^(- upright(i) gamma)} \
    &= "CNOT" dot R Z(2 gamma)dot "CNOT"
  $

  /* End subequations */
  在考虑将要作用到的量子比特后定理第二部分得证。
]

必须指出，图
// #ref(<fig-chap9-SingleCoupleFoldZGate-QuantumCircuit>)
中的 $q_(i_(1))$ 与 $q_(i_(2))$ 并不一定是相邻的， $i_(1),i_(2)$ 的取值只取决于式@eq-chap9-QuestionHamiltonian 中的 $delta $ 。由此定理得到以下推论：

#tufted.corollary[ $times.o.big_(k = 1)^(n) Z_(i_(k))$ 对应的酉算子及其量子电路][
  若算子 $bold(cal(H)) = times.o.big_(k = 1)^(n) Z_(i_(k))$ ，那么其对应酉算子 $U(bold(cal(H)), gamma)$ 的量子电路如式#ref(<eq-chap9-MultiFoldZGate-QuantumCircuit>)和
// 图#ref(<fig-chap9-MultiFoldZGate-QuantumCircuit>)
所示。
  $
    (product_(k = 1)^(n - 1)"CNOT"_(i_(n))^(i_(k))) dot R Z_(i_(n))(2 gamma) dot (product_(k = 1)^(n - 1)"CNOT"_(i_(n))^(i_(n - k)))
  $ <eq-chap9-MultiFoldZGate-QuantumCircuit>
//  #align(center)[
//  /* Begin quantikz */
// column sep=0.2cm /* \lstick */$q_(i_(1))$ & /* \ctrl */4 & & & & & & & & & & & & /* \ctrl */4 & \  /* \lstick */$q_(i_(2))$ & & /* \ctrl */3 & & & & & & & & & & /* \ctrl */3 & & \  /* \lstick */dots.v  /* \wave */&&&&&&&&&&&&&& \  /* \lstick */$q_(i_(n - 1))$ & & & & /* \ */ ... /* \ */  & & /* \ctrl */1 & & /* \ctrl */1 & & /* \ */ ... /* \ */  & & & & \  /* \lstick */$q_(i_(n))$ & /* \targ */ & /* \targ */ & & /* \ */ ... /* \ */  & & /* \targ */ & /* \gate */RZ( 2gamma   )  & /* \targ */ & & /* \ */ ... /* \ */  & & /* \targ */ & /* \targ */ &
// /* End quantikz */
//  /* \captionof */figure$times.o.big_(k = 1)^(n) Z_(i_(k))$对应的量子电路 <fig-chap9-MultiFoldZGate-QuantumCircuit>
// ]
] <coro-chap9-MultiFoldZGate-QuantumCircuit>

#tufted.proof[
  证明留给读者作为习题。提示：使用数学归纳法。
]

// 由定理#ref(<theo-chap9-SingleCoupleFoldZGate-QuantumCircuit>)，
任意QUBO问题都能轻易地转化为QAOA量子电路了；进一步地，
// 由推论#ref(<coro-chap9-MultiFoldZGate-QuantumCircuit>)，
任意PUBO问题也能转化为量子电路。但千万别忘了：QAOA的终态 $ket(bgabe)$ 是由 $bgabe $ 中共 $2 p $ 个角度参数决定的，这些参数直接影响了算法对量子绝热过程的近似模拟的好坏。因此QAOA的下一步，是寻找到一组足够好的参数、以尽可能地模拟真实的量子绝热过程，或者说输出足够好的结果。

#html.hr()

== 四、经典参数的训练

与经典计算中的机器学习、神经网络类似，这些角度参数也通常通过梯度下降法训练。衡量结果好坏的标准是——终态 $ket(bgabe)$ 所代表的自旋构型 $s $ 输入到伊辛哈密顿量后得到的期望能量值，即如式@eq-chap9-IsingHamiltonianPolynomial 所示的 $cal(H)(s)$ ，越低越好。显然该值也可以使用问题哈密顿量计算出：
$
  lr(chevron.l bHC chevron.r)(bgabe) = braket(bgabe, bHC, bgabe)
$
这一关于参数 $bgabe $ 的函数称为*能量景观*（Energy Landscape）。假定角度参数 $bold(theta) =(bgabe)$ 表示两个角度参数向量的合并， $eta $ 是学习率，那么参数更新公式为：
$
  bold(theta)^((t + 1)) = bold(theta)^((t)) - eta dot frac(partial lr(chevron.l bHC chevron.r)(bold(theta)^((t))), partial bold(theta)^((t))) .
$

这一更新公式虽然与常见的并无二致，但在应用之前还需要讨论一些问题。第一个问题：对于变分量子线路，它的梯度绝非似经典机器学习那般，可以借助计算图、应用链式法则、实现反向传播从而轻易算出，因为这要求记录每个输出节点的数据，而在量子线路中这却是引入了测量、破坏了中间量子态。一种理论上常用的的梯度计算方式是参数移位法（Parameter-Shift Rule），该法指出 @Mitarai2018-Quantum-circuit-learning, Wierichs2022-General-parameter-shift-rules-for-quantum-gradients：
$
  frac(partial lr(chevron.l bHC chevron.r)(bold(theta)), partial theta_(k)) = 1/2[ lr(chevron.l bHC chevron.r) - lr(chevron.l bHC chevron.r) ], quad k = 1,2,...,2 p .
$ <eq-chap9-QAOAParameterShiftRule>
这里 $lr(chevron.l bHC chevron.r) (theta_(k) - pi /2)$ 是 $lr(chevron.l bHC chevron.r) (theta_(1), ..., theta_(k) - pi /2, ..., theta_(2 p))$ 的简写，表示在参数向量 $bold(theta) $ 只有第 $k $ 参数 $theta_(k)$ 被减去 $pi /2 $ 。但在实践上，使用该法计算梯度的QAOA算法每一次完整的参数更新迭代需要运行线路并测量 $4 p $ 次（因为 $2 p $ 个参数每一者均需采样两次），无疑降低了训练效率；同时，即便式@eq-chap9-QAOAParameterShiftRule 计算出的梯度理论上是精确的，真实量子硬件的噪声也使之变得不精确。因此_同时扰动随机逼近算法_（Simultaneous Perturbation Stochastic Approximation，SPSA）等更采样次数更少且不追求精确的算法反而更常用于真实硬件 @Kandala2017-Hardware-efficient-variational-quantum-eigensolver-for-small-molecules-and-quantum-magnets。

第二个问题：参数是否应当被截断在某一范围内？回答是肯定的，因为能量景观使用“角度”参数，它自然会隐含一个周期。在训练时将参数限制在一个周期内有助于训练的收敛。在说明周期性之前，首先介绍一个有关缩放的定理。

#tufted.theorem[伊辛哈密顿量的缩放][
  设缩放参数 $k > 0 $ 。若自旋构型 $s^(*)$ 是被缩放后的伊辛哈密顿量 $cal(H)(s)/k $ 的最优解，那么 $s^(*)$ 同样是原始伊辛哈密顿量 $cal(H)(s)$ 的最优解。
] <theo-chap9-伊辛哈密顿量的缩放>

#tufted.proof[
  $
    frac(cal(H)(s), k) <= frac(cal(H)(s^(*)), k) arrow.l.r.double.long cal(H)(s) <= cal(H)(s^(*)) .
  $
]

接下来的定理描述了：能量景观关于 $bold(beta) $ 参数具有普适的周期性。

#tufted.theorem[QAOA算法的能量景观中 $bold(beta) $ 参数的周期性][
  在忽略产生的全局相位的情况下，QAOA算法的能量景观的参数 $bold(beta) $ 具有周期 $pi $ ，即：
  $
    lr(chevron.l bHC chevron.r)bold(gamma), beta_(1), ..., beta_(i)+ pi, ..., beta_(p)) = lr(chevron.l bHC chevron.r)bgabe), quad i = 1,2,...,p
  $ <eq-chap9-QAOAEnergyLandscapeBetaPeriodicity>
] <theo-chap9-QAOA算法的能量景观中beta参数的周期性>

#tufted.proof[
  注意到由式@eq-chap9-QAOAUnitaryOperatorDefine 代入混合哈密顿量推导出的图@fig-chap9-MixerUnitaryOperatorEffect 中 RX 门的角度参数均为 $2 beta $ ，因此 $pi $ 是能量景观关于 $bold(beta) $ 参数的最小正周期。
]

// 基于定理@theo-chap9-QAOA算法的能量景观中beta参数的周期性，
在训练时可以将 $bold(beta) $ 的取值范围限制在 $[- pi /2, pi /2 ]$ 。

最后这个定理描述了：在一般情况下，对能量景观的 $bold(gamma) $ 参数，不具有普适的周期性。

#tufted.theorem[QAOA算法的能量景观中 $bold(gamma) $ 参数的周期性][
  在忽略产生的全局相位的情况下，形如式@eq-chap9-IsingHamiltonianPolynomial 的伊辛哈密顿量中：

  + 若存在某个系数 $h_(delta)$ 是无理数，那么能量景观关于 $bold(gamma) $ 参数不具有周期性，但具有准周期性；
  + 若所有系数均为有理数，那么 $gamma $ 参数具有最小公共正周期 $T = pi/g$ ，其中 $g = gcd(h_(delta)) = gcd(h_(0),...,h_(2^(n)- 1)) $ 是所有系数的最大公约数。
] <theo-chap9-QAOA算法的能量景观中gamma参数的周期性>


#tufted.proof[
  存在无理数系数的情况下：待证。

  所有系数均为有理数的情况下：由定理
// #ref(<theo-chap9-SingleCoupleFoldZGate-QuantumCircuit>)和推论#ref(<coro-chap9-MultiFoldZGate-QuantumCircuit>)，
  考虑相关系数后即按照式@eq-chap9-QuestionUnitaryOperatorEffectWithCoeffientB， RZ 门的角度参数是 $2 h_(delta)gamma $ 。故对单个 $gamma $ ，其周期是 $frac(pi, h_(delta))$ 。那么对于所有 $gamma $ 、即 $bold(gamma) $ 具有最小公共正周期 $"lcm"(frac(pi, h_(delta))) = frac(pi, gcd(h_(delta)))$ 。
]

但应当注意到，在许多实际问题中，无理数系数是较难取到的。并且，即便确实有无理数系数，一方面也可以通过近似的手段化为有理数；另一方面使用计算机处理问题时也仅能存储为近似的浮点数，因此在实际应用时认为能量景观关于 $bold(gamma) $ 参数具有普适周期性并非不可接受的。

第三个问题：该参数空间能否进一步缩小，即能否为能量景观函数找到更小的周期、或者寻到一些特殊的对称性？回答也是肯定的。首先，利用定理
// @theo-chap9-伊辛哈密顿量的缩放，
总能找到合适的缩放参数 $k $ ，使定理
// @theo-chap9-QAOA算法的能量景观中gamma参数的周期性
中的最小正周期约束化为 $pi $ ，从而使 $bold(gamma) $ 的取值范围限定在 $[- pi /2, pi /2 ]$ 中。接下来，定理
// @theo-chap9-QAOA算法的能量景观的对称性
给出了一种普遍的对称性。

#tufted.theorem[QAOA算法的能量景观的对称性 @giovagnoli-2025-An-Introduction-to-the-Quantum-Approximate-Optimization-Algorithm][
  QAOA算法的能量景观是关于原点对称的，即： /* Begin subequations */
  /* Begin numcases */
  $
    lr(chevron.l bHC chevron.r)(-bold(gamma) , bold(beta) ) = lr(chevron.l bHC chevron.r)(bold(gamma) , -bold(beta) ) #<eq-chap9-QAOAEnergyLandscapeSymmetryA> \
    lr(chevron.l bHC chevron.r)(-bold(gamma) , -bold(beta) ) = lr(chevron.l bHC chevron.r)(bold(gamma) , bold(beta) ) #<eq-chap9-QAOAEnergyLandscapeSymmetryB>
  $ <eq-chap9-QAOAEnergyLandscapeSymmetry>
  /* End numcases */
  /* End subequations */
] <theo-chap9-QAOA算法的能量景观的对称性>

#tufted.proof[
  以证明式
// @eq-chap9-QAOAEnergyLandscapeSymmetryB
  为例。首先易证，对任意实向量 $ket(v)$ 有 $ket(v)^(*) = ket(v)$ ，于是：
  $
    braket(v, bold(U), v)^(*) = (ket(v))^(*)(bold(U))^(*)(ket(v))^(*) = braket(v, bold(U)^(*), v)
  $
  其次易证对任意一层酉算子存在：
  $
    L_(i)^(*)(- gamma_(i), - beta_(i)) & =(U(bHB, - beta_(i))U(bHC, - gamma_(i)))^(*) \
    &=(upright(e)^(- upright(i)(- beta_(i)) bHB)upright(e)^(- upright(i)(- gamma_(i)) bHC))^(*) \
    &= upright(e)^(- upright(i) beta_(i) bHB)upright(e)^(- upright(i) gamma_(i) bHC) \
    &= L_(i)(gamma_(i), beta_(i)),
  $
  于是对于所有层酉算子存在：
  $
    L^(*)(- bold(gamma), - bold(beta)) = product_(i) L_(i)^(*)(- gamma_(i), - beta_(i)) = product_(i) L_(i)(gamma_(i), beta_(i)) = L(bgabe) .
  $
  所以： /* Begin subequations */
  <eq-chap9-QAOAEnergyLandscapeSymmetryProof>
  $
    lr(chevron.l bHC chevron.r)(- bold(gamma), - bold(beta)) &= braket(negbgabe, bHC, negbgabe) \
    &= braket(s, L^(dagger)(negbgabe) bHC L(negbgabe),s) \
    &= braket(s, L^(dagger)(negbgabe) bHC L(negbgabe),s)^(*) \
    &= braket(s, (L^(dagger)(negbgabe))^(*) bHC^(*) L^(*)(negbgabe), s)  \
    &= braket(s, L^(dagger)(bgabe) bHC L(bgabe), s) \
    &= braket(bgabe, bHC, bgabe) \
    &= lr(chevron.l bHC chevron.r)(bgabe) .
  $ <eq-chap9-QAOAEnergyLandscapeSymmetryProofC>

// /* End subequations */
  其中
// 式@eq-chap9-QAOAEnergyLandscapeSymmetryProofB 到式@eq-chap9-QAOAEnergyLandscapeSymmetryProofC
  是因为能量期望值 $lr(chevron.l bHC chevron.r)(- bold(gamma), - bold(beta))$ 是实数的。
// 式@eq-chap9-QAOAEnergyLandscapeSymmetryA
  的证明类似。
]

由于式@eq-chap9-QAOAEnergyLandscapeSymmetry 所示的对称性， $bgabe $ 中任取一者的取值范围都能进一步缩减到非负区间，例如 $[0, pi /2 ]^(p) times[- pi /2, pi /2 ]^(p)$ 。可惜的是，在一般情况下该参数空间不能再缩小了，但在特殊情形下能量景观函数可以有比 $pi $ 更小的周期——意味着更小的参数空间。

#tufted.theorem[QUBO问题特殊情形下对应QAOA算法的能量景观的周期性 @giovagnoli-2025-An-Introduction-to-the-Quantum-Approximate-Optimization-Algorithm][
  若忽略全局相位，问题哈密顿量 $bHC$ 是从QUBO问题导出的、且不包含一次项，即仅包含二次项，那么对应的能量景观函数中，参数 $bold(beta) $ 的周期是 $pi/2$ ，即：
  $
    lr(chevron.l bHC chevron.r)(bold(gamma), beta_(1), ..., beta_(i)+ pi/2, ..., beta_(p)) = lr(chevron.l bHC chevron.r)(bgabe), quad i = 1,2,...,p
  $
] <theo-chap9-QUBO问题特殊情形下对应QAOA算法的能量景观的周期性>

#tufted.proof[
  注意到对任一层酉算子有： /* Begin subequations */
  $
    L_(i)(gamma_(i), beta_(i)+ pi/2) &= upright(e)^(- upright(i)(beta_(i) + pi/2)bHB) upright(e)^(- upright(i) gamma_(i)bHC) \
    &= upright(e)^(- upright(i) pi/2bHB) upright(e)^(- upright(i) beta_(i)bHB) upright(e)^(- upright(i) gamma_(i)bHC) \
    &= upright(e)^(- upright(i) pi/2bHB) L_(i)(gamma_(i), beta_(i)) .
  $

  /* End subequations */
  其中： /* Begin subequations */
  $
    upright(e)^(- upright(i) pi/2bHB) &= upright(e)^(- upright(i) pi/2sum_(i = 1)^(n) bold(X)_(i)) = product_(i = 1)^(n)upright(e)^(- upright(i) pi/2bold(X)_(i)) \
    &= product_(i = 1)^(n)(- upright(i) bold(X)_(i)) =(- upright(i))^(n) product_(i = 1)^(n)bold(X)_(i) .
  $

  /* End subequations */
  其中 $(- upright(i))^(n)$ 可以作为全局相位被忽略掉。利用性质 $[A,B ]= 0 arrow.r.double.long[A,f(B)]= 0 $ ，显然 $[bold(X)_(i)times.o bold(X)_(j), bold(Z)_(i)times.o bold(Z)_(j)]= 0 arrow.r.double.long[bold(X)_(i)times.o bold(X)_(j), exp {bold(Z)_(i)times.o bold(Z)_(j)}]= 0 $ 。更进一步地，得到：
  $
    [ product_(i = 1)^(n)bold(X)_(i), product_(i < j = 1)^(n)exp { - upright(i)(h_(delta)gamma)bold(Z)_(i)bold(Z)_(j) } ] = 0 .
  $
  在问题哈密顿量中只含有二次项的情况下，上式说明 $product_(i = 1)^(n)bold(X)_(i)$ 与问题酉算子 $U(bHC, gamma_(i))$ 是对易的。利用对易的性质显然也容易推知 $product_(i = 1)^(n)bold(X)_(i)$ 与混合酉算子 $U(bHB, beta_(i))$ 亦是对易的，从而 $product_(i = 1)^(n)bold(X)_(i)$ 与任一层酉算子 $L_(i)(gamma_(i), beta_(i)+ pi/2) $ 是对易的。故 $product_(i = 1)^(n)bold(X)_(i)$ 可以被交换到下式的任意位置中： /* Begin subequations */
  $
    &lr(| bold(gamma), beta_(1), ..., beta_(i)+ pi/2, ..., beta_(p) chevron.r) \
    =& L_(p)(gamma_(p), beta_(p)) ... L_(i)(gamma_(i), beta_(i)+ pi/2) ... L_(1)(gamma_(1), beta_(1)) ket(s) \
    =& L_(p)(gamma_(p), beta_(p)) ...(product_(i = 1)^(n)bold(X)_(i)) L_(i)(gamma_(i), beta_(i)) ... L_(1)(gamma_(1), beta_(1)) ket(s) \
    =& L_(p)(gamma_(p), beta_(p)) ... L_(i)(gamma_(i), beta_(i)) ... L_(1)(gamma_(1), beta_(1))(product_(i = 1)^(n)bold(X)_(i)) ket(s) \
    =& L_(p)(gamma_(p), beta_(p)) ... L_(i)(gamma_(i), beta_(i)) ... L_(1)(gamma_(1), beta_(1)) ket(s) \
    =& ket(bgabe) .
  $ <eq-chap9-QAOASpecialQUBOProofFinalStateD>

// /* End subequations */
  其中
// 式@eq-chap9-QAOASpecialQUBOProofFinalStateC 到式@eq-chap9-QAOASpecialQUBOProofFinalStateD
  是因为初态 $ket(s)$ 就是 $product_(i = 1)^(n)bold(X)_(i)$ 的特征向量。因此，在忽略全局相位的情况下能量景观也是不变的。
]

// 进一步地，将定理@theo-chap9-QUBO问题特殊情形下对应QAOA算法的能量景观的周期性推广至PUBO问题得到以下推论。

#tufted.corollary[特殊情形下QAOA算法的能量景观的周期性 @giovagnoli-2025-An-Introduction-to-the-Quantum-Approximate-Optimization-Algorithm][
  若忽略全局相位，问题哈密顿量 $bHC$ 中仅包含偶数次项，那么对应的能量景观函数中，参数 $bold(beta) $ 的周期是 $pi/2$ ，即：
  $
    lr(chevron.l bHC chevron.r)(bold(gamma), beta_(1), ..., beta_(i)+ pi/2, ..., beta_(p)) = lr(chevron.l bHC chevron.r)(bgabe), quad i = 1,2,...,p
  $ <eq-chap9-QAOAEnergyLandscapePeriodicity>
] <theo-chap9-特殊情形下QAOA算法的能量景观的周期性>

#tufted.proof[
  该推论为读者留作习题。
]

在这种特殊情况下，利用 $bold(beta) $ 参数的周期性，可以进一步将参数空间缩小到 $[0, pi /2 ]^(p) times[0, pi /2 ]^(p)$ 。

#html.hr()

== 五、QAOA 背后的图景

量子绝热算法利用量子绝热定理，通过设计一条演化路径，将易于制备基态的初始哈密顿量连续演化为问题哈密顿量。若演化足够缓慢且满足绝热条件，系统最终将处于问题哈密顿量的基态，此时对该态进行测量即可得到优化问题的解。QAOA 则借鉴量子绝热算法的思想，使用参数化量子电路分段近似模拟这一绝热演化过程。那么，QAOA 算法究竟是如何推演得到的呢？下面阐述这个问题。

假设总演化时间为T，选定的初始哈密顿量为H0，那么系统随时间演化到问题哈密顿量HC 的一种路径如下所示：
$
  bH(t) = (1 - frac(t, T)) bH_0 + frac(t, T) bHC.
$
若初始哈密顿量的基态是 $ket(s)$ ，定义时间演化算子 $bU(t)$ ，则系统绝热演化到某时间t 时哈密顿量的基态是 $psi(t) = bU(t) ket(s)$ 。解含时薛定谔方程：
$
  tdiff psi(t) = - upright(i) bH(t) psi(t) arrow.r.l.double.long tdiff bU(t) = - upright(i) bH(t) bU(t),
$
得到：
$
  bU(t) &= cal(T) exp{ -upright(i) integral_(0)^(T) bH(tau) upright(d) tau } \
  &= lim_(p -> infinity) negEI(bH(t_p) Delta t) dot negEI(bH(t_(p-1)) Delta t) dot ... dot negEI(bH(t_1) Delta t) negEI(bH(t_0) Delta t).
$
其中 $Delta t = T/p$ ， $t_k = k Delta t$ ； $cal(T)$ 是时序算子，作用在于保证式(9.133b)中严格按时间顺序相乘。该式的导出不在此处给出，可以参考文献[79]。

那么，将式(9.133)离散化得到近似，并代入式(9.131)的线性演化路径，得到：
$
  bU(t) approx cal(T) product_(k = 1)^(p) exp{ -upright(i) [(1 - frac(t_k, T)) bH_0 + frac(t_k, T) bHC] Delta t },
$
再利用一阶 Lie-Trotter 近似，进一步得到：
$
  bU(t) approx cal(T) product_(k = 1)^(p) exp{ -upright(i) (1 - frac(t_k, T)) Delta t bH_0 } dot exp{ -upright(i) frac(t_k, T) Delta t bHC }.
$

到这里相信读者能够看出，上式形式上已经基本对应到 QAOA 的整体分层形式即式(9.115)了。不妨直接记 $L_k = exp{ -upright(i) (1 - frac(t_k, T)) Delta t bH_0 } dot exp{ -upright(i) frac(t_k, T) Delta t bHC }$ ，再同时令 $beta_k = (1 - frac(t_k, T)) Delta t$ 、 $gamma_k = frac(t_k, T) Delta t$ ，则 $bU(T) approx product_(k = 1)^(p) L_k(gamma_k, beta_k)$ ，便得到前述的QAOA 构造了。

读者大概会疑惑于：既然按照如上的推导，角度参数 $gabe$ 应当已经是唯一指定的了，又为何在 QAOA 中需要一个经典参数的训练步骤呢？首先，显然地，依据式(9.133)，当 QAOA 的层数 $p != 1$ 时，电路运行结果就是理想情况下量子退火得到的最优解。但是，当 $p$ 是有限值时，便可以视作后续所有层酉算子都是 $bold(I)$ ，对应能量景观函数值必然大于等于最优解对应的能量。这就会引入误差，影响收敛性，所以使用上述指定值时基本得不到足够好的结果，故而重新训练这些角度参数反而是更好的选择。

#set text(lang: "en")

#bibliography("reference.bib", style: "ieee")
