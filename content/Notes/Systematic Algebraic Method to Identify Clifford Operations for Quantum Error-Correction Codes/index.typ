// =====================================================================================
// 组会报告（30 页）：Systematic Algebraic Method to Identify Clifford Operations
//                 for Quantum Error-Correction Codes
//   S.-C. Liu, Y.-X. Lin, Y.-X. Wang, L.-Y. Peng,
//   Chin. Phys. Lett. 43, 040603 (2026).  DOI: 10.1088/0256-307X/43/4/040603
//
// 版面约定：
//   * 卡片式排版：浅色卡片（白底 / 极浅绿）+ 细边框 + 左侧色条，深绿只用在页眉细条、
//     表头文字与强调数字上，避免大面积深色。
//   * 卡片高度自适应，卡片之间用 #v(1fr) 弹性间距，所以既不会超出页面底部，也不会出现大片空白。
//   * 版式轮换：单卡片 / 上下双卡片 / 三块数字条 / 左右两栏配图 / 通宽表格。
//   * 推导、证明、逐元素检查统一放在附录 A–D；正文用真交叉引用（@app:...）指向它们。
//   * 每页可选 #speaker-note[...]，只进演讲者视图；需要双屏备注时打开下面的注释。
// =====================================================================================

#import "@preview/touying:0.7.4": *
#import "@preview/physica:0.9.8": *
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import "@preview/cetz:0.4.2": canvas, draw, vector, matrix
#import "@preview/theorion:0.5.0": *
#import "@preview/tablex:0.0.9": tablex, rowspanx, colspanx, hlinex
#import themes.aqua: *

#let cetz-canvas = touying-reducer.with(reduce: canvas, cover: draw.hide.with(bounds: true))

#set math.mat(delim: "[", row-gap: 3pt, column-gap: 6pt)
#set math.equation(numbering: "(1)")
#set figure(numbering: none)

// #show touying-equation(): 

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 自定义 slide：保留 aqua 的绿色页眉细条与页脚，但不画左上角那条白色斜线

#let slide(
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  let header(self) = {
    place(
      center + top,
      dy: .5em,
      rect(
        width: 100%,
        height: 1.5em,
        fill: self.colors.primary,
        align(
          left + horizon,
          h(1.2em) + text(fill: white, size: 0.9em, utils.call-or-display(self, self.store.header)),
        ),
      ),
    )
  }
  let footer(self) = {
    set text(size: 0.75em, fill: rgb("#6b7d6d"))
    place(right, dx: -3%, utils.call-or-display(self, utils.call-or-display(
      self,
      self.store.footer,
    )))
  }
  let self = utils.merge-dicts(self, config-page(header: header, footer: footer))
  touying-slide(
    self: self,
    config: config,
    repeat: repeat,
    setting: setting,
    composer: composer,
    ..bodies,
  )
})

#show: aqua-theme.with(
  aspect-ratio: "16-9",
  config-page(margin: (x: 2em, top: 2.9em, bottom: 1.2em)),
  config-info(
    title: [#text(size: 28pt)[Systematic Algebraic Method to Identify Clifford Operations for Quantum Error-Correction Codes]],
    author: [#text(size: 19pt)[Sheng-Chen Liu, Yu-Xuan Lin, Ying-Xiang Wang, and Liang-You Peng]],
    institution: [
      $#none^1$State Key Laboratory for Mesoscopic Physics and Frontiers Science Center for Nano-optoelectronics, School of Physics, Peking University, Beijing 100871, China \
      $#none^2$Collaborative Innovation Center of Extreme Optics, Shanxi University, Taiyuan 030006, China
    ],
  ),
  config-common(
    auto-offset-for-heading: true,
    slide-fn: slide,
    // 需要双屏备注时取消下一行注释
    // show-notes-on-second-screen: bottom,
  ),
  config-colors(
    primary: rgb("#006d12"),
    secondary: rgb("#10be4a"),
  ),
)

// 中文用系统黑体，拉丁字母与公式用默认衬线体
#set text(lang: "zh", font: ("Libertinus Serif", "Noto Sans SC", "Microsoft YaHei"))

#set list(spacing: 0.3em, indent: 1em, body-indent: 0.5em)
#set par(leading: 0.55em, spacing: 0.6em)

// 交叉引用只显示编号（默认会显示"小节 5.4"）
#show ref: it => {
  let el = it.element
  if el != none and el.func() == heading {
    link(el.location(), numbering(el.numbering, ..counter(heading).at(el.location())))
  } else {
    it
  }
}

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 配色：浅色为主，深绿只用作文字与细线

#let green-ink = rgb("#0B5E1F")      // 深绿文字
#let green-line = rgb("#CBE6D0")     // 卡片边框
#let green-bar = rgb("#8FD49B")      // 卡片左侧色条
#let green-wash = rgb("#F2FBF3")     // 极浅绿底
#let red-ink = rgb("#9B2C2C")
#let red-line = rgb("#F0CFCF")
#let red-wash = rgb("#FDF3F3")
#let mute-ink = rgb("#5A6B5C")

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 组件：浅色卡片、数字条、图表卡

// 卡片：tone 取 "plain"（白底）/ "wash"（浅绿底）/ "caution"（浅红底）
// height: 在 fill-page / fill-2col 里传 100%，卡片会撑满所在区域（不产生白带）
#let card(title, body, tone: "plain", title-size: 20pt, body-size: 17pt, inset: 11pt, height: auto) = {
  let (bg, line, ink, bar) = if tone == "caution" {
    (red-wash, red-line, red-ink, rgb("#E29A9A"))
  } else if tone == "wash" {
    (green-wash, green-line, green-ink, green-bar)
  } else {
    (white, green-line, green-ink, green-bar)
  }
  block(
    width: 100%,
    height: height,
    fill: bg,
    stroke: (left: 3pt + bar, rest: 0.7pt + line),
    radius: 4pt,
    inset: (left: inset + 4pt, right: inset, top: inset - 2pt, bottom: inset - 2pt),
  )[
    #set par(leading: 0.6em)
    #set list(tight: false, spacing: auto)
    #text(fill: ink, size: title-size, weight: "bold")[#title]
    #v(4pt)
    #text(size: body-size, )[#body]
  ]
}

// 数字条：一排小方块，用来放关键数字
#let stat-tile(value, label) = block(
  width: 100%,
  fill: green-wash,
  stroke: 0.7pt + green-line,
  radius: 4pt,
  inset: (x: 8pt, y: 7pt),
)[
  #align(center)[
    #text(size: 20pt, fill: green-ink, weight: "bold")[#value]
    #v(1pt)
    #text(size: 12pt, fill: mute-ink)[#label]
  ]
]

#let stat-row(items, gutter: 10pt) = grid(
  columns: items.len() * (1fr,),
  gutter: gutter,
  ..items.map(pair => stat-tile(pair.at(0), pair.at(1))),
)

// 图表卡：居中放图 + 出处
#let figure-card(image-path, source, height: 240pt, caption: none, box-height: auto) = {
  block(
    width: 100%,
    height: box-height,
    fill: white,
    stroke: 0.7pt + green-line,
    radius: 4pt,
    inset: 10pt,
  )[
    #align(center + horizon)[
      #image(image-path, height: height)
    ]
    #if caption != none {
      align(center)[#text(size: 13pt, fill: mute-ink)[#caption]]
    }
    #align(center)[#text(size: 12pt, fill: mute-ink)[#source]]
  ]
}

// 两栏：左卡片 + 右侧图表卡（图高可调）
#let two-col(
  columns: (1.05fr, 1fr),
  gutter: 12pt,
  title: none,
  body: none,
  image-path: none,
  source: none,
  height: 250pt,
  tone: "plain",
) = grid(
  columns: columns,
  gutter: gutter,
  card(title, body, tone: tone),
  figure-card(image-path, source, height: height),
)

// 浅色表格：表头浅绿底 + 深绿字，行间交替底色
#let light-table(columns, header, rows, size: 14pt, inset: 7pt) = {
  set text(size: size)
  table(
    columns: columns,
    column-gutter: 10pt,
    inset: inset,
    stroke: none,
    fill: (x, y) => if y == 0 { rgb("#E4F5E6") } else if calc.even(y) { white } else { green-wash },
    ..header.map(h => text(fill: green-ink, weight: "bold")[#h]),
    ..rows.flatten(),
  )
}

// 竖直分栏容器：把若干 (权重, 内容) 从上到下铺满整页（内容里用 height: 100% 才不会留白）
#let fill-page(specs, gutter: 12pt) = layout(size => {
  block(width: 100%, height: size.height)[
    #grid(
      rows: specs.map(s => s.at(0)),
      row-gutter: gutter,
      ..specs.map(s => s.at(1)),
    )
  ]
})

// 左右两栏容器：两栏都铺满整页高度
#let fill-2col(fractions: (1.05fr, 1fr), gutter: 12pt, left, right) = layout(size => {
  block(width: 100%, height: size.height)[
    #grid(
      columns: fractions,
      rows: (size.height,),
      column-gutter: gutter,
      left,
      right,
    )
  ]
})

// —— 常用整页版式（卡片一律撑满各自区域，页面上不会出现白带）——

// —— 版面工具 ——

// 把 0.6 / 0.6fr / 60% 统一换算成 float（用于行高分配）
#let to-frac(x) = {
  if type(x) == ratio { x / 100% }
  else if type(x) == fraction { x / 1fr }
  else if type(x) in (float, int) { x }
  else { panic("比值请写成 0.6、0.6fr 或 60%") }
}

// 归一化权重：0.6 -> (0.6, 0.4)；(1.4fr, 1fr) -> (0.583, 0.417)
#let norm-weights(w) = {
  let arr = if type(w) == array { w } else { (to-frac(w), 1 - to-frac(w)) }
  let fs = arr.map(to-frac)
  let s = fs.sum()
  if s == 0 { fs.map(_ => 1 / fs.len()) } else { fs.map(f => f / s) }
}

// 自适应卡片：内容超过 avail 时按"优先压内边距 → 再压正文字号 → 最后压标题"逐档收缩，
// 保证卡片内容永远完整显示（不会被裁切，也不会盖住下一张卡）
#let fit-card(
  title,
  body,
  tone: "plain",
  avail: 0pt,
  width: 0pt,
  height: 100%,
  sizes: (17pt, 16pt, 15pt, 14pt, 13pt, 12pt),
  insets: (11pt, 9pt, 7pt),
  title-sizes: (20pt, 18pt),
) = {
  let pick = (sizes.last(), insets.last(), title-sizes.last())
  if avail > 0pt and width > 0pt {
    let found = false
    for ts in title-sizes {
      for s in sizes {
        for ins in insets {
          if not found {
            let h = measure(
              card(title, body, tone: tone, body-size: s, title-size: ts, inset: ins, height: auto),
              width: width,
            ).height
            if h <= avail {
              pick = (s, ins, ts)
              found = true
            }
          }
        }
      }
    }
  }
  card(
    title,
    body,
    tone: tone,
    body-size: pick.at(0),
    inset: pick.at(1),
    title-size: pick.at(2),
    height: height,
  )
}

// 一页上下两张卡片
//   weights / rsize 控制行高：
//     * 默认 auto —— 按两张卡的内容自然高度分配（推荐，永远不会裁切）
//     * rsize: 0.6（或 0.6fr、60%）—— 上卡占 0.6、下卡自动占 0.4
//     * weights: (1.4fr, 1fr) —— 按权重分配（等于 0.583 / 0.417）
//   注意 rsize 是"行高比例"，不是卡片框高；旧写法 rsize: 100% 会被忽略（等价 auto）。
#let page-2cards(
  title1,
  body1,
  title2,
  body2,
  tone1: "wash",
  tone2: "plain",
  weights: auto,
  gap: 12pt,
  rsize: auto,
) = layout(size => {
  let avail = size.height - gap
  let h1 = measure(card(title1, body1, tone: tone1, height: auto), width: size.width).height
  let h2 = measure(card(title2, body2, tone: tone2, height: auto), width: size.width).height

  // 显式比例（rsize 优先，其次 weights）；否则按内容自动分配
  let explicit = if rsize != auto and to-frac(rsize) < 1 { rsize }
    else if weights != auto { weights }
    else { auto }

  let (r1, r2) = if explicit == auto {
      let a = h1 / 1pt
      let b = h2 / 1pt
      if a + b <= 0 {
        (avail * 0.5, avail * 0.5)
      } else if avail - h1 - h2 <= 0pt {
        // 两张卡的自然高度之和就超过一页：按内容比例压缩，
        // 具体缩字号由 fit-card 负责，保证内容完整显示
        let t = a + b
        (avail * a / t, avail * b / t)
     } else {
       // 有富余：各自取自然高度，再按自然高度比例分享剩余空间
        let s = (avail - h1 - h2) / 1pt
       let t = a + b
       (h1 + (s * a / t) * 1pt, h2 + (s * b / t) * 1pt)
     }
    } else {
      let ws = norm-weights(explicit)
      (ws.at(0) * avail, ws.at(1) * avail)
    }

  block(width: 100%, height: size.height)[
    #grid(
      rows: (r1, r2),
      row-gutter: gap,
      fit-card(title1, body1, tone: tone1, avail: r1, width: size.width),
      fit-card(title2, body2, tone: tone2, avail: r2, width: size.width),
    )
  ]
})

// 一页：卡片 + 底部数字条
//   数字条取自然高度，卡片吃掉剩下的全部高度（也可用 weights 显式分配）
#let page-card-tiles(
  title,
  body,
  tiles,
  tone: "wash",
  weights: auto,
  gap: 12pt,
) = layout(size => {
  let avail = size.height - gap
  let tile-h = measure(stat-row(tiles), width: size.width).height
  let h = measure(card(title, body, tone: tone, height: auto), width: size.width).height
  let (r1, r2) = if weights == auto {
      // 数字条取自然高度；卡片吃掉剩余高度。若剩余高度不够，
      // fit-card 会自动缩字号，而不是让内容溢到页外。
      if h + tile-h <= avail { (avail - tile-h, tile-h) } else { (avail - tile-h, tile-h) }
    } else {
      let ws = norm-weights(weights)
      (ws.at(0) * avail, ws.at(1) * avail)
    }
  block(width: 100%, height: size.height)[
    #grid(
      rows: (r1, r2),
      row-gutter: gap,
      fit-card(title, body, tone: tone, avail: r1, width: size.width),
      align(center + horizon, stat-row(tiles)),
    )
  ]
})

// 一页：左卡片 + 右侧图卡（两栏等高于整页）
//   左栏宽度按 fractions 计算，卡片内容过多时自动收缩而不是被裁切；
//   需要放两张图或别的右栏内容时，用 right: [...] 覆盖默认的图卡。
#let page-2col(
  title,
  body,
  image-path: none,
  source: none,
  right: none,
  img-height: 240pt,
  tone: "plain",
  fractions: (1.05fr, 1fr),
  gap: 12pt,
) = layout(size => {
  let fs = fractions.map(to-frac)
  let total = fs.sum()
  let col1 = (size.width - gap) * fs.at(0) / total
  let right-content = if right != none { right } else {
    figure-card(image-path, source, height: img-height, box-height: 100%)
  }
  block(width: 100%, height: size.height)[
    #grid(
      columns: fractions,
      rows: (size.height,),
      column-gutter: gap,
      fit-card(title, body, tone: tone, avail: size.height, width: col1),
      right-content,
    )
  ]
})

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 封面

#title-slide(extra: [
  #place(top + center, dy: -3em)[#text(size: 19pt)[Chinese Physics Letters 43, 040603 (2026)]]
  // 汇报人/日期：取消注释并改成自己的信息
  // #place(top + center, dy: -6em)[#text(size: 17pt)[汇报人：姓名 \ 日期：2026-xx-xx]]
  #text(size: 14pt)[$#none^1$State Key Laboratory for Mesoscopic Physics and Frontiers Science Center for Nano-optoelectronics, \
    School of Physics, Peking University, Beijing 100871, China \
    $#none^2$Collaborative Innovation Center of Extreme Optics, Shanxi University, Taiyuan 030006, China ]
])

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 第 2 页：目录与时间分配

// #slide(config: config-store(header: [目录与时间分配]), [
//   #page-card-tiles(
//     [本次汇报的五个部分],
//     [
//       #set text(size: 17pt)
//       - *01 研究背景与动机*：量子纠错与阈值、逻辑操作的困难、本文的定位。
//       - *02 预备知识*：Pauli 链与辛内积、稳定子码与 CSS 码、Clifford 的辛表示。
//       - *03 代数方法*：三条约束方程、二次约束线性化、物理门分解与化简。
//       - *04 结果*：环面码上的 $overline(H)_1 overline(I)_2$、资源与逻辑错误率、连续 Clifford、$\{4,5\}$ 双曲曲面码。
//       - *05 讨论与总结*：适用边界、容错代价、与已有方法比较、可以继续挖的问题。
//       - 推导、逐元素检查、计数细节统一放在附录 A–D，正文用编号交叉引用（例如"见 5.4"）。
//       - 所有数字取自论文正文（$alpha$、240 CNOT、$p = 10^(-4)$ 等）；论文未给具体门数的位置已明确标注。
//     ],
//     (
//       ([12 min], [01 背景与动机]),
//       ([12 min], [02 预备知识]),
//       ([25 min], [03 代数方法]),
//       ([20 min], [04 结果]),
//       ([10 min], [05 讨论与总结]),
//     ),
//   )
//   #speaker-note[
//     开场用 2 min 说清两件事：这是一篇方法型论文（不提出新码），以及正文与附录的分工。
//     时间紧就跳过 02 的稳定子补课，直接讲 2.3 的辛条件。
//   ]
// ])

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 一、研究背景与动机

= 研究背景与动机

== 噪声、阈值与开销

#slide[
  #page-2cards(
    [为什么需要量子纠错],
    [
    - 物理比特是模拟量：退相干、门误差、读出误差、串扰都会累积；当前平台上单比特操作错误率大致在 $10^(-3)$–$10^(-2)$（与平台、操作类型有关）。
    - 编码：把 $k$ 个逻辑比特编进 $n$ 个物理比特，$k/n$ 是编码率；多出来的自由度用来"检出并纠正"错误。
    - 阈值定理：只有物理错误率 $p < p_"th"$ 时，增大码距 $d$ 才会把逻辑错误率压下去。这是容错路线的起点（标准结论，本文不涉及细节）。
  ],
    [代价在哪里：本文关心的是门数],
    [
    - 纠错本身的开销：稳定子测量、辅助比特制备与测量、解码计算，都是物理门与物理比特的开销。
    - 工程上真正关心的是"每个逻辑操作要消耗多少物理门"，以及这个数目随码距怎么增长。
    - 本文回答后者：给定码与目标逻辑操作，算出具体的物理门序列，并给出门数标度。
  ],
    tone1: "wash",
    tone2: "caution",
  )
  #speaker-note[
    只给直觉：噪声 → 编码 → 阈值 → 逻辑错误率下降，但开销上升。熟悉 QEC 的听众可以只讲下面那张卡片。
  ]
]

== 三条路线与三个缺点

#slide[
  #page-2cards(
    [已有的三条路线],
    [
    - *横向（transversal）门*：对每个物理比特施加相同的门，最简单；但横向门集合受结构限制，多数码只有部分 Clifford 门可用。
    - *格点手术（lattice surgery）与规范固定*：在表面码上通过合并、分裂码片实现逻辑 CNOT；代价是额外物理比特与多轮测量。
    - *几何 / 拓扑方法*：把逻辑操作等价实现为曲面上的拓扑操作，例如双曲曲面码上用 Dehn twist 实现逻辑 CNOT；自对偶码还能借几何对称性给出部分门。
  ],
    [三个缺点],
    [
    + 单比特逻辑门 $overline(H)$、$overline(S)$ 对一般（非自对偶）码没有通用构造 —— 几何方法给不出"只动一个逻辑比特、另一个不动"的操作。
    + 这些方法基本是"一码一策"：换一种码、换一个门，往往要重新设计。
    + 逻辑信息散布在整个物理比特集合上，局部几何操作难以同时保持稳定子结构。
    - 本文的做法：绕开几何直觉，把"实现逻辑操作"直接转换为求解代数方程。
  ],
    tone1: "wash",
    tone2: "caution",
  )
  #speaker-note[
    把三个缺点说具体，尤其缺点一（单比特 H/S 门）—— 这是本文两个例子的来源。预判提问："Dehn twist 不就够了吗？"答：它给的是两个逻辑比特之间的 CNOT 类操作。
  ]
]

== 本文的贡献与定位

#slide[
  #page-2cards(
    [三条贡献],
    [
    + *通用性*：对任意 CSS 码（Calderbank–Shor–Steane code）求任意指定的 Clifford 逻辑操作，把"保持码结构"与"实现目标逻辑映射"写成 $bb(F)_2$ 上的方程组。
    + *可解性*：用辛表示把 Clifford 操作编码成 $2 n times 2 n$ 的二进制矩阵（$O(n^2)$ 个比特）；二次约束线性化后是稀疏线性方程组，复杂度略高于 $O(n^4)$，不是指数级。
#highlight[    + *可落地*：解出的 $U$ 分解为单比特门与双比特门序列（四种基本门 + 辛高斯消元），再用 CNOT 消去模板压缩门数；门与稳定子送入 Stim 可得逻辑错误率。
]  ],
    [三条代价],
    [
    - 门数不保证最优：消元顺序、逻辑算符的选取都会影响结果，论文只做模板级局部化简。
    - 需要牺牲一部分容错性：完整容错设计留作后续工作。
    - 只处理 Clifford 逻辑操作；逻辑 $T$ 这类门仍然需要魔术态注入等额外机制。
  ],
    tone1: "wash",
    tone2: "caution",
  )
  #speaker-note[
    只给直觉：噪声 → 编码 → 阈值 → 逻辑错误率下降，但开销上升。熟悉 QEC 的听众可以只讲下面那张卡片。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 二、预备知识

= 预备知识

== Pauli 链、辛内积与对易条件

#slide[
  #page-2cards(
    [把 Pauli 链写成 $bb(F)_2$ 上的向量],
    [
    - $n$ 比特 Pauli 群由 $I, X, Y, Z$ 的张量积加相位 $plus.minus 1, plus.minus i$ 构成；纠错讨论只关心"在哪些比特上做什么"，相位可以整体忽略。
    - 编码约定：一维二进制向量 $A_P = (A_Z | A_X) in bb(F)_2^(2 n)$，前后两段各长 $n$。链上第 $i$ 个门使用两位二进制数表示：取 $A_Z, A_X$ 中的第 $i$ 位组合为 $(A_(Z)^((i)), A_(X)^((i)))$，则 $00 -> I$，$01 -> X$，$10 -> Z$，$11 -> Y$。
  ],
    [辛内积反映对易关系],
    [
    $ A Lambda B^T = A_Z dot B_X + A_X dot B_Z quad (mod 2), quad Lambda = mat(0, I_n; I_n, 0). $
    - 取值 $0$ 表示两条 Pauli 链对易，取值 $1$ 表示反对易。例：$Z_1$ 与 $X_1$ 反对易，$X_1$ 与 $X_2$ 对易。
    - $Lambda$ 在 $bb(F)_2$ 上自逆：$Lambda^T = Lambda^(-1) = Lambda$。稳定子之间的对易与 Clifford 的保辛条件都是同一个辛内积。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    把三个缺点说具体，尤其缺点一（单比特 H/S 门）—— 这是本文两个例子的来源。预判提问：“Dehn twist 不就够了吗？”答：它给的是两个逻辑比特之间的 CNOT 类操作。
  ]
]

== 稳定子码与 CSS 码 <稳定子码与CSS码>

#slide[
  #page-2cards(
    [稳定子码与逻辑算符],
    [
    - 取相互对易的 Pauli 生成元 $S_1, dots, S_m$（不含 $-I$），码空间是它们的 $+1$ 公共本征空间。
    - 落在码空间外的错误会改变某些稳定子的本征值，测量这些本征值（症状）即可定位错误。
    - 逻辑算符：与所有稳定子对易、但本身不属于稳定子群的 Pauli 链。每个逻辑比特选一对 $overline(Z)_i$、$overline(X)_i$，要求二者反对易（辛配对）、不同逻辑比特之间对易。
  ],
    [CSS 结构：$Z$ 型与 $X$ 型分开],
    [
    - 生成元分成纯 $Z$ 型与纯 $X$ 型两组，可以被写为矩阵 $H_Z$（$n_Z times n$）与 $H_X$（$n_X times n$）。
    - 要求 $Z$ 型与 $X$ 型稳定子两两对易，等价于
      #align(center)[$ H_Z H_X^T = 0. $]
      逐元素推导见 @app:css。
    - 逻辑算符条件：$H_X A_Z^T = 0$、$H_Z A_X^T = 0$，且算符本身不落在稳定子群中。多数 LDPC 码都是 CSS 码；非 CSS 码可映射为 CSS，代价是更多物理比特。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    全场地图。提醒：约束为什么这么写、保辛条件怎么推，这些细节放在附录 A–D，正文只讲用法。
  ]
]

== Clifford 操作与辛条件

#slide[
  #page-2cards(
    [Clifford 操作 = 保辛的二进制矩阵],
    [
    - 酉操作的作用是 $P -> U_"op"^dagger P U_"op"$；Clifford 操作把 Pauli 链映为 Pauli 链（最多带相位）。
    - 忽略相位后它是 $bb(F)_2^(2 n)$ 上的线性映射，可用 $2 n times 2 n$ 二进制矩阵表示：$A_P -> A_P U$。*行约定*：第 $j$ 行是 $Z_j$ 的像，第 $(n+j)$ 行是 $X_j$ 的像。
    - 保辛条件：对任意 $A, B$，$A Lambda B^T = (A U) Lambda (B U)^T = A (U Lambda U^T) B^T$，因此
      $ U Lambda U^T = Lambda. $ <eq:保辛条件>
      取基向量逐个元素比较即可得到（展开见 @app:symp）。
  ],
    [分块形式与二次约束的来源],
    [
    - 把 $U$ 按 $n times n$ 分块写成 $U = mat(A, B; C, D)$，@eq:保辛条件 等价于三条矩阵恒等式：
      $ A B^T + B A^T = 0, quad C D^T + D C^T = 0, quad A D^T + B C^T = I_n. $
    - 满足 @eq:保辛条件 的矩阵构成辛群 $"Sp"(2 n, bb(F)_2)$ —— "找一个逻辑操作"就是"在辛群里找满足码结构条件的矩阵"。
    - 注意 @eq:保辛条件 的每个矩阵元都是 $U$ 中两个元素之积：*这就是后文"二次约束"的来源*。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    全篇最"硬"的一步，值得板书：把 $A Lambda B^T = A (U Lambda U^T) B^T$ 对基向量取，就得到 @eq:保辛条件；分块三条恒等式的展开见附录 A（@app:symp）。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 三、代数方法

= 代数方法

== 三条约束：把逻辑操作写成方程

#slide[
  #page-2cards(
    [求解目标就是下面三组条件],
    [
    - *① 保辛（ @eq:保辛条件）*：$U Lambda U^T = Lambda$ —— 保证任意 Pauli 链之间的对易/反对易关系不变。
    - *② 码结构（式 (3)）*：
      #align(center)[$ mat(H_Z, 0; 0, H_X) U = mat(H_Z, 0; 0, H_X). $]
      论文为求解方便*直接要求每个稳定子生成元回到自身*；更一般的情形允许稳定子置换/重组，但会引入组合问题。
    - *③ 目标映射（式 (4)）*：
      #align(center)[$ mat(overline(Z), 0; 0, overline(X)) U = mat(overline(Z)^Z, overline(X)^Z; overline(Z)^X, overline(X)^X). $]
      $overline(Z)$、$overline(X)$ 各是 $k times n$；右端四块表示像的 $Z$/$X$ 部分，可由 $overline(Z)$、$overline(X)$ 的行线性表示。
  ],
    [两个例子的目标映射],
    [
    - $overline(H)_1 overline(I)_2$：$overline(Z)_1 -> overline(X)_1$、$overline(X)_1 -> overline(Z)_1$，其余不变（式 (7)）。
    - $overline(S)_1 overline(I)_2$：$overline(X)_1 -> overline(Z)_1 overline(X)_1$，其余不变（式 (8)）。
    - 于是"设计线路"变成"求满足 (2)(3)(4) 的 $U$"，解出后分解成物理门。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    用 $n = 2$ 举例：$X_1 Z_2 -> (1,0|0,1)$、$Y_1 -> (1,0|1,0)$；强调 $A_Z$ 在前、$A_X$ 在后，后面所有分块矩阵的左半/右半都按这个顺序。
  ]
]

== 二次约束与线性化

#slide[
  #page-2cards(
    [难点在 @eq:保辛条件：它是二次的],
    [
    - 把 $U$ 的元素记作 $U_(i j)$， @eq:保辛条件 的每个矩阵元都是"两个元素相乘再求和"：
      #align(center)[$ (U Lambda U^T)_(i j) = sum_(k = 1)^n U_(i, k+n) U_(j k) + sum_(k = n+1)^(2 n) U_(i, k-n) U_(j k). $]
      因此 @eq:保辛条件 给出 $O(n^2)$ 个*二次*方程（分块展开见 @app:symp），而式 (3)(4) 都是线性的。
    - *线性化*：对出现在这些二次方程中的每一对元素引入新变量 $v_(a b c d) = U_(a b) U_(c d)$；代入后 @eq:保辛条件 变成关于 $(U, v)$ 的线性方程，再与式 (3)(4) 合并。
    - *规模*：论文指出线性方程组的行数（方程数）与列数（未知量数）都在 $O(n^2)$ 量级且*高度稀疏* —— 每个方程只涉及少数几个变量。
  ],
    [复杂度与一致性回代],
    [
    - *复杂度*：稀疏消元的总代价"略高于 $O(n^4)$"（论文原话 slightly over $O(n^4)$），不是指数级；对比态矢量方法的 $4^n$ 维空间。量级估计见 @app:linear。
    - *一致性回代*：$v$ 是形式变量，必须满足 $v_(a b c d) = U_(a b) U_(c d)$；论文在解空间里做"二次变量与 $U$ 元素的匹配"，并指出这一步开销很小。
    - *规模示例*：$d = 7$ 环面码 $n = 2 d^2 = 98$，$U$ 是 $196 times 196$，元素约 $3.8 times 10^4$ 个 —— 直接枚举 $2^38416$ 不可行。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    熟悉稳定子形式的听众只需强调 $k = n - m$ 与式 (1)；后面算双曲码逻辑比特数（$60 - 52 = 8$）用的就是 $k = n - m$。
  ]
]

== 分解为物理门：四种门与四种列操作

#slide[
  #page-2cards(
    [门的种类与它们对 $U$ 的作用],
    [
    #light-table(
      (auto, 1.15fr, 1.3fr),
      ("门", "对 Pauli 链的作用（物理效果）", "对 $U$ 的列操作（右乘初等矩阵）"),
      (
        ([$H_i$], [$Z_i <-> X_i$], [交换第 $i$ 列与第 $(i+n)$ 列]),
        ([$S_i$], [$X_i -> Z_i X_i$（相差相位）], [把第 $(i+n)$ 列加到第 $i$ 列]),
        ([$"CNOT"_(i j)$], [$X_i -> X_i X_j$、$Z_j -> Z_i Z_j$], [第 $j$ 列加到第 $i$ 列；第 $(i+n)$ 列加到第 $(j+n)$ 列]),
        ([$"SWAP"_(i j)$], [$Z_i <-> Z_j$、$X_i <-> X_j$], [交换第 $i$、$j$ 列；交换第 $(i+n)$、$(j+n)$ 列]),
      ),
    )
  ],
    [只允许这四类辛操作，把 $U$ 化为 $I_(2 n)$],
    [
    - 这四类初等矩阵*不构成*全部初等操作，但都是*辛*的（每步保持 @eq:保辛条件），所以消元顺序必须专门设计。
    - 记初等矩阵为 $P_k$：$U P_1 dots.c P_T = I_(2 n)$ ⟹ $U = P_T dots.c P_1$（论文式 (5)(6)），门序列按*逆序*读出，$T$ 是化简前的物理门数。
    - $n = 2$ 的显式 $4 times 4$ 矩阵见 @app:gates，可以直接核对上表的列操作。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    全篇最“硬”的一步，值得板书：把 $A Lambda B^T = A (U Lambda U^T) B^T$ 对基向量取，就得到 @eq:保辛条件；分块三条恒等式的展开见附录 A。
  ]
]

== 辛高斯消元：四步流程（Fig. 1）

#slide[
  #page-2col(
    [四步（对应论文正文的流程）],
    [
      - *① 双比特门*：只看 $U$ 左侧 $2 n times n$ 部分，用 CNOT/SWAP 型操作把它化为列阶梯形（reduced column echelon form）；右侧 $n$ 列被同步作用。
      - *② $H$ 门换列*：若左上还没出现 $I_n$，说明右半存在带零元的列（$U$ 满秩），用 $H$ 把右半的列换进来再重复 ①。通常此时左上、右下两个块都成了 $I_n$。
      - *③ 清左下*：单个元素 $(i+n, i)$ 用 $S_i$ 消去；成对元素 $(i+n, j)$ 与 $(j+n, i)$（$i < j$）用 $H_i "CNOT"_(j i) H_i$ 一起清掉。
      - *④ 清右上*：右上角若还有非零元，再补 $H$ 门处理，最终 $U -> I_(2 n)$，分解结束。
      - 边界情形（只剩左下/右上非零等）论文逐类给出清除手法；完整证明在 SM 中。
    ],
    image-path: "img/fig1.png",
    source: "Fig. 1",
    img-height: 250pt,
    fractions: (1.1fr, 1fr),
  )
  #speaker-note[
    对照 Fig. 1 上排"矩阵演化"与下排"量子线路"：上面是 $U$ 逐步消成 $I$，下面是同步产生的门序列（时间轴向左）。
    重点解释第 ③ 步的 $H "CNOT" H$：同时清除一对互相关联的非零元，而不破坏已经做好的 $I_n$ 块。
  ]
]

== 化简与输出：能减多少门

#slide[
  #page-2col(
    [两条化简规则，迭代使用],
    [
      - *SWAP 折算*：一个 SWAP 等于三个 CNOT（Fig. 2(a)），统计门数时把所有双比特门统一折算成 CNOT。
      - *五 CNOT 模板*：满足该模板的三 CNOT 组合可以化成两个 CNOT（Fig. 2(b)）；CNOT 之间常有对易关系，这类组合在实际线路里出现得很频繁。
      - *迭代*：替换后可能出现新的可化简组合，反复搜索直到无法继续；化简只改变实现方式，不改变 $U$。
      - *输出*：物理门序列 + 门数（简化前 / 简化后）；门与稳定子送入 Stim 可得逻辑错误率（见 4.2）。
    ],
    image-path: "img/fig2.png",
    source: "Fig. 2",
    img-height: 230pt,
    fractions: (1fr, 1.1fr),
  )
  #speaker-note[
    化简为什么重要：环面码上的拟合指数从 $alpha = 2.51$ 降到 $2.28$，全部来自这里。
    提问预案："只用到五个 CNOT 的模板，更长的恒等式还有收益吗？" —— 见 5.2 的开放问题。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 四、结果

= 结果

== 环面码与目标操作 $overline(H)_1 overline(I)_2$

#slide[
  #page-2col(
    [环面码：参数、稳定子与逻辑算符],
    [
      - *参数*：码距 $d$ 的环面码物理比特数 $n = 2 d^2$，逻辑比特数 $k = 2$（论文正文给出）。
      - *结构*：比特放在方格的*边*上；每个面给一个 weight-4 的 $Z$ 稳定子，每个顶点给一个 weight-4 的 $X$ 稳定子。
      - *逻辑算符*：沿非平凡闭环的 $X$ 链与 $Z$ 链。Fig. 3 的 $d = 7$ 实例中，深色点是真实比特、浅色点是边界带来的虚拟比特，彩线标出两个逻辑比特的 $overline(Z)$、$overline(X)$。
      - *几何方法的极限*：横向 $H$ + SWAP 恢复稳定子结构会*同时*交换两个逻辑比特的 $Z$ 与 $X$，"只动一个"做不到。
      - *目标映射（式 (7)）*：$overline(Z)_1 -> overline(X)_1$、$overline(Z)_2 -> overline(Z)_2$、$overline(X)_1 -> overline(Z)_1$、$overline(X)_2 -> overline(X)_2$。
      - *方程规模*：$d = 3, 5, 7, 9, 11$ 对应 $U$ 的维数 $36, 100, 196, 324, 484$；$d = 3$ 的完整结果在 SM 中。
    ],
    image-path: "img/fig3.png",
    source: "Fig. 3：$d = 7$ 的环面码",
    img-height: 280pt,
    fractions: (1.15fr, 1fr),
  )
  #speaker-note[
    先讲图：方格、边上的比特、面与顶点对应的稳定子，再说明逻辑算符沿非平凡闭环。
    现场算规模：$d = 7$ 时 $n = 2 times 49 = 98$，$U$ 是 $196 times 196$。
  ]
]

== 资源标度与逻辑错误率

#slide[
  #layout(size => block(width: 100%, height: size.height)[
    #grid(
      columns: (1.05fr, 1fr),
      rows: (size.height,),
      column-gutter: 12pt,
      card([资源与错误率：三个可以记住的结论], [
        - *门数标度*：$N_"gate" = N_0 d^alpha$ 拟合给出 $alpha = 2.51$（简化前）$->$ $2.28$（简化后）；$n prop d^2$，论文的结论是门数与*一轮稳定子测量*同量级。
        - *错误率*：总逻辑错误率随 $d$ 上升，但*平均到每个物理门*的错误率随 $d$ 下降 —— 增长慢于门数增长，对容错设计有利。
        - *数据边界*：以上都是标度与量级；论文没有给出每个 $d$ 的具体 CNOT 数（需查 SM 或自行复现）。
        #v(10pt)
        #stat-row((
          ([$alpha$], [2.51 → 2.28]),
          ([240], [一轮测量的 CNOT 数]),
          ([$10^(-4)$], [仿真噪声率 $p$]),
        ))
      ], tone: "wash", height: 100%),
      grid(
        rows: (1fr, 1fr),
        row-gutter: 12pt,
        figure-card("img/fig4a.png", "Fig. 4(a)", height: 150pt, box-height: 100%),
        figure-card("img/fig4b.png", "Fig. 4(b)", height: 150pt, box-height: 100%),
      ),
    )
  ])
  #speaker-note[
    先把 $alpha$ 的两个值说清（都来自论文），再说"与一轮稳定子测量同量级"这个对照。
    右图强调两个相反趋势：总量上升、单位门下降 —— 后者才是容错的希望所在。
  ]
]

== 连续 Clifford 操作：一步实现 $overline(S)$ 与 $overline(H)$

#slide[
  #page-2col(
    [把 $overline(S)_1 overline(H)_1$ 当成一个整体来解],
    [
      - *目标映射（式 (8)）*：$overline(Z)_1 -> overline(Z)_1$、$overline(X)_1 -> overline(Z)_1 overline(X)_1$，其余逻辑算符不变。
      - *做法*：直接按式 (4) 写出整个 $(overline(S)_1 overline(H)_1) overline(I)_2$ 的目标，只需要解*一条*物理门序列，而不是"先解 $overline(S)$、再解 $overline(H)$"两条串联。
      - *收益*：论文报告一步实现比两步方案少约三分之一的门数，而且只比两步方案中 $overline(S)$ 的那一步略多。
      - *用途*：Fig. 5(a) 的线路（两个逻辑比特从 $|0 angle_L$ 出发，第一个经过 $overline(H)$、$overline(S)$，再做一次逻辑 CNOT）可制备相位偏移 Bell 态 $(|00 angle_L + i |11 angle_L)/sqrt(2)$，用于检验纠缠的基本不等式。
      - *更一般地*：若干基本 Clifford 门在逻辑线路里连续出现时，可以合并成一个目标映射一次求解。
    ],
    tone: "wash",
    fractions: (1.05fr, 1fr),
    right: block(
      width: 100%,
      height: 100%,
      fill: white,
      stroke: 0.7pt + green-line,
      radius: 4pt,
      inset: 10pt,
    )[
      #align(center + horizon)[
        #image("img/fig5a.png", width: 96%)
        #v(4pt)
        #image("img/fig5b.png", height: 150pt)
        #v(4pt)
        #text(size: 12pt, fill: mute-ink)[Fig. 5(a)(b)]
      ]
    ],
  )
  #speaker-note[
    Fig. 5(b) 里圆点是"一步法"的 $overline(S) overline(H)$，三角形是分两步；论文说一步法少约三分之一门数。
    顺带提醒：这条线路的用途是制备相位偏移 Bell 态。
  ]
]

== 双曲 ${4,5}$ 曲面码：结构与规模

#slide[
  #page-2col(
    [$\{r, s\}$ 双曲曲面码与最小的 $\{4,5\}$ 实现],
    [
      #set text(size: 16pt)
      - *局部规则*：与环面码一样把比特放在边上；$s$ 个相邻 $r$-边形在同一顶点相遇，构成一个 $X$ 稳定子。因此 $Z$ 稳定子是 $r$-权、$X$ 稳定子是 $s$-权。
      - *可铺砌条件*：$1/r + 1/s < 1/2$。Poincaré 圆盘上有无穷多种 ${r, s}$ 可选；欧氏平面只有三种满足 $1/r + 1/s = 1/2$ 的铺砌。
      - *最小 ${4,5}$ 实现*：60 个物理比特；30 个 $Z$ 稳定子与 24 个 $X$ 稳定子，*各含一个冗余*。独立稳定子数 $29 + 23 = 52$，逻辑比特数 $k = 60 - 52 = 8$。
      - *拓扑与收益*：边界上的边配对"粘合"后得到多手柄闭曲面（环面码只有 1 个手柄）；每个 handle 携带两个逻辑比特，编码率高于环面码。
      - *为什么值得算*：该码*不是自对偶*的（$Z$ 型与 $X$ 型稳定子数目不等），正是几何方法处理不了的情形。
    ],
    image-path: "img/fig6.png",
    source: "Fig. 6",
    img-height: 280pt,
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[
    讲三层：局部铺砌规则 → 可铺砌条件 → 粘合成闭曲面带来的拓扑自由度。
    数两个关键数字：60 个比特、52 个独立稳定子、8 个逻辑比特（复习 $k = n - m$）。
  ]
]

== 双曲码资源与三个例子的汇总

#slide[
  #page-2col(
    [$overline(H)_m$、$overline(S)_m$ 的资源与三个例子的汇总],
    [
      - 每个逻辑比特 $m$ 分别求解：门数随 $m$ 变化不大，化简后明显下降。
      - *对照*：一轮稳定子测量需 240 个 CNOT，本文门数与之同量级；论文正文未给具体门数。
      - 汇总：
      #light-table(
        (auto, auto, auto, 1fr),
        ("码（参数）", "目标逻辑操作", "资源", "备注"),
        (
          ([环面码 $n = 2 d^2$], [$overline(H)_1 overline(I)_2$], [$prop d^2.51 -> d^2.28$], [几何方法给不出单比特逻辑 $H$]),
          ([环面码 同上], [$(overline(S)_1 overline(H)_1) overline(I)_2$], [比两步法少约 $1/3$], [连续 Clifford 可合并一次求解]),
          ([双曲码 $k = 8$], [$overline(H)_m$、$overline(S)_m$], [与一轮测量同量级], [非自对偶码同样适用；编码率更高]),
        ),
        size: 12pt,
        inset: 5pt,
      )
    ],
    image-path: "img/fig7.png",
    source: "Fig. 7",
    img-height: 300pt,
    tone: "wash",
    fractions: (1.25fr, 1fr),
  )
  #speaker-note[
    这一页把双曲码资源收口，并给出三行汇总，方便听众拍照。
    "资源"一列是标度或量级，不是某次运行的确切门数。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 五、讨论与总结

= 讨论与总结

== 适用边界、容错代价与硬件连通性

#slide[
  #page-2cards(
    [方法与数据的边界],
    [
    - *只处理 CSS 码*（非 CSS 码可先映射为 CSS，代价是更多物理比特）与 *Clifford 逻辑操作*；逻辑 $T$ 门需要魔术态注入等机制。
    - 约束二把"码结构不变"加强为"每个稳定子生成元不变"，这是一个可以放松的假设。
    - *门数不是最优的*：消元顺序、逻辑算符 $overline(Z)$、$overline(X)$ 的选取都会影响结果；论文只做模板级局部化简。
  ],
    [容错代价与硬件连通性],
    [
    - *相关错误*：求出的门序列没有专门考虑错误在序列中间传播造成的相关错误，这类错误可能破坏码距；论文明确说算法通用但要牺牲一部分容错性。
    - *补救*：在算出的线路里插入若干对 flag qubit \[39–42\] 探测危险的两个比特错误，再补门纠正；更细致的设计可以保持码距。
    - *连通性*：只有近邻耦合的平台上，不相邻比特对需要额外 SWAP，论文指出这部分开销正比于码距 $d$ —— 本文门数*不含*这部分。全连接（all-to-all）的离子阱系统不需要额外 SWAP；另一条路是改造布局让连接匹配码的结构。
  ],
    tone1: "wash",
    tone2: "caution",
  )
  #speaker-note[
    先讲图：方格、边上的比特、面与顶点对应的稳定子，再说明逻辑算符沿非平凡闭环。现场算规模：$d = 7$ 时 $n = 2 times 49 = 98$，$U$ 是 $196 times 196$。
  ]
]

== 与已有方法对比，以及可以继续挖的问题

#slide[
  #page-2cards(
    [四条路线的分工],
    [
    #light-table(
      (auto, auto, auto, 1fr),
      ("方法", "提供什么门", "适用范围", "主要代价"),
      (
        ([横向门], [部分 Clifford 门], [结构上允许横向门的码], [受结构限制，门集合不通用]),
        ([格点手术 / 规范固定], [逻辑 CNOT 及其组合], [表面码等平面码], [额外物理比特与多轮测量]),
        ([几何 / Dehn twist], [逻辑 CNOT], [双曲曲面码（自对偶时更多）], [单比特 $overline(H)$、$overline(S)$ 无通用构造]),
        ([本文方法], [任意 Clifford 逻辑操作], [任意 CSS 码], [门数非最优；需要后续容错加固]),
      ),
      size: 13pt,
    )
  ],
    [可以继续挖的问题（我整理的，不是论文结论）],
    [
    - *① 约束 (3) 放松*：允许稳定子置换/重组后，解空间与门数变化多少？
    - *② 选取与顺序*：逻辑算符选取 + 消元顺序按"最少 CNOT"联合优化，能省多少？
    - *③ 更长模板与容错加固*：更长 CNOT 恒等式、flag qubit 加固的代价各是多少？
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    先把 $alpha$ 的两个值说清（都来自论文），再说“与一轮稳定子测量同量级”这个对照；右图强调两个相反趋势：总量上升、单位门下降。
  ]
]

== 总结

#slide[
  #page-card-tiles(
    [三句话总结这篇论文],
    [
      - *问题*：给定任意 CSS 码和目标 Clifford 逻辑操作，怎样系统地把线路（物理门序列）算出来？
      - *方法*：把"合法 Clifford"（ @eq:保辛条件）、"码结构不变"（式 (3)）、"逻辑算符按目标映射"（式 (4)）写成 $bb(F)_2$ 上的方程；二次约束线性化后用稀疏消元求 $U$，再用四种辛初等操作把 $U$ 消成 $I_(2n)$，逆序读出物理门序列，最后用 CNOT 模板化简。
      - *结果*：环面码上给出 $overline(H)_1 overline(I)_2$、$(overline(S)_1 overline(H)_1) overline(I)_2$；$\{4,5\}$ 双曲码上给出 $overline(H)_m$、$overline(S)_m$，并给出资源与逻辑错误率趋势。
      - *意义与保留*：为 LDPC 码的逻辑操作设计提供了不依赖几何直觉的通用工具；代价是门数非最优、需要额外的容错加固。
      - *延伸阅读*：辛表示 \[30\]、Stim \[38\]、双曲曲面码 \[24, 25\]、flag qubit \[39–42\]。
      #v(4pt)
      #align(center)[#text(size: 13pt, fill: mute-ink)[
        原文：S.-C. Liu, Y.-X. Lin, Y.-X. Wang, L.-Y. Peng, _Chin. Phys. Lett._ *43*, 040603 (2026). DOI: 10.1088/0256-307X/43/4/040603
      ]]
    ],
    (
      ([$d^2.28$], [简化后的门数标度]),
      ([$1/3$], [一步法相对两步法省下的门数]),
      ([240 CNOT], [一轮稳定子测量的量级]),
      ([$k = 8$], [双曲码的逻辑比特数]),
    ),
  )
  #speaker-note[
    收尾三句话即可，留出提问时间。提问若问到具体门数或 $d = 3$ 的结果，指向 SM 与附录 C。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录：推导、显式矩阵、计数细节（正文用编号交叉引用）

== 附录 A：保辛条件 $U Lambda U^T = Lambda$ 的逐元素推导 <app:symp>

#slide[
  #page-2cards(
    [从"保持对易关系"到 @eq:保辛条件，再到分块恒等式],
    [
    - *出发点*：辛内积 $A Lambda B^T$ 取值 $0$ / $1$ 分别表示对易 / 反对易。Clifford 操作保持这一关系，即对任意 $A, B$
      #align(center)[$ A Lambda B^T = (A U) Lambda (B U)^T = A (U Lambda U^T) B^T quad ==> quad U Lambda U^T = Lambda. quad (2) $]
    - *分块展开*：按 $n times n$ 分块写成 $U = mat(A, B; C, D)$。因为 $Lambda$ 只把两半互换，$U Lambda = mat(B, A; D, C)$；代入 @eq:保辛条件 后比较四个块，得到三条恒等式
      #align(center)[$ A B^T + B A^T = 0, quad C D^T + D C^T = 0, quad A D^T + B C^T = I_n. $]
  ],
    [注记],
    [
    - 在 $bb(F)_2$ 上 $1 = -1$，所以 "$X + X^T = 0$" 就是"$X$ 对称"。
    - 三条恒等式的每一项都是 $U$ 中两个元素之积 —— 这正是正文 3.2 中"二次约束"的来源。
    - 本附录是把正文的两行结论展开成中间步骤（论文只给结论），不含原文之外的假设。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    讲三层：局部铺砌规则 → 可铺砌条件 → 粘合成闭曲面带来的拓扑自由度。数两个关键数字：60 个比特、52 个独立稳定子、8 个逻辑比特。
  ]
]

== 附录 B：四种门的显式辛矩阵（$n = 2$） <app:gates>

#slide[
  #page-2cards(
    [行约定与四个 $4 times 4$ 矩阵],
    [
    #set text(size: 16pt)
    - $A_P -> A_P U$，第 $j$ 行是 $Z_j$ 的像，第 $(n+j)$ 行是 $X_j$ 的像；取 $n = 2$，行/列顺序 $(Z_1, Z_2, X_1, X_2)$：
      #align(center)[$ U_(H_1) = mat(0,0,1,0; 0,1,0,0; 1,0,0,0; 0,0,0,1), quad U_(S_1) = mat(1,0,0,0; 0,1,0,0; 1,0,1,0; 0,0,0,1) $]
      #align(center)[$ U_("CNOT"_(1 2)) = mat(1,0,0,0; 1,1,0,0; 0,0,1,1; 0,0,0,1), quad U_("SWAP"_(1 2)) = mat(0,1,0,0; 1,0,0,0; 0,0,0,1; 0,0,1,0) $]
  ],
    [对照检查与列操作对应],
    [
    #set text(size: 16pt)
    - 以 $U_("CNOT"_(1 2))$ 为例：第二行 $e_1 + e_2$ 对应 $Z_2 -> Z_1 Z_2$；第三行 $e_3 + e_4$ 对应 $X_1 -> X_1 X_2$；第一、四行使 $Z_1$、$X_2$ 不变 —— 与物理 CNOT（控制 1、目标 2）一致。
    - 四个矩阵都满足 $U Lambda U^T = Lambda$（可直接验算）；列操作对应见正文 3.3 的表格。本附录把论文的列操作描述写成显式矩阵（属整理内容）。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这一页把双曲码资源收口，并给出三行汇总，方便听众拍照。“资源”一列是标度或量级，不是某次运行的确切门数。
  ]
]

== 附录 C：线性化与复杂度的计数细节 <app:linear>

#slide[
  #page-2cards(
    [量级是怎么数出来的],
    [
    - *未知量*：$U$ 是 $2 n times 2 n$，共 $(2 n)^2 = 4 n^2$ 个 $bb(F)_2$ 上的比特。
    - *二次方程个数*： @eq:保辛条件 是 $2 n times 2 n$ 个矩阵元方程，去掉冗余后独立方程数与未知量同量级，即 $O(n^2)$。
    - *每个方程的项数*：由分块展开式，每个矩阵元是 $sum_k U_(i, k+n) U_(j k)$ 这类求和，含 $O(n)$ 个"两个元素之积"的单项式。
    - *线性化后的规模*：论文把这些乘积提升为新变量，并指出线性方程组的行数与列数都在 $O(n^2)$ 量级；矩阵高度稀疏，稀疏消元总代价"略高于 $O(n^4)$"。
    - *一致性回代*：新变量须满足 $v_(a b c d) = U_(a b) U_(c d)$；论文在解空间里做匹配，并说明这一步不消耗很多计算资源。
  ],
    [规模示例与注记],
    [
    - $d = 7$ 环面码：$n = 2 d^2 = 98$，$U$ 为 $196 times 196$，元素 $196^2 = 38416$ 个；对应态矢量维数 $2^196$。两者都说明必须走稀疏线性代数这条路。
    - 本附录按论文叙述整理量级，论文未给出逐项计数与复杂度常数；如需精确数字应查阅 SM。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页回答"$O(n^4)$ 是怎么来的"，是审稿式提问最集中的地方。诚实说明：论文只给量级结论，逐项计数是我们的整理。
  ]
]

== 附录 D：$H_Z H_X^T = 0$ 与逻辑算符条件的推导 <app:css>

#slide[
  #page-2cards(
    [从"两两对易"到矩阵条件],
    [
    - *对易判据*：$Z_a$ 与 $X_b$ 反对易当且仅当它们*共同作用的比特数为奇数*（每个共同比特贡献一次 $Z X$ 型的反对易）。
    - 记 $H_Z$ 的第 $a$ 行为 $r_a in bb(F)_2^n$、$H_X$ 的第 $b$ 行为 $s_b$，则共同比特数为 $r_a dot s_b mod 2$。
    - 要求所有 $Z$ 型与 $X$ 型稳定子两两对易，即 $r_a dot s_b = 0$ 对所有 $a, b$ 成立，写成矩阵形式就是
      #align(center)[$ H_Z H_X^T = 0. quad (1) $]
    - *同型自动对易*：$Z$ 与 $Z$、$X$ 与 $X$ 永远对易（$Z Z = I$、$X X = I$），所以只需检查 $Z$ 型与 $X$ 型之间的重叠比特数。
  ],
    [逻辑算符的条件],
    [
    - 逻辑 $Z$ 型算符 $A_Z$ 要与所有 $X$ 型稳定子对易：$H_X A_Z^T = 0$；逻辑 $X$ 型算符满足 $H_Z A_X^T = 0$。
    - *非平凡性*：还要排除"算符本身等于若干稳定子的乘积"的情况，否则它不是逻辑算符而是稳定子。
    - 这就是正文 2.2 中两条条件的来历；论文正文直接用这两条结果。
    返回 @稳定子码与CSS码
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这是“诚实的限制清单”，也是讨论环节最好的抓手。有硬件/编译背景的听众会关心“SWAP 开销不计在内”这一点。
  ]
]
