#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../../../index.typ": template, tufted
#let dt = $d t$
#let ds = $d s$
#let Ev = $"Ev"$
#let Od = $"Od"$
#let leftrightarrow(body) = $limits(stretch(math.arrow.l.r)^#body)$
#show: template.with(
    title: "信号系统（七）——积分变换与微分方程",
    description: "",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$
#let tj = $"j"$


= 信号系统（七）——积分变换与微分方程

#tufted.full-width[
    #image("header.jpg")
]

到目前为止，我们还只是简单认为，直接知道输入 $x(t)$ 到输出 $y(t)$ 之间的映射是什么，或者直接知道在给定输入 $x(t)$ 的情况下会得到怎样的输出 $y(t)$ 。在此情况下，利用信号卷积，系统函数 $H(...)$ 显然就是：

$
H(...)= frac(Y(...), X(...))
$

但在实际理论分析应用中，以上这些信息并不容易获取；更多的是在已知系统中的数学规律的情况下，列出微分方程，例如对力学系统、或是电路系统的分析。并且，这类系统的微分方程在大部分情况下是*线性常系数微分方程*，也就是如下形式：

$
  sum_(k=0)^(N)a_k frac(d^k, dt^k)y(t)= sum_(k=0)^(M)b_k frac(d^k, dt^k)x(t)
$

另外，有些时候我们也需要分析离散系统。此时并非微分方程，而是差分方程。*线性常系数差分方程*的一般形式如下：

$
  sum_(k=0)^(N)a_k y[n-k]= sum_(k=0)^(M)b_k x[n-k]
$

= 一、连续傅里叶变换与线性常系数微分方程

只需要将微分方程两边同时施行傅里叶变换：

$
  sum_(k=0)^(N)a_k cal(F) {  frac(d^k, dt^k)y(t)  }= sum_(k=0)^(M)b_k cal(F) {  frac(d^k, dt^k)x(t)  }
$

进一步利用*信号微分*：

$
  sum_(k=0)^(N)a_k (tj omega)^(k)Y(tj omega)= sum_(k=0)^(M)b_k (tj omega)^(k)X(tj omega)
$

 $X(tj omega),Y(tj omega)$ 中不含 $k$ ，因此可以提取到求和号外。于是系统函数就非常显然了：

$
H(tj omega)= frac(Y(tj omega), X(tj omega))= frac(sum_(k=0)^(M)b_k(tj omega)^(k), sum_(k=0)^(N)a_k(tj omega)^(k))
$

因此，对于线性常系数微分方程，其系统函数是有理分式。这样，对于任意具有有理分式形式傅里叶变换的输入 $x(t)$ ，就可以在计算 $Y(tj omega)=H(tj omega)X(tj omega)$ 之后，利用部分分式展开，非常方便地逆变换为时域上的输出信号 $y(t)$ 。

#html.hr()

= 二、拉普拉斯变换与线性常系数微分方程

== 1.双边拉普拉斯变换

只需要将微分方程两边同时施行拉普拉斯变换：

$
  sum_(k=0)^(N)a_k cal(L) {  frac(d^k, dt^k)y(t)  }= sum_(k=0)^(M)b_k cal(L) {  frac(d^k, dt^k)x(t)  }
$

进一步利用信号微分：

$
  sum_(k=0)^(N)a_k s^(k)Y(s)= sum_(k=0)^(M)b_k s^(k)X(s)
$

 $X(s),Y(s)$ 中不含 $k$ ，因此可以提取到求和号外。于是系统函数就非常显然了：

$
H(s)= frac(Y(s), X(s))= frac(sum_(k=0)^(M)b_k s^(k), sum_(k=0)^(N)a_k s^(k))
$

为了确定系统函数的*收敛域*，一般我们应当指定系统的性质，例如*因果性*或*稳定性*。之后就可以对系统的性质做出进一步的分析。

对于线性常系数微分方程，其系统函数是有理分式。这样，对任意具有有理分式形式拉普拉斯变换的输入 $x(t)$ ，就可以在计算 $Y(s)=H(s)X(s)$ 之后，利用部分分式展开，*结合收敛域*，非常方便地逆变换为时域上的输出信号 $y(t)$ 。

== 2.单边拉普拉斯变换

由于单边拉普拉斯变换的信号微分性质——即信号求导后、其拉普拉斯变换会携带初值信息，因此在不仅给出线性常系数微分方程、还给出各阶导数的初始值时，常会利用之求解。
#footnote[具体的使用例可参照以下文章：
// [简谐运动及振动的动力学解](https://zhuanlan.zhihu.com/p/529091434)
// [电磁感应中几种模型的定量分析](https://zhuanlan.zhihu.com/p/452332537)
]

在使用积分变换之后，我们将微分方程转化为了代数方程来求解。值得补充的是，有时我们可以将输入信号 $x(t)$ 重写为 $ alpha x(t)$ 。在单边拉普拉斯变换之后得到输出的拉普拉斯变换为有理分式之和：

$
 cal(Y)(s)=  sum frac(Lambda_i, s+ lambda_i)
$

记各阶导数的初始值为 $[ psi]= psi_0, psi_1,...$ ，那么上式中系数分子 $ Lambda_i$ 必然是关于 $ alpha$ 与初始值 $[ psi]$ 的函数，即 $ Lambda_i= Lambda_i ( alpha,[ psi])$ ，并且仅是*线性组合*的关系，也就是可以拆写为 $ Lambda_i= Lambda_(i_1)( alpha)+ Lambda_(i_2)([ psi])$ 。由此可以将 $ cal(Y)(s)$ 按照相关参数重新组合：

$
 cal(Y)(s)=  sum frac(Lambda_(i_1)( alpha), s+ lambda_i)+ sum frac(Lambda_(i_2)([ psi]), s+ lambda_i)
$

当 $ alpha=1$ 时自然就是原方程的解。但是，当我们置 $ alpha=0$ 时，相当于系统接受的*输入为* $0$ ，但依然产生输出：

$
 cal(Y)_2(s)=  sum frac(Lambda_(i_2)([ psi]), s+ lambda_i)
$

将这个输出称为系统的*零输入响应*。

同样地，如果置 $[ psi]=0$ #footnote[意思是使所有的初始值 $ psi_i$ 都取 $0$ ]，就相当于*初始松弛条件*，或称为令系统初始状态为 $0$ ，由此产生的输出：

$
 cal(Y)_1(s)=  sum frac(Lambda_(i_1)( alpha), s+ lambda_i)
$

就称为系统的*零状态响应*。

系统的总响应表达式：

$
 cal(Y)(s)=  sum frac(Lambda_(i_1)( alpha), s+ lambda_i)+ sum frac(Lambda_(i_2)([ psi]), s+ lambda_i)
$

说明了系统的响应总能拆分为*零输入响应和零状态响应的和*。

#html.hr()

= 三、离散傅里叶变换与线性常系数差分方程

只需要将差分方程两边同时施行离散傅里叶变换：

$
  sum_(k=0)^(N)a_k cal(F) { y[n-k]  }= sum_(k=0)^(M)b_k cal(F) { x[n-k]  }
$

进一步利用*时间平移*：

$
  sum_(k=0)^(N)a_k te^(-tj k omega)Y(te^(tj omega))= sum_(k=0)^(M)b_k te^(-tj k omega)X(te^(tj omega))
$

 $X(te^(tj omega)),Y(te^(tj omega))$ 中不含 $k$ ，因此可以提取到求和号外。于是系统函数就非常显然了：

$
H(te^(tj omega))= frac(Y(te^(tj omega)), X(te^(tj omega)))= frac(sum_(k=0)^(M)b_k te^(-tj k omega), sum_(k=0)^(N)a_k te^(-tj k omega))
$

因此，对于线性常系数差分方程，其系统函数是(关于 $te^(-tj k omega)$ 的)有理分式。这样，对于任意具有有理分式形式傅里叶变换的输入 $x(t)$ ，就可以在计算 $Y(te^(tj omega))=H(te^(tj omega))X(te^(tj omega))$ 之后，利用部分分式展开，非常方便地逆变换为时域上的输出信号 $y(t)$ 。

#html.hr()

= 四、 $Z$ 变换与线性常系数差分方程

== 1.双边 $Z$ 变换

只需要将差分方程两边同时施行 $Z$ 变换：

$
  sum_(k=0)^(N)a_k cal(Z) { y[n-k]  }= sum_(k=0)^(M)b_k cal(Z) { x[n-k]  }
$

进一步利用*时间平移*：

$
  sum_(k=0)^(N)a_k z^(-k)Y(z)= sum_(k=0)^(M)b_k z^(-k)X(z)
$

 $X(z),Y(z)$ 中不含 $k$ ，因此可以提取到求和号外。于是系统函数就非常显然了：

$
H(z)= frac(Y(z), X(z))= frac(sum_(k=0)^(M)b_k z^(-k), sum_(k=0)^(N)a_k z^(-k))
$

为了确定系统函数的*收敛域*，一般我们应当指定系统的性质，例如*因果性*或*稳定性*。之后就可以对系统的性质做出进一步的分析。

对于线性常系数差分方程，其系统函数是有理分式。这样，对于任意具有有理分式形式傅里叶变换的输入 $x(t)$ ，就可以在计算 $Y(z)=H(z)X(z)$ 之后，利用部分分式展开，结合*收敛域*，非常方便地逆变换为时域上的输出信号 $y(t)$ 。

== 2.单边 $Z$ 变换

类似于单边拉普拉斯变换，单边 $Z$ 变换的时间平移同样会使其携带初始信息。因此在给定初始值的情况下，常使用单边 $Z$ 变换来求解。并且，系统的总响应也能看做零输入响应和零状态响应的和。
