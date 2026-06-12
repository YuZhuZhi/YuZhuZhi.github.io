#import "@preview/physica:0.9.8": *
#set math.mat(delim: "[", row-gap: 4pt, column-gap: 8pt)
#import "../../index.typ": template, tufted
#show: template.with(
    title: "量子计算（五）——Deutsch-Jozsa算法与Simon算法",
    description: "量子计算的两个重要算法：Deutsch-Jozsa算法和Simon算法。前者是Deutsch算法的推广，后者则是一个与函数有关的承诺问题。",
)

#let otimes = $times.o$
#let tr = $"Tr"$
#let CNOT = $"CNOT"$
#let te = $"e"$
#let ti = $"i"$


= 量子计算（五）——Deutsch-Jozsa算法与Simon算法

#tufted.full-width[
    #image("header.jpg")
]

= 一、Deutsch算法

== 1.Deutsch问题与经典算法

*Deutsch算法*是利用量子特性实现的最简单量子算法。这个算法要解决的问题是：对于一个接受一位二进制数输入并输出一位二进制数的函数 $f(x)$ ，判断它是*常量的*(Constant)还是*平衡的*(Balanced)。将其称为*Deutsch问题*。
#footnote[当函数 $f(x)$ 对任意输入都得到相同输出时，称它是*常量的*，在这个问题中例如 $f_1(0)=f_1(1)=0$ 那么 $f_1(x)$ 就是常量的；当函数的所有输出结果一半为 $0$ 而另一半为 $1$ 时，则称它是*平衡的*。]

这个问题在经典算法里只有一种解决方法，即*分别*计算 $f(0),f(1)$ ，判断结果是否相同：

```Python
def Judge(function(bool)) -> bool:
    if (function(0) == function(1)): 
        return Constant
    else: return Balanced
```

这显然需要对函数计算两次才能判断函数性质。当然，“判断结果是否相同”也可以利用*异或*来解决，当函数为平衡函数时返回真：

```Python
def Judge(function(bool)) -> bool:
    return (function(0) ^ function(1))
```

== 2.黑箱量子门

对于量子位而言，函数的作用如下：
#figure(caption: [$f(ket(x))= ket(f(x))$的量子电路图])[#image("imgs/oracle.png")]
$
f( ket(x))= ket(f(x))
$

#footnote[虽然在上面的量子电路中将函数 $f(x)$ 视作一个“量子门”绘制在其中，但需要注意这甚至有极大的概率是非法的——因为它不一定是严格意义的量子门、也即*酉矩阵*。例如对于常量函数 $f_1(0)=f_1(1)=0$ ， $f_1(x)$ 对应的矩阵 $mat(1 , 1;  0 , 0 )$ 就不是一个酉矩阵。]
为了实现Deutsch算法，我们需要对函数进行进一步的封装，使其接受两个量子位的输入，将其记为一个*黑箱*#footnote[在英文中，会称之为*Oracle*，意为“神谕”。] $B_f$ ，量子电路如 @2QubitsOracle 所示。
#figure(caption: [$attach(scripts(B_f), tr: 0, br: 1) ket(x) ket(y)= ket(x) ket(y plus.o f(x))$的量子电路图])[#image("imgs/oracle2.png")] <2QubitsOracle>
$
attach(scripts(B_f), tr: 0, br: 1) ket(x) ket(y)= ket(x) ket(y plus.o f(x))
$

#footnote[其中 $ plus.o$ 是*异或*，也即无进位二进制加法。为什么我们要大费周章设计这样一个黑箱？这是为了生成一个合法的量子门。为了证明 $B_f$ 是一个量子门(酉矩阵)，只需要假设在量子电路中连续作用两次 $B_f$ 即可。此时第一个量子依然不变；第二个量子则是 $ ket(y plus.o f(x) plus.o f(x))= ket(y plus.o 0)= ket(y)$ ，回到原状态。因此， $B_f$ 的逆阵、转置共轭 $B^ dagger$ 就是其自身。]

== 3.Deutsch算法的实现

Deutsch算法的完整量子电路如 @DeutschCircuit 所示。
#tufted.full-width[
    #image("imgs/deutsch.png")
]
#tufted.margin-note[
    #figure(caption: [Deutsch算法的量子电路图])[] <DeutschCircuit>
]

也即可以用下列公式表示：
$
H[0] dot attach(scripts(B_f), tr: 0, br: 1) dot H[0,1] dot ket(01)
$

最终的判断结果由对 $0$ 号量子的*测量*产生。计算可知这个线路如何实现函数性质的判断：

$
    &*"After action of "H[0,1]*\
    "Origin"&=H[0] dot attach(scripts(B_f), tr: 0, br: 1) dot  frac(1, 2) (  ket(0)+ ket(1)  ) (  ket(0)- ket(1)  )\
    &*"Expand"*\
    &= frac(1, 2)H[0] dot attach(scripts(B_f), tr: 0, br: 1) dot ( ket(00)- ket(01)+ ket(10)- ket(11))\
    &*"After action of "B_f*\
    &= frac(1, 2)H[0] dot { ket(0) dot( ket(0 plus.o f(0))- ket(1 plus.o f(0)))\
    & quad + ket(1) dot( ket(0 plus.o f(1))- ket(1 plus.o f(1))) }\
    &*"Using "ket(0 plus.o x)- ket(1 plus.o x)=(-1)^x( ket(0)- ket(1))*\
    &= frac(1, 2)H[0] dot { (-1)^(f(0)) ket(0)( ket(0)- ket(1))\
    & quad+(-1)^(f(1)) ket(1)( ket(0)- ket(1)) }\
    &= frac(1, 2)H[0] dot ((-1)^(f(0)) ket(0)+(-1)^(f(1)) ket(1)) dot ( ket(0)- ket(1))\
    &*"In the first parenthesis, extract "(-1)^(f(0))*\
    &= frac(1, 2)(-1)^(f(0))H[0] dot ( ket(0)+(-1)^(f(0) plus.o f(1)) ket(1))( ket(0)- ket(1))\
    &*"After action of "H[0]*\
    &*"Using "H( ket(0)+(-1)^(x) ket(1))= sqrt(2) ket(x)*\
    &= frac(1, sqrt(2))(-1)^(f(0)) dot  ket(f(0) plus.o f(1))( ket(0)- ket(1))\
$

由最后一式可以看出， $0$ 号量子的测量结果必然为 $f(0) plus.o f(1)$ ，也正如之前经典算法所述，此*异或结果就是函数的性质*！在这个算法中，我们只运行了一次线路即得到了结果。
#footnote[另一个有趣的点在于，线路最后的运行结果 $0$ 号量子和 $1$ 号量子并非是纠缠的，不论测量谁都不影响另一个量子；而且，最后只有 $0$ 号量子包含我们需要的信息， $1$ 号量子则被丢弃。]
#footnote[如果仔细观察，Deustch算法中，在 $H[0,1]$ 作用后， $1$ 号量子的状态为 $ frac(1, sqrt(2))( ket(0)- ket(1))$ ； $B_f$ 作用后， $1$ 号量子的状态依然为 $ frac(1, sqrt(2))( ket(0)- ket(1))$ ！此事的蹊跷之处在于，我们一开始引入黑箱量子门 $B_f$ 时，状态不变的是 $0$ 号量子， $1$ 号量子反而才是应该发生改变的！]
#footnote[像这种“本应改变的量子位(通常是受控位)没变、不应变的量子位(通常是控制位)反而发生改变”的现象称为*相位反冲*(Phase Kick-back)。这一现象会是许多量子算法的基础。]

#html.hr()

= 二、Deutsch-Josza算法

== 1.哈达玛变换再探

对于哈达玛变换我们已经知道：

$
cases(
    H ket(0)= frac(1, sqrt(2))( ket(0)+ ket(1)),
    H ket(1)= frac(1, sqrt(2))( ket(0)- ket(1)),
)
$

可以合并写为：

$
    H ket(x)&= frac(1, sqrt(2))( ket(0)+(-1)^(x) ket(1))\
    &= frac(1, sqrt(2))  sum_(y=0)^(1)(-1)^(x y) ket(y)\
$

现在我们希望像上式最后一式那样，以求和的形式，写出 $ ket(x)= ket(x_0x_1...x_(n-1))$ 被 $H[0 ~ n-1]$ 操作的结果。难点在于如何确定 $ ket(y)$ 的符号。注意到单个量子哈达玛变换后 $ ket(0)$ 必是正的，因此当 $x_k=0$ 时不会对符号改变作出贡献(相当于用 $0$ 乘上某个数)。当 $x_k=1$ 时，符号就由 $ ket(y)= ket(y_0y_1...y_(n-1))$ 中有多少个 $1$ 决定了。由此可以得出：

$
    H[0 ~ n-1] ket(x)&= frac(1, sqrt(2^n))  sum_(y=0)^(2^(n)-1)(-1)^{ sum_(i=0)^(n-1)x_i y_i} ket(y)\
    &= frac(1, sqrt(2^n))  sum_(y=0)^(2^(n)-1)(-1)^(bold(x) dot  bold(y)) ket(y)\
$

第二行中将指数部分的求和视作了向量点乘。

== 2.Deutsch-Josza算法的实现

现在我们来*推广Deutsch问题*。现在函数 $f(x)$ 接受一个长度为 $n$ 的*二进制串*作为输入，而依然输出一位二进制数。要求判断这个函数是常量的还是平衡的。
#footnote[显然当 $n>1$ 时，函数可以既不是常量的也不是平衡的。为了问题的进一步讨论，应当指出我们会规定其为一个*承诺问题*(Promised Problem)，即承诺受到判断的函数必然是常量的或是平衡的，不存在其他状态。]

类似地，我们需要将函数封装为黑箱，它对量子系统的操作是：
$
attach(scripts(B_f), tr: 0~n-1, br:n) ket(x) ket(y)= ket(x) ket(y plus.o f(x))
$

其中 $ ket(x)$ 包含 $n$ 个量子，而 $y in { 0,1 }$ 。
#footnote[值得一提的是，黑箱量子门 $B_f$ 必然是一个*置换矩阵*(Permutation Matrix)，即每行每列都有且只有一个 $1$ ，其余元素均为 $0$ 。这也正是 $B_f$ 是一个量子门(酉矩阵)的基础。(当然这也说明置换矩阵不一定是 $B_f$ ，因为置换矩阵的转置共轭矩阵不一定与自身相等。)]

解决这个问题的算法即是Deutsch算法的推广——*Deutsch-Josza算法*。它使用的量子电路如 @DeutschJoszaCircuit 与Deutsch算法几乎一致：
#tufted.full-width[
    #image("imgs/dj.png")
]
#tufted.margin-note[
    #figure(caption: [Deutsch-Josza算法的量子电路图])[] <DeutschJoszaCircuit>
]
$
H[0 ~ n-1] dot attach(scripts(B_f), tr: 0~n-1, br:n) dot H[0 ~ n] dot  ket(00...01)
$

计算可得：

$
    &*"After action of "H[0 ~ n]*\
    "Origin"&= frac(1, sqrt(2^(n+1)))H[0 ~ n-1] dot attach(scripts(B_f), tr: 0~n-1, br:n) dot {  sum_(x=0)^(2^(n)-1) ket(x)  }( ket(0)- ket(1))\
    &*"After action of "attach(scripts(B_f), tr: 0~n-1, br:n)*\
    &= frac(1, sqrt(2^(n+1)))H[0 ~ n-1] dot  {  sum_(x=0)^(2^(n)-1)(-1)^(f(x)) ket(x)  }( ket(0)- ket(1))\
    &*"After action of "H[0 ~ n-1]*\
    &= frac(1, sqrt(2^(2n+1))) dot { sum_(x=0)^(2^(n)-1)(-1)^(f(x)) sum_(y=0)^(2^(n)-1)(-1)^(bold(x) dot bold(y)) ket(y)  }( ket(0)- ket(1))\
    &= { sum_(y=0)^(2^(n)-1) ( frac(1, 2^n) sum_(x=0)^(2^(n)-1)(-1)^(f(x)+ bold(x) dot bold(y)) ) ket(y) } dot  frac(1, sqrt(2)) ( ket(0)- ket(1) )
$

也就是说，最后 $0 ~ n-1$ 号量子的状态是：

$
  sum_(y=0)^(2^(n)-1) ( frac(1, 2^n) sum_(x=0)^(2^(n)-1)(-1)^(f(x)+ bold(x) dot bold(y)) ) ket(y)
$

其中，计算基态 $ ket(0^n)$ 的*振幅*是：

$
frac(1, 2^n)  sum_(x=0)^(2^(n)-1)(-1)^(f(x))
$

因此，当函数是*常量的*时，计算基态 $ ket(0^n)$ 的*概率*是：

$
abs(frac(1, 2^n) sum_(x=0)^(2^(n)-1)(-1)^(0" or "1))^2=1
$

而问题又是受承诺的，因此当测量结果并非全 $0$ 时，函数就必然是平衡的了。

总结：这个算法的测量结果*全部*为 $0$ 时，函数是常量的；否则是平衡的。

== 3.与经典算法对比

也许您在阅读Deutsch算法时会认为，量子算法计算一次相比经典算法的计算两次来说也并没有多大优势，甚至在时序上量子算法还要经过三个量子门，是完全的小题大做。但量子算法的优势需要在大规模数据前体现。例如对于推广的Deutsch问题来说，经典算法*最差时*、以及*完全确定时*需要计算 $2^(n-1)+1$ 次，而Deutsch-Josza算法依然只需要计算一次。

当然，从实用性来说，Deutsch问题确实不具有太大的现实意义，更像是为了彰显量子优越性刻意设计的问题。但也正因如此，我们得以见识一个设计精妙的量子算法可以产生多大的加速效果。

经典算法的解决思路是：*纯随机无重复*地从 $0 ~ 2^n-1$ 的字符串中挑选代入函数，如果出现一次计算结果与之前不同，即可确定是*平衡函数*；否则，以指数上升的概率认为其是*常量函数*；直到计算到第 $2^(n-1)+1$ 次即可完全确定函数性质。

#html.hr()

= 三、Simon算法

== 1.Simon问题

*Simon问题*也是一个与函数有关的*承诺问题*。设函数 $f(x)$ 接受长度为 $n$ 的二进制字符串输入，输出也是长度为 $n$ 的二进制串。承诺如果两个输入 $s_1,s_2$ 有相同的输出即 $f(s_1)=f(s_2)$ ，那么两者的(*按位*)异或必然是 $n$ 位全零字符串、或是某个特定字符串 $s$ ，即：

$
s_1 plus.o s_2 in  { 0^n,s  }
$

应当注意我们允许特殊字符串 $s$ 是 $0^n$ ，此时函数是*一一映射*的。

这个问题要解决的是：寻找到这个特定字符串 $s$ 。

== 2.Simon算法的实现

Simon算法使用的量子电路如 @SimonCircuit 和 式@SimonEquation 所示。
#tufted.full-width[
    #image("imgs/simon.png")
]
#tufted.margin-note[
    #figure(caption: [Simon算法的量子电路图])[] <SimonCircuit>
]
$
H[0 ~ n-1] dot attach(scripts(B_f), tr: 0~n-1, br: n~2n-1) dot H[0 ~ n-1] dot  ket(0^n) ket(0^n)
$ <SimonEquation>

其中，黑箱 $B_f$ 的作用与D-J算法差不多，但现在是二进制串间的按位异或：

$
B_f ket(x) ket(y)= ket(x) ket(f(x) plus.o y)
$

因此，计算算法运行过程可得：

$
    &*"After action of "H[0 ~ n-1]*\
    "Origin"&= frac(1, sqrt(2^n))H[0 ~ n-1] dot attach(scripts(B_f), tr: 0~n-1, br: n~2n-1) dot  {  sum_(x=0)^(2^n-1) ket(x)  } ket(0^n)\
    &*"After action of "attach(scripts(B_f), tr: 0~n-1, br: n~2n-1)*\
    &= frac(1, sqrt(2^n))H[0 ~ n-1] dot  sum_(x=0)^(2^n-1) ket(x) ket(f(x))\
    &*"After action of "H[0 ~ n-1]*\
    &= frac(1, 2^n) sum_(x=0)^(2^n-1) sum_(y=0)^(2^n-1)(-1)^(bold(x) dot bold(y)) ket(y) ket(f(x))\
    &= sum_(y=0)^(2^n-1) ket(y)  (  frac(1, 2^n) sum_(x=0)^(2^n-1)(-1)^(bold(x) dot bold(y)) ket(f(x))  )\
$

最后我们只对 $0 ~ n-1$ 号量子测量。当特殊字符串 $s=0^n$ 时， $f(x)$ 是*一一映射*函数，因此 $ { f(x)  }= { x  }$ ——也就是说，所有计算基态 $ ket(x)$ 都会作为态矢量 $ ket(f(x))$ 出现，只是不一定按自然数递增顺序出现而已。因此，在 $s=0^n$ 的情况下对 $0 ~ n-1$ 号量子的测量，任意一个状态出现的概率都是 $ frac(1, 2^n)$ 。

当 $s != 0^n$ 时，那么在 $f(x)$ 的*值域*中的任意一个输出 $z$ ，应当*存在且仅存在*两个不同的输入 $x_(z 1),x_(z 2)$ 使 $x_(z 1) plus.o x_(z 2)=s$ 。而由于按位异或是循环的，前式也能写为 $x_(z 2)=s plus.o x_(z 1)$ 。于是，计算任意态 $ ket(y)$ 被测量得到的概率为：

$
    &abs(frac(1, 2^n) sum_(x=0)^(2^n-1)(-1)^(bold(x) dot bold(y)) ket(f(x)))^(2)\
    =& abs(frac(1, 2^n) sum  ( (-1)^{ bold(x)_(z 1) dot bold(y)}+(-1)^{ bold(x)_(z 2) dot bold(y)} ) ket(z))^(2)\
    =& abs(frac(1, 2^n) sum  ( (-1)^{ bold(x)_(z 1) dot bold(y)}+(-1)^{(s plus.o  bold(x)_(z 1)) dot bold(y)} ) ket(z))^(2)\
    =& abs(frac(1, 2^n) sum (-1)^{ bold(x)_(z 1) dot bold(y)}  ( 1+(-1)^(bold(s)  dot bold(y)) ) ket(z))^(2)\
    =& cases(
        frac(1, 2^(n-1)) quad&",if"  bold(s)  dot bold(y)=0( mod 2),
        0 quad&",if" bold(s)  dot bold(y) != 0( mod 2),
    )
$

也就是说，在这种情况下，测量出的态 $ ket(y)$ 必定符合条件 $ bold(s) dot bold(y)=0( mod 2)$ 。但显然要想确定特殊字符串 $s$ ，测量一次绝对是不够的—— $s$ 中含有 $n$ 个未知字符，按照方程理论，需要 $n$ 个*线性无关*的方程才能完全确定(也就是 $n$ 次测量)，但实际上受“二进制字符串且不是 $0^n$ ”这个条件的限制，只需要 $n-1$ 个线性无关的方程即可。

因此要想算得 $s$ ，至少需要通过测量得到 $n-1$ 个线性无关的计算基态。在 $n-1$ 次测量下得到 $n-1$ 个线性无关的计算基态的概率是：

$
p=  product_(k=1)^(+ infinity) ( 1- frac(1, 2^k)  )
$

取对数后放缩可得：

$

    ln  p&=  sum_(k=1)^(+ infinity)ln ( 1- frac(1, 2^k)  )\
    & >=  sum_(k=1)^(+ infinity)2ln 2 dot  ( - frac(1, 2^k)  )\
    &=-2ln 2 dot  sum_(k=1)^(+ infinity) frac(1, 2^k)\
    & -> -2ln 2\

$

也就是 $p> frac(1, 4)$ ，几乎三成的概率可以在 $n-1$ 次测量下得到线性无关方程组。

使用计算机可以得到实际近似值约为：
```JAVA
public class Main {
    public static void main(String[] args) {
        System.out.println(Tandem(100));
    }

    public static BigDecimal Tandem(int iteration) {
        BigDecimal halve = BigDecimal.valueOf(1);
        BigDecimal result = BigDecimal.valueOf(1);
        for (int it = 1; it <= iteration; it++) {
            halve = halve.divide(BigDecimal.valueOf(2));
            result = result.multiply(BigDecimal.ONE.subtract(halve));
        }
        return result;
    }
}
```

```JAVA
--->result = 0.28878809508660242127...
```

当然您会说三成的概率小的离谱了，从抽卡经验来看相当于必歪呀！但如果将这 $n-1$ 次测量再进行 $m$ 次呢？那么能够得到线性无关方程组的概率就非常大了——只需要计算*不能*得到的概率至多为：

$
p' = ( 1- frac(1, 4) )^(m) = ( frac(3, 4) )^(m) < te^(- frac(m, 4))
$

例如当将整个过程重复 $10$ 次时，不能得到线性无关方程组的概率就降为 $5.63\%$ ，几乎是必然可以解决问题的。这大抵就是量子算法与概率的魅力吧。
