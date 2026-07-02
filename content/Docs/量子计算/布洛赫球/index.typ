#import "@preview/cetz:0.5.2"
#import "../../index.typ": template, tufted
#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#show: template.with(
    title: "量子计算（三）——布洛赫球",
    description: "布洛赫球是单量子态的几何表示，本文将介绍布洛赫球的定义、单量子门在布洛赫球上的作用，以及混合态与布洛赫球的关系。",
)

#let ti = $"i"$
#let te = $"e"$
#let otimes = $times.o$
#let varphi = $phi$
#let varPsi = $Psi$
#let tr = $"Tr"$

= 量子计算（三）——布洛赫球

#tufted.full-width[
    #image("imgs/header.jpg")
]

= 一、纯态的表示

在上一篇文章#link("../量子态与量子门/")[量子态与量子门]中，我们了解到*纯态是单位的*。也就是说任意量子态在表示为$ ket(psi) =alpha ket(0) + beta ket(1) $时，总存在 $|alpha|^2+|beta|^2=1$ 。这促使我们想到三角变换，让 $alpha, beta$ 同时关联到一个变量 $theta$ 上：

$
ket(psi) = cos theta ket(0) + sin theta ket(1)
$ 

上式允许我们在几何上做出这样的解释：想象一个由 $ket(0), ket(1)$ 张成的直角坐标系，如 @简单直角坐标系 所示，那么任意纯态 $ket(psi)$ 总是一个*单位圆*上的矢量，它与 $ket(0)$ 间的夹角是 $theta$。

#figure(caption: [由$ket(0)$和$ket(1)$张成的直角坐标系])[
  #image("imgs/简单直角坐标系.png")
] <简单直角坐标系>

然而这样做相当于认定 $theta$ 是一个实参数，带来一个问题：计算基态的振幅并不局限在*实数域*上。我们当然能通过让 $theta$ 作为复数、从而使 $cos theta,sin theta$ 成为复数，但这使我们失去了几何意义上的直观，并且相当于在 $theta$ 内部又引入了两个变量(以描述复量)，完全将这个问题复杂化了。

为了在保持$theta$作为独立实数变量的同时、又保证振幅是复数的，联想到欧拉公式$te^(ti phi) = cos phi + ti sin phi$。$te^(ti phi)$本身也是单位的、并在 $phi$ 也是实数的情况下引入了虚数。这样，我们就可以将量子态重写为：

$
ket(psi) = te^(ti phi_0) cos theta ket(0) + te^(ti phi_1) sin theta ket(1)
$ 

可是又出现了新的问题：$ phi_0, phi_1$之间有什么关系？这个问题的答案不能体现在上式中。为此，将$te^(ti phi_0)$提取出来并扔掉：

$
ket(psi) =te^(ti phi_0)(cos theta ket(0) +te^(ti (phi_1 - phi_0)) sin theta ket(1) ) \
=> ket(psi) attach(stretch(eq, size: #100%), t: phi = phi_1 - phi_0) cos theta ket(0) + te^(ti  phi) sin theta ket(1)
$ 

#tufted.remark[][
扔掉 $te^(ti  phi_0)$ 的操作是合情合理的。在同时使用 $te^(ti  phi_0), te^(ti  phi_1)$ 的时候，是分别对计算基态 $ket(0) , ket(1)$ 的相位做偏移，这个时候称为*绝对相位*。提取并丢弃 $te^(ti  phi_0)$ 时，是以 $ket(0)$ 的相位为基准，或者说强制使其相位为 $0$，来标定 $ket(1)$ 的相位，这时称为*相对相位*。相对相位 $phi= phi_1- phi_0$ 正体现了 $phi_0, phi_1$ 之间的关系。两种表示方法是等价的，但相对相位更加方便——因为使用绝对相位的时候，我们并不能预先知道相位为 $0$ 的标准！就像物理学中研究势能场时，必须指定势能零点，否则是无意义的。
]

#html.hr()

= 二、纯态与布洛赫球面

== 1.目前的纯态表示方法

在确定了两个角度变量 $theta, phi$ 之后，纯态显然可以被标识在一个*单位球面*上了
#footnote[但需要注意，与前一节所述不同，这个球的坐标轴*不是*由计算基态张成的，而是普通的$x y z$坐标系。]！
规定 $phi$表示矢量在 $x O y$ 平面上的投影与 $x$ 轴的张角，$theta$表示矢量与$z$轴的夹角。也就如 @布洛赫球面上的纯态 所示。

#figure(caption: [布洛赫球面上的纯态])[
  #image("imgs/布洛赫球面上的纯态.png")
] <布洛赫球面上的纯态>

现在，对于两个计算基态，能够取得它们的条件分别是：

$
cases(
    ket(0) : theta = 0 ", " phi="arbitrary",
    ket(1) : theta = frac(pi, 2) ", " phi=0
)
$ 

在球上的位置如 @当前认知下计算基态的位置 所示。

#figure(caption: [当前认知下计算基态在球面上的位置])[
  #image("imgs/当前认知下计算基态的位置.png")
] <当前认知下计算基态的位置>

这时，$x O z$ 平面像是回到了之前说的“用计算基态张成的平面”，而 $y$ 轴的作用仅仅是告诉我们计算基态 $ket(1)$ 的相位。球面上*关于原点对称*的两点，其代表的纯态互为*相反数*，此时对应的变换是 $theta -> pi-theta, phi -> phi+pi$；而为了求得与纯态正交的另外两个纯态，首先将这个纯态对称于 $x O z$ 平面——这是变换 $phi -> - phi$，再做变换  $theta -> frac(pi, 2)plus.minus theta$。这两个纯态显然也分别互为相反数。

== 2.真实的布洛赫球面

在上述的球面中，要寻找与纯态正交的另一个纯态略显复杂了。解决方法是，由于研究纯态与研究其相反数是一样的，所以完全可以在球面上将相反的纯态全部剔除。“正的”纯态集中于上半球面，因此将这一部分重新映射到整个球面上——这是做变换 $theta -> frac(theta, 2)$。此时，纯态被记为：
#tufted.definition[纯态的布洛赫球表示（Bloch Sphere Representation）][
  $
    ket(psi) = cos frac(theta, 2) ket(0) + te^(ti phi)sin frac(theta, 2) ket(1)
  $ 
]
而两个计算基态分别位于球面的*北极点和南极点*，如 @实际计算基态的位置 所示。

#figure(caption: [计算基态在布洛赫球面上的实际位置])[
  #image("imgs/实际计算基态的位置.png")
] <实际计算基态的位置>

这样定义出来的球面就是*布洛赫球面*。在布洛赫球面上，*关于原点对称的两个点所代表的纯态是正交的*，因为：

$
  &mat(cos frac(theta, 2), te^(-ti  phi) sin frac(theta, 2))
  mat(cos frac(pi-theta, 2); te^(ti (phi+pi)) sin frac(pi-theta, 2)) \
  =& cos frac(theta, 2) sin frac(theta, 2)+te^(ti pi) cos frac(theta, 2) sin frac(theta, 2) \
  =& 0
$

注意第一个矩阵(行向量)是原纯态的共轭转置，因此指数要取反；第二矩阵(列向量)应用上文中的原点对称变换 $theta -> pi - theta, phi ->  phi + pi$。

== 3.纯态密度矩阵的对角化

在上一篇文章#link("../量子态与量子门/")[量子态与量子门]中我们对单量子纯态密度矩阵做了*对角化*的工作。纯态 $alpha ket(0) + beta ket(1)$ 的密度矩阵可以对角化为：

$
  mat(
    |alpha|^2, alpha overline(beta);
    overline(alpha) beta, |beta|^2
  )
  = mat(
    alpha, overline(beta);
    beta, -overline(alpha)
  )
  mat(
    1, 0;
    0, 0
  )
  mat(
    overline(alpha), overline(beta);
    beta, -alpha
  )
$

如果用角度表示法可以重新写为：

$
  &mat(
    cos^2 (theta/2), te^(-ti varphi) cos(theta/2) sin(theta/2);
    te^(ti varphi) cos(theta/2) sin(theta/2), sin^2 (theta/2)
  ) \
  =& mat(
    cos(theta/2), sin(theta/2);
    te^(ti varphi) sin(theta/2), te^(ti varphi) cos(theta/2)
  )
  mat(
    1, 0;
    0, 0
  )
  mat(
    cos(theta/2), te^(-ti varphi) sin(theta/2);
    sin(theta/2), te^(-ti varphi) cos(theta/2)
  )
$

不妨记：

$
  U_i = mat(
    cos(theta_i/2), sin(theta_i/2);
    te^(ti varphi_i) sin(theta_i/2), te^(ti varphi_i) cos(theta_i/2)
  )
  , \
  Lambda = mat(
    1, 0;
    0, 0
  )
$

就将单量子纯态的密度矩阵简记为 $ketbra(psi_i)=U_i Lambda U_i^dagger$。注意到两个量子态的密度矩阵的张量积，就是这两个量子态的量子态的密度矩阵，即$rho_(A B)=rho_A otimes rho_B$，那么从单量子纯态就可以扩展为任意(可分解)纯态：

$
    ketbra(psi) &= otimes_(i=1)^(n) ketbra(psi_i) \
    &= otimes_(i)U_i Lambda U_i^dagger \
    &= U_i^(otimes n)Lambda^(otimes n) U_i^(dagger otimes n)
$ 

由于 $Lambda$ 只在左上角有一个 $1$，所以 $Lambda^(otimes n)$ 也只在左上角有一个 $1$。这意味着，任意纯态的对角化，特征值都只有一个 $1$，其余均为 $0$ ——更加物理化一点地说，纯态对角化提供的信息是，纯态以百分百的概率处在 $ket(psi_i) ^(otimes n)$。
#footnote[您可能会说这不是废话么！但这就是经过数学处理之后得到的事实。因此您在其他地方都见不到对纯态密度矩阵的对角化，因为它基本不提供有效信息——唯一有效的是在处理过程中得到的其他特征向量，它们都代表了与这个态矢正交的纯态。但在这个纯态可以拆分为各单量子纯态之张量积的情况下，求出各单量子纯态的正交纯态之后、再任意匹配作张量积，显然更加便捷。]

#html.hr()

= 三、再论单量子门

== 1.单量子门与角度表示法

在上节中我们提到$Z$门：

$
  Z = mat(
    1, 0;
    0, -1
  )
$

它的全名是泡利 $Z$ 门，作用是将相位翻转。实际上，如果用上面的角度表示法来看待这个量子门，那么得到的新量子态是：

$
&cos frac(theta, 2) ket(0) - te^(ti  phi) sin frac(theta, 2) ket(1) \
=& cos frac(theta, 2) ket(0) + te^(ti (phi+pi)) sin frac(theta, 2) ket(1)
$ 

这对应变换$ phi -> phi+pi$，也就是让纯态矢量*绕 $z$ 轴旋转 $pi$ 角度*（或者说关于 $z$ 轴做轴对称）！这便是 $Z$ 门名称的由来。相应地，$X$ 门也是让矢量*绕* $x$ *轴旋转* $pi$ 角度，上节未提到的 $Y$ 门也是让其*绕* $y$ *轴旋转* $pi$ 角度。泡利 $Y$ 门的矩阵形式是：

$
  Y = mat(
    0, -ti;
    ti, 0
  )
$

$Z$门的旋转作用是比较直观的，但是$X,Y$门并不太好看出来。以$Y$门为例，作用于量子态之后：
$
  mat(
    0, -ti;
    ti, 0
  )
  mat(
    cos(theta/2);
    te^(ti varphi) sin(theta/2)
  )
  = mat(
    te^(ti (varphi - pi/2)) sin(theta/2);
    te^(ti pi/2) cos(theta/2)
  )
$
还记得之前说到，我们使用相对相位来表示纯态，因此总要强制 $ket(0)$ 的相位为 $0$ ，这便是以 $te^(ti(phi - frac(pi, 2)))$ *遍除*新量子态的每一项，从而新量子态应当写为：
$
sin frac(theta, 2) ket(0) +te^(ti (pi- phi))cos frac(theta, 2) ket(1)
$ 
因此看出这个量子门对原纯态(在布洛赫球面上)施加的变换为 $theta -> theta-pi, phi -> pi- phi$，这便是绕 $y$ 轴旋转了 $pi$ ！$X$ 门同理。

泡利 $Z$ 门实际是绕 $z$ 轴旋转 $delta$ 角的 $Z$ *旋转门* $R_(Z)(delta)$ 的特例，也就是取 $delta=pi$ 时：

$
  R_(Z)(delta) = mat(
    1, 0;
    0, te^(ti delta)
  )
  , \
  R_(Z)(delta) ket(psi) = cos(theta/2) ket(0) + te^(ti (varphi + delta)) sin(theta/2) ket(1)
$

对于哈达玛变换，由于它一般用于从计算基态进入实数等概率的叠加态、及其逆过程，因此我们可以忽略掉用于提供虚数的$te^(ti  phi)$。计算如下：

$
  &frac(1, sqrt(2)) mat(
    1, 1;
    1, -1
  ) mat(
    cos(theta/2);
    sin(theta/2)
  ) \
  =& frac(1, sqrt(2)) mat(
    cos(theta/2) + sin(theta/2);
    cos(theta/2) - sin(theta/2)
  ) \
  =& frac(1, sqrt(2)) mat(
    cos(pi/4 - theta/2);
    sin(pi/4 - theta/2)
  )
$

这对应变换 $theta -> frac(pi, 2)-theta$，几何上相当于*互换*了 $x$ 与 $z$ 轴——于是原来的计算基态就变成了叠加态。

== 2.单量子纯态密度矩阵的矢量化

按照上述的内容，单量子纯态在表示为 $ket(psi) = cos frac(theta, 2) ket(0) + te^(ti  phi) sin frac(theta, 2) ket(1)$ 时，可以非常直观简便地将其看做布洛赫球上的一个点。但是当它被写为密度矩阵时：

$
  mat(
    cos^2(theta/2), te^(-ti varphi) cos(theta/2) sin(theta/2);
    te^(ti varphi) cos(theta/2) sin(theta/2), sin^2(theta/2)
  )
$

反而不太直观了，因为一个矩阵要看做矢量并不是一件简单的事。将单量子密度矩阵矢量化的一种简单做法当然是将其看做下述四个“单位”矩阵的线性叠加：

$
  mat(1, 0; 0, 0) quad
  mat(0, 1; 0, 0) quad
  mat(0, 0; 1, 0) quad
  mat(0, 0; 0, 1)
$

但这四个矩阵*不是酉矩阵*，不适合用在布洛赫球面中。重新看回泡利 $X,Y,Z$ 门，现在将它们改名为泡利 $sigma_1,sigma_2,sigma_3$ 矩阵：

$
  sigma_1 = X = mat(0, 1; 1, 0), quad
  sigma_2 = Y = mat(0, -ti; ti, 0), quad
  sigma_3 = Z = mat(1, 0; 0, -1)
$

这三个矩阵的迹都等于 $0$，都是正交酉矩阵，并且*两两反对易*#footnote[如果两个算符 $F,G$ 存在关系 $F G=-G F$ ，那么称 $F$ 和 $G$ 是*反对易*的。]，要由它们生成一个迹恒等于$1$的密度矩阵，就应再找到一个迹恒为常值的酉矩阵——最简单的自然就是*单位阵* $I$ 了，将其记为 $sigma_0$：

$
  sigma_0 = I = mat(1, 0; 0, 1)
$

$sigma_(0~3)$ 可以生成以上四个“单位”矩阵，因此用 $sigma_(0~3)$ 的线性组合可以表示任意二阶矩阵，因为：

$
  cases(
    frac(1, 2)(sigma_0 + sigma_3) &= mat(1, 0; 0, 0),
    frac(1, 2)(sigma_1 + ti sigma_2) &= mat(0, 1; 0, 0),
    frac(1, 2)(sigma_1 - ti sigma_2) &= mat(0, 0; 1, 0),
    frac(1, 2)(sigma_0 - sigma_3) &= mat(0, 0; 0, 1),
  )
$

为了用 $sigma_(0~3)$ 生成密度矩阵，就必须要使其迹为 $1$ —— $tr(sigma_(1~3))$ 都为 $0$，而 $tr(sigma_0)=2$，因此密度矩阵的线性组合中*必须*要有一项 $frac(1, 2)sigma_0$。而 $sigma_(1~ 3)$ 在任意实系数线性组合下，总能让密度矩阵是*厄米的*(即$U=U^dagger$)，因此：
$
frac(1, 2)sigma_0+x sigma_1+y sigma_2+z sigma_3
$ 
必然是一个密度矩阵。为了更加规整，不妨将系数 $frac(1, 2)$ 放在最外层，并记$bold(sigma) = {sigma_1,sigma_2,sigma_3}, bold(r)={x,y,z}$，于是任意单量子密度矩阵可以记为：
$
  rho = frac(1, 2)(sigma_0 + bold(sigma) dot (bold(r))) = frac(1, 2) mat(
    1 + z, x - ti y;
    x + ti y, 1 - z
  )
$
这样便完成了对单量子纯态密度矩阵的矢量化。

但这样做的意义是什么呢？首先，混合态是不适合以右矢的形式写出的，矢量化有利于之后向混合态推广；其次，在上节我们说到*纯态*的密度矩阵是*幂等的*，因此：
$
    rho^2 &= frac(1, 4) (sigma_0^2 + 2 sigma_0 bold(sigma) dot.op bold(r) + bold(sigma)^2 bold(r)^2) \
    &= frac(1, 4) (sigma_0 + 2 bold(sigma) dot.op bold(r) + bold(sigma)^2 r^2) \
    &= rho = frac(1, 2) (sigma_0 + bold(sigma) dot.op bold(r))
$
这样得到方程：
$
bold(sigma)^2 r^2 = sigma_0
$ 
其中由于 $bold(sigma)^2 = 2sigma_0^2 - sigma_0^2 = sigma_0^2 = sigma_0$，于是得到在纯态下 $r^2=x^2+y^2+z^2=1$ 的结论。因而，在矢量化的密度矩阵中，参数 $bold(r)$ 起区分纯态与混合态的作用。而纯态的参数 $||bold(r)||$ 总是等于 $1$，这也反映了纯态必然处在布洛赫球面上。

#html.hr()

= 四、混合态与布洛赫球

== 1.从布洛赫球面到布洛赫球

在上一篇中，我们知道*混合态*密度矩阵表示为：

$
  rho_("mix") = sum_(i=1)^n p_i ketbra(psi_i)
$

而通过上面的推导，纯态的密度矩阵又是：

$
  rho = ket(psi) bra(psi) = frac(1, 2)(sigma_0 + bold(sigma) dot bold(r))
$

代入可得：

$
    rho_("mix") &= sum_(i=1)^n p_i dot frac(1, 2) (sigma_0 + bold(sigma) dot bold(r)_i) \
    &= frac(1, 2) sum_(i=1)^n p_i sigma_0 + frac(1, 2) sum_(i=1)^n p_i bold(sigma) dot bold(r)_i \
    &= frac(1, 2) sigma_0 + frac(1, 2) bold(sigma) dot sum_(i=1)^n p_i bold(r)_i
$

那么混合态的参数$bold(r)=sum p_i bold(r)_i$，平方得模长平方为：

$
    r^2 &= sum_i p_i bold(r)_i dot sum_j p_j bold(r)_j \
    &= sum_i sum_j p_i p_j bold(r)_i dot bold(r)_j \
    &< sum_i sum_j p_i p_j \
    &= sum_i p_i = 1
$

故而对于混合态来说总存在 $||bold(r)||<1$。这就说明，代表单量子混合态的点在布洛赫球面之中，于是我们就将布洛赫球面推广到了*布洛赫球*。

单量子混合态显然可以被分解成*两个正交纯态*的线性组合——这是从布洛赫球的几何形态直接推出的。因为在布洛赫球面上关于原点对称的两个纯态是正交的，因此只需延长混合态的矢量交布洛赫球面于 $A$ 点，那么与其原点对称的 $B$ 点代表的纯态就与 $A$ 纯态构成了这个混合态的正交纯态基。
#footnote[而这在数学上就相当于将密度矩阵对角化。因此 $A$ 纯态出现的概率就是原混合态参数 $bold(r)$ 的模长，$B$ 纯态的概率自然就是 $1- ||bold(r)||$ 了。在极限的情况，即密度矩阵矢量代表的就是纯态，就回到了上一篇文章中对 $alpha ket(0) + beta ket(1)$ 密度矩阵对角化的讨论，即这个纯态本身的概率就是 $1$、而 $overline(beta) ket(0) - overline(alpha) ket(1) $的概率就是 $0$。]

== 2.偏迹

在已知密度矩阵 $rho$ 的情况下，要想得知一个态 $ket(phi)$ 出现的概率，只需要计算：

$
  bra(varphi) rho ket(varphi)
$

#footnote[这是因为$bra(varphi) rho ket(varphi) = bra(varphi) ket(psi) bra(psi) ket(varphi) = |bra(varphi) ket(psi)|^2$。]

如果有两个量子*子系统* $A,B$，那么它们张成的密度矩阵就是 $rho_(A B) = rho_A otimes rho_B$。由已经展开的张量积分解为原来的两个矩阵的操作称为*偏迹*，它是张量积的逆运算，记为：

$
tr_(A)(rho_(A B)) = rho_B quad,quad tr_(B)(rho_(A B)) = rho_A
$ 

也即，求谁的偏迹，就是在恢复另一个矩阵。那么偏迹具体又应该怎么算？答案是测量——测量其中一个子系统、而不对另一个子系统操作，自然就只剩下另一个子系统了。

现在以求 $tr_(A)(rho_(A B))$ 为例，这就是要测量 $A$ 子系统而剩下 $B$ 子系统。为此，*遍历*测量 $A$ 中的每一个量子位、并且要保证不影响 $B$ 子系统，因此在测量其中一个量子位的时候要张量积上单位阵 $I$：

$
  (bra(i) otimes I) rho_(A B) (ket(i) otimes I)
$

遍历每一个量子位之后，便剩下了 $B$ 子系统：

$
  tr_(A)(rho_(A B)) = rho_B = sum_(i in A) (bra(i) otimes I) rho_(A B) (ket(i) otimes I)
$

类似地，遍历测量 $B$ 子系统就得到了 $A$ 的密度矩阵：

$
  tr_(B)(rho_(A B)) = rho_A = sum_(i in A) (I otimes bra(i)) rho_(A B) (I otimes ket(i))
$

== 3.纠缠态与完全混合态

现在来看*贝尔纠缠态*：

$
ket(Phi_plus.minus) = frac(1, sqrt(2))( ket(00) plus.minus ket(11) )
$ 

$
ket(Psi_plus.minus) = frac(1, sqrt(2))( ket(01) plus.minus ket(10) )
$ 

以 $ket(Phi_+) = frac(1, sqrt(2))( ket(00) + ket(11) )$ 为例来分析一下。容易写出此纠缠态的密度矩阵为：

$
    rho &= frac(1, 2) (ket(00) + ket(11)) otimes (bra(00) + bra(11)), \
    &= frac(1, 2) (ket(00) bra(00) + ket(00) bra(11) + ket(11) bra(00) + ket(11) bra(11)), \
    &= frac(1, 2) mat(
      1, 0, 0, 1;
      0, 0, 0, 0;
      0, 0, 0, 0;
      1, 0, 0, 1
    )
$

再来求其平方：

$
  rho^2 = frac(1, 4) mat(
    2, 0, 0, 2;
    0, 0, 0, 0;
    0, 0, 0, 0;
    2, 0, 0, 2
  ) = rho
$

这说明*贝尔纠缠态是纯态*。现在求第一个量子位的偏迹：

$
  tr_("first")(ket(Phi_+)) =& (bra(0) otimes I) rho (ket(0) otimes I) + (bra(1) otimes I) rho (ket(1) otimes I) \
  =& frac(1, sqrt(2)) ket(0) frac(1, sqrt(2)) bra(0) + frac(1, sqrt(2)) ket(1) frac(1, sqrt(2)) bra(1) \
  =& frac(1, 2) (ket(0) bra(0) + ket(1) bra(1)) \
  =& frac(1, 2) mat(1, 0; 0, 1) = rho_("second")
$

同理，求第二量子位的偏迹：

$
  tr_("second")(ket(Phi_+)) =& (I otimes bra(0)) rho (I otimes ket(0)) + (I otimes bra(1)) rho (I otimes ket(1)) \
  =& frac(1, sqrt(2)) ket(0) frac(1, sqrt(2)) bra(0) + frac(1, sqrt(2)) ket(1) frac(1, sqrt(2)) bra(1) \
  =& frac(1, 2) (ket(0) bra(0) + ket(1) bra(1)) \
  =& frac(1, 2) mat(1, 0; 0, 1) = rho_("first")
$

也就是 $rho_("first") = rho_("second") = frac(1, 2)I$，平方以后得 $rho_("first")^2 = frac(1, 4)I != rho_("first")$！如果对剩下三个贝尔纠缠态做同样的计算，结果都是相同的。这告诉我们一个事实：贝尔纠缠态本身是*纯态*，但是组成它的两个量子位都处于*相同的混合态*！推广而言，任意处于混合态的子系统，总能通过某些处理被包容在一个纯态中，这种处理称为“*纯化*”，会在之后说明。

对比贝尔纠缠态子系统的密度矩阵 $rho_("first") = rho_("second") = frac(1, 2)I = frac(1, 2)sigma_0$ 与在之前推导过的矢量化的单量子密度矩阵：

$
rho=frac(1, 2)(sigma_0 + bold(sigma) dot bold(r))
$ 

这说明贝尔纠缠态子系统的参数 $||bold(r)||=0$！在布洛赫球中，这就是*原点*的位置。将这种特殊的混合态称为*完全混合态*。

== 4.混合态的纯化

上面我们看到*纯态的子系统可以是混合态*。实际上对于任意混合态：

$
  rho_("mix") = sum_(i=1)^n p_i ket(psi_i) bra(psi_i)
$

它总能通过与另一个子系统耦合形成一个纯态。为此，必须将上述矩阵对角化（称作 *谱分解*），设这样得到的特征值为 ${q_1, q_2, ..., q_n}$，对应的特征向量为 ${ket(varphi_1), ket(varphi_2), ..., ket(varphi_n)}$，于是：

$
  rho_("mix") = sum_(i=1)^n p_i ket(psi_i) bra(psi_i) = sum_(i=1)^n q_i ket(varphi_i) bra(varphi_i)
$

#footnote[注意这里隐含的性质：特征向量代表一个纯态，这些纯态之间是正交的，而$q_i$是对应特征向量代表的纯态的概率。]

现在，在*同样维度*计算基态张成的空间中，再寻找一组正交纯态${ ket(kappa_1) , ket(kappa_2) ,..., ket(kappa_n) }$，那么像下面这样：

$
ket(varPsi) =sum_(i=1)^(n) sqrt(q_i) ket( phi_i) ket(kappa_i)
$ 

生成的量子态就会是*纯态*。这是因为：

$
  braket(Psi) =& sum_(i=1)^n sqrt(q_i) bra(kappa_i) bra(varphi_i) dot sum_(j=1)^n sqrt(q_j) ket(varphi_j) ket(kappa_j) \
  =& sum_(i=1)^n sum_(j=1)^n sqrt(q_i q_j) bra(kappa_i) braket(varphi_j) ket(kappa_j) \
  =& sum_(i=1)^n sqrt(q_i^2) braket(kappa_i) = 1
$

因此 $ket(Psi) braket(Psi) bra(Psi) = ket(Psi) bra(Psi)$，其密度矩阵是 *幂等的*，故而是纯态。问题在于，如何寻找 ${ ket(kappa_1), ket(kappa_2), ..., ket(kappa_n) }$ 这组正交纯态呢？答案其实很明显了：因为对角化得到的特征向量 ${ ket(varphi_1), ket(varphi_2), ..., ket(varphi_n) }$ 就是这个空间中的一组正交基，直接取这组基即可，这和贝尔纠缠态是类似的；甚至，更简单地，取 *计算基态* 即可。

== 5.施密特分解

混合态能被纯化为纯态——或者说，纯态系统中可能有混合态的子系统的数学原理是*施密特分解*。假设$ket(varPsi) = ket(phi) ket(K)$ 是一个由子系统 $ket(phi), ket(K)$组合成的纯态，而子系统本身可以被正交对角化分解：

$
ket(Phi) = sum_(i=1)^(n) a_i ket(Phi_i) quad,quad ket(K) = sum_(j=1)^(m) b_j ket(K_j)
$ 

注意，子系统 $ket(Phi) , ket(K)$ 的维度分别为 $n,m$，并*不要求它们相等*；${ ket(Phi_i) },{ ket(K_j) }$ 是它们各自在自己空间中的正交右矢。于是纯态 $ket(varPsi)$ 可以重新写为：

$
ket(varPsi) = sum_(i=1)^(n)sum_(j=1)^(m) a_i b_j ket(Phi_i) ket(K_j)
$ 

但施密特分解定理指出，上式还可以进一步化简为：

$
ket(varPsi) = sum_(i=1)^(min(n,m)) sqrt(lambda_i) ket(phi_i) ket(kappa_i)
$ 

其中，求和的上限是两个子空间中维数*较小*那一个。以后不妨假定$ket(K )$是较小那一个，那么上式再写为：

$
ket(varPsi) = sum_(i=1)^(m) sqrt(lambda_i) ket(phi_i) ket(kappa_i)
$ 

而 $lambda_i, ket(kappa_i)$ 分别是 $ket(K)$ 的密度矩阵 $ketbra(K)$ 对角化后的特征值与其对应的特征向量；$ket(phi_i)$ 亦是与特征值 $lambda_i$ 对应的在 $ket( phi )$ 空间中的特征向量。也就是说，$ket( phi_i), ket(kappa_i)$ *共享*同一个特征值 $lambda_i$。

因此，施密特分解其实就是混合态纯化的逆过程。上面提到的纯化虽然要求新的子系统的空间维数和原来的子系统相等，但实际只要*大于等于*即可。

