#import "@preview/physica:0.9.8": *
#import "@preview/lovelace:0.2.0": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../index.typ": template, tufted
#show: template.with(
    title: "量子计算（七）——振幅放大与振幅估计",
    description: "这篇文章基于Brassard的论文*Quantum amplitude amplification and estimation* @Quantum-amplitude-amplification-and-estimation 写成，大致概括了其中的算法思路，并具体计算了其中一些内容。因此这篇文章的主题就是*数学计算*，难度相比之前会有较大的跃升。但之后会回到原先基础算法的简单讲解。事实上，如果读完了这篇文章，基本就相当于理解了 Grover 算法的原理。",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$

#let result = $"result"$
#let AmpEst = $"AmpEst"$
#let QFT = $"QFT"$
#let Count = $"Count"$
#let BasicApproxCount = $"BasicApproxCount"$
#let ExactCount = $"ExactCount"$

= 量子计算（七）——振幅放大与振幅估计

#tufted.full-width[
    #image("header.jpg")
]

= 零、声明

这篇文章基于Brassard的论文*Quantum amplitude amplification and estimation* @Quantum-amplitude-amplification-and-estimation 写成，大致概括了其中的算法思路，并具体计算了其中一些内容。因此这篇文章的主题就是*数学计算*，难度相比之前会有较大的跃升。但之后会回到原先基础算法的简单讲解。

事实上，如果读完了这篇文章，基本就相当于理解了 Grover 算法的原理。笔者原准备讲述完 Grover 算法之后再发出这篇文章，但现在笔者正在思考是否应该在下一篇文章中更细致地讲 Grover 算法。

另外，请读者务必注意：文章中符号众多，并且在后面再次提及时*不会*重新解释其含义，因此请读者在阅读过程中务必*直接记住*各符号的含义。


#html.hr()

= 一、振幅放大的问题背景

== 1.问题引入

这个算法要解决的问题就是在解空间中寻找符合标准的解。设每个解都可以表示为二进制字符串，并且已知某种能够确定解空间中各个解的好坏的标准。

也就是给出*布尔函数* $ cal(X)$ ，它将解空间中的解 $x$ 映射到 $ {0,1 }$ ：
$
 cal(X)(x)= cases(
    0 & ", "quad "if"  x  "is bad",
    1 & ", "quad "if"  x  "is good",
)
$

这个目标基本和 Grover 算法要解决的问题是一致的。事实上， Grover 算法中的核心算法就是*振幅放大*，这篇论文就是对 Grover 算法的总结推广，使得任意*无测量*量子算法也可以使用。

== 2.量子化

显然，由于解空间被表示为二进制串，因而解空间可以作为一个希尔伯特空间，从而允许量子算法的运行。而解的好坏，则将其*划分*为两个子空间——称为*好空间*与*坏空间*。于是解空间的任意纯态 $ ket(psi)$ 都可以被分解表示为：

$
 ket(psi)= ket(psi_0)+ ket(psi_1)
$

其中 $ ket(psi_0)$ 表示落入坏空间的部分，相应地 $ ket(psi_1)$ 表示落入好空间的部分。于是 $b_ psi= bra(psi_0) psi_0  chevron.r$ 表示了对这个纯态测量后得到坏结果的概率， $a_ psi= chevron.l  psi_1 ket(psi_1)$ 则是得到好结果的概率，以后简记为 $a$ 。显然 $a_ psi+b_ psi=1$ 。

到这一步，我们的目标就已经清晰明朗了：只要让好空间部分的 $ ket(psi_1)$ 振幅变大，就提高了测到好结果的概率。之后只需要代入 $ cal(X)$ 判定其是否确实是好结果即可。

#html.hr()

= 二、振幅放大的构建

== 1.振幅放大算符 $ upright(bold(Q))$ 

假定 $n$ 是解空间的*二进制串的长度*。假设无测量量子算法 $ cal(A)$ 是作用到解空间上的酉矩阵，并假设纯态 $ ket(Psi)$ 是由其作用到*初始零态*的结果即 $ ket(Psi)= cal(A) ket(0^n)$ 。那么如下构建的算符 $ upright(bold(Q))$ 即可实现*振幅放大*：

$
 upright(bold(Q))= upright(bold(Q))( cal(A), cal(X))=- cal(A) upright(bold(S))_0 cal(A)^(-1) upright(bold(S))_ cal(X)
$

其中， $ upright(bold(S))$ 代表这个矩阵算符会改变振幅的*符号*，而下标表示改变的条件：

$
 upright(bold(S))_0 ket(x)= cases(
    - ket(x) & ", "quad "if " x=0^n,
     ket(x) & ", "quad "if " x !=0^n,
)
$

$
 upright(bold(S))_ cal(X) ket(x)= cases(
    - ket(x) & ", "quad "if "   cal(X)(x)=1,
     ket(x) & ", "quad "if "   cal(X)(x)=0,
)
$

显然可以将 $ upright(bold(S))_0$ 写为 $I-2 ket(0^n) bra(0^n) $ ，于是：
$
     cal(A) upright(bold(S))_0 cal(A)^(-1)&= cal(A)(I-2 ket(0^n) bra(0^n) ) cal(A)^(-1)\
    &=I-2 cal(A) ket(0^n) bra(0^n) cal(A)^(-1)\
    &=I-2 ket(Psi) bra(Psi) 
$

现在我们来研究算符 $ upright(bold(Q))$ 作用到任意态上会发生什么。由于在这个问题中纯态被分解为*好纯态*和*坏纯态*，因此研究此算符分别作用到好坏纯态上的结果。首先是坏纯态 $ ket(Psi_0)$ ：

$
     upright(bold(Q)) ket(Psi_0)&=- cal(A) upright(bold(S))_0 cal(A)^(-1) upright(bold(S))_ cal(X) ket(Psi_0)\
    &=- cal(A) upright(bold(S))_0 cal(A)^(-1) ket(Psi_0)\
    &=-(I-2 ket(Psi) bra(Psi) ) ket(Psi_0)\
    &=- ket(Psi_0)+2(1-a) ket(Psi)\
    &=(1-2a) ket(Psi_0)+2(1-a) ket(Psi_1)\
$

同理对于好纯态 $ ket(Psi_1)$ ：

$
     upright(bold(Q)) ket(Psi_1)&=- cal(A) upright(bold(S))_0 cal(A)^(-1) upright(bold(S))_ cal(X) ket(Psi_1)\
    &=(I-2 ket(Psi) bra(Psi) ) ket(Psi_1)\
    &= ket(Psi_1)-2a ket(Psi)\
    &=-2a ket(Psi_0)+(1-2a) ket(Psi_1)\
$

== 2.振幅如何被放大

假设对 $ ket(Psi)$ 施加 $k-1$ 次 $ upright(bold(Q))$ 算符后：

$
 upright(bold(Q))^(k-1) ket(Psi)=S_k ket(Psi_0)+T_k ket(Psi_1)
$

也就是好纯态的振幅变为 $T_k$ ，显然可以得到下列递推式：

$
 cases(
    S_(k+1)=(1-2a)S_k-2a T_k,
    T_(k+1)=(2-2a)S_k+(1-2a)T_k,
) quad, quad cases(
    S_1=1,
    T_1=1,
)
$

为了解出上式，首先计算 $S_k$ 与 $T_k$ 的线性组合：
$
x S_(k+1)+y T_(k+1)=[x(1-2a)+y(2-2a)]S_k+[-2a x+y(1-2a)]T_k
$
上式能成为*等比递推式*的条件是：
$
 lambda= frac(x(1-2a)+y(2-2a), x)= frac(-2a x+y(1-2a), y)
$
显然可取 $x= sqrt(a-1),y= sqrt(a)$ 从而 $ lambda=1-2a-2 sqrt(a(a-1))$ 。记 $u_k= sqrt(a-1)S_k+ sqrt(a)T_k$ ，则 $u_1= sqrt(a-1)+ sqrt(a)$ ，则 $u_k= lambda^(k-1)u_1$ 。于是：
$
S_k= frac(lambda^(k-1)u_1, sqrt(a-1))- sqrt( frac(a, a-1))T_k
$
代入递推方程组之第二式得：
$
T_(k+1)= ( 1-2a+2 sqrt(a(a-1))  )T_k- frac(2 sqrt(a-1)u_1, lambda) lambda^k
$
记 $A=1-2a+2 sqrt(a(a-1))$，$B= frac(2 sqrt(a-1)u_1, lambda)$，$C= lambda=1-2a-2 sqrt(a(a-1))$ 。已知递推形式 $a_(n+1)=A a_n+B C^n$ 在 $A != C$ 时具有通项：
$
a_n=a_1A^(n-1)+B C frac(A^(n-1)-C^(n-1), A-C)
$
代入可得：

$
    T_k&= frac(sqrt(a)- sqrt(a-1), 2 sqrt(a)) ( 1-2a+2 sqrt(a(a-1))  )^(k-1)\
    & quad+ frac(sqrt(a)+ sqrt(a-1), 2 sqrt(a)) ( 1-2a-2 sqrt(a(a-1))  )^(k-1)\
$

或者说，对于 $ upright(bold(Q))^(k) ket(Psi)$ ，若记 $a=sin^2 theta$ 且不等于 $0$ 或 $1$ 且限定 $ theta in (0, frac(pi, 2) ]$ ，那么其好纯态的振幅是：

$
    T_(k+1)&= frac(sqrt(a)- sqrt(a-1), 2 sqrt(a)) ( 1-2a+2 sqrt(a(a-1))  )^(k)\
    & quad+ frac(sqrt(a)+ sqrt(a-1), 2 sqrt(a)) ( 1-2a-2 sqrt(a(a-1))  )^(k)\
    &= frac(sin theta-ti cos theta, 2 sqrt(a))(1-2sin^2 theta+ti 2sin theta cos theta)^k\
    & quad+ frac(sin theta+ti cos theta, 2 sqrt(a))(1-2sin^2 theta-ti 2sin theta cos theta)^k\
    &= frac(- te^(ti ( frac(pi, 2)+ theta)), 2 sqrt(a))(cos 2 theta+ti sin 2 theta)^k+ frac(te^(ti ( frac(pi, 2)- theta)), 2 sqrt(a))(cos 2 theta-ti sin 2 theta)^k\
    &= frac(- te^(ti ( frac(pi, 2)+(2k+1) theta)), 2 sqrt(a))+ frac(te^(ti ( frac(pi, 2)-(2k+1) theta)), 2 sqrt(a))\
    &= frac(1, sqrt(a)) dot sin ( (2k+1) theta  )\
$

因此，作用 $ upright(bold(Q))$ 算符 $k$ 次后，测得*好纯态*的概率就是 $sin^2 ( (2k+1) theta  )$ 。我们可以将结论记为：

$
 upright(bold(Q))^k ket(Phi)= frac(1, sqrt(1-a))cos((2k+1) theta) ket(Phi_0)+ frac(1, sqrt(a))sin((2k+1) theta) ket(Phi_1)
$

== 3.算符 $ upright(bold(Q))$ 的几何意义

首先显然易见的是 $ ket(Psi_0)$ 与 $ ket(Psi_1)$ 是*正交的*，因此完全可以将这两个态作为平面坐标系的两个轴，并将 $ ket(Psi)$ 标注其中(而 $a=sin^2 theta$ 中的 $ theta$ ，就是 $ ket(Psi)$ 与 $ ket(Psi_0)$ 的张角)：

#figure(caption: [$ket(Psi)$在$ket(Psi_0)$ 与 $ket(Psi_1)$所张坐标系中的位置])[#image("imgs/grover-coordinate1.png")]

现在我们将算符 $ upright(bold(Q))$ 拆开为两部分： $ upright(bold(S))_ cal(X)$ 与 $- cal(A) upright(bold(S))_0 cal(A)^(-1)=2 ket(Psi) bra(Psi) -I$ 。不妨首先观察 $ upright(bold(S))_ cal(X)$ ，对于任意能够被拆分为好纯态与坏纯态的态 $ ket(Psi)= ket(Psi_0)+ ket(Psi_1)$ ：

$
     upright(bold(S))_ cal(X) ket(Psi)&= ket(Psi_0)- ket(Psi_1)
$

这意味着将 $ ket(Psi)$ 以 $ ket(Psi_0)$ 为轴做了一次对称，即：

#figure(caption: [$ket(Psi)$被$upright(bold(S))$作用之后的位置])[#image("imgs/grover-coordinate2.png")]

而在此基础上再作用一次 $2 ket(Psi) bra(Psi) -I$ ：

$
    &(2 ket(Psi) bra(Psi) -I)( ket(Psi_0)- ket(Psi_1))\
    =& (2(1-a) ket(Psi)- ket(Psi_0))-(2a ket(Psi)- ket(Psi_1))\
    =& (1-4a) ket(Psi_0)+(3-4a) ket(Psi_1)\
    =& upright(bold(Q)) ket(Psi)
$

不妨计算 $ upright(bold(Q)) ket(Psi)$ 与 $ upright(bold(S))_ cal(X) ket(Psi)$ 的*中点*坐标：

$
 ( frac(1+(1-4a), 2), frac(-1+(3-4a), 2) ) = (1-2a,1-2a)
$

此时我们发现，此坐标正好在 $ ket(Psi)$ 的射线上！这意味着再作用一次 $2 ket(Psi) bra(Psi) -I$ 是将 $ upright(bold(S))_ cal(X) ket(Psi)$ 以 $ ket(Psi)$ 为轴再做一次对称，也就是：

#figure(caption: [$ket(Psi)$被$upright(bold(Q))$作用之后的位置])[#image("imgs/grover-coordinate3.png")]

因此，作用一次算符 $ upright(bold(Q))$ 就相当于将原来的态向 $ ket(Psi_1)$ 靠近 $2 theta$ 。加上原先就存在的一个 $ theta$ ，就形成了 $(2k+1) theta$ 。这也是好纯态振幅中 $sin((2k+1) theta)$ 的来历。

== 4.算符 $ upright(bold(Q))$ 作用的次数

显然我们希望测得好纯态的概率越大越好，这就要求 $sin^2 ( (2k+1) theta  ) -> 1$ ，即 $(2k+1) theta ->  frac(pi, 2)$ ，即 $k= frac(pi, 4 theta)- frac(1, 2) ->floor( frac(pi, 4 theta)  )$ 。以后记 $ tilde(m)= frac(pi, 4 theta)- frac(1, 2), m=floor( frac(pi, 4 theta)  )$ 。

此时重新计算测得好纯态的概率：

$
    sin^2 ( (2m+1) theta  )& approx sin^2 (  ( floor( frac(pi, 2 theta)  )+1  ) theta  )\
    & approx sin^2 ( floor( frac(pi, 2)  )+ theta  )\
    & >= sin^2 (   frac(pi, 2)+ theta  )\
    &=1-sin^2 theta\
    &=1-a
$

#footnote[虽然 $sin^2 ( (2m+1) theta  ) >=1-a$ 这一结论是正确的，但上式的证明是稍有问题的，即 $sin^2 ( 1+ theta  ) >= sin^2 (   frac(pi, 2)+ theta  )$ 这一步。但至少在 $ theta in[0.2854,1.8562]$ 范围内是正确的。错误的根本原因在于向下取整符号内的分母不能与外部直接约分。要想完美证明，接下来只需证 $ theta in[0,0.2854]$ 内成立即可，这里不再证明。论文中的证明是引用另一篇文章@Tight-Bounds-on-Quantum-Searching ，请自行观阅。]
也就是说测量到好纯态的概率是大于 $1-a$ 的；同时由于本就是对好纯态振幅的放大，因此这个概率也大于 $a$ 。因此最后测到好纯态的概率*至少是* $max { a,1-a  }$ 。

然而这引申出一个问题：之所以能要求让 $ upright(bold(Q))$ 作用 $floor( frac(pi, 4 theta)  )$ 次，是因为我们*已知*了 $ theta$ 值，即已知了 $a$ 值，即已知在最初的时候能够测得好纯态的概率，例如 Grover 算法中就是如此。但在实际问题中，很多时候这个值具有置信度，甚至完全未知，此时则不能确定 $ upright(bold(Q))$ 作用的次数。因此，我们有必要从 Grover 搜索算法进一步推广。

== 5.算符 $ upright(bold(Q))$ 的特征值与特征向量

除了数列递推外，我们也可以通过将 $ upright(bold(Q))$ 对角化后，简便地得到 $ upright(bold(Q))^k$ 。为此假设：

$
 upright(bold(Q))(x ket(Psi_0)+y ket(Psi_1))= lambda(x ket(Psi_0)+y ket(Psi_1))
$

显然有方程：

$
 lambda= frac(x(1-2a)+-2a y, x)= frac(x(2-2a)+y(1-2a), y)
$

这与之前数列递推所得方程很像，但并没有必然联系。相似的步骤可得特征值与特征向量为：

$
 cases(
     lambda_(plus.minus)=1-2a plus.minus 2 sqrt(a(a-1))=te^(plus.minus ti 2 theta),
     ket(Psi_ plus.minus)= frac(1, sqrt(2)) (  frac(ti, sqrt(1-a)) ket(Psi_0)+ frac(1, sqrt(a)) ket(Psi_1)  )
)
$

#footnote[在论文@Quantum-amplitude-amplification-and-estimation 中，导出 $ upright(bold(Q))^k ket(Phi)= frac(1, sqrt(1-a))cos((2k+1) theta) ket(Phi_0)+ frac(1, sqrt(a))sin((2k+1) theta) ket(Phi_1)$ 这个结论正是通过求 $ upright(bold(Q))$ 的特征值与特征向量得出的。读者可以自行尝试。]

#html.hr()

= 三、量子算法的去随机化

由上节我们已经知道，在已知 $a$ 的情况下，使用 $ upright(bold(Q))^m cal(A) ket(0^n)$ 即可使我们得到好纯态的概率为 $sin^2 ( (2m+1) theta  ) >= max { a,1-a  }$ 。然而我们依然有可能使这个概率为 $1$ ，这就是量子算法的*去随机化*。论文中给出两种方法：

== 1. $ theta$ 微调

当 $m= tilde(m)$ 时，也就是 $ frac(pi, 4 theta)- frac(1, 2)$ 恰是*整数*，那么 $ upright(bold(Q))^m cal(A) ket(0^n)$ 就自然完全得到好纯态。另一方面，若记 $overline(m)= ceil( tilde(m))$ ，那么 $overline(m)$ 次迭代又稍微多了点，因此不妨使角度 $ theta$ 更小点，取 $overline(theta)}=frac(pi,4overline(m)+2)$ 。因此，只要调整算法的初始准确率至 $overline(a)=sin^2overline( theta)}$ ，那么 $overline(m)$ 次迭代就恰恰好了。

于是问题转化为如何使算法 $ cal(A)$ 的初始准确率从 $a$ 变为 $overline(a)$ 。这很简单：只要构建另一个算法 $ cal(B)$ 使得其作用在单个量子位上时：

$
 cal(B) ket(0)=sqrt(1-frac(overline(a), a)) ket(0)+sqrt(frac(overline(a), a)) ket(1)
$

然后同时应用算法 $ cal(A), cal(B)$ ，那么当 $ cal(A)$ 输出为好结果且 $ cal(B)$ 的输出为 $ ket(1)$ 时，那么我们获得的结果就必定是好结果。

== 2. $ upright(bold(Q))$ 算符的改进(相位附加)

现在我们改进算符 $ upright(bold(Q))$ ，使其在符合条件的情况下不是改变符号，而是*附加相位*：

$
 upright(bold(Q))= upright(bold(Q))( cal(A), cal(X), phi.alt, phi)=- cal(A) upright(bold(S))_0( phi.alt) cal(A)^(-1) upright(bold(S))_ cal(X)( phi)
$

其中相位 $ phi.alt, phi in[0,2 pi]$ ，并且：

$
 upright(bold(S))_0( phi.alt) ket(x)= cases(
     te^(ti  phi.alt) ket(x) & ", "quad "if " x=0^n,
     ket(x) & ", "quad "if " x !=0^n,
)
$

$
 upright(bold(S))_ cal(X)( phi) ket(x)= cases(
     te^(ti  phi) ket(x) & ", "quad "if "  cal(X)(x)=1,
     ket(x) & ", "quad "if "  cal(X)(x)=0,
)
$

显然：

$

     upright(bold(S))_0( phi.alt)&=  sum ket(result_i) bra(i) \
    &= te^(ti  phi.alt) ket(0^n) bra(0^n) + sum_(i=1)^(2^n-1) ket(i) bra(i) \
    &= sum_(i=0)^(2^n-1) ket(i) bra(i) +( te^(ti  phi.alt)-1) ket(0^n) bra(0^n) \
    &=I+( te^(ti  phi.alt)-1) ket(0^n) bra(0^n) 
$

于是：

$

     cal(A) upright(bold(S))_0( phi.alt) cal(A)^(-1)&= cal(A) dot(I+( te^(ti  phi.alt)-1) ket(0^n) bra(0^n) ) dot cal(A)^(-1)\
    &=I+( te^(ti  phi.alt)-1) cal(A) ket(0^n) bra(0^n) cal(A)^(-1)\
    &=I+( te^(ti  phi.alt)-1) ket(Psi) bra(Psi) 
$

于是：

$

     upright(bold(Q)) ket(Psi_0)&=- cal(A) upright(bold(S))_0( phi.alt) cal(A)^(-1) upright(bold(S))_ cal(X)( phi) ket(Psi_0)\
    &=-(I+( te^(ti  phi.alt)-1) ket(Psi) bra(Psi) ) ket(Psi_0)\
    &=- ket(Psi_0)+(1- te^(ti  phi.alt))(1-a) ket(Psi)\
    &=(a( te^(ti  phi.alt)-1)- te^(ti  phi.alt)) ket(Psi_0)+(1- te^(ti  phi.alt))(1-a) ket(Psi_1)\

$

$

     upright(bold(Q)) ket(Psi_1)&=- te^(ti  phi)(I+( te^(ti  phi.alt)-1) ket(Psi) bra(Psi) ) ket(Psi_1)\
    &=- te^(ti  phi) ket(Psi_1)- te^(ti  phi)( te^(ti  phi.alt)-1)a ket(Psi)\
    &= te^(ti  phi)(1- te^(ti  phi.alt))a ket(Psi_0)+ te^(ti  phi)((1- te^(ti  phi.alt))a-1) ket(Psi_1)\

$

于是在作用 $ floor( tilde(m))$ 次 $ upright(bold(Q))( cal(A), cal(X), pi, pi)$ 后，系统处于叠加态：

$
 frac(1, sqrt(1-a))cos((2 floor( tilde(m))+1) theta) ket(Psi_0)+ frac(1, sqrt(a))sin((2 floor( tilde(m))+1) theta) ket(Psi_1)
$

之后再作用一次 $ upright(bold(Q))( cal(A), cal(X), phi.alt, phi)$ ，但要求相位 $ phi.alt, phi$ 符合下式：

$
 frac(1, sqrt(1-a))cos(...)(a( te^(ti  phi.alt)-1)- te^(ti  phi.alt))+ sqrt(a)sin(...) te^(ti  phi)(1- te^(ti  phi.alt))=0
$

也就是在这次作用之后， $ ket(Psi_0)$ 的振幅为 $0$ ，那么 $ ket(Psi_1)$ 的振幅自然就为 $1$ 了。于是问题转换为最后一次作用时应当如何选取 $ phi.alt, phi$ 。如何选取并不是论文中的重要内容，但其存在性是*可以保证*的。

#html.hr()

= 四、 QSearch 算法

在 $a$ 未知的情况下， Grover 算法不能发挥太大的作用，因为不知道算符 $ upright(bold(Q))$ 应当作用的次数，使得测得好纯态的概率偏离最优值。为此，我们推广其至 QSearch 算法。

== 1.算法流程

```C
int l = 1;  
float c = random(start=1, end=2);     // c 不等于 1 或 2。
l++;    
int M = (int)pow(c, l) + 1;

// 将 A 作用于初始零态 ket(0^n)，并测量得到 ket(x)。

if (X(x) == 1) return x;    // 如果是好结果，即 X(x)=1 ，那么return x;
else ket(Psi) = A ket(0^n);    // 否则，记录 ket(Psi)= A ket(0^n)$ 。

int j = (int)random(1, M);

// 将算符 Q 作用到 ket(Psi) 上 j 次，即 Q^j ket(Psi)。测量结果得到 ket(x)。

if (X(x) == 1) return x;    // 如果是好结果，即 X(x)=1 ，那么return x;
else goto step3;    // 否则，goto step3。
```

尽管这个算法看起来比已知 $a$ 的搜索算法的时间规模更大，但可以证明其依然是 $O( sqrt(N))$ 的。

== 2.启发式经典算法的植入

然而很多启发式经典算法也可以做到 $O( sqrt(N))$ ，这导致我们之前讨论的量子算法看起来没多少优势。但是如果考虑将这些启发式算法改造为量子算法，那不就可以在 $ sqrt(N)$ 的基础上再取一次根号么！可以证明，如果经典算法解决问题的期望时间是 $T$ ，那么将其改造为量子算法后再使用 QSearch 算法，规模是 $O( sqrt(T))$ 的。

#html.hr()

= 五、振幅估计

== 1.振幅估计的问题引入

*振幅放大*是为了寻找解，但这却不能告诉我们解空间中*有多少*解是好的。振幅估计就是为了解决这个问题。记 $t=abs( (x) | cal(X)(x)=1  )$ ，由于 $a$ 是首次运行 $ cal(A)$ 后测量得到好纯态的概率，因此 $a= frac(t, N)$ 。因此，只要我们能估计振幅 $a$ ，就能估计好解的数量。

另一方面，*振幅放大*算法的有效运行本就要求 $a$ 是已知的(除非使用 Qsearch 算法)。那么既然能够通过振幅估计得到 $a$ 的估计值，我们当然也就可以利用上振幅放大算法了。

注意到 $a=sin^2 theta$ ，现在问题转化为估计 $ theta$ 。注意到算符 $ upright(bold(Q))$ 及其作用次数使得好纯态与坏纯态的振幅形成了三角函数，因此估计这些三角函数的最大周期 $ frac(pi, theta)$ 亦可。另一方面，注意到算符 $ upright(bold(Q))$ 的*特征根*是 $te^(plus.minus ti 2 theta)$ ，利用#link("量子计算/量子傅里叶变换与相位估计/")[量子计算（六）——量子傅里叶变换与相位估计]中的*相位估计*来获得 $ upright(bold(Q))$ 的特征根也是一种可行的方法。

== 2.利用相位估计的振幅估计

将*相位估计*中的 $U$ 矩阵替换为 $ upright(bold(Q))$ 即可，如下图所示：
#tufted.full-width[
    #image("imgs/amplitude-estimation.png")
]
#tufted.margin-note[
    #figure(caption: [振幅估计的量子电路图])[] <AmplitudeEstimationCircuit>
]


于是 $y$ 就代表了 $ upright(bold(Q))$ 特征值中的相位，对比 $ upright(bold(Q))$ 的特征值可得 $ti 2 theta=ti 2 pi  frac(y, n)$ 即 $ theta= pi  frac(y, n)$ ，从而可以得到 $a$ 的一个*估计值*：

$
 tilde(a)=sin^2 (  pi dot frac(y, n)  )
$

于是得到好解的数量的估计值为 $ tilde(t)=N tilde(a)$ 。

我们记振幅估计的算法为 $AmpEst$ ，其所需参数显然为 $( cal(A), cal(X),n)$ 。而得到好解的数量的估计算法为 $Count$ ，显然这个算法只需计算 $N times AmpEst(...)$ 。此时 $AmpEst$ 所使用的参数则是 $(QFT, cal(X),n)$ ，因此 $Count$ 的参数列表是 $( cal(X),n)$ 。

== 3.误差分析

首先做点数学上的准备工作。假如已知相位误差 $abs(tilde(theta)- theta) <= epsilon.alt$ ，那么 $abs(tilde(a)-a)=abs(sin^2 tilde(theta)-sin^2 theta)$ 的上界应是什么？只需要利用和差化积，一方面：

$
    sin^2 tilde(theta)-sin^2 theta& <= sin^2( theta+ epsilon.alt)-sin^2 theta\
    &= frac(1, 2)cos(2 theta)- frac(1, 2)cos(2 theta+2 epsilon.alt)\
    &=sin(2 theta+ epsilon.alt)sin   epsilon.alt\
    &=(sin(2 theta)cos   epsilon.alt+sin   epsilon.alt cos(2 theta))sin   epsilon.alt\
    &=2 sqrt(a(1-a))cos   epsilon.alt  sin epsilon.alt+(1-2a)sin^2   epsilon.alt\
    &= sqrt(a(1-a))sin 2 epsilon.alt+(1-2a)sin^2   epsilon.alt\
    & <= 2 epsilon.alt sqrt(a(1-a))+ epsilon.alt^2
$

另一方面：

$

    sin^2 theta-sin^2 tilde(theta)& <= sin^2 theta-sin^2( theta- epsilon.alt)\
    &= sqrt(a(1-a))sin 2 epsilon.alt+(2a-1)sin^2   epsilon.alt\
    & <= 2 epsilon.alt sqrt(a(1-a))+ epsilon.alt^2

$

因此 $abs(tilde(a)-a) <= 2 epsilon.alt sqrt(a(1-a))+ epsilon.alt^2$ 。如果我们希望误差最小，即取 $ epsilon.alt= frac(pi, n)$ (因为 $y$ 是离散的整数值)，那么显然此时 $a$ 的*误差上限*是：

$
abs(tilde(a)-a) <=  frac(2 pi, n) sqrt(a(1-a))+ frac(pi^2, n^2)
$

 $t$ 的*误差上限*是：

$

    abs(tilde(t)-t)&=N abs(tilde(a)-a)\
    & <= frac(2N pi, n) sqrt(a(1-a))+ frac(N pi^2, n^2)\
    &= frac(2 pi, n) sqrt(t(N-t))+ frac(N pi^2, n^2)

$

并且由相位估计中的结论，*正确*的概率至少是 $ frac(8, pi^2)$ 。如果允许更大的误差，例如取 $ epsilon.alt= frac(k pi, n)$ ，那么正确的概率会更大，即 $1- frac(1, 2(k-1))$ 。

在最小误差下，应取 $n=ceil(sqrt(N)  )$ (至于为什么，论文中尚未说明)。此时进一步得到 $t$ 的误差上限是：

$

    abs(tilde(t)-t)& <= frac(2 pi, n) sqrt(t(N-t))+ frac(N pi^2, n^2)\
    &=2 pi sqrt( frac(t(N-t), N))+ pi^2\
    &=2 pi sqrt( frac(t(N-t), N))+11

$

== 4.给定误差时的好解数量估计算法

假定要求 $abs(tilde(t)-t) <= epsilon.alt t, epsilon.alt in (0,1]$ ，那么我们使用算法 $BasicApproxCount( cal(X),n)$ ，其步骤是：

```C
int l = 0;
l++;
int tilde_t = Count(X, 2^l);
if ( (tilde_t == 0) && (2^l < 2 * sqrt(N)) )
    goto step2;
n = ceil(frac(20 pi^2, epsilon)2^l);
tilde_t = Count(X, n);
return t;   // 要求 abs(t- tilde(t)) <= frac(2, 3)
```

根据这个思想，当我们对 $t$ *没有*任何先验估计时，我们可以使用另一算法 $ExactCount( cal(X))$ ：

```C
int tilde_t_1 = Count(X, ceil(14 pi sqrt(N)));
int M_i = ceil(30 * sqrt((tilde_t_i + 1) * (N - tilde_t_i + 1)));
int M = min(M_1, M_2);
int t_apostrophe = Count(cal(X),M);
return t;   // 要求 abs(t-t') <= frac(2, 3)
```

#set text(lang: "en")

#bibliography("reference.bib", title: none, style: "ieee")
