#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#let dt = $d t$
#let Ev = $"Ev"$
#let Od = $"Od"$
#let jk = $j k$
#let jnk = $j n k$
#let jkn = $j k n$
#let omega_0n = $omega_0 n$
#let omega_0t = $omega_0 t$
#let c_ke = $c_k e$
#let a_ke = $a_k e$
#let a_lb_ = $"a_l b"$
#let dot1 = $dot 1$
#let j2 = $j 2$
#let ke = $k e$
#let jl = $j l$
#let Other = $"Other"$
#let Cases = $"Cases"$
#let Nc = $N c$
#let Na = $N a$
#let lb = $l b$
#let kb = $k b$
#let j0 = $j 0$
#let Nc_l = $N c_l$
#let Na_kb_k = $N a_k b_k$
#let FS = $"FS"$
#let F = $"F"$
#let dX = $d X$
#let dY = $d Y$
#let leftrightarrow(body) = $limits(stretch(math.arrow.l.r)^#body)$
#show: template.with(
    title: "信号系统（四）——离散时间傅里叶",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


=! https://zhuanlan.zhihu.com/p/703724937
= 信号系统(四)——离散时间傅里叶

在上一节中我们介绍了连续时间周期信号的傅里叶级数，以及非周期信号与周期信号的狭义与广义傅里叶变换。那么，对于离散信号而言，也应当存在类似的级数与变换。

= 一、离散傅里叶级数的计算

== 1.离散傅里叶级数的特殊性

虽然离散信号与连续信号具有大量的相似性，但由于傅里叶级数的基底是复指数函数，这就导致离散傅里叶级数和连续情况下不同。对于连续信号 $x(t)$ 而言，当它被展开成傅里叶级数时：

$
x(t)=  sum_(k=- infinity)^(+ infinity)c_ke^(jk omega_0t)= sum_(k=- infinity)^(+ infinity)c_ke^(jk frac(2 pi, T)t)
$

可以看到 $k$ 从负无穷累加到正无穷，因此这是一个*无限项级数*；然而在信号系统(一)中提到过：

>对任意自变量 $n$ ，由于 $e^(j2 pi n)=1$ 也总是成立的，那么：
>$
x[n]=e^(j omega_0n) dot1=e^(j omega_0n) dot e^(j2 pi n)=e^(j( omega_0+2 pi)n)
$
>因此让离散指数信号的频率 $ omega_0$ 增加 $2k pi$ ，那么得到的新离散指数信号与旧的并没有区别！

所以，对于以 $N$ 为(基波)周期的离散信号 $x[n]=x[n+N]$ 而言，离散复指数函数系：

$
 [e^(j k frac(2 pi, N)n) ]= [ e^(j 0 frac(2 pi, N)n),e^(j frac(2 pi, N)n),e^(j -frac(2 pi, N)n),...  ]
$

看似具有无穷多个元素，实际 $k$ 每增加 $N$ ，就会得到一个重复的复指数函数——也就是说，*离散复指数函数系*中，只有 $N$ 个元素。

这就是导致离散傅里叶级数与连续傅里叶级数的结构稍有不同的原因。具体体现在：离散傅里叶级数是*有限项级数*、而连续傅里叶级数则是无限项的：

$
x[n]=  sum_(k= bra(N chevron.r)c_ke^(jk omega_0n)= sum_(k= chevron.l N chevron.r)c_ke^(jk frac(2 pi, N)n)
$

这里求和号下 $k= chevron.l N chevron.r$ 表示的是， $k$ 在一段 $N$ 内求和。由于离散复指数信号的性质，无论将 $k$ 在 $[0,1,...,N-1]$ 还是在 $[N,N+1,...,2N-1]$ 内求和，结果都是相同的。这也同时导出下式的结论：

$
c_k=c_(k+N)
$

也就是说，即使我们将离散傅里叶级数系数视作无穷多个，这里面也仅有 $N$ 个是有意义的。

== 2.离散傅里叶级数系数的计算

完全类似于连续时间中的情况，对于离散复指数函数来说，当时间在*一个周期*上求和时：

$
  sum_(n= chevron.l N chevron.r)e^(jk frac(2 pi, N)n)= cases(
    N, quad k=0, -N, -2N dots,
    0, quad Other  Cases,
)
$

因此，类似于连续情况中的处理，在傅里叶级数展开式两边同时乘上 $e^(-jl frac(2 pi, N)n)$ ：

$

    x[n]e^(-jl frac(2 pi, N)n)&=e^(-jl frac(2 pi, N)n)  sum_(k= chevron.l N chevron.r)c_ke^(jk frac(2 pi, N)n)\
    &= sum_(k= chevron.l N chevron.r)c_ke^(j(k-l) frac(2 pi, N)n)\

$

然后两边再在一个时间周期上求和：

$

      sum_(n= chevron.l N chevron.r)x[n]e^(-jl frac(2 pi, N)n)&= sum_(n= chevron.l N chevron.r) sum_(k= chevron.l N chevron.r)c_ke^(j(k-l) frac(2 pi, N)n)\
    &= sum_(k= chevron.l N chevron.r) { c_k sum_(n= chevron.l N chevron.r)e^(j(k-l) frac(2 pi, N)n)  }\
    &=Nc_l\

$

所以：

$
c_k= frac(1, N)  sum_(n= chevron.l N chevron.r)x[n]e^(-jk frac(2 pi, N)n)= frac(1, N) sum_(n= chevron.l N chevron.r)x[n]e^(-jk omega_0n)
$

== 3.离散傅里叶级数的收敛

离散复指数函数的特殊性质还将导致离散傅里叶级数的另一性质：即离散傅里叶级数几乎必定收敛，与连续情况中大为不同。要导出这个结论是很简单的：因为大部分信号 $x[n]$ 的取值都是有限的，那么 $x[n]e^(-jk omega_0n)$ 必定是有限值，而求和又只在有限区间内求和，所得值也必然是有限的——因此必然收敛。*吉布斯现象*也自然*不会*在离散傅里叶级数中出现。

== 4.帕塞瓦尔定理

离散情况下的*帕塞瓦尔定理*也是类似的，将积分号替换为求和号即可：

$
 frac(1, N)  sum_(n=0)^(N-1)abs(x[n])^2= sum_(k=0)^(N-1)abs(c_k)^2
$

#html.hr()

= 二、离散傅里叶级数的性质

离散傅里叶级数的性质与连续情况几乎相同，因此这里不再多做证明。但需要注意：离散情况下的信号相乘(系数卷积)与连续情况下稍有不同，这会在稍后说明。假设有信号 $x[n]\xleftrightarrow{ cal(FS)}c_k$ ，周期为 $N= frac(2 pi, omega_0)$ ：

== 1.时间平移

当时间发生平移 $n -> n-n_0$ ：

$
x[n-n_0]\xleftrightarrow{ cal(FS)}e^(-jk omega_0n_0)c_k
$

== 2.时间反演

当时间发生反演 $n -> -n$ ：

$
x[-n]\xleftrightarrow{ cal(FS)}c_(-k)
$

因此，对于奇信号来说， $c_(-k)=-c_(k)$ ；而对于偶信号， $c_(-k)=c_(k)$ 。

== 3.时间伸缩

当时间发生伸缩 $n ->  frac(n, alpha)$ ，此时应当注意只有 $n$ 是 $ alpha$ 的整数倍时 $x [  frac(n, alpha)  ]$ 才取非零值：

$
x [  frac(n, alpha)  ]\xleftrightarrow{ cal(FS)} frac(1, alpha)c_(k)
$

== 4.信号共轭

当信号取共轭 $x[n] -> overline(x[n])$ ：

$
 overline(x[n])\xleftrightarrow{ cal(FS)} overline(c_(-k))
$

按照上式，对于*实信号*来说存在 $ overline(c_(-k))=c_k$ ，因此以下四式成立：

$
 cases(
     cal(Re) {c_(k) }= cal(Re) {c_(-k) },
     cal(Im) {c_(k) }=- cal(Im) {c_(-k) },
    abs(c_(k))=abs(c_(-k)),
    arg(c_(k))=-arg(c_(-k))
)
$

== 5.信号相加(线性)

假设两个具有*相同周期*的信号：

$
 cases(
    x[n]\xleftrightarrow{ cal(FS)}a_k,
    y[n]\xleftrightarrow{ cal(FS)}b_k,
)
$

那么：

$
 alpha x[n]+ beta y[n]\xleftrightarrow{ cal(FS)} alpha a_k+ beta b_k
$

== 6.信号相乘(系数卷积)

假设两个具有*相同周期*的信号：

$
 cases(
    x[n]\xleftrightarrow{ cal(FS)}a_k,
    y[n]\xleftrightarrow{ cal(FS)}b_k,
)
$

那么：

$
x[n]y[n]\xleftrightarrow{ cal(FS)}  sum_(l= chevron.l N chevron.r)a_lb_(k-l)=a_k*b_k
$

>对比连续情况中：
>$
x(t)y(t)\xleftrightarrow{ cal(FS)}  sum_(k=- infinity)^(+ infinity)a_kb_(n-k)=a_n*b_n
$
>可以看到两者的差别在于卷积和的上下限。离散者只在*一个周期内*卷积，将其称为*周期卷积*；连续者在正负无穷中卷积，称为*非周期卷积*。虽然后面都被简记为 $a_k*b_k$ 的形式，但务必注意其中差别。

== 7.信号卷积(系数相乘)

假设两个具有*相同周期*的信号：

$
 cases(
    x[n]\xleftrightarrow{ cal(FS)}a_k,
    y[n]\xleftrightarrow{ cal(FS)}b_k,
)
$

那么对于这两个信号的*周期卷积*：

$
x[n]*y[n]=  sum_(l= chevron.l N chevron.r)x[l]y[n-l]\xleftrightarrow{ cal(FS)}Na_kb_k
$

== 8.信号差分

离散信号虽然不具有导数的概念，但一个相似的概念是*差分*。信号的*一阶差分*定义为：

$
x[n]-x[n-1]
$

因此，信号的一阶差分的傅里叶级数系数就可以利用时间平移与线性性质得出：

$
x[n]-x[n-1]\xleftrightarrow{ cal(FS)}(1-e^(-jk omega_0))c_k
$

== 9.信号求和

对于离散信号来说与积分相似的概念是求和：

$
  sum_(k=- infinity)^(n)x[k]
$

它的傅里叶级数系数是：

$
  sum_(k=- infinity)^(n)x[k]\xleftrightarrow{ cal(FS)} frac(1, 1-e^(-jk omega_0))c_k
$

>当然，在这里出现了离散傅里叶级数可能不收敛的情况，因为对信号本身的求和可能导致信号出现取值为无穷的情况。为了规避这个问题，注意到：
>$
c_0=  sum_(k= chevron.l N chevron.r)x[k]
$
>因此 $c_0$ 代表了信号在*一个周期*上的求和值。当 $c_0=0$ 时， $  sum_(k=- infinity)^(n)x[k]$ 才是有限的，此时傅里叶级数不发散。因此只有在 $c_0=0$ 时，讨论信号求和的傅里叶级数才是有意义的。

== 10.信号奇偶

对于*偶部*：

$
 cal(Ev) {x[n] }\xleftrightarrow{ cal(FS)} frac(1, 2)(c_k+c_(-k))= cal(Re) {c_k }
$

对于*奇部*：

$
 cal(Od) {x[n] }\xleftrightarrow{ cal(FS)} frac(1, 2)(c_k-c_(-k))=j cal(Im) {c_k }
$

#html.hr()

= 三、离散傅里叶变换的计算

== 1.非周期离散傅里叶变换

首先看回离散傅里叶级数系数的计算：

$
c_k= frac(1, N)  sum_(n= chevron.l N chevron.r)x[n]e^(-jk frac(2 pi, N)n)= frac(1, N) sum_(n= chevron.l N chevron.r)x[n]e^(-jk omega_0n)
$

将它代回 $x[n]=  sum_(k= chevron.l N chevron.r)c_ke^(jk omega_0n)$ ：

$

    x[n]&=  sum_(k= chevron.l N chevron.r)c_ke^(jk omega_0n)\
    &= frac(1, N) sum_(k= chevron.l N chevron.r) {  sum_(n= chevron.l N chevron.r)x[n]e^(-jk omega_0n)  } dot e^(jk omega_0n)\
    &= frac(1, 2 pi) sum_(k= chevron.l N chevron.r) {  sum_(n= chevron.l N chevron.r)x[n]e^(-jk omega_0n)  } dot e^(jk omega_0n) dot omega_0\

$

将非周期离散信号视作周期为无穷大的周期信号，也就是令 $N ->+ infinity, omega_0 ->0$ ，此时不妨记 $ omega_0$ 为 $d omega$ ，于是上式大括号中可以化为：

$

      sum_(n= chevron.l N chevron.r)x[n]e^(-jk omega_0n)&= sum_(n= chevron.l + infinity chevron.r)x[n]e^(-jnk dot d omega)\
    &= sum_(n=- infinity)^(+ infinity)x[n]e^(-j omega n)

$

观察上式可知，其运算结果为一个关于连续变量 $ omega$ 的函数。一般简便起见，视作关于 $e^(j omega)$ 的函数，也就是存在*分析公式*：

$
X(e^(j omega))= cal(F) {x[n] }= sum_(n=- infinity)^(+ infinity)x[n]e^(-j omega n)
$

按同样的极限分析 $x[n]$ ：

$

    x[n]&=  frac(1, 2 pi) sum_(k= chevron.l N chevron.r)X(e^(j omega)) dot e^(jk omega_0n) dot omega_0\
    &= frac(1, 2 pi) sum_(k= chevron.l + infinity chevron.r)X(e^(j omega)) dot e^(jkn dot d omega) dot d omega\
    &= frac(1, 2 pi) sum_(k=- infinity)^(+ infinity)X(e^(j omega)) dot e^(j omega n) dot d omega\
    &= frac(1, 2 pi) integral X(e^(j omega))e^(j omega n)  d omega\

$

上式中我们发现，在倒数第二行中，求和号右边实际已经不存在变量 $k$ 了，因为被吸收进连续变量 $ omega=k dot d omega$ 了。因此，最后是转化为了对 $ omega$ 的积分，但积分的上下限是什么？注意到 $d omega= omega_0= frac(2 pi, N)$ ，因此对 $ omega$ 来说，只需要积分区间的长度为 $2 pi$ 即可：

$
x[n]= frac(1, 2 pi) integral_(2 pi) X(e^(j omega))e^(j omega n)  d omega
$

上式便是*综合公式*。

>应当指出，使用记号 $X(e^(j omega))$ 在无形中指出了离散傅里叶变换的特殊性，即 $X(e^(j omega))$ 必定是*周期的*：
>$
X(e^(j( omega+2 pi)))=X(e^(j omega))
$
>而连续傅里叶变换 $X(j omega)$ 则一般不是。

== 2.周期离散傅里叶变换

与连续情况中相同，狭义傅里叶变换并不能适应周期信号的傅里叶变换。例如对于基本复指数信号 $x[n]=e^(j omega_0 n)$ ：

$
 cal(F) {e^(j omega_0 n) }=  sum_(n=- infinity)^(+ infinity)e^(j( omega_0- omega) n)
$

求和是不收敛的。但是通过引入单位冲激函数以及恒一函数的傅里叶变换：

$
 cases(
     cal(F) {  delta[n]  }=1,
     cal(F) { 1  }=2 pi  sum_(l=- infinity)^(+ infinity) delta( omega-2 pi l),
)
$

就可以(结合傅里叶变换的性质——具体地说，是频移性质)定义基本复指数信号的傅里叶变换：

$
 cal(F) {e^(j omega_0 n) }=2 pi  sum_(l=- infinity)^(+ infinity) delta( omega- omega_0-2 pi l)
$

所以，既然周期离散信号 $x[n]$ 可以以傅里叶级数展开为：

$
x[n]=  sum_(k= chevron.l N chevron.r)c_ke^(jk omega_0n)
$

那么其傅里叶变换就显然可以写出：

$

    X(e^(j omega))&=  sum_(k= chevron.l N chevron.r)c_k { 2 pi sum_(l=- infinity)^(+ infinity) delta( omega-k omega_0-2 pi l)  }\
    &=2 pi sum_(k=- infinity)^(+ infinity)c_k delta( omega-k omega_0)

$

此式在形式上与连续情况中是完全一致的。

#html.hr()

= 四、离散傅里叶变换的性质

假设信号 $x[n]\xleftrightarrow{ cal(F)}X(e^(j omega))$ ，其周期 $N= frac(2 pi, omega_0)$ ：

== 1.时间平移

当时间发生平移 $n -> n-n_0$ ：

$
x[n-n_0]\xleftrightarrow{ cal(F)}e^(-j omega n_0)X(e^(j omega))
$

== 2.时间反演

当时间发生反演 $n -> -n$ ：

$
x[-n]\xleftrightarrow{ cal(F)}X(e^(-j omega))
$

== 3.时间伸缩(频域伸缩)

当时间发生伸缩变换 $n ->  frac(n, k)$ ：

$
x [ frac(n, k) ]\xleftrightarrow{ cal(F)}X(e^(jk omega))
$

== 4.频域平移

当频域发生平移 $ omega -> omega- omega_0$ ：

$
e^(j omega_0 n)x[n]\xleftrightarrow{ cal(F)}X(e^(j( omega- omega_0)))
$

== 5.信号共轭

若取信号的共轭 $x[n] -> overline(x[n])$ ：

$
 overline(x[n])\xleftrightarrow{ cal(F)} overline(X(e^(-j omega)))
$

根据这个结论展开对实信号的讨论。显然存在下四式：

$
 cases(
     cal(Re) {X(e^(j omega)) }= cal(Re) {X(e^(-j omega)) },
     cal(Im) {X(e^(j omega)) }=- cal(Im) {X(e^(-j omega)) },
    abs(X(e^(j omega)))=abs(X(e^(-j omega))),
    arg(X(e^(j omega)))=-arg(X(e^(-j omega)))
)
$

== 6.信号相加(线性)

$
 alpha x[n]+ beta y[n]\xleftrightarrow{ cal(F)} alpha X(e^(j omega))+ beta Y(e^(j omega))
$

== 7.信号差分

$
x[n]-x[n-1]\xleftrightarrow{ cal(F)}(1-e^(-j omega))X(e^(j omega))
$

== 8.信号累加

$
  sum_(k=- infinity)^(n)x[n]\xleftrightarrow{ cal(F)} frac(1, 1-e^(-j omega))X(e^(j omega))
$

>当然，在奥本海姆的教科书上给出的累加性质是：
>$
  sum_(k=- infinity)^(n)x[n]\xleftrightarrow{ cal(F)} frac(1, 1-e^(-j omega))X(e^(j omega))+ pi X(e^(j0)) sum_(k=- infinity)^(+ infinity) delta( omega-2 pi k)
$

== 9.信号奇偶

$
 cases(
     cal(Ev) {x[n] }\xleftrightarrow{ cal(F)} cal(Re) {X(e^(j omega)) },
     cal(Od) {x[n] }\xleftrightarrow{ cal(F)}j cal(Im) {X(e^(j omega)) },
)
$

== 10.时域相乘(频域卷积)

$
x[n]y[n]\xleftrightarrow{ cal(F)} frac(1, 2 pi)  integral_(2 pi)X(e^(j theta))Y(e^(j( omega- theta)))d theta=X(e^(j omega))*Y(e^(j omega))
$

>注意上式是*周期卷积*。

== 11.时域卷积(频域相乘)

$
x[n]*y[n]\xleftrightarrow{ cal(F)}X(e^(j omega))Y(e^(j omega))
$

== 12.频域微分

$
n x[n]\xleftrightarrow{ cal(F)}j frac(dX(e^(j omega)), d omega)
$

#html.hr()

= 五、基本傅里叶变换表

以下给出一些基本信号的离散傅里叶变换表：

$

    & x[n]  quad& quad& X(e^(j omega))= cal(F) {x[n] } \
    &1 quad& quad&2 pi  sum_(l=- infinity)^(+ infinity) delta( omega-2 pi l)\
    & e^(j omega_0t)  quad& quad& 2 pi  sum_(l=- infinity)^(+ infinity) delta( omega- omega_0-2 pi l) \
    &  sum_(k= chevron.l N  chevron.r)a_ke^(jk omega_0t) quad& quad&2 pi sum_(k=- infinity)^(+ infinity)a_k delta( omega-k omega_0)\
    &  delta[n]  quad& quad& 1 \
    &  delta[n-n_0]  quad& quad& e^(-j omega n_0) \
    & u[n]  quad& quad&  frac(1, 1-e^(j omega))+ pi sum_(k=- infinity)^(+ infinity) delta( omega-2 pi k) \
    &  sum_(k=- infinity)^(+ infinity) delta[n-kN]  quad& quad&  frac(2 pi, N) sum_(k=- infinity)^(+ infinity) delta (  omega- frac(2k pi, N)  ) \
    & cos   omega_0n  quad& quad&  pi sum_(l=- infinity)^(+ infinity) {  delta( omega- omega_0-2 pi l)+ delta( omega+ omega_0-2 pi l)  } \
    & sin   omega_0n  quad& quad&  frac(pi, j) sum_(l=- infinity)^(+ infinity) {  delta( omega- omega_0-2 pi l)- delta( omega+ omega_0-2 pi l)  } \
    & a^nu(t),abs(a)<1  quad& quad&  frac(1, 1-ae^(-j omega)) \
    & (n+1)a^nu(t),abs(a)<1  quad& quad&  frac(1, (1-ae^(-j omega))^2) \
    &  frac((n+r-1)!, n!(r-1)!)a^nu(t),abs(a)<1  quad& quad&  frac(1, (1-ae^(-j omega))^r) \
    &  frac(sin  Wn, pi n)  quad& quad& X( omega)= cases(
        1 quad,&abs(omega)<W,
        0 quad,&W<abs(omega)< pi,
    ) \
    &  cases(
        1 quad,&abs(n)<N_1,
        0 quad,&abs(n)>N_1,
    )  quad& quad&  frac(sin (  omega(N_1+ frac(1, 2))  ), sin frac(omega, 2)) \
    &  cases(
        1 quad, quadabs(n)<N_1,
        0 quad, quad N_1<abs(n) <= frac(N, 2),
        x[n+N]=x[n],
    )  quad& quad& 2 pi sum_(k=- infinity)^(+ infinity)c_k delta( omega-k omega_0) \
    &   quad& quad&  \

$
