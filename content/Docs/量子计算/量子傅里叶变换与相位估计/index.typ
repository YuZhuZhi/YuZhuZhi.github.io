#import "@preview/physica:0.9.8": *
#import "@preview/theorion:0.6.0": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../index.typ": template, tufted
#show: template.with(
    title: "量子计算（六）——量子傅里叶变换与相位估计",
    description: "本文介绍了量子傅里叶变换的定义、构建方法以及相位反冲的原理，并通过对离散傅里叶变换的量子化，展示了量子傅里叶变换在量子计算中的重要作用。",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$
#let SWAP = $"SWAP"$

= 量子计算（六）——量子傅里叶变换与相位估计

#tufted.full-width[
    #image("header.png")
]

= 一、离散傅里叶变换简介

#note-block[
+ 这一节的内容可以跳过，直接观看 @量子傅里叶变换 ！
+ 这一节的内容仅仅是对数值分析及信号系统内容的极其粗略的概括，会忽略大量严谨的细节，细节内容请翻阅或移步与数值分析或信号系统相关的教材或文章。]

== 1.函数的范数与内积

不妨思考一个问题：我们知道对于向量来说存在正交分解——也就是可以将 $n$ 维向量表示为 $n$ 个正交基分量的线性和，甚至只要几个分量线性无关即可——那么对于函数来说是否也有类似的操作，可以分解为几个正交函数呢？

这个问题首先要解决的是：如何将函数视作一个向量(这样才能定义函数的正交)？或者说，向量应当具有什么性质？我们常说，向量是具有方向的数量，因此为了将函数向量化，就应当有某种手段衡量其方向与数量。不妨首先介绍衡量数量的手段，这意味着我们必须将一个函数整体映射为一个实数。对于我们所熟知的向量，其数量(一般会称之为长度)是：

$
    abs(bold(x))=&(x_1^2+x_2^2+...+x_n^2)^(frac(1, 2))\
    =& ( sum_(k=1)^(n)x_k^2  )^(frac(1, 2))
$

在线性空间中更规范的称呼是 $2-$ 范数，记为 $ norm(bold(x))_(2)$ ，特点是将其在各分量上的大小平方累加后再开方。对于函数 $f(x)$ 就能以类似的方法定义其 $2-$ 范数，只要将函数在各点上与 $x$ 轴围成的面积视作分量大小即可——当然这也意味着我们必须事先指定函数的定义域，其 $2-$ 范数才是有意义的：

$
    norm(f(x))_(2)=&
    lim_(Delta x  -> 0) ( sum_(k=1)^(frac(b-a, Delta x)) f^2(a+k Delta x) dot  Delta x  )^(frac(1, 2))\
    =& (  integral_(a)^(b)f^2(x) d x  )^(frac(1, 2))
$

现在可以思考如何衡量函数的方向了——当然在这里我们只关心如何确定函数正交。在熟知的线性空间中，向量的 $2-$ 范数也可视作自内积后开方，而两个向量正交则是由内积后是否为 $0$ 来判断的！由此仿照向量内积、结合函数 $2-$ 范数的形式，即可定义两个函数 $f(x),g(x)$ 的内积 $(f,g)$ ：

$
(f,g)= integral_(a)^(b)f(x) dot g(x) d x
$

当内积为 $0$ 时，就可以称 $f(x),g(x)$ 是正交的了。

== 2.正交函数系与三角拟合

与向量类似，我们或许会热衷于将函数分解为正交函数的线性叠加。定义在 $[- pi,  pi]$ 上
#footnote[定义在 $[0,2 pi]$ 上也是可以的]
的三角函数系 $[1,cos  k x, sin  k x],k=1,2,...$ 正是这样一种性质优异的正交函数系，因为：

$
    integral_(- pi)^(pi)cos k x=  integral_(- pi)^(pi)sin k x  d x=0\
    integral_(- pi)^(pi)cos k x dot sin  n x  d x=0, quad k != n\
    integral_(- pi)^(pi)cos k x dot cos  n x  d x=0, quad k != n\
    integral_(- pi)^(pi)sin k x dot sin  n x  d x=0, quad k != n\
$

因此某些函数 $f(x)$ 应当能被表示为这些三角函数的线性叠加——或者至少能利用最小二乘法被*最佳逼近*！这便是三角拟合，也即我们常说的傅里叶级数(的三角形式)了：

$
f(x)= frac(a_0, 2)+  sum_(k=1)^(+ infinity)a_k cos  k omega_0 x+b_k sin  k omega_0 x
$

这意味着函数 $f(x)$ 有无穷多的、 $k omega_0$ 频率的谐波，无论 $k$ 多大。当然为了计算上的方便、形式上的美观，利用欧拉公式，我们更喜爱傅里叶级数的复指数形式：

$
f(x)=  sum_(k=- infinity)^(+ infinity)c_k te^(ti k omega_0x)
$

必须指出，上面的级数只能拟合周期为 $ frac(2 pi, omega_0)$ 的*连续*函数，但不局限于实函数。而对于周期为 $N= frac(2 pi, omega_0)$ 离散函数 $f[x]$ ，如果研究离散的复指数函数 $ te^(ti k omega_0x)$ ，你会发现每当 $k$ 增加一个周期 $N$ ，却依然变回自身即 $ te^(ti k omega_0x)$ ——这意味着周期离散函数的谐波频率具有上界，故离散函数的傅里叶级数是：

$
f[x]=  sum_(k= chevron.l N chevron.r)c_k te^(ti k omega_0x) = sum_(k= chevron.l N chevron.r)c_k te^(ti k frac(2 pi, N)x)
$

#footnote[这里在求和号下的 $k= chevron.l N  chevron.r$ 表示：只要是在一个周期 $N$ 上对 $k$ 进行的求和即是合法的。]
同时也能求出：

$
c_n= frac(1, N)  sum_(k= chevron.l N chevron.r)f[k] te^(-ti k frac(2 pi, N)n)
$

== 2.对复向量的离散傅里叶变换

对傅里叶级数系数的计算：

$
c_n= frac(1, N)  sum_(k= chevron.l N chevron.r)f[k] te^(-ti k frac(2 pi, N)n)
$

实际上彰显了各谐波在函数 $f[x]$ 中的强度(也就是我们常说的从时域到频域)——这不就是对函数的正交分解么！但是现在我们又回归到了向量身上，因为对于周期为 $N$ 的离散函数而言，只要采样确定 $N$ 个取值就已经获得了函数的所有信息。不妨重新记这连续的 $N$ 个函数值 $f[k]$ 为复向量：

$
 bold(x)=[x_0,x_1,...,x_(N-1)]
$

#footnote[当然您会说：为什么不需要记录各函数值对应的时间点？首先，我们总能定义开始观察的时间点为零点；其次，时间平移操作作用到傅里叶级数系数上时只会使其附加一个 $ te^(-ti k omega_0t_0)$ 的相位系数，其中 $t_0$ 是时间平移的量，而这个系数的模为 $1$ ，并不会影响到我们评估谐波分量的强度。]
并记输出为复向量 $ bold(y)$ ，于是有：

$
y_k= frac(1, N)  sum_(j= chevron.l N  chevron.r)x_j te^(-ti j frac(2 pi, N)k)
$

当发生时间反演时也不改变谐波分量的强度，因此不妨假定我们总反转一下时间即取 $j -> -j$ ，这样可以去掉复指数函数上烦人的负号：

$
y_k= frac(1, N)  sum_(j= chevron.l N  chevron.r)x_j te^(ti j frac(2 pi, N)k)
$

另一方面，式前的系数 $ frac(1, N)$ 取什么也并不重要，或者说只在特定的场景下重要(其实际作用是为了归一化)——而在量子傅里叶变换中，只有取 $ frac(1, sqrt(N))$ 才是重要的。这样我们终于得到在量子傅里叶变换中我们所期望的离散傅里叶变换形式：

$
y_k=  frac(1, sqrt(N)) sum_(j=0)^(N-1)x_j dot  te^(ti  frac(2 pi, N)j k)
$

#html.hr()

= 二、量子傅里叶变换 <量子傅里叶变换>

== 1.离散傅里叶变换的量子化

已知离散傅里叶变换的形式是：

$
y_k=  frac(1, sqrt(N)) sum_(j=0)^(N-1)x_j dot  te^(ti  frac(2 pi, N)j k)
$

其中， $x_j$ 是复向量 $ bold(x)=[x_0,x_1,...,x_(N-1)]$ 中的元素， $y_k$ 是复向量 $ bold(y)=[y_0,y_1,...,y_(N-1)]$ 中的元素，两个复向量应当且必然具有相同数量的元素。现在不妨将上式量子化。既然已知 $y_k$ 的计算式，那么复向量 $ bold(y)$ 也就轻易写出：

$

     bold(y)&=y_0[1,0,...,0]+y_1[0,1,...,0]+...+y_(N-1)[0,0,...,1]\
    &*"Using Dirac Notation"*\
    &=  sum_(k=0)^(N-1)y_k ket(k) \
    &= frac(1, sqrt(N)) sum_(k=0)^(N-1) {  sum_(j=0)^(N-1)x_j dot  te^(ti  frac(2 pi, N)j k)  } ket(k)\
    &= cal(F) { bold(x) }

$

那么，当复向量 $ bold(x)$ 恰为计算基态 $ ket(j)$ 时，此时 $ bold(x)$ 中只有第 $j$ 位为 $1$ 而其余为 $0$ ，这意味着大括号中只剩下 $ te^(ti  frac(2 pi, N)j k)$ ，代入得到：

$
 cal(F) { ket(j) }=  frac(1, sqrt(N)) sum_(k=0)^(N-1) te^(ti  frac(2 pi, N)j k) ket(k)
$

从而量子化了离散傅里叶变换，所得到的形式是*针对计算基态*的傅里叶变换。当然不妨进一步改写：对于量子傅里叶变换来说显然有一些 $N$ 值是不能取到的，例如 $5$ ——因为当有 $N$ 个量子位时，将产生 $2^N$ 个计算基态。故将上式中的 $N$ 全部替换为 $2^N$ 得：

$
 cal(F) { ket(j) }=  frac(1, 2^(N/2)) sum_(k=0)^(2^N-1) te^(ti  frac(2 pi, 2^N)j k) ket(k)
$

== 2.量子傅里叶变换的直积态形式

由于量子态可以叠加，只要实现了对计算基态的量子傅里叶变换，就实现了对任意量子态的量子傅里叶变换。为了得到计算基态之傅里叶变换的量子电路图，我们必须进一步改写上式。

注意到上式左边是以直积态形式写出的计算基态，而右边却以附带相位的计算基态之线性和写出。为了更加契合两边的形式，同时为了确认每一个量子最后所处的量子态，需要将右边改写为直积态形式。为此，首先将 $j$ 展开写为二进制形式 $ overline(j_1j_2 dots j_N)$ ， $k$ 也展开写为二进制形式 $ overline(k_1k_2 dots k_N)$ ，于是上式右边可以重新计算——首先是对 $k$ 从 $0$ 到 $2^N-1$ 的遍历，按二进制展开可得：

$
  sum_(k=0)^(2^N-1) te^(ti  frac(2 pi, 2^N)j k) ket(k)= sum_(k_1=0)^(1) dots sum_(k_N=0)^(1) te^(ti 2 pi j dot sum_(l=1)^(N)k_l 2^(-l)) ket(k_1k_2 dots k_N)
$

其中，将指数部分的分母重新组合，使得指数中的 $k$ 重写为二进制小数的形式：

$
     frac(k, 2^N)&= frac(k_1k_2 dots k_n, 2^N)\
    &=0.k_1k_2 dots k_N\
    &=k_1 dot frac(1, 2^1)+k_2 dot frac(1, 2^2)+...+k_N dot frac(1, 2^N)\
    &=  sum_(l=1)^(N)k_l 2^(-l)\
$

显然这样改写之后，大求和号之后的部分可以重写为直积态形式：

$
 te^(ti 2 pi j dot sum_(l=1)^(N)k_l 2^(-l)) ket(k_1k_2 dots k_N)=  limits(times.o.big)_(l=1)^(N) te^(ti 2 pi j dot k_l 2^(-l)) ket(k_l)
$

于是：

$
     cal(F) { ket(j) }&=  frac(1, 2^(N/2)) sum_(k=0)^(2^N-1) te^(ti  frac(2 pi, 2^N)j k) ket(k)\
    &= frac(1, 2^(N/2)) sum_(k_1=0)^(1) dots sum_(k_N=0)^(1) limits(times.o.big)_(l=1)^(N) te^(ti 2 pi j dot k_l 2^(-l)) ket(k_l)\
    &= frac(1, 2^(N/2)) limits(times.o.big)_(l=1)^(N) sum_(k_l=0)^(1) te^(ti 2 pi j dot k_l 2^(-l)) ket(k_l)\
    &= frac(1, 2^(N/2)) limits(times.o.big)_(l=1)^(N)( ket(0)+ te^(ti 2 pi j dot 2^(-l)) ket(1))\
$

再展开一次，可以更加直观：

$
 cal(F) { ket(j) }= frac(1, 2^(N/2)) ( ket(0)+ te^(ti 2 pi dot 0.j_N) ket(1) ) ( ket(0)+ te^(ti 2 pi dot 0.j_(N-1)j_N) ket(1) ) dots ( ket(0)+ te^(ti 2 pi dot 0.j_1j_2...j_N) ket(1) )
$

也就是说，在对计算基态 $ ket(j)$ 傅里叶变换之后，第 $k$ 号量子所处的量子态是：

$
 frac(1, sqrt(2))( ket(0)+ te^(ti 2 pi dot 0.j_(N-k)...j_(N-1)j_N) ket(1))
$

== 3.构建量子线路

为了构建量子线路，我们首先引入相位矩阵 $R_k$ ：

$
R_(k)= mat(
    1 , 0 ;  0 ,  te^(ti  frac(2 pi, 2^k))
)
$

这个量子门的作用是显然的，它为 $ ket(1)$ 附加了 $ frac(2 pi, 2^k)$ 的相对相位，也就是使量子态在布洛赫球上绕 $z$ 轴旋转 $ frac(2 pi, 2^k)$ ，因此它是 $Z$ 旋转门的特殊形式： $R_(k)=R_Z (  frac(2 pi, 2^k)  )$ 。

接下来开始构建线路。注意到变换后每个量子都处于均匀的叠加态(意为 $ ket(0), ket(1)$ 的振幅的模相等)，因此首先在 $1$ 号量子上作用一个 $H$ 门使其变为叠加态。之后，注意到相位是按二进制写出的：

$

    2 pi dot 0.j_(N-k)...j_(N-1)j_N&=2 pi dot (  frac(j_(N-k), 2)+ frac(j_(N-k+1), 2^2)+...+ frac(j_(N), 2^(k+1))  )\
    &= frac(2 pi, 2)j_(N-k)+ frac(2 pi, 2^2)j_(N-k+1)+...+ frac(2 pi, 2^(k+1))j_(N)

$

也就是说， $j_(N-k+l)$ 表示了是否要为 $ ket(1)$ 附加 $ frac(2 pi, 2^(l+1))$ 的相位。这说明在线路中应当存在以 $N-k+l$ 号量子作为控制位，控制 $N-k$ 号量子是否作用 $R_(l+1)$ 的受控量子门。对于同一个量子，作用 $R_k$ 门的顺序并不重要。并且在此之前， $N-k+l$ 号量子不能进入叠加态，否则会在系统中产生纠缠态。由此分析，可以得到量子傅里叶变换的线路应当如 @QFTCircuit 所示。
#tufted.full-width[
    #image("imgs/QFT.png")
]
#tufted.margin-note[
    #figure(caption: [量子傅里叶变换的量子电路图])[] <QFTCircuit>
]

当然值得注意的是，如果只考虑之前文字所述的操作，将产生的量子态是：

$
 frac(1, 2^(N/2)) ( ket(0)+ te^(ti 2 pi dot 0.j_1j_2...j_N) ket(1) ) dots ( ket(0)+ te^(ti 2 pi dot 0.j_(N-1)j_N) ket(1) ) ( ket(0)+ te^(ti 2 pi dot 0.j_N) ket(1) )
$

这个顺序与我们所期望的恰好是相反的。因此需要在线路最后，再执行一次重排以调整顺序。只需要在序号对称的两个量子位上作用 $SWAP$ 门即可。

== 4.量子傅里叶变换的几何意义

#footnote[由于技术所限，这里只能以语言的形式表达其几何意义，敬请见谅。]
由前两节我们知道了在对计算基态 $ ket(j)$ 傅里叶变换之后，第 $k$ 号量子所处的量子态是：

$
 frac(1, sqrt(2))( ket(0)+ te^(ti 2 pi dot 0.j_(N-k)...j_(N-1)j_N) ket(1))
$

在#link("量子计算/布洛赫球/")[量子计算（三）——布洛赫球]中介绍布洛赫球时还知道，单个量子的纯态可以表示为：

$
 ket(psi)=cos frac(theta, 2) ket(0)+ te^(ti  phi)sin frac(theta, 2) ket(1)
$

对比可知，显然单个量子在傅里叶变换后对应 $ theta=90^ circle.small= pi$ 的情况，也就是在球面的赤道上；而在变换之前要么是 $ ket(0)$ 要么是 $ ket(1)$ ，即北极点和南极点，因此量子傅里叶变换显然是将计算基态由南北极点的交错表示变换为了赤道上的频率表示。

何谓南北极点的交错表示？举个三量子的简单例子，对于计算基态 $ ket(010)$ 来说，各量子在布洛赫球面上的排列是 [北极,南极,北极] ，对于其它计算基态也是类似地按二进制数指向南北极点，这便是南北极点的交错表示。

而赤道上的频率表示又是如何？在上节也已提到过，变换后的量子具有的相对相位是：

$
2 pi dot 0.j_(N-k)...j_(N-1)j_N= frac(2 pi, 2)j_(N-k)+ frac(2 pi, 2^2)j_(N-k+1)+...+ frac(2 pi, 2^(k+1))j_(N)
$

因此对于计算基态 $ ket(010)$ ， $1$ 号量子在变换后具有相对相位：

$
 frac(2 pi, 2) dot 0+ frac(2 pi, 2^2) dot 1+ frac(2 pi, 2^3) dot 0= frac(pi, 2)
$

 $2,3$ 号则分别是：

$
 frac(2 pi, 2) dot 1+ frac(2 pi, 2^2) dot 0= pi frac(2 pi, 2) dot 0=0
$

因此，对于三位量子态，每变化到下一计算基态，那么变换后的 $i$ 号量子的相对相位将会增加 $ frac(2 pi, 2^(3-i+1))$ ，这反映了变化的幅度，也反映了每个位的频率。对于 $n$ 位量子态也是类似地，序号越小，每次增加的相位越小。这就是所谓赤道上的频率表示。

#html.hr()

= 三、相位反冲(Phase Kick-back)

在#link("量子计算/Deutsch-Jozsa算法与Simon算法/")[量子计算（五）——Deutsch-Jozsa算法与Simon算法]中介绍的算法都利用了相位反冲。但相位反冲的产生条件与原理究竟是什么？接下来我们讨论这个问题。

== 1.量子门的相位

量子门作为矩阵，自然是具有特征值与特征向量的。由于量子门是酉矩阵，它显然不会改变向量的模长——因此其本征值(特征值)必然具有形式 $ te^(ti 2 pi theta)$ 。从而对于量子门 $U$ ，必然存在本征态(特征向量) $ ket(psi)$ 使得：

$
U ket(psi)= te^(ti 2 pi theta) ket(psi)
$

这意味着对于本征态，量子门仅仅是为其附加了一个全局相位。对于现实世界的观测者而言，这多出的全局相位显然是不重要的。

== 2.相位反冲的原理

但是，如果这个量子门 $U$ 是作为受控门呢？以最普通的受控 $U$ 门为例，不妨首先构造这个受控矩阵 $"C"U$ 。既然当控制位为 $0$ 时 $U$ 不作用，反之为 $1$ 时作用，因此：

$
    "C"U&=( ket(0) bra(0) times.o I)+( ket(1) bra(1) times.o U)\
    &= mat(
        I , O ;  O , U
    )
$

那么，假设控制位处于量子态 $ ket(phi)= alpha ket(0)+ beta ket(1)$ 而受控位恰为 $U$ 的本征态 $ ket(psi)$ 。经过 $"C"U$ 作用之后：

$
    "C"U( ket(phi) ket(psi))&=( ket(0) bra(0) times.o I)( ket(phi) ket(psi))+( ket(1) bra(1) times.o U)( ket(phi) ket(psi))\
    &= ket(0) bra(0) phi  chevron.r times.o ket(psi)+ ket(1) bra(1) phi  chevron.r times.o U ket(psi)\
    &= alpha ket(0) ket(psi)+ te^(ti 2 pi theta) beta ket(1) ket(psi)\
    &=( alpha ket(0)+ te^(ti 2 pi theta) beta ket(1)) ket(psi)
$

可以发现，本应由受控位独占的全局相位，却被控制位吸收为局部相位；而应当改变的受控位反而没有发生变化。

#footnote[笔者个人的理解是：对于控制位而言，其包含的 $ ket(0)$ 态与 $ ket(1)$ 态并不是平权的。例如，当控制位为 $1$ 时，那么在作用之后恰好是 $ te^(ti 2 pi theta) beta ket(1) ket(psi)$ ，此时引入了全局相位；而控制位为 $0$ 时，则不会引入相位改变。于是由于叠加态原理，控制位的两个计算基态间的相位差发生改变，也就导致了相对相位的产生或改变。]

现在让我们考虑当受控位不是本征态的情况。由于 $U$ 是酉矩阵，其各本征态自然是正交的，因此任意(等量子位数的)量子态 $ ket(phi.alt)$ 都可以表示为其本征态之线性和：

$
 ket(phi.alt)=  sum w_k ket(psi_k)
$

从前述可知，要知道相位改变多少，只需要计算当控制位为 $1$ 时的结果：

$
    ( ket(1) bra(1) times.o U)( ket(1) ket(phi.alt))&= ket(1) times.o U ket(phi.alt)\
    &= ket(1) times.o  sum w_k te^(ti 2 pi theta_k) ket(psi_k)\
    &= sum w_k te^(ti 2 pi theta_k) ket(1) ket(psi_k)\
$

从而：

$
    "C"U( ket(phi) ket(psi))&= alpha  sum w_k ket(0) ket(psi_k)+ beta sum w_k te^(ti 2 pi theta_k) ket(1) ket(psi_k)\
    &= sum w_k ( alpha ket(0)+ te^(ti 2 pi theta_k) beta ket(1)) ket(psi_k)
$

可见， $ ket(phi)$ 将会以概率 $abs(w_k)^2$ 获得相对相位 $2 pi theta_k$ 。

#html.hr()

= 四、相位估计

== 1.算法思路 <相位估计算法思路>

在现实世界中，量子门往往仅是个黑箱——这意味着我们并不知道这个量子门的具体形式，也就更不必提求出它的本征值了。而相位估计就是为了解决这个问题。

显然对于本征态来说，无论是否利用相位反冲，量子门 $U$ 都只能引入一个对观测概率不产生影响的相位，因此这对我们估计量子门的本征值没有任何作用。但是注意到：我们之前介绍的量子傅里叶变换，就是让计算基态进入具有相对相位的叠加态；而量子电路可逆，相反地也自然能将相对相位转换为计算基态——而计算基态被测量到的概率就是 $100\%$ ！这就给了我们相位估计的思路：只要利用相位反冲，让相位作用到控制位上，最后让控制位逆傅里叶变换一次即可。

== 2.线路构建

为了分析简便，取受控位为 $U$ 的本征态 $ ket(psi)$ 。在相位反冲之前，我们要让控制位都进入叠加态——否则要么不引入相位、要么引入全局相位。为此首先让控制位从初始零态做一次量子傅里叶变换，如 @QFTEquivCircuit 所示。
#footnote[值得注意的是，对 $ ket(0^n)$ 做 QFT 与在每个量子位上作用 $H$ 门的效果是等价的。因为此时受控 $R_k$ 门均不起作用，可以直接从量子傅里叶变换的线路图中删去。此时控制位进入均匀叠加态。]
#tufted.full-width[
    #image("imgs/QFT0.png")
]
#tufted.margin-note[
    #figure(caption: [对 $ket(0^n)$ 做 QFT 与在每个量子位上作用 $H$ 门的效果是等价的])[] <QFTEquivCircuit>
]

现在考虑如何使 $U$ 的相位反冲到控制位上。我们再次将本征值 $ te^(ti 2 pi theta)$ 中的 $ theta$ 也写为二进制小数形式：

$
 theta=0. theta_1 theta_2... theta_(n-1) theta_n...
$

因此 $U^2$ 的本征值就会是 $( te^(ti 2 pi theta))^2= te^(ti 2 pi 2 theta)= te^(ti 2 pi 0. theta_2 theta_3... theta_(n-1) theta_n...)$ ，同理 $U^(2^(k))$ 中的 $ theta$ 值为 $0. theta_(k) theta_(k+1)...$ 。这样我们就构造出与量子傅里叶变换中各量子位相对相位相似的排列了。因此这个量子线路将如下构造：
#tufted.full-width[
    #image("imgs/phase-estimation.png")
]
#tufted.margin-note[
    #figure(caption: [相位估计的量子电路图])[] <PhaseEstimationCircuit>
]

当然，我们应该更喜欢下面这种简便的画法：
#figure(caption: [相位估计的简化量子电路图])[#image("imgs/phase-estimation-simplify.png")] <PhaseEstimationSimplifyCircuit>
// #tufted.full-width[
//     #image("imgs/phase-estimation-simplify.png")
// ]
// #tufted.margin-note[
//     #figure(caption: [相位估计的简化量子电路图])[] <PhaseEstimationSimplifyCircuit>
// ]


== 3.误差与概率分析

看到这里，您可能会惊叹于相位估计对量子傅里叶变换的巧妙运用。但有必要提醒您重新仔细阅读“由二进制本征值构造量子线路”这一部分。我们给出的线路图是可以正常正确运行的，但却刻意忽略了一个细节——图中相位反冲之后的相位是被高位截断了的！而在之前将 $ theta$ 写为 $0. theta_1... theta_n...$ 时后面还有省略号。

这意味着相位测量算法是存在精确性问题的。如果 $ theta$ 在二进制表示下是有穷的，那么使用足够多的量子确实可以精准得到其数值；但显然还有很多二进制无穷的 $ theta$ 只能得到近似值。而这尚未穷尽的相位输入到逆傅里叶变换后会带来不确定性。现在我们的问题是：在无穷的情况下，测量得到的 $ tilde(theta)$ 与真实的 $ theta$ 之间有多少误差？在给定误差限的情况下，测量结果又能以多大概率落在误差限内？

记 $j= floor(2^n theta)$ ，因为在有截断的情况下 $2^n theta$ 依然是小数， $j$ 才是真正测量的结果。考虑控制位在相位反冲后、逆傅里叶变换前的状态是：

$
 frac(1, 2^(n/2))  sum_(k=0)^(2^n-1) te^(ti 2 pi k theta) ket(k)
$

所以在逆傅里叶变换之后的状态是：
$
    & frac(1, 2^(N)) mat(
        1 , 1 , 1 ,  dots , 1;
        1 ,  omega^(-1) ,  omega^(-2) ,  dots ,  omega^(-(2^N-1));
        1 ,  omega^(-2) ,  omega^(-4) ,  dots ,  omega^(-2(2^N-1));
         dots.v ,  dots.v ,  dots.v ,  dots.down ,  dots.v;
        1 ,  omega^(-(2^N-1)) ,  omega^(-2(2^N-1)) ,  dots ,  omega^(-(2^N-1)^2);
    ) mat(
         te^(ti 2 pi dot 0 theta) ;   te^(ti 2 pi dot 1 theta) ;   te^(ti 2 pi dot 2 theta) ;   dots.v ;   te^(ti 2 pi dot (2^N-1) theta)
    )\
    &= frac(1, 2^(N)) [   sum_(k=0)^(2^N-1) te^(ti 2 pi k theta),  sum_(k=0)^(2^N-1) omega^(-k) te^(ti 2 pi k theta),  sum_(k=0)^(2^N-1) omega^(-2k) te^(ti 2 pi k theta),  dots,  sum_(k=0)^(2^N-1) omega^(-(2^N-1)k) te^(ti 2 pi k theta) ]\
    &= frac(1, 2^(N)) sum_(k=0)^(2^N-1) sum_(j=0)^(2^N-1) omega^(-j k) te^(ti 2 pi k theta) ket(j)\
    &= frac(1, 2^(N)) sum_(k=0)^(2^N-1) sum_(j=0)^(2^N-1) te^(ti 2 pi  ( k theta- frac(k j, 2^N)  )) ket(j)\
    &= sum_(j=0)^(2^N-1) (  frac(1, 2^(N)) sum_(k=0)^(2^N-1) te^(ti 2 pi k  (  theta- frac(j, 2^N)  ))  ) ket(j)\
$

为什么呢？虽然之前并未说明过量子傅里叶逆变换如何计算，但是注意到量子傅里叶变换本身可以用矩阵形式写出：
$
     cal(F) { ket(j) }&=  frac(1, 2^(N/2)) sum_(k=0)^(2^N-1) te^(ti frac(2 pi, 2^N)j k) ket(k)\
    &= frac(1, 2^(N/2)) mat(
        1 , 1 , 1 ,  dots , 1;
        1 ,  omega ,  omega^(2) ,  dots ,  omega^(2^N-1);
        1 ,  omega^(2) ,  omega^(4) ,  dots ,  omega^(2(2^N-1));
         dots.v ,  dots.v ,  dots.v ,  dots.down ,  dots.v;
        1 ,  omega^(2^N-1) ,  omega^(2(2^N-1)) ,  dots ,  omega^((2^N-1)^2);
    ) ket(j)
$
其中 $ omega= te^(ti  frac(2 pi, 2^N))$ 。不妨将其中的矩阵也记为 $ cal(F)$。 这一方面是一个范德蒙矩阵，但另一方面——既然它对应量子傅里叶变换的整体量子门，那么它就是一个酉矩阵。因此要计算量子傅里叶逆变换，只要计算 $ cal(F)^(-1)= cal(F)^ dagger$ ，也就是 $ cal(F)$ 的转置共轭即可！

因此测量结果为 $ ket(j)$ 的概率就是：
$
    P(j)&= abs(frac(1, 2^(N)) sum_(k=0)^(2^N-1) te^(ti 2 pi k  (  theta- frac(j, 2^N)  )))^2\
    &*"Using geometric sequence summation"*\
    &= frac(1, 2^(2N)) abs( frac(te^(ti 2 pi(2^N theta-j))-1, te^(ti 2 pi (  theta- frac(j, 2^N)  ))-1))^2\
$

我们记误差 $ epsilon.alt=abs(theta- frac(j, 2^N))$ 。显然误差具有最小值 $ frac(1, 2^(N+1))$ 。在最好的情况下， $j$ 应当是二进制 $ theta$ 的前 $n$ 位(四舍五入后)，测量得到的概率自然也是最小的，此时 $ epsilon.alt$ 的最大值是 $ frac(1, 2^(N))$ 。为了得到这个概率的下界，自然应取 $ epsilon.alt= frac(1, 2^(N+1))$ ，首先求分子：

$
abs(te^(ti 2 pi(2^N theta-j))-1)=abs(te^(ti 2 pi 2^N epsilon.alt)-1)=2
$

#footnote[对于 $abs(te^(ti 2 theta)-1)$ ，显然可以将其视作单位圆之实轴右交点与圆上一点所连的弦长，此点与实轴之张角为 $2 theta$ 。于是弦长可以简单写为 $2sin theta$ 。在上面的例子中， $ theta= pi dot 2^N epsilon.alt= frac(pi, 2)$ ，于是弦长为 $2$ 。]
同理分母为：

$
abs( te^(ti 2 pi (  theta- frac(j, 2^N)  ))-1)=abs(te^(ti 2 pi epsilon.alt)-1)=2sin frac(pi, 2^(N+1))approx frac(2 pi, 2^(N+1))= frac(pi, 2^(N))
$

所以 $P(j)= frac(1, 2^(2N)) dot (  frac(2, frac(pi, 2^N))  )^2= frac(4, pi^2)=40.53\%$ 。这说明至少有四成的概率测量到最好的结果。也许您会觉得这个概率小得可怜，但这是因为我们只考虑了一个方向的误差，也就是只让结果比期望的小。如果允许测量值在期望值的两侧取值，那么概率就上升到至少八成。

如果允许更大的误差，那么测量值在误差限内的概率将会更大。例如如果允许 $k$ 倍的最小误差，那么测量结果在允许范围内的概率就至少是 $1- frac(1, 2(k-1))$ 。

== 4.问题重顾——当受控位不是本征态

在这里，希望读者再重新阅读本节 @相位估计算法思路 中的第一句话：

#tip-block[在现实世界中，量子门往往仅是个黑箱——这意味着我们并不知道这个量子门的具体形式，也就更不必提求出它的本征值了。]

在上面的分析中，我们已提前让受控位进入 $U$ 的本征态。但是，既然我们不知道量子门的具体形式，又怎么可能提前制备本征态呢？这里就需要回到之前已分析过的<相位反冲的原理>了。当受控位处于本征态的叠加态时：

$
"C"U( ket(phi) ket(psi))= sum w_k ( alpha ket(0)+ te^(ti 2 pi theta_k) beta ket(1)) ket(psi_k)
$

这意味着即便是任意态，利用相位反冲也能将本征值的相位作用到控制位上；并且， $ theta_k$ 与 $ ket(psi_k)$ 是绑定的，只要测量受控位得到 $ ket(psi_k)$ ，那么算法能得到的也将会是 $ theta_k$ 。

另一方面，由于叠加态性质，经过量子逆傅里叶变换之后，控制位会保留各本征值对应的振幅。因此最后测量控制位时，会以 $abs(w_k)^2$ 的概率得到 $ theta_k$ 对应的信息。

综上所述，相位估计是一个有效的算法，不因无法制备本征态而无法运行，而能测量到的 $ theta_k$ 则取决于控制位所使用的位数。量子傅里叶变换也将会是后续许多算法的基础。
