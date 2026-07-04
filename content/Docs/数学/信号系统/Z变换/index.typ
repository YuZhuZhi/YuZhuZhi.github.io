#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#let dt = $d t$
#let ds = $d s$
#let ROC = $upright("ROC")$
#let All = $"All"$
#let Ev = $"Ev"$
#let Od = $"Od"$
#let leftrightarrow(body) = $limits(stretch(arrow.l.r))^#body)$
#let UZ = $"UZ"$
#let UL = $"UL"$
#show: template.with(
    title: "信号系统（六）——Z变换",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$
#let tj = $"j"$


= 信号系统（六）——Z变换

#tufted.full-width[
    #image("header.jpg")
]

= 一、双边 $Z$ 变换的计算

== 1. $Z$ 变换引入

类似于从连续傅里叶变换推广到拉普拉斯变换，也可以从离散傅里叶变换推广为 $Z$ 变换——可以说， $Z$ 变换就是离散形式的拉普拉斯变换。离散傅里叶变换的定义是：

$
X(te^(tj omega))= cal(F) {x[n] }=  sum_(n=- infinity)^(+ infinity)x[n]te^(-tj omega n)
$

显然 $te^(tj omega)$ 是复平面上的一个*单位圆*。现在要将 $te^(tj omega)$ 扩展为整个复平面，最简单的做法当然是为其附上长度，也就是复数的*极坐标表示法*：

$
z=r te^(tj omega)
$

这样推广之后就是*双边* $Z$ *变换*：
#tufted.definition[双边 $Z$ 变换][
$
    X(z)&= cal(Z) {x[n] }=  sum_(n=- infinity)^(+ infinity)x[n]z^(-n)\
    &= sum_(n=- infinity)^(+ infinity)(x[n]r^(-n))te^(-tj omega n)\
    &= cal(F) {x[n]r^(-n) }
$
]
也就是说， $Z$ 变换可以看做 $x[n]r^(-n)$ 的离散傅里叶变换，而 $x[n]$ 的傅里叶变换也可以看做 $z=te^(-tj omega n)$ 即 $r=1$ 时的 $Z$ 变换。

== 2. $Z$ 变换的收敛域，零点与极点

同样地，对于给定的信号 $x[n]$ ，也应有 $r=abs(z)$ 处在一定范围内时才能使求和收敛，这个范围就是 $Z$ 变换的*收敛域* $ROC$ 。正如之前所说， $x[n]$ 的傅里叶变换可以看做 $r=1$ 时的 $Z$ 变换，因此当 $Z$ 变换的收敛域中*包含*(复平面上的)*单位圆*时 $x[n]$ 的傅里叶变换也*收敛*。

同样地，我们还是只关注变换结果为*有理分式*的那些信号，也就是*指数函数*的线性组合。设：

$
X(z)= frac(M(z), D(z))
$

与拉普拉斯变换相同，将分母多项式 $D(z)$ 的根称为*极点*，而分子多项式 $M(z)$ 的根称为*零点*。在现实中，我们更多处理的是 $n<0$ 时 $x[n]=0$ 的右边信号，此时按照 $Z$ 变换的定义式：

$
X(z)= cal(Z) {x[n] }=  sum_(n=- infinity)^(+ infinity)x[n]z^(-n)
$

其变换结果就应是 $z$ 之负幂的求和，因此对于这些信号我们也乐意写为：

$
X(z)= frac(M(z^(-1)), D(z^(-1)))
$

这些表示方法是等价的，也不改变零点和极点。

== 3. $Z$ 逆变换

同样地，由离散傅里叶逆变换可以推出 $Z$ *逆变换*：

$
x[n]=  frac(1, 2 pi tj)integral.cont X(z)z^(n-1)  d z
$

然而我们只关注具有有理分式形式的 $X(z)$ 。可以像拉普拉斯逆变换那样，将 $X(z)$ 拆写为*简单有理分式之和*：

$
X(z)=  sum frac(A_i, 1-a_i z^(-1))
$

从而根据收敛域，将 $ frac(A_i, 1-a_i z^(-1))$ 逆变换为 $A_i a_i^n u[n]$ 或 $-A_i a_i^n u[-n-1]$ 其中之一。另一种逆变换方式是将 $X(z)$ 展开为洛朗级数，也就是像定义式那样的*幂级数*：

$
X(z)=  sum_(n=- infinity)^(+ infinity)a_n z^(-n)
$

对比定义式显然有 $x[n]=a_n$ 。

#html.hr()

= 二、收敛域与极点的关系

== 1.收敛域的形状

 $Z$ 变换与拉普拉斯变换最大的不同体现在收敛域的形状。在拉普拉斯变换中，积分的收敛由 $ sigma$ 决定，而 $ sigma$ 却处在指数的位置上——因此收敛与 $ cal(Re) {s }$ 有关，在复平面上体现为一个带状区域。而 $Z$ 变换的收敛由 $r$ 决定，也就是 $z$ 的模 $abs(z)$ ，因此在复平面上体现为一个*以原点为中心的圆环区域*。

所以在表述 $Z$ 变换的收敛域时，常常以关于*模长* $abs(z)$ 的不等式表示。

== 2.收敛域内无极点

这一点与拉普拉斯变换是相同的。

== 3.收敛域何时为整个复平面

当 $x[n]$ 是*有限长序列*时，收敛域就是*整个复平面*——但可能*不包括原点* $abs(z)=0$ 和*无穷远* $abs(z)= infinity$ 。

之所以要剔除掉这两个情况，是因为在 $Z$ 变换的定义式中：

$
X(z)= cal(Z) {x[n] }=  sum_(n=- infinity)^(+ infinity)x[n]z^(-n)
$

所得结果是可能包含 $z$ 的负幂和正幂的。

== 4.当 $X(z)$ 是有理分式

当 $X(z)$ 是有理分式，那么其收敛域就由*极点*或*无穷远*界定。

== 5.右边序列

如果信号 $x[n]$ 是*右边序列*，那么其收敛域就由*内边界*向外(无穷远)延伸。结合性质 $4$ ，如果 $X(z)$ 还是*有理分式*的话，那么收敛域就由*最外的极点*开始延伸至无穷远#footnote[但不一定包括无穷远]。在此基础上，如果 $x[n]$ 还是个*因果信号*，那么收敛域包含 $abs(z)= infinity$ 。
#footnote[所谓最外的极点，指的是模长 $abs(z)$ 最大的那个极点。同理，最内的极点是指模长最小的极点。]

== 6.左边序列

如果信号 $x[n]$ 是*左边序列*，那么其收敛域就由*外边界*向内(原点)缩小。结合性质 $4$ ，如果 $X(z)$ 还是*有理分式*的话，那么收敛域就由*最内的极点*开始缩小至原点#footnote[但不一定包括原点]。在此基础上，如果 $x[n]$ 还是个*反因果信号*，那么收敛域包含 $abs(z)=0$ 。

== 7.双边序列

由于双边序列可以分解为右边序列和左边序列，因此双边序列的收敛域*至少*是两者的收敛域之交。

#html.hr()

= 三、 $Z$ 变换的性质

假设有信号 $x_1[n]limits(stretch(arrow.l.r))^(cal(Z))X_1(z),x_2[n]limits(stretch(arrow.l.r))^(cal(Z))X_2(z)$ ，并且分别具有收敛域 $R_1,R_2$ 。

== 1.时间平移

若时间发生平移 $n -> n-n_0$ ：

$
x[n-n_0]limits(stretch(arrow.l.r))^(cal(Z))z^(-n_0)X(z)
$

其收敛域还是 $R$ ，但*可能会增加或剔除* $abs(z)=0$ 或 $abs(z)= infinity$ 。

== 2.时间伸缩

若时间发生伸缩变换 $n ->  frac(n, alpha)$ (要求 $ alpha >=1$ ，也就是对于离散信号而言，只考虑时间的膨胀)：

$
x [ frac(n, alpha) ]limits(stretch(arrow.l.r))^(cal(Z))X ( z^ alpha  )
$

此时收敛域为 $R^(frac(1, alpha))$ 。

时间反演相当于取 $ alpha = -1$ ，此时有：

$
x[-n]limits(stretch(arrow.l.r))^(cal(Z))X(z^(-1))
$

== 3.复域伸缩

由于我们现在是以极坐标的形式考虑复数，因此考虑 $ frac(z, z_0)$ 就变得有意义起来。在一般情况下有：

$
z_0^n x[n]limits(stretch(arrow.l.r))^(cal(Z))X (  frac(z, z_0)  )
$

而其收敛域为 $z_0R$ 。当取 $r=abs(z_0)=1$ 时，即 $z_0=te^(tj omega_0)$ ，就得到了我们之前常常见到的形式：

$
te^(tj omega_0 n)x[n]limits(stretch(arrow.l.r))^(cal(Z))X ( te^(-tj omega_0)z  )
$

#tufted.remark[][
应当指出， $ frac(z, z_0)$ 相当于使 $z$ 的模长缩小 $abs(z_0)$ 倍，而相位则减少 $ omega_0= arg(z_0)$ 。因此复域伸缩实际还包含了*旋转*的操作，会使所有零点极点顺时针旋转 $ omega_0$ 的同时，向原点缩短 $abs(z_0)$ 倍。
]

另一个重要的特例是当 $z_0$ 取实数时即 $z_0= alpha$ ，相应地有：

$
 alpha^n x[n]limits(stretch(arrow.l.r))^(cal(Z))X (  alpha^(-1)z  )
$

== 4.信号共轭

当取信号的共轭 $x[n] ->  overline(x[n])$ ：

$
 overline(x[n])limits(stretch(arrow.l.r))^(cal(Z)) overline(X( overline(z)))
$

其收敛域还是 $R$ 。

== 5.信号相加(线性)

$
 alpha x_1[n]+ beta x_2[n]limits(stretch(arrow.l.r))^(cal(Z)) alpha X_1(z)+ beta X_2(z)
$

其收敛域*至少*是 $R_1 inter R_2$ 。

== 6.信号差分

$
x[n]-x[n-1]limits(stretch(arrow.l.r))^(cal(Z))(1-z^(-1))X(z)
$

其收敛域*至少*是 $R inter (abs(z)>0)$ 。

== 7.信号累加

$
  sum_(k=- infinity)^(n)x[k]limits(stretch(arrow.l.r))^(cal(Z)) frac(1, 1-z^(-1))X(z)
$

其收敛域*至少*是 $R inter (abs(z)>1)$ 。

== 8.时域卷积(复域相乘)

$
x_1[n]*x_2[n]limits(stretch(arrow.l.r))^(cal(Z))X_1(z)X_2(z)
$

其收敛域*至少*是 $R_1 inter R_2$ 。

== 9.复域微分

若对 $X(z)$ 在复域上微分：

$
n x[n]limits(stretch(arrow.l.r))^(cal(Z))-z frac(d, ds)X(z)
$

其收敛域还是 $R$ 。

== 10.初值定理

这个定理要求 $x[n]$ 是以 $0$ 为界的*右边信号*，即当 $n<0$ 时 $x[n]=0$ 。有*初值定理*：

$
x[0]=  lim_(z -> infinity)X(z)
$

#html.hr()

= 四、系统函数

正如拉普拉斯变换那般，*系统函数* $H(z)$ 能够非常方便地揭示系统的性质。

== 1.因果性

对于*离散线性时不变系统*而言，如果其系统函数的收敛域从某个圆开始*向外延伸*，并且*包含无穷远*，那么这个系统就是*因果的*。这个结论的*逆命题是成立的*。

在说明收敛域的性质时我们也已说明过 $H(z)$ 为因果的且为有理分式时收敛域的性质。此时其收敛域在最外的极点之外并*以之为界*，并且收敛域中包含无穷远。而对于“收敛域包含无穷远”这一表述，又有几种不同等价的形式。因果代表 $H(z)$ 的幂级数形式中必然含有 $z$ 的正幂项，这就是收敛域包含无穷远的原因。这等价于 $H(z)$ 在无穷远没有极点；也就等价于， $H(z)$ 的分子多项式的次数不能高于分母多项式。

== 2.稳定性

对于离散线性时不变系统而言，稳定性就等价于单位脉冲响应 $h[n]$ 的*傅里叶变换是收敛的*。因此，当 $H(z)$ 的收敛域中*包含单位圆*，那么系统就是*稳定的*。

对于因果的且具有有理分式的 $H(z)$ 的系统，与上述等价的描述是：所有极点*均在单位圆内*。

#html.hr()

= 五、单边 $Z$ 变换及其特殊性质

== 1.单边 $Z$ 变换

类似地，*单边* $Z$ *变换*定义为：

$
 cal(X)(z)= cal(UZ) {x[n] }=  sum_(n=0)^(+ infinity)x[n]z^(-n)
$

单边 $Z$ 变换的收敛域必然从某个圆开始*向外延伸*。注意到对于单边 $Z$ 变换来说不应包含 $z$ 的正幂项，也就是说，如果 $ cal(X)(z)$ 是有理分式，那么其分子的次数必然不能超过分母的次数。

单边 $Z$ 变换相比双边 $Z$ 变换的性质基本相同，但对于信号卷积，需要严格要求当 $n<0$ 时 $x_1[n],x_2[n]$ 都为 $0$ ，否则性质不成立。

*时间平移*与*信号差分*这两个性质则有较大不同。在这里，信号差分中会携带原信号某些时刻值的特性的来源，是时间平移的特性。

== 2.时间平移

对于信号 $x[n-1]$ ，其单边 $Z$ 变换可以计算如下：

$

     cal(UZ) {x[n-1] }&=  sum_(n=0)^(+ infinity)x[n-1]z^(-n)\
    &=x[-1]+ sum_(n=1)^(+ infinity)x[n-1]z^(-n)\
    &=x[-1]+ sum_(n=0)^(+ infinity)x[n]z^(-n-1)\
    &=z^(-1) cal(X)(z)+x[-1]

$

也就是：

$
x[n-1]limits(stretch(arrow.l.r))^(cal(UZ))z^(-1) cal(X)(z)+x[-1]
$

归纳而言，在一般情况下存在(要求 $m>0$ )：

$
x[n-m]limits(stretch(arrow.l.r))^(cal(UZ))z^(-m) cal(X)(z)+z^(-m+1)x[-1]+z^(-m+2)x[-2]+...+x[-m]
$

以上对应的是*时延*。而另一方面，对于*时间超前*：

$

     cal(UZ) {x[n+1] }&=  sum_(n=0)^(+ infinity)x[n+1]z^(-n)\
    &=-z x[0]+z x[0]+ sum_(n=1)^(+ infinity)x[n]z^(-n+1)\
    &=-z x[0]+z sum_(n=0)^(+ infinity)x[n]z^(-n)\
    &=z cal(X)(z)-z x[0]

$

也就是：

$
x[n+1]limits(stretch(arrow.l.r))^(cal(UZ))z cal(X)(z)-z x[0]
$

归纳而言，在一般情况下存在(要求 $m>0$ )：

$
x[n+m]limits(stretch(arrow.l.r))^(cal(UZ))z^m cal(X)(z)-z^(m)x[0]-z^(m-1)x[1]-...-z x[m]
$

== 3.信号差分

因此，利用时间平移的性质，可以得到单边 $Z$ 变换下的信号差分性质：

$
x[n]-x[n-1]limits(stretch(arrow.l.r))^(cal(UZ))(1-z^(-1)) cal(X)(z)-x[-1]
$

#html.hr()

= 六、基本 $Z$ 变换表

以下给出一些常见函数的*双边* $Z$ *变换*表：

#figure(
    table(
        columns: 3,
        align: left,
        [*信号*], [*Z 变换*], [*ROC*],
        [$x[n]$], [$X(z)=cal(Z)\{x[n]\}$], [全部 $z$],
        [$delta[n]$], [$1$], [全部 $z$],
        [$delta[n-n_0]$], [$z^(-n_0)$], [满足 $n_0>0$ 时 $z!=0$],
        [$delta[n-n_0]$], [$z^(-n_0)$], [满足 $n_0<0$ 时 $z!=infinity$],
        [$u[n]$], [$frac(1, 1-z^(-1))$], [$abs(z)>1$],
        [$-u[-n-1]$], [$frac(1, 1-z^(-1))$], [$abs(z)<1$],
        [$alpha^n u[n]$], [$frac(1, 1-alpha z^(-1))$], [$abs(z)>abs(alpha)$],
        [$n alpha^n u[n]$], [$frac(alpha z^(-1), (1-alpha z^(-1))^2)$], [$abs(z)>abs(alpha)$],
        [$-alpha^n u[-n-1]$], [$frac(1, 1-alpha z^(-1))$], [$abs(z)<abs(alpha)$],
        [$-n alpha^n u[-n-1]$], [$frac(alpha z^(-1), (1-alpha z^(-1))^2)$], [$abs(z)<abs(alpha)$],
        [$cos(omega_0 n) dot u[n]$], [$frac(1-(cos omega_0) z^(-1), 1-(2 cos omega_0) z^(-1)+z^(-2))$], [$abs(z)>1$],
        [$sin(omega_0 n) dot u[n]$], [$frac((sin omega_0) z^(-1), 1-(2 cos omega_0) z^(-1)+z^(-2))$], [$abs(z)>1$],
        [$r^n cos(omega_0 n) dot u[n]$], [$frac(1-(r cos omega_0) z^(-1), 1-(2 r cos omega_0) z^(-1)+r^2 z^(-2))$], [$abs(z)>r$],
        [$r^n sin(omega_0 n) dot u[n]$], [$frac((r sin omega_0) z^(-1), 1-(2 r cos omega_0) z^(-1)+r^2 z^(-2))$], [$abs(z)>r$],
    ),
    caption: [基本 $Z$ 变换表],
)
