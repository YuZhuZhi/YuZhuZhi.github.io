#import "@preview/touying:0.5.3": *
#import "@preview/physica:0.9.8": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/cetz:0.4.2": canvas, draw, vector, matrix
#import "@preview/theorion:0.5.0": *
#import "@preview/tablex:0.0.9": tablex, rowspanx, colspanx, hlinex
#import "@preview/quill:0.7.2": *
#import themes.aqua: *

#let cetz-canvas = touying-reducer.with(reduce: canvas, cover: draw.hide.with(bounds: true))

#set math.mat(delim: "[", row-gap: 10pt, column-gap: 10pt, )
#set figure(numbering: none)

#show: aqua-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [图灵奖背后的量子计算],
    // subtitle: [Subtitle],
    author: [御伫之],
    date: datetime.today(),
    institution: [中山大学],
  ),
  config-common(
    auto-offset-for-heading: true,
    handout: true,
    // show-notes-on-second-screen: bottom
  ),
  config-colors(
    primary: rgb("#006d12"),
    secondary: rgb("#10be4a")
  )
)

// #set text(font: "PingFang SC", size: 20pt)

#title-slide()

#let art = $arrow.t$
#let arr = $arrow.r$
#let artr = $arrow.tr$
#let artl = $arrow.tl$

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

= 什么是量子计算

== 量子计算的开端

#slide[
  #grid(
    columns: 2,
    column-gutter: 100pt,

    diagram(
      mark-scale:130%,
    $
      edge("rdr", overline(q), "-<|-")
      edge(#(4, 0), #(3.5, 0.5), b, "-<|-")
      edge(#(4, 1), #(3.5, 0.5), overline(b), "-<|-", label-side:#left) \
      & & edge("d", "-<|-") & & edge(#(3.5, 0.5), #(2, 1), Z', "wave") \
      & & edge(#(3.5, 2.5), #(2, 2), gamma, "wave") \
      edge("rru", q, "-|>-") & \
    $),
    pause,
    image("images/量子计算机.png", width: 100%)
  )
  #h(20pt)

  + 计算可以基于量子力学实现。
  + 量子系统可以高效模拟量子系统。
  + 经典计算在某些问题上是根本受限的。

  #speaker-note()[
    假设你有一个极其复杂的系统，比如一个分子，它有几百几千个电子。用普通计算机去精确模拟它，计算量会爆炸增长——甚至穷尽整个地球的计算资源都不够。

    但这不是因为我们的程序写的不好，而是因为这个量子系统的解空间实在太大。1981年，物理学家理查德·费曼提出了量子计算机的概念：即既然经典计算机不能高效模拟量子系统，那么不妨就用量子系统本身来完成这个任务吧！

    在此之后，这一使用大自然规定的微观物理规律来进行计算的想法，逐渐发展成了一个独立的研究领域——量子计算。它为我们提供了全新的计算工具，能够解决一些经典计算机无法高效处理的问题。
    ]
]

== 现今的量子计算

#slide[
  #grid(
    columns: 2,
    column-gutter: 20pt,
    row-gutter: 20pt,

    image("images/超导.png", width: 70%),
    pause,
    image("images/离子阱.png"), 
    pause,
    image("images/光量子.png", width: 80%),
    pause,
    image("images/中性原子.jpg", width: 68%)
  )

  #speaker-note()[#text(size: 20pt)[
    目前，量子计算的物理实现主要有以下几种途径：
    + 超导量子比特：利用超导电路中的约瑟夫森结来实现量子比特，通过微波脉冲进行精确操控。该方案具有较好的可扩展性和集成能力，但需要在接近绝对零度的极低温环境中运行。
    + 离子阱量子比特：通过电磁场捕获和操控带电离子，并利用激光实现量子态的制备与门操作。其特点是相干时间长、保真度高，但门操作速度较慢且系统扩展较为复杂。
    + 光量子比特：利用光子的偏振、路径等自由度来编码量子信息，通过线性光学器件实现量子计算。该方案可在室温下工作，抗环境干扰能力强，但光子间相互作用较弱，增加了实现通用计算的难度。
    + 中性原子量子比特：通过激光冷却和光学陷阱精确操控中性原子，并利用里德堡相互作用实现量子门操作。该方法在大规模阵列构建方面具有优势，但对激光控制精度和系统稳定性要求较高。
  ]]
]

== 量子计算基本特性

#columns(2)[
  #align(center)[
    #diagram(
      node-stroke: 1pt,
      node((0,0), [#text(size: 50pt)[$0 quad 1$] \ \ #text(size: 30pt)[经典比特]], corner-radius: 2pt, extrude: (0, 6), inset: 20pt, shape: rect, width: 200pt),
    )
  ]

  #colbreak()

  #align(center)[
    #diagram(
      node-stroke: 1pt,
      node((0,0), [#text(size: 50pt)[$ket(0) quad ket(1)$] \ \ #text(size: 30pt)[量子比特]], corner-radius: 2pt, extrude: (0, 6), inset: 20pt, shape: rect),
    )
  ]
]

#pause

#text(size: 20pt)[根本区别在于，量子比特可以处于#highlight[叠加态]，测量之后才以一定概率坍缩到确定结果：]

#figure()[
  #diagram(
    node-stroke: 1pt,
    node-inset: 15pt,
    edge-stroke: 1pt,
    edge-corner-radius: 5pt,

    node((0, 0), shape: rect, name: "origin")[$frac(i, sqrt(4))(ket(00) + ket(01) + ket(10) + ket(11))$],
    node((0, 0.5), name: "mid"),

    node((-1.5, 1), shape: rect, name: "00")[$ket(00)$],
    node((-0.4, 1), shape: rect, name: "01")[$ket(01)$],
    node((0.4, 1), shape: rect, name: "10")[$ket(10)$],
    node((1.5, 1), shape: rect, name: "11")[$ket(11)$],

    edge((0, 0), (0, 0.4))[测量],
    for x in (-1.5, -0.4, 0.4, 1.5) {
      edge((0, 0.4), (x, 0.6), (x, 1), "-|>")
    }
  )
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

= Bennett 与 Brassard

== 两位先驱

#grid(
  columns: 2,
  figure(image("images/Charles-H-Bennett-2018.jpg", width: 50%), caption: [*Charles H. Bennett* (IBM Research)]),
  figure(image("images/Gilles-Brassard.jpg", width: 50%), caption: [*Gilles Brassard* (Université de Montréal)]),
)

2026 年 3 月 18 日，国际计算机学会（ACM）宣布，将 2025 年度 ACM A.M. 图灵奖授予 Charles H. Bennett 和 Gilles Brassard，表彰二人在创建量子信息科学基础、革新安全通信与计算方面的核心贡献。这是图灵奖自 1966 年设立以来，首次颁给与量子物理直接相关的研究。

#speaker-note[#text(size: 20pt)[
  一位是物理学家，一位是计算机科学家，两人的合作跨越了四十余年，却并不起源于任何正式的实验室计划，而是始于一次泳池里的闲聊。

  1979 年 10 月，第 20 届 IEEE 计算基础研讨会在波多黎各圣胡安举行。Brassard 当时 24 岁，刚从康奈尔大学拿到博士学位，到会议上宣读一篇关于密码学基础的论文。Bennett 已在 IBM 研究院工作了六年，一直琢磨物理定律如何约束信息处理，但很少有同行对此感兴趣。他注意到日程表上 Brassard 那个密码学相关的报告，决定找机会跟对方聊聊。

  机会出现在海滩上。Brassard 正在游泳，一个陌生人径直游过来，开口就讲起一个用量子力学制造不可伪造钞票的设想。Brassard 对量子物理一无所知，但出于礼貌，他听了下去，然后很快意识到，这个听起来像科幻小说的想法，背后有严肃的科学逻辑。那次海水中的对话开启了持续至今的合作。
]]

#pagebreak()

*核心贡献*：
  - 1984年提出第一个量子密钥分发协议——*BB84*。
  - 共同奠定了“量子信息科学”这一交叉学科的基础。
  - 1996年提出了*量子隐形传态* (Quantum Teleportation) 的理论模型。

#h(20pt)
#figure()[
  #quantum-circuit(
    scale: 200%,
    lstick($ket(psi)$), 1, 1, ctrl(1), gate($H$), meter(), setwire(2), ctrl(2, wire-count: 2), setwire(0), [\ ],
    lstick($ket(0)$), 1, targ(), targ(), 1, meter(target: 1), setwire(0), [\ ],
    lstick($ket(0)$), gate($H$), ctrl(-1), 1, 1, gate($X$), gate($Z$), 1, rstick($ket(psi)$)
  )
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

= 量子计算基础

#canvas({
  import draw: *

  ortho(y: -30deg, x: 30deg, {
    on-xz({
      grid((0,-2), (8,2), stroke: gray + .5pt)
    })

    // Draw a sine wave on the xy plane
    let wave(amplitude: 1, fill: none, phases: 2, scale: 8, samples: 100) = {
      line(..(for x in range(0, samples + 1) {
        let x = x / samples
        let p = (2 * phases * calc.pi) * x
        ((x * scale, calc.sin(p) * amplitude),)
      }), fill: fill)

      let subdivs = 8
      for phase in range(0, phases) {
        let x = phase / phases
        for div in range(1, subdivs + 1) {
          let p = 2 * calc.pi * (div / subdivs)
          let y = calc.sin(p) * amplitude
          let x = x * scale + div / subdivs * scale / phases
          line((x, 0), (x, y), stroke: rgb(0, 0, 0, 150) + .5pt)
        }
      }
    }

    on-xy({
      wave(amplitude: 1.6, fill: rgb(0, 0, 255, 50))
    })
    on-xz({
      wave(amplitude: 1, fill: rgb(255, 0, 0, 50))
    })
  })
})

// == 量子态

// #slide()[

//   #set list(spacing: 30pt)

//   - #highlight[单量子计算基态]
//     - $ket(0) = mat(1 ; 0)$
//     - $ket(1) = mat(0 ; 1)$

//   #pause

//   - #highlight[单量子叠加态]
//     - $frac(1, sqrt(2)) mat(1 ; 1) pause = frac(1, sqrt(2)) ket(0) + frac(1, sqrt(2)) ket(1)$ #pause
//     - 对于任意量子态$ket(psi) = alpha ket(0) + beta ket(1)$ #pause，都应存在： $ alpha^2 + beta^2 = 1 $

// ][

//   #pause

//   - #highlight[多量子计算基态] $ ket(01) = ket(0) times.o ket(1) = mat(1 ; 0) times.o mat(0 ; 1) = mat(0 ; 1 ; 0 ; 0) $

//   #pause

//   - #highlight[张量积] $ mat(a_(11), dots, a_(1 n);
//       dots.v, dots.down, dots.v;
//       a_(n 1), dots, a_(n n)
//   ) times.o bold(B) = mat(a_(11)bold(B), dots, a_(1 n)bold(B);
//       dots.v, dots.down, dots.v;
//       a_(n 1)bold(B), dots, a_(n n)bold(B)
//   ) $

// ]



== 简单量子态

// - #highlight[量子态的振幅]：假设任意量子态$ket(psi) = sum_(i=0)^(2^n-1) alpha_i ket(i)$。其中$alpha_i in bb(C)$称为*振幅*。#pause 振幅的模的平方即$abs(alpha_i)^2$代表量子态$ket(psi)$在*测量*之后*坍缩*到基态$ket(i)$上的概率。#pause 因此显然这些复振幅需要满足概率归一化条件：$sum_(i=0)^(2^n-1) |alpha_i|^2 = 1$。

// #pause

// - #highlight[测量后坍缩到另一量子态]：假设两个两个量子态$ket(psi_1)$和$ket(psi_2)$，那么测量$ket(psi_1)$后，系统坍缩到$ket(psi_2)$上的概率为$abs(braket(psi_2, psi_1))^2$。
//   $ bra(psi) = ket(psi)^dagger, quad braket(psi_1, psi_2) = bra(psi_1) dot ket(psi_2) $

// #pause

#h(10pt)
#columns(2)[

  #align(center)[#text(size: 100pt)[$ket(0)$]]

  #colbreak()

  #align(center)[#text(size: 100pt)[$ket(1)$]]
]
#h(20pt)

#h(10pt)
#columns(2)[

  #align(center)[
    #canvas({
      import draw: *

      line((-10, 10), (-10, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    }, length: 10pt)
  ]

  #colbreak()

  #align(center)[
    #canvas({
      import draw: *

      line((0, 0), (-10, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
      line((-10, 3), (-10, 3), stroke: (thickness: 10pt, paint: white), mark: (symbol: "triangle"), close: true)
    }, length: 10pt)
  ]
]
#h(20pt)

#pause

#align(center)[#text(size: 30pt)[这是两个#highlight[相互正交]的量子态]]



#pagebreak()



// #h(20pt)
// #columns(2)[

//   #align(center)[#text(size: 40pt)[$ket(+) = frac(1, sqrt(2)) (ket(0) + ket(1))$]]

//   #colbreak()

//   #align(center)[#text(size: 40pt)[$ket(-) = frac(1, sqrt(2)) (ket(0) - ket(1))$]]
// ]
// #h(20pt)

#h(10pt)
#columns(2)[

  #align(center)[
    #canvas({
      import draw: *

    line((-9.5, 7.5), (-16.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    }, length: 10pt)
  ]

  #colbreak()

  #align(center)[
    #canvas({
      import draw: *

    line((-16.5, 7.5), (-9.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    }, length: 10pt)
  ]
]
#h(20pt)

#h(20pt)
#columns(2)[

  #align(center)[#text(size: 40pt)[#artr = $frac(1, 2)(#art + #arr)$]]

  #colbreak()

  #align(center)[#text(size: 40pt)[#artl = $frac(1, 2)(#art - #arr)$]]
]
#h(20pt)

#pause

#align(center)[#text(size: 30pt)[这也是两个相互正交的量子态]]





// - #highlight[量子态的正交性]：如果两个量子态$ket(psi_1)$和$ket(psi_2)$满足$braket(psi_1, psi_2) = 0$，则称它们是正交的。#pause
//   这实际上代表*测量$ket(psi_1)$时，不可能测量到$ket(psi_2)$*，反之同理。

// #pause

// - #highlight[典型的正交量子态]：在单量子情况下，$ket(0)$和$ket(1)$是正交的；#pause $ket(+)$和$ket(-)$也是正交的。
//   $ ket(+) = frac(1, sqrt(2)) (ket(0) + ket(1)), quad ket(-) = frac(1, sqrt(2)) (ket(0) - ket(1)) $

// #pause



== 偏振实验

假设如下两个偏振片，分别为*直角线偏振片*和*对角圆偏振片*：

#grid(
  columns: 2,
  column-gutter: 20pt,

  canvas({
    import draw: *

    line((0, 5), (10, 5), stroke: (thickness: 10pt, paint: green))
    line((5, 0), (5, 10), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )
  }, length: 8pt),

  canvas({
    import draw: *

    line((0.25, 9.75), (9.75, 0.25), stroke: (thickness: 10pt, paint: green))
    line((0.25, 0.25), (9.75, 9.75), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )
  }, length: 8pt),
)

#pause

那么对于*相同方向*的光量子：

#grid(
  columns: 2,
  column-gutter: 60pt,
  row-gutter: 20pt,

  canvas({
    import draw: *

    line((-10, 10), (-10, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0, 5), (10, 5), stroke: (thickness: 10pt, paint: green))
    line((5, 0), (5, 10), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    line((18, 5), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability")
    content((name: "probability", anchor: 75%), [$100%$], anchor: "south", padding: 10pt)
    line((20, 10), (20, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),

  canvas({
    import draw: *

    line((-10, 5), (-20, 5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0, 5), (10, 5), stroke: (thickness: 10pt, paint: green))
    line((5, 0), (5, 10), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    line((18, 5), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability")
    content((name: "probability", anchor: 75%), [$100%$], anchor: "south", padding: 10pt)
    line((30, 5), (20, 5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),

  // pause,

  canvas({
    import draw: *

    line((-9.5, 7.5), (-16.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0.25, 9.75), (9.75, 0.25), stroke: (thickness: 10pt, paint: green))
    line((0.25, 0.25), (9.75, 9.75), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    line((18, 5), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability")
    content((name: "probability", anchor: 75%), [$100%$], anchor: "south", padding: 10pt)
    line((25.5, 7.5), (18.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),

  canvas({
    import draw: *

    line((-16.5, 7.5), (-9.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0.25, 9.75), (9.75, 0.25), stroke: (thickness: 10pt, paint: green))
    line((0.25, 0.25), (9.75, 9.75), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    line((18, 5), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability")
    content((name: "probability", anchor: 75%), [$100%$], anchor: "south", padding: 10pt)
    line((18.5, 7.5), (25.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),
)

#pagebreak()

另外对于*不同方向*的光量子：

#grid(
  columns: 2,
  column-gutter: 60pt,
  row-gutter: 60pt,

  canvas({
    import draw: *

    line((-10, 10), (-10, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0.25, 9.75), (9.75, 0.25), stroke: (thickness: 10pt, paint: green))
    line((0.25, 0.25), (9.75, 9.75), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    let xShift = 1
    let yShift = 5
    line((20, 10), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "south", padding: 12pt)
    line((18.5 + xShift, 7.5 + yShift), (25.5 + xShift, 1.5 + yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)

    line((20, 0), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "north", padding: 12pt)
    line((25.5 + xShift, 7.5 - yShift), (18.5 + xShift, 1.5 - yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),

  canvas({
    import draw: *

    line((-10, 5), (-20, 5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0.25, 9.75), (9.75, 0.25), stroke: (thickness: 10pt, paint: green))
    line((0.25, 0.25), (9.75, 9.75), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    let xShift = 1
    let yShift = 5
    line((20, 10), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "south", padding: 12pt)
    line((18.5 + xShift, 7.5 + yShift), (25.5 + xShift, 1.5 + yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)

    line((20, 0), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "north", padding: 12pt)
    line((25.5 + xShift, 7.5 - yShift), (18.5 + xShift, 1.5 - yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),

  canvas({
    import draw: *

    line((-9.5, 7.5), (-16.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0, 5), (10, 5), stroke: (thickness: 10pt, paint: green))
    line((5, 0), (5, 10), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    let xShift = 1
    let yShift = 5
    line((20, 10), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "south", padding: 12pt)
    line((20 + xShift + 4, 10 + yShift), (20 + xShift + 4, 0 + yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)

    line((20, 0), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "north", padding: 12pt)
    line((30 + xShift, 5 - yShift), (20 + xShift, 5 - yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),

  canvas({
    import draw: *

    line((-16.5, 7.5), (-9.5, 1.5), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
    line((-2, 5), (-8, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "measurement")
    content((name: "measurement", anchor: 75%), [测量], anchor: "south", padding: 10pt)

    line((0, 5), (10, 5), stroke: (thickness: 10pt, paint: green))
    line((5, 0), (5, 10), stroke: (thickness: 10pt, paint: green))
    rect((0, 0), (10, 10), stroke: (thickness: 5pt), )

    let xShift = 1
    let yShift = 5
    line((20, 10), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "south", padding: 12pt)
    line((20 + xShift + 4, 10 + yShift), (20 + xShift + 4, 0 + yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)

    line((20, 0), (12, 5), stroke: (thickness: 3pt), mark: (symbol: "straight"), close: true, name: "probability1")
    content((name: "probability1", anchor: 75%), [$50%$], anchor: "north", padding: 12pt)
    line((30 + xShift, 5 - yShift), (20 + xShift, 5 - yShift), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
  }, length: 8pt),
  
)


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

= BB84 协议

#pause

#align(center)[
  你听说过量子通信吗？#pause

  你知道墨子号吗？
]

== 密码系统的安全性

#slide[
  #text(size: 25pt)[
    一个通用的密码系统通常满足两点：
    1. 设计不应当保密, 其原理与细节应当公开。
    2. 只要密钥隐秘即安全。
  ]

  #pause

  #align(center)[
    #cetz-canvas({
      import draw: *

      // ===== 下层（梯形）=====
      line(
        (-8, 0),
        (8, 0),
        (4, 4),
        (-4, 4),
        close: true,
        fill: rgb("#008f54"),
        stroke: 1pt + black
      )

      content((0, 1.5),
        align(center)[
          #text(size: 28pt, fill: white)[计算安全性 / 可证安全性]
        ]
      )

      // ===== 上层（三角形）=====
      (pause, )

        line(
          (-4, 4),
          (4, 4),
          (0, 8),
          close: true,
          fill: rgb("#45c686"),
          stroke: 1pt + black
        )

        content((0, 5),
          align(center)[
            #text(size: 28pt, fill: white)[无条件安全性]
          ]
        )
      
    })
  ]

  #speaker-note()[
    *计算安全性*: 破解该加密需要远大于窃听者拥有的计算能力或者该破解过程等价于某已被理论证明复杂的数学问题。比如常用的RSA方法便是基于大数分解问题复杂这一理论事实之上, 然而1994年Shor提出基于量子计算的大数分解算法, 成功将大数分解变成可有效快速求解的问题。
    
    *无条件安全性*: 即便给予窃听者无限的计算资源, 任意破译算法仍旧不能有效破解该加密系统。
  ]
]



// #align(center)[
//   #text(size: 40pt)[计算安全性 / 可证安全性] #pause

//   #text(size: 40pt)[无条件安全性]
// ]

// 安全性往往是指*计算安全性*或者*可证安全性*, 即破解该加密需要远大于窃听者拥有的计算能力或者该破解过程等价于某已被理论证明复杂的数学问题。比如常用的RSA方法便是基于大数分解问题复杂这一理论事实之上, 然而1994年Shor提出基于量子计算的大数分解算法, 成功将大数分解变成可有效快速求解的问题。

// 更加严苛的还有*无条件安全性*：即便给予窃听者无限的计算资源, 任意破译算法仍旧不能有效破解该加密系统。

#pagebreak()

#text(size: 25pt)[
  那么如何实现*无条件安全性*？
]

#pause

#align(center)[
  #text(size: 40pt)[#highlight[一次一密]]
]

#pause

现实世界为何不使用一次一密？
// + 密钥管理庞大：因为密钥长度与明文长度相同，因此无论是生成抑或存储，都资源消耗巨大。并且，双方的密钥必须完全同步，否则相错任意一位都会解密失败。
// + 密钥分发困难：需要以绝对安全的方式传输密钥。然而，若该方式绝对安全，为什么不直接明文传输?

#columns(2)[

  #align(center)[#text(size: 40pt)[密钥管理庞大]]

  #colbreak()

  #align(center)[#text(size: 40pt)[密钥分发困难]]
]


#pause

解决办法：
#align(center)[
  #text(size: 40pt)[#highlight[量子密钥分发]]
]

#speaker-note()[
  使用*一次一密*。这包含三点要求：
  1. 密钥长度与明文长度相同。
  2. 密钥只能使用一次。
  3. 密钥必须是真正随机的。

  现实世界为何不使用一次一密？
  + 密钥管理庞大：因为密钥长度与明文长度相同，因此无论是生成抑或存储，都资源消耗巨大。并且，双方的密钥必须完全同步，否则相错任意一位都会解密失败。
+ 密钥分发困难：需要以绝对安全的方式传输密钥。然而，若该方式绝对安全，为什么不直接明文传输?
]


// *量子密钥分发*解决的正是密钥分发困难的问题，从而实现一次一密。BB84 协议正是人类历史上第一个量子密钥分发协议，开创了量子密码学。

// #pause

// 为什么需要绝对安全？

// #pagebreak()

// 为什么需要绝对安全？
// + 这是无条件安全性数学证明的前提。即便密钥只泄漏一部分，安全性也会降级为计算安全性。
// + 密文可能因此被解出一部分，影响整体安全性。

// *量子密钥分发*解决的正是密钥分发困难的问题，从而实现一次一密。BB84 协议正是人类历史上第一个量子密钥分发协议，开创了量子密码学。




== 什么是 BB84 协议？

传统上，我们只能通过确保密钥不被窃听来实现安全性。

那么，有没有其他办法来实现安全性？

#pause

#align(center)[
  #text(size: 40pt)[有的，兄弟，有的！]

  #pause

  #text(size: 40pt)[#highlight[量子不可克隆原理]]
]

#pause

BB84 协议通过两组互不相容的量子字母表来编码经典比特，并结合量子信道中的通信与经典公开讨论，实现了窃听可检测的密钥分发。它表明，通信安全可以直接建立在量子力学基本规律之上，而不必依赖于经典计算困难性假设。

// - 关键特性：
//   - 基于 *量子不可克隆原理*。
//   - 任何对量子态的测量都会对系统产生不可逆的干扰。
//   - 抵御计算能力无限（包含量子计算机）的攻击。

// - #highlight[量子不可克隆原理]：不可能构造一个能够完美复制任意未知量子态的装置。简单而言，只有测量量子态才能获得原量子态的部分信息，但测量这一行为必然改变量子态。

#speaker-note()[量子不可克隆原理：不可能构造一个能够完美复制任意未知量子态的装置。简单而言，只有测量量子态才能获得原量子态的部分信息，但测量这一行为必然改变量子态。]

== 基底与编码

在 BB84 中，我们使用光子的偏振态进行比特编码，其偏振方向与数学表示如下：

#align(center)[
#grid(
  columns: 4,
  column-gutter: 50pt,

  figure(
      canvas({
        import draw: *
        line((0, 10), (0, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
      }, length: 8pt),
      caption: [$ket(0)$]
    ),
  figure(
      canvas({
        import draw: *
        line((0, 0), (-10, 0), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
        line((0, 3), (-10, 3), stroke: (thickness: 10pt, paint: white), mark: (symbol: "triangle"), close: true)
      }, length: 8pt),
      gap: 50pt,
      caption: [$ket(1)$]
    ),
  figure(
      canvas({
        import draw: *
        line((0, 0), (-8, -8), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
      }, length: 8pt),
      gap: 25pt,
      caption: [$ket(+)$]
    ),
  figure(
      canvas({
        import draw: *
        line((0, 0), (8, -8), stroke: (thickness: 10pt, paint: blue), mark: (symbol: "triangle"), close: true)
      }, length: 8pt),
      gap: 25pt,
      caption: [$ket(-)$]
    ),
)]

将前两个合称为*直角基*（记为$+$），后两个称为*对角基*（记为$times$）。

#pause

复习：

$ cases(#artr = frac(1, 2)(#art + #arr),
    #artl = frac(1, 2)(#art - #arr)) $

另外，在一个基下测量另一个基，得到该基的两个偏振方向的可能性都是$50%$。





== 协议过程:量子阶段

#let alice = diagram(
  node-stroke: 1pt,
  node-inset: 5pt,
  node-corner-radius: 3pt,
  edge-stroke: 1pt,
  edge-corner-radius: 5pt,

  node((0, 0), shape: rect, stroke: 0pt)[#image("images/alice.png", width: 70pt)],
  node((0, 0.5), stroke: 0pt)[Alice],
)

#let bob = diagram(
  node-stroke: 1pt,
  node-inset: 5pt,
  node-corner-radius: 3pt,
  edge-stroke: 1pt,
  edge-corner-radius: 5pt,

  node((0, 0), shape: rect, stroke: 0pt)[#image("images/bob.png", width: 70pt)],
  node((0, 0.5), stroke: 0pt)[Bob],
)


// #columns(2)[

//   1. Alice 选取一个二进制串密钥$S$。另外，随机逐位选择测量基$+$或$times$记为串$M_A$。根据字母表，通过#highlight[量子信道]发送不同偏振方向的光子。

//   #colbreak()

//   #figure(
//   tablex(
//     columns: 7,
//     align: center + horizon,
//     // stroke: none, // 默认无边框，模拟 booktabs 风格
//     auto-vlines: false,
//     auto-hlines: false,
//     inset: 9pt, 
//     // gutter: 5pt,

//     // table.hline(stroke: 1.5pt),
//     hlinex(stroke: 1.5pt),
//     [二进制串$S$], [$0$], [$0$], [$1$], [$1$], [$0$], [$dots$],
//     hlinex(stroke: 1pt),
//     [测量基$M_A$], [$+$], [$times$], [$+$], [$times$], [$+$], [$dots$],
//     hlinex(stroke: 1pt),
//     rowspanx(2)[发送光子], [$ket(0)$], [$ket(+)$], [$ket(1)$], [$ket(-)$], [$ket(0)$], [$dots$],
//     hlinex(stroke: 1pt),
//     [#art], [#artr], [#arr], [#artl], [#art], [$dots$],
//     // 底部粗线 (Bottomrule)
//     // table.hline(stroke: 1.5pt),
//     hlinex(stroke: 1.5pt),
//   )
// )
// ]

#slide[
  在 BB84 协议中，存在*经典信道*和*量子信道*。规定量子字母表如下：

  #figure(
    table(
      columns: 4,
      align: center + horizon,
      stroke: none, // 默认无边框，模拟 booktabs 风格
      
      // 顶部粗线 (Toprule)
      table.hline(stroke: 1.5pt),
      [基名称], [表示比特值], [对应量子态], [对应符号],
      
      // 中间线 (Midrule)
      table.hline(stroke: 0.5pt),
      [$+$ 基], [0], [$ket(0)$], [#art],
      [$+$ 基], [1], [$ket(1)$], [#arr],
      [$times$ 基], [0], [$ket(+)$], [#artr],
      [$times$ 基], [1], [$ket(-)$], [#artl],

      // 底部粗线 (Bottomrule)
      table.hline(stroke: 1.5pt),
    ),
    kind: table,
    // caption: [BB84协议中字母表的编码规则],
  )

  #v(20pt)

  #pause

  #grid(
    columns: 3,
    column-gutter: 20pt,

    alice,
    diagram(
      spacing: 10pt,
      node-shape: rect,
      node-stroke: 2pt + rgb("0EAB77"),
      node-inset: 10pt,
      node-corner-radius: 3pt,
      edge-stroke: 1pt,
      edge-corner-radius: 5pt,


      node((0, 0), shape: rect, )[我首先选取一个二进制串密钥$S$],
      node((0, 1), shape: rect)[然后逐位随机选择测量基记为串$M_A$],
      node((0, 2), shape: rect)[查询字母表，通过#highlight[量子信道]发送 \ 不同偏振方向的光子],
    ),

    pause,

    tablex(
      columns: 7,
      align: center + horizon,
      // stroke: none, // 默认无边框，模拟 booktabs 风格
      auto-vlines: false,
      auto-hlines: false,
      inset: 9pt, 
      // gutter: 5pt,

      // table.hline(stroke: 1.5pt),
      hlinex(stroke: 1.5pt),
      [$S$], [$0$], [$0$], [$1$], [$1$], [$0$], [$dots$],
      hlinex(stroke: 1pt),
      [$M_A$], [$+$], [$times$], [$+$], [$times$], [$+$], [$dots$],
      hlinex(stroke: 1pt),
      rowspanx(2)[发送光子], [$ket(0)$], [$ket(+)$], [$ket(1)$], [$ket(-)$], [$ket(0)$], [$dots$],
      hlinex(stroke: 1pt),
      [#art], [#artr], [#arr], [#artl], [#art], [$dots$],
      // 底部粗线 (Bottomrule)
      // table.hline(stroke: 1.5pt),
      hlinex(stroke: 1.5pt),
    )
  )

  #speaker-note()[前提要求是，经典信道可以被监听但不能被篡改。]

]

== 协议过程:筛选阶段

#slide(repeat: 4, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #align(right)[
    #grid(
      columns: 3,
      column-gutter: 20pt,

      only("3-")[
        #figure(
          table(
            columns: 7,
            align: center + horizon,
            stroke: none, // 默认无边框，模拟 booktabs 风格
            gutter: 10pt,

            table.hline(stroke: 1.5pt),

            [测量基$M_A$], [$+$], [#text(fill: red)[$times$]], [$+$], [$times$], [#text(fill: red)[$+$]], [$dots$],
            [测量基$M_B$], [$+$], [#text(fill: red)[$+$]], [$+$], [$times$], [#text(fill: red)[$times$]], [$dots$],
            [保留位], [$checkmark$], [$$], [$checkmark$], [$checkmark$], [$$], [$dots$],
            [筛选秘钥], [#text(fill: rgb("#006d12"))[$0$]], [#text(fill: red)[$0$]], [#text(fill: rgb("#006d12"))[$1$]], [#text(fill: rgb("#006d12"))[$1$]], [#text(fill: red)[$0$]], [$dots$],
             // 底部粗线 (Bottomrule)
            table.hline(stroke: 1.5pt),
          ),
          caption: [#text(fill: red)[红色]表示#text(fill: red)[丢弃]该位]
        )],

      diagram(
        spacing: 10pt,
        node-shape: rect,
        node-stroke: 2pt + rgb("195FB4"),
        node-inset: 10pt,
        node-corner-radius: 3pt,
        edge-stroke: 1pt,
        edge-corner-radius: 5pt,

        node((0, 0))[我已接收到这些光子],
        node((0, 1))[随机选择测量基记为串$M_B$],
        node((0, 2))[再通过#highlight[经典信道]发送测量基$M_B$\ 并对光子进行测量],
      ),

        bob,

    )
  ]

  #speaker-note()[
    + 显然他有 50% 的概率选对基底，这些选对的光子会测量得到正确的结果。
    + 注意发送的不是测量结果，而是测量基
  ]

  #v(10pt)
  #pause

  #grid(
      columns: 3,
      column-gutter: 20pt,

      alice,
      diagram(
        spacing: 10pt,
        node-shape: rect,
        node-stroke: 2pt + rgb("0EAB77"),
        node-inset: 10pt,
        node-corner-radius: 3pt,
        edge-stroke: 1pt,
        edge-corner-radius: 5pt,

        node((0, 0))[我已接收到$M_B$，对比我的$M_A$],
        node((0, 1))[在#highlight[经典信道]上：\ BoB，这些比特上的测量基我们是相同的！],
      ),
  )

  #pause
  #pause

  然后，双方都#text(fill: red)[丢弃]测量基不同的比特，只*保留*相同的比特。此时双方保留的二进制串长度大约为原来的一半，称为#highlight[*筛选秘钥*]。

])

== 协议过程:窃听检测

#slide[
  接下来都在在#highlight[经典信道]上进行通信。

  #grid(
    columns: 2,
    column-gutter: 20pt,

    alice,
    diagram(
      spacing: 10pt,
      node-shape: rect,
      node-stroke: 2pt + rgb("0EAB77"),
      node-inset: 10pt,
      node-corner-radius: 3pt,
      edge-stroke: 1pt,
      edge-corner-radius: 5pt,

      node((0, 0))[BoB，我这里$x$到$y$的筛选秘钥是这样的：\ 0100100111010011],
    ),
  )

  若*没有被窃听*，那么理论上双方得到的筛选秘钥应是完全相同的：

  #align(right)[
    #grid(
      columns: 2,
      column-gutter: 20pt,

      diagram(
        spacing: 10pt,
        node-shape: rect,
        node-stroke: 2pt + rgb("195FB4"),
        node-inset: 10pt,
        node-corner-radius: 3pt,
        edge-stroke: 1pt,
        edge-corner-radius: 5pt,

        node((0, 0))[Alice，我这里$x$到$y$的筛选秘钥是这样的：\ *0100100111010011* \ 完全相同。接下来开始偷税地聊天吧],
      ),
      bob
    )
  ]

  于是双方丢弃方才比对的部分，称为#highlight[*绝对安全密钥*]。之后双方可以开始密文通信。
]

#slide[
  但若 Eve 在一开始的#highlight[量子信道]中进行了窃听。她也只能随机选择基底测量，有$1/2$的概率选错基底。由于需保证光子数，她必须根据测量结果重发一个光子。在 Eve 选错基底的情况下，若之后 Bob 选对了基底，那么就会产生$1/2 times 1/2 = 1/4$的误码率。于是通信双方可以大概率地断定密钥被窃听，因此丢弃密钥并取消通信，等待下一次尝试。

    #grid(
    columns: 2,
    column-gutter: 20pt,

    alice,
    diagram(
      spacing: 10pt,
      node-shape: rect,
      node-stroke: 2pt + rgb("0EAB77"),
      node-inset: 10pt,
      node-corner-radius: 3pt,
      edge-stroke: 1pt,
      edge-corner-radius: 5pt,

      node((0, 0))[BoB，我这里$x$到$y$的筛选秘钥是这样的：\ 0100100111010011],
    ),
  )

  #align(right)[
    #grid(
      columns: 2,
      column-gutter: 20pt,

      diagram(
        spacing: 10pt,
        node-shape: rect,
        node-stroke: 2pt + rgb("195FB4"),
        node-inset: 10pt,
        node-corner-radius: 3pt,
        edge-stroke: 1pt,
        edge-corner-radius: 5pt,

        node((0, 0))[Alice，我这里$x$到$y$的筛选秘钥是这样的：\ *0#text(fill: red)[1]0010#text(fill: red)[01]11010#text(fill: red)[0]11* \ 误码率大约$25%$。有内鬼，终止交易！],
      ),
      bob
    )
  ]//*  

]

// 假如量子信道没被窃听，那么双方得到的筛选秘钥应是完全相同的。为了*检测窃听*，双方需要进行误码率分析。

// 1. 双方选择筛选秘钥的一小部分，在#highlight[经典信道]上进行比较。此时：
//   1. 如果#highlight[没有被窃听]，双方得到的比较结果应是相同的。于是双方丢弃方才比对的部分，只留下剩余部分，称为*绝对安全密钥*。之后双方可以开始密文通信。
//   2. 如果#highlight[被窃听]，那么误码率会升高。若误码率超过阈值，则双方丢弃所有密钥取消本次通信，等待下一次尝试通信。

// #pause

// #highlight[重新总结过程]：
// - *量子阶段*：发送光子序列。
// - *筛选阶段*：通过经典信道对比测量基底，仅保留基底一致的比特。
// - *窃听检测*：检查一部分样本。若超过阈值，则认为存在窃听，放弃当前密钥。
// - *后续处理*：纠错与隐私放大。


== 总结

BB84 协议的精髓在于：
+ 它使一次一密的实现成为可能。
+ 它对通信安全的保证，不在于避免被窃听，而是使通信双方能够检测到窃听行为。这拓宽了人们对通信安全的实现方式。
+ 而能够检测到窃听行为，是通过量子力学中不可克隆原理实现的。这是对物理规律的绝妙利用。

#pause

当然，BB84 协议是一种极理想化的协议。例如，协议要求*单光子传送*，但在现实中一个激光脉冲里总是包含多个光子。因此有许多改进版本的 BB84 协议被提出，以适应实际应用的需求。

#pause

墨子号实验的正是诱骗态 BB84 协议。



#slide(self => [
  #align(center + horizon)[
    #set text(size: 3em, weight: "bold", fill: self.colors.primary)
    愿诸位徜徉量子之海
  ]
])













