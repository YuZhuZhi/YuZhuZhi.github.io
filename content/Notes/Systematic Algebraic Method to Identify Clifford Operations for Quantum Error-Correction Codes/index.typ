// =====================================================================================
// 组会报告（41 页）：Systematic Algebraic Method to Identify Clifford Operations
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

#import "@preview/touying:0.8.0": *
#import "@preview/physica:0.9.8": *
// #import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
// #import "@preview/cetz:0.4.2": canvas, draw, vector, matrix
// #import "@preview/theorion:0.5.0": *
#import "@preview/tablex:0.0.9": tablex, rowspanx, colspanx, hlinex
#import themes.aqua: *

// 逐页讲稿与问答分别由 speak/notes.typ、speak/questions.typ 维护，不进入观众视图。
#import "speak/notes.typ": entries
#import "speak/questions.typ": all-questions
#let talk-notes = range(entries.len()).map(i => {
  let entry = entries.at(i)
  all-questions.at(i).fold(entry.paragraphs, (note, qa) => note + [
    #parbreak()
    可能提问：#qa.question
    #parbreak()
    参考回答：#qa.answer
  ])
})

// #let cetz-canvas = touying-reducer.with(reduce: canvas, cover: draw.hide.with(bounds: true))

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
#let figure-card(image-path, source, height: 240pt, caption: none, box-height: auto, figWidth: 100%) = {
  block(
    width: 100%,
    height: box-height,
    fill: white,
    stroke: 0.7pt + green-line,
    radius: 4pt,
    inset: 10pt,
  )[
    #align(center + horizon)[
      #image(image-path, width: figWidth, height: height)
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
  figWidth: 100%,
) = layout(size => {
  let fs = fractions.map(to-frac)
  let total = fs.sum()
  let col1 = (size.width - gap) * fs.at(0) / total
  let right-content = if right != none { right } else {
    figure-card(image-path, source, height: img-height, box-height: 100%, figWidth: figWidth)
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

// 一页：上=图卡、下=说明卡（宽图用这种上下结构，图能占满整页宽度而不被裁切）
//   image-height 不填时按区域自动留出说明文字的位置
#let page-figure-notes(
  image-path,
  source,
  notes-title,
  notes,
  caption: none,
  weights: (3.4fr, 1fr),
  gap: 12pt,
  tone: "wash",
  figWidth: 100%,
) = layout(size => {
  let ws = norm-weights(weights)
  let avail = size.height - gap
  let r1 = ws.at(0) * avail
  let r2 = ws.at(1) * avail
  block(width: 100%, height: size.height)[
    #grid(
      rows: (r1, r2),
      row-gutter: gap,
      figure-card(
        image-path,
        source,
        height: r1 - 40pt,
        caption: caption,
        box-height: 100%,
        figWidth: figWidth
      ),
      fit-card(notes-title, notes, tone: tone, avail: r2, width: size.width),
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
#speaker-note[#talk-notes.at(0)]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 一、研究背景与动机


= 研究背景与动机
#speaker-note[#talk-notes.at(1)]

== 文章概览

#slide[
  #page-2cards(
    [目的与方法],
    [
    + *通用性*：对#highlight[任意] CSS 码求#highlight[任意]指定的 Clifford 逻辑操作，把"保持码结构"与"实现目标逻辑映射"写成 $bb(F)_2$ 上的方程组。
    + *可解性*：用辛表示把 Clifford 操作编码成 $2 n times 2 n$ 的二进制矩阵 $U$（$O(n^2)$ 个比特）；将二次约束线性化后是稀疏线性方程组，复杂度略高于 $O(n^4)$。
    + *流程*：解出的 $U$ 被分解为单比特门与双比特门序列，再用 CNOT 消去模板压缩门数；将门与稳定子输入到 Stim 可获得逻辑错误率。
    ],
    [代价],
    [
    - 门数不保证最优：消元顺序、逻辑算符的选取都会影响结果，文章只做模板级局部化简。
    - 需要牺牲一部分容错性：完整容错设计留作后续工作。
    - 只处理 Clifford 逻辑操作；逻辑 $T$ 这类门仍然需要魔术态注入等额外机制。
  ],
    tone1: "wash",
    tone2: "caution",
  )
  #speaker-note[#talk-notes.at(4)]
]

// == 噪声、阈值与开销

// #slide[
//   #page-2cards(
//     [为什么需要量子纠错],
//     [
//     - 退相干、门误差、读出误差、串扰都会累积；当前平台上单比特操作错误率大致在 $10^(-3)$–$10^(-2)$。
//     - *阈值定理*：只有物理错误率 $p < p_"th"$ 时，增大码距 $d$ 才会把逻辑错误率压下去。这是容错路线的起点。
//     - $[n,k,d]$：$n$ —— 物理比特数，$k$ —— 逻辑比特数，$d$ —— 码距。
//   ],
//     [代价在哪里],
//     [
//     - 工程上真正关心的是"每个逻辑操作要消耗多少物理门"，以及这个数目随码距怎么增长。
//     - 本文回答后者：给定码与目标逻辑操作，算出具体的物理门序列，并给出门数标度。
//   ],
//     tone1: "wash",
//     tone2: "caution",
//   )
//   #speaker-note[#talk-notes.at(2)]
// ]

== 三条路线与三个缺点

#slide[
  #page-2cards(
    [已有路线],
    [
    - *横向门*：对每个物理比特施加相同的门，最简单；但横向门集合受结构限制，多数码只有部分 Clifford 门可用。
    - *格点手术与规范固定*：在表面码上通过合并、分裂码片实现逻辑 CNOT；代价是额外物理比特与多轮测量。
    - *几何 / 拓扑方法*：把逻辑操作等价实现为曲面上的拓扑操作，例如双曲曲面码上用 Dehn twist 实现逻辑 CNOT；自对偶码还能借几何对称性给出部分门。
  ],
    [缺点],
    [
    + 单比特逻辑门 $overline(H)$、$overline(S)$ 对一般（非自对偶）码没有通用构造 —— 几何方法不能给出"只动一个逻辑比特、另一个不动"的操作。
    + 这些方法基本是"一码一策"：换一种码、换一个门，往往要重新设计。
    + 逻辑信息散布在整个物理比特集合上，局部几何操作难以同时保持稳定子结构。
    - 本文的做法：绕开几何直觉，把"实现逻辑操作"直接转换为求解代数方程。
  ],
    tone1: "wash",
    tone2: "caution",
  )
  #speaker-note[#talk-notes.at(3)]
]


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 二、预备知识

= 预备知识 · 文章约定
#speaker-note[#talk-notes.at(5)]

== 稳定子码与 CSS 码 <稳定子码与CSS码>

#slide[
  #page-2cards(
    [稳定子码与逻辑算符],
    [
    - 取相互对易的 Pauli 生成元 $S_1, dots, S_m$（不含 $-I$），码空间是它们的 $+1$ 公共本征空间。
    - 落在码空间外的错误会改变某些稳定子的本征值，测量这些本征值（错误综合征）即可定位错误。
    - 逻辑算符：与所有稳定子对易、但本身不属于稳定子群的 Pauli 链。每个逻辑比特选一对 $overline(Z)_i$、$overline(X)_i$，要求二者反对易（辛配对）、不同逻辑比特之间对易。
  ],
    [CSS 码的结构],
    [
    - 生成元分成纯 $Z$ 型与纯 $X$ 型两组，可以被写为校验矩阵 $H_Z$（$n_Z times n$）与 $H_X$（$n_X times n$）。
    - 要求 $Z$ 型与 $X$ 型稳定子两两对易，等价于
      $ H_Z H_X^T = 0, $
      意味着这两个稳定子共同作用的比特数为偶数。推导见 @app:css。
    - 逻辑算符满足条件：$H_X A_Z^T = 0$、$H_Z A_X^T = 0$，且算符本身不落在稳定子群中。
    - 非 CSS 码可映射为 CSS 码，代价是更多物理比特。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(7)]
]

== Pauli 链、辛内积与对易条件

#slide[
  #page-2cards(
    [把 Pauli 链写成 $bb(F)_2$ 上的向量],
    [
    - $n$ 比特 Pauli 群由 $I, X, Y, Z$ 的张量积以及相位 $plus.minus 1, plus.minus i$ 构成；纠错只关心"在哪些比特上做什么"，相位可以整体忽略。
    - 编码约定：一维二进制向量 $A_P = (A_Z | A_X) in bb(F)_2^(2 n)$，前后两段各长 $n$。链上第 $i$ 个门使用两位二进制数表示：取 $A_Z, A_X$ 中的第 $i$ 位组合为 $(A_(Z)^((i)), A_(X)^((i)))$，则：#v(20pt)
    #align(center)[
    #tablex(
      columns: 5,
      align: horizon + center,
      auto-vlines: false,
      column-gutter: 10pt,
      inset: 10pt,

      [$A_(Z)^((i))A_(X)^((i))$], [$00$], [$01$], [$10$], [$11$],
      [对应门], [$I$], [$X$], [$Z$], [$Y$]
    )]
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
  #speaker-note[#talk-notes.at(6)]
]

== Clifford 操作与辛条件

#slide[
  #page-2cards(
    [Clifford 操作 = 保辛的二进制矩阵],
    [
    - 酉操作的作用是 $P -> U_"op"^dagger P U_"op"$；Clifford 操作把 Pauli 链映为 Pauli 链，意味着 $U_"op"^dagger P U_"op" = plus.minus P'$。
    - 忽略相位，设 $U$ 是 $bb(F)_2^(2 n)$ 上的线性映射，可用 $2 n times 2 n$ 二进制矩阵表示：$A_P -> A_P U$。
    - *行约定*：$U$ 的第 $j$ 行是 $Z_j$ 的像，第 $(n+j)$ 行是 $X_j$ 的像。
    - 保辛条件：对任意 Pauli 链 $A, B$，$A Lambda B^T = (A U) Lambda (B U)^T = A (U Lambda U^T) B^T$，因此
      $ U Lambda U^T = Lambda. $ <eq:保辛条件>
      取基向量逐个元素比较即可得到（展开见 @app:symp）。
  ],
    [分块形式],
    [
    - 把 $U$ 按 $n times n$ 分块写成 $U = mat(A, B; C, D)$，@eq:保辛条件 等价于三条矩阵恒等式：
      $ A B^T + B A^T = 0, quad C D^T + D C^T = 0, quad A D^T + B C^T = I_n. $
    - 满足 @eq:保辛条件 的矩阵构成辛群 $"Sp"(2 n, bb(F)_2)$ —— "找一个逻辑操作"就是"在辛群里找满足码结构条件的矩阵"。
    // - 注意 @eq:保辛条件 的每个矩阵元都是 $U$ 中两个元素之积：*这就是后文"二次约束"的来源*。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(8)]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 三、代数方法

= 代数方法
#speaker-note[#talk-notes.at(9)]

== 三条约束 <sec:三条约束>

#slide[
  #page-2cards(
    [求解目标],
    [
    + *保辛（@eq:保辛条件）*：$U Lambda U^T = Lambda$ —— 保证任意 Pauli 链之间的对易/反对易关系不变。
    + *稳定子生成元不变（@eq:码结构）*：
      $ mat(H_Z, 0; 0, H_X) U = mat(H_Z, 0; 0, H_X). $ <eq:码结构>
      论文为求解方便*直接要求每个稳定子生成元在变换之后回到自身*。更一般的情形允许稳定子置换/重组，但会引入组合问题。
    + *目标映射（@eq:目标映射）*：
      $ mat(overline(Z), 0; 0, overline(X)) U = mat(overline(Z)^Z, overline(X)^Z; overline(Z)^X, overline(X)^X). $ <eq:目标映射>
      $overline(Z)$、$overline(X)$ 各是 $k times n$；右端四块表示像的 $Z$/$X$ 部分，可由 $overline(Z)$、$overline(X)$ 的行线性表示。
  ],
    [两个例子的目标映射],
    [
    - $overline(H)_1 overline(I)_2$：$overline(Z)_1 -> overline(X)_1$、$overline(X)_1 -> overline(Z)_1$，其余不变。
    - $overline(S)_1 overline(I)_2$：$overline(X)_1 -> overline(Z)_1 overline(X)_1$，其余不变。
    // - 于是"设计线路"变成"求满足 @eq:保辛条件 @eq:码结构 @eq:目标映射 的 $U$"，解出后再分解成物理门。三条约束具体怎么合成一个线性方程组，见 @app:merge；自由变量的削减与特解见 @app:vars、@app:particular。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(10)]
]

== 二次约束与线性化

#slide[
  #page-2cards(
    [@eq:保辛条件 是二次的],
    [
    - 把 $U$ 的元素记作 $U_(i j)$， @eq:保辛条件 的每个矩阵元都是"两个元素相乘再求和"：
      #align(center)[$ (U Lambda U^T)_(i j) = sum_(k = 1)^n U_(i, k+n) U_(j k) + sum_(k = n+1)^(2 n) U_(i, k-n) U_(j k). $]
      因此 @eq:保辛条件 给出 $O(n^2)$ 个*二次*方程（分块展开见 @app:symp），而 @eq:码结构，@eq:目标映射 都是线性的。
    - *线性化*：对出现在这些二次方程中的每一对元素引入新变量 $v_(a b c d) = U_(a b) U_(c d)$；代入后 @eq:保辛条件 变成关于 $(U, v)$ 的线性方程，再与 @eq:码结构，@eq:目标映射 合并。合并的确切含义见 @app:merge。
    - *规模*：论文指出线性方程组的行数（方程数）与列数（未知量数）都在 $O(n^2)$ 量级且*高度稀疏* —— 每个方程只涉及少数几个变量。
  ],
    [复杂度与二次约束验证],
    [
    - *复杂度*：稀疏消元的总代价"略高于 $O(n^4)$"，对比态矢量方法的 $4^n$ 维空间。量级估计见 @app:linear。
    - *二次约束验证*：$v$ 是形式变量，必须满足 $v_(a b c d) = U_(a b) U_(c d)$；论文在解空间里做"二次变量与 $U$ 元素的匹配"，并指出这一步开销很小。@app:kernel、@app:sparse、@app:matching。
    - *规模示例*：$d = 7$ 环面码 $n = 2 d^2 = 98$，$U$ 是 $196 times 196 = 38416$，故直接枚举 $U_"op"$ 是不可行的。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(11)]
]

== 物理门分解

#slide[
  // 上卡仍是整页宽的表；下卡只占左侧，右侧留给环面码的消元动画（不配任何说明文字）。
  #layout(size => {
    let gap = 12pt
    let avail = size.height - gap
    let h1 = 0.45 * avail            // 上卡高度：与原来的 rsize: 0.45 一致
    let h2 = avail - h1              // 下卡与动画所在的一行
    let left-w = (size.width - gap) * 0.68
    let right-w = size.width - gap - left-w
    block(width: 100%, height: size.height)[
      #grid(
        rows: (h1, h2),
        row-gutter: gap,
        fit-card(
          [门的种类与它们对 $U$ 的作用],
          [
            #light-table(
              (0.3fr, 0.8fr, 1.3fr),
              ("门", "对 Pauli 链的作用（物理效果）", "对 $U$ 的列操作（右乘初等矩阵）"),
              (
                ([$H_i$], [$Z_i <-> X_i$], [交换第 $i$ 列与第 $(i+n)$ 列]),
                ([$S_i$], [$X_i -> Z_i X_i$], [把第 $(i+n)$ 列加到第 $i$ 列]),
                ([$"CNOT"_(i j)$], [$X_i -> X_i X_j$、$Z_j -> Z_i Z_j$], [第 $j$ 列加到第 $i$ 列；第 $(i+n)$ 列加到第 $(j+n)$ 列]),
                ([$"SWAP"_(i j)$], [$Z_i <-> Z_j$、$X_i <-> X_j$], [交换第 $i$、$j$ 列；交换第 $(i+n)$、$(j+n)$ 列]),
              ),
              size: 16pt
            )
          ],
          tone: "wash",
          avail: h1,
          width: size.width,
        ),
        grid(
          columns: (left-w, right-w),
          rows: (h2,),
          column-gutter: gap,
          fit-card(
            [只允许四类辛操作把 $U$ 化为 $I_(2 n)$],
            [
            - 这四类初等矩阵*不构成*全部初等操作，但都是*辛*的，即每步保持 @eq:保辛条件 ：$U Lambda U^T = Lambda$，所以高斯消元时顺序必须专门设计。
            - 记初等矩阵为 $P_k$。那么 $U P_1 dots.c P_T = I_(2 n)$ $==>$ $U = P_T dots.c P_1$，门序列按*逆序*读出，$T$ 是化简前的物理门数。
            // - $n = 2$ 的显式 $4 times 4$ 矩阵见 @app:gates，可以直接核对上表的列操作。
            ],
            tone: "plain",
            avail: h2,
            width: left-w,
          ),
          block(
            width: 100%,
            height: 100%,
            fill: white,
            stroke: 0.7pt + green-line,
            radius: 4pt,
            inset: 8pt,
          )[
            #align(center + horizon)[#image(
              if sys.inputs.at("appendix-static", default: "false") == "true" { "img/appendix-toric-poster.png" } else { "img/appendix-toric.gif" },
              width: 100%,
              height: h2 - 16pt,
              fit: "contain",
            )]
          ],
        ),
      )
    ]
  })
  #speaker-note[#talk-notes.at(12)]
]

== 辛高斯消元

#slide[
  #page-2cards(
    [$U --> I_(2 n)$ 四步消元],
    [
      + *双比特门*：只看 $U$ 左侧 $2 n times n$ 部分，用 CNOT/SWAP 操作把它化为列阶梯形；右侧 $n$ 列会被同步作用。
      + *$H$ 门换列*：若左上还没出现 $I_n$，说明右半存在带零元的列（因 $U$ 满秩，不会出现全零列），因此用 $H$ 把右半的列换进来再重复*第一步*。通常此时左上、右下两个块都已是 $I_n$。
      + *消左下*：单个元素 $(i+n, i)$ 用 $S_i$ 消去；成对元素 $(i+n, j)$ 与 $(j+n, i)$（$i < j$）用 $H_i "CNOT"_(j i) H_i$ 一起消掉。
      + *消右上*：右上角若还有非零元，再继续使用 $H$ 门处理，最终 $U -> I_(2 n)$，分解结束。
    ],
    [边界情形与读数规则],
    [
      - 只剩左下非零、只剩右上非零等边界情形，论文逐类给出了消除手法。
      - *可行性*：这四类初等矩阵不构成全部初等操作，但都是辛的，每步都保持 $U Lambda U^T = Lambda$，所以消元顺序必须专门设计。
      - *门序列读出*：由 $U P_1 dots.c P_T = I_(2 n)$ 得 $U = P_T dots.c P_1$，最终线路要把消元过程*逆序*读出（Fig. 1 的时间轴指向左侧）；$T$ 就是化简前的物理门数。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(13)]
]

== 四步消元流程图

#slide[
  #page-figure-notes(
    "img/fig1.png",
    "Fig. 1",
    [],
    [
      - *上部*是变换矩阵 $U$ 的演化: 先把左侧 $2 n times n$ 化为列阶梯形, 再 $H$ 换列、$S$ 清左下、$H$ 清右上, 最后得到 $I_(2 n)$。
      - *下部*是与每一步同步的量子线路：矩阵上每做一次初等列操作，线路上就多一个对应的门。
      - *时间轴 $t$ 向左*：因为门序列要逆序读出，所以线路要从右往左看。
    ],
    figWidth: 65%
    // caption: [分解流程：上排是矩阵演化，下排是对应的量子线路],
  )
  #speaker-note[#talk-notes.at(14)]
]

== 化简与输出

#slide[
  #page-2cards(
    [两条化简规则迭代使用],
    [
      + *SWAP 折算*：一个 SWAP 等于三个 CNOT（Fig. 2(a)），统计门数时把所有双比特门统一折算成 CNOT。
      + *五 CNOT 模板*：满足该模板的三 CNOT 组合可以化成两个 CNOT（Fig. 2(b)）；CNOT 之间常有对易关系，这类组合在实际线路里出现得很频繁。
      - *迭代*：替换后可能出现新的可化简组合，反复搜索直到无法继续；化简只改变实现方式，不改变 $U$。
    ],
    [输出与代价],
    [
      - *输出*：物理门序列 + 门数（简化前 / 简化后）。
      - *仿真*：门与稳定子输入 Stim 可得逻辑错误率（见 @sec:资源标度与逻辑错误率）。
      - *代价*：化简只是模板级局部优化，门数不保证最优；更长的 CNOT 恒等式是否还有收益，论文没有回答。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(15)]
]

== 化简规则示意图

#slide[
  #page-figure-notes(
    "img/fig2.png",
    "Fig. 2",
    [],
    [
      - *Fig. 2(a) 左侧*：一个 SWAP 可以用三个 CNOT 代替 —— 这是把双比特门统一折算成 CNOT 的依据。
      - *Fig. 2(a) 右侧*：两个 CNOT 在某些情形下对易（可以交换顺序），这给"重新组合、消除门"留出了空间。
      - *Fig. 2(b) 五 CNOT 模板*：五个 CNOT 的组合等于恒等，于是可以从不同位置"切三留二"，把三个 CNOT 换成两个。
    ],
    // caption: [两比特门的等价关系与五 CNOT 化简模板],
    figWidth: 75%
  )
  #speaker-note[#talk-notes.at(16)]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 四、结果

= 结果
#speaker-note[#talk-notes.at(17)]

== 环面码与目标操作 $overline(H)_1 overline(I)_2$

#slide[
  #page-2col(
    [环面码：参数、稳定子与逻辑算符],
    [
      - *参数*：码距 $d$ 的环面码物理比特数 $n = 2 d^2$，逻辑比特数 $k = 2$。
      - *结构*：比特放在方格的*边*上。
      - *逻辑算符*：沿非平凡闭环的 $X$ 链与 $Z$ 链。Fig. 3 的 $d = 7$ 实例中，深色点是真实比特、浅色点是边界带来的虚拟比特，彩线标出两个逻辑比特的 $overline(Z)$、$overline(X)$。
      - *几何方法的极限*：横向 $H$ + SWAP 恢复稳定子结构会*同时*交换两个逻辑比特的 $Z$ 与 $X$，无法实现*只作用在一个逻辑比特上*的 $H$ 门。
      - *目标映射*：$overline(Z)_1 -> overline(X)_1$、$overline(Z)_2 -> overline(Z)_2$、$overline(X)_1 -> overline(Z)_1$、$overline(X)_2 -> overline(X)_2$。
      - *方程规模*：$d = 3, 5, 7, 9, 11$ 对应 $U$ 的维数 $36, 100, 196, 324, 484$。$d = 3$ 时的完整输入矩阵、一个解与逐项核验见 @app:d3、@app:seq。
    ],
    image-path: "img/fig3.png",
    source: [Fig. 3：$d = 7$ 的环面码],
    img-height: 300pt,
    fractions: (1.15fr, 1fr),
    figWidth: 90%
  )
  #speaker-note[#talk-notes.at(18)]
]

== 资源标度与逻辑错误率 <sec:资源标度与逻辑错误率>

#slide[
  #layout(size => block(width: 100%, height: size.height)[
    #grid(
      columns: (0.8fr, 1fr),
      rows: (size.height,),
      column-gutter: 12pt,
      card([资源与错误率的三个结论], [
        - *门数标度*：使用幂函数 $N_"gate" = N_0 d^alpha$ 拟合给出 $alpha = 2.51$（简化前）$->$ $2.28$（简化后）；而 $n prop d^2$，结论是门数与*一轮稳定子测量*同量级。
        - *错误率*：总逻辑错误率随 $d$ 上升，但*平均到每个物理门*的错误率随 $d$ 下降 —— 增长慢于门数增长，对容错设计有利。
        // - *数据边界*：以上都是标度与量级。
        #v(30pt)
        #stat-row((
          ([$alpha$], [2.51 → 2.28]),
          ([240], [一轮测量的 CNOT 数]),
          ([$10^(-4)$], [仿真噪声率 $p$]),
        ))
      ], tone: "wash", height: 100%),
      grid(
        rows: (1fr, 1fr),
        row-gutter: 12pt,
        figure-card("img/fig4a.png", "Fig. 4(a)", height: 150pt, box-height: 100%, figWidth: 50%),
        figure-card("img/fig4b.png", "Fig. 4(b)", height: 150pt, box-height: 100%, figWidth: 50%),
      ),
    )
  ])
  #speaker-note[#talk-notes.at(19)]
]

== 连续 Clifford 操作：一步实现 $overline(S)$ 与 $overline(H)$

#slide[
  #page-2col(
    [把 $overline(S)_1 overline(H)_1$ 当成一个整体来解],
    [
      - *用途*：Fig. 5(a) 的线路可制备相位偏移 Bell 态 $(ket(00)_L + i ket(11)_L)/sqrt(2)$，用于检验纠缠的基本不等式。
      - *做法*：直接按 @sec:三条约束 @eq:目标映射 写出整个 $(overline(S)_1 overline(H)_1) overline(I)_2$ 的目标，只需要解*一条*物理门序列，而不是"先解 $overline(S)$、再解 $overline(H)$"两条串联。
      - *收益*：一步实现比两步方案少约三分之一的门数，而且只比两步方案中 $overline(S)$ 的那一步略多。
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
        #image("img/fig5a.png", width: 100%)
        #v(4pt)
        #image("img/fig5b.png", width: 100%)
        #v(4pt)
        #text(size: 12pt, fill: mute-ink)[Fig. 5(a)(b)]
      ]
    ],
  )
  #speaker-note[#talk-notes.at(20)]
]

== 双曲 ${4,5}$ 曲面码：结构与规模

#slide[
  #page-2col(
    [${r, s}$ 双曲曲面码与最小的 ${4,5}$ 实现],
    [
      #set text(size: 16pt)
      - *局部规则*：与环面码一样把比特放在边上；$s$ 个相邻 $r$-边形在同一顶点相遇，构成一个 $X$ 稳定子。因此 $Z$ 稳定子是 $r$-权、$X$ 稳定子是 $s$-权。
      - *可铺砌条件*：$1/r + 1/s < 1/2$。Poincaré 圆盘上有无穷多种 ${r, s}$ 可选；欧氏平面只有三种满足 $1/r + 1/s = 1/2$ 的铺砌。
      - *最小 ${4,5}$ 实现*：60 个物理比特；30 个 $Z$ 稳定子与 24 个 $X$ 稳定子，各含一个冗余。独立稳定子数 $29 + 23 = 52$，逻辑比特数 $k = 60 - 52 = 8$。
      - *拓扑与收益*：边界上的边配对后得到多手柄闭曲面；每个手柄携带两个逻辑比特，编码率高于环面码。
      - 该码*不是自对偶*的，即$Z$ 型与 $X$ 型稳定子数目不等，是几何方法处理不了的情形。
      // - 铺砌如何折成有限码、$n_Z = 29$ 与 $k = 8$ 是怎么数出来的，见 @app:hypergroup、@app:hyper。
    ],
    image-path: "img/fig6.png",
    source: "Fig. 6",
    img-height: 330pt,
    tone: "wash",
    fractions: (1.1fr, 1fr),
    figWidth: 90%
  )
  #speaker-note[#talk-notes.at(21)]
]

== 双曲码资源与三个例子

#slide[
  #page-2col(
    [$overline(H)_m$、$overline(S)_m$ 的资源与三个例子的汇总],
    [
      - 每个逻辑比特 $m$ 分别求解：门数随 $m$ 变化不大，化简后明显下降。
      - *对照*：一轮稳定子测量需 240 个 CNOT，本文门数与之同量级。
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
  #speaker-note[#talk-notes.at(22)]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 五、讨论与总结

= 余篇散入斜阳里 \ 且听满座起春风
#speaker-note[#talk-notes.at(23)]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录：SM（补充材料）详解

= 附录
#speaker-note[#talk-notes.at(24)]

// 沿用正文的 page-2cards / page-2col；字号交给 fit-card 自适应。
// 这里只 set 字体、不要再 set text(size)：否则会盖掉 fit-card 传入的 body-size，
// 卡片内容一变长就只能溢出，无法自动缩小。
#let app-body(body) = {
  set text(font: ("Libertinus Serif", "Noto Serif SC"))
  set par(leading: 0.45em, spacing: 0.36em)
  set list(spacing: 0.25em, tight: true)
  set enum(spacing: 0.25em, tight: true)
  body
}

// =====================================================================================
// 附录小节编号：字母对应正文的哪一块，数字是块内序号。
// 这样页眉与正文引用（@app:...）显示的是同一个记号，避免"正文写 6.2、标题写 B："的错位。
#let app-tags = (
  // "A",
  "A.1", "A.2",
  "B.1", "B.2", "B.3",
  "C.1", "C.2", "C.3", "C.4", "C.5",
  "D.1", "D.2", "D.3",
  "E.1", "E.2", "E.3", "E.4",
)
#let app-num(..nums) = {
  let n = nums.pos()
  let i = if n.len() > 1 { n.at(1) } else { 1 }
  app-tags.at(i - 1, default: str(i))
}
#set heading(numbering: app-num)

// // =====================================================================================
// // A · 导读：正文与附录的对应关系

// == 正文与附录的对应关系 <app:map>

// #slide[
//   #page-2cards(
//     [正文哪一节，对应附录哪一节],
//     [
//       #light-table(
//         (0.95fr, 0.46fr, 1.75fr),
//         ("正文", "附录", "这里补上正文省略掉的部分"),
//         (
//           ([§2.2 稳定子码与 CSS 码], [B.1], [$H_Z H_X^T = 0$ 的来历、逻辑 Pauli 配对与输入自检]),
//           ([§2.3 Clifford 与辛条件], [B.2], [保辛条件的分块展开与 $n(2 n - 1)$ 条约束]),
//           ([§3.1 三条约束], [C.1 C.2 C.3], [三条约束怎么合并；核空间参数化；特解 $B$ 与零常数块]),
//           ([§3.2 二次约束与线性化], [D.1 D.2], [四个提升矩阵；向量化与 $cal(A)$ 的规模]),
//           ([§3.2 线性化之后], [D.3 D.4 D.5], [七类核方向；稀疏特解与相容性；乘积匹配]),
//           ([§3.3–§3.5 门分解与辛消元], [E.1 E.2 E.3], [门的辛矩阵与相位；消元为何收尾；两比特演示]),
//           ([§4 结果], [F.1 F.2], [环面码 $d = 3$ 的输入、解、门序列与核验]),
//           ([§4 结果], [F.3 F.4], [双曲码的群、陪集计数与逻辑比特数]),
//         ),
//         size: 12pt,
//         inset: 4pt,
//       )
//     ],
//     [记号与阅读约定],
//     [#app-body[
//       - 全部运算在 $bb(F)_2$ 上。公式尽量沿用补充材料（SM）的原形，并标出 (S1)–(S58) 的编号，方便与原文件对照。
//       - *分块记号*：SM 把 $U$ 分成 $U_(Z Z), U_(Z X), U_(X Z), U_(X X)$ 四块（(S1)）；正文用 $A, B, C, D$ 表示同样四块，对应关系是 $A = U_(Z Z)$、$B = U_(Z X)$、$C = U_(X Z)$、$D = U_(X X)$。
//       - *上标*：$1$ 表示"自由变量部分"（(S3)(S4) 中的 $U^1$），$b$ 表示"特解"（Fig. S2 中的 $u^b$）。
//       - *讲述顺序*：SM 把算法 (S17)–(S29) 放在 §1、把证明放在 §2；本附录按正文的先后，把"怎么构造"和"为什么成立"合在一处讲，所以公式次序与 SM 不同，但每条都注明 SM 编号。
//     ]],
//     tone1: "wash",
//     tone2: "plain",
//     weights: (1.45fr, 1fr),
//     gap: 10pt,
//   )
// ]

// #speaker-note[#talk-notes.at(25)]

// =====================================================================================
// B · 对应正文 §2 预备知识（输入数据与保辛条件）

== CSS 码的输入数据与逻辑 Pauli 的配对 <app:css>

#slide[
  #page-2cards(
    [输入必须是一套合法数据],
    [#app-body[
      // 全部运算在 $bb(F)_2$ 上，Pauli 链写成行向量 $(z | x)$。
  $ H_Z in bb(F)_2^(n_Z times n), quad H_X in bb(F)_2^(n_X times n), quad k = n - n_Z - n_X. $
  $ H_Z H_X^T = 0, quad H_Z overline(X)^T = 0, quad H_X overline(Z)^T = 0, quad overline(Z) overline(X)^T = I_k. $ <eq:app-css>
  - $H_Z H_X^T = 0$ 的来历：一条纯 $Z$ 链 $(z | 0)$ 与一条纯 $X$ 链 $(0 | x)$ 的辛内积是 $z dot x$，正是二者*共同支撑的比特数*。于是"两条稳定子对易" $<=>$ "共同支撑为偶数" $<=>$ $H_Z H_X^T = 0$。
  - 中间两项约束逻辑算符与*另一类*稳定子的对易；最后一项要求同编号的 $overline(Z)_i$ 与 $overline(X)_i$ 反对易，不同编号的对易。
  - $H_Z$、$H_X$ 都取行满秩；逻辑行要在相应稳定子的商空间中线性独立。
    ]],
    [目标也遵循同一关系],
    [#app-body[
      @eq:目标映射 右端的四块 $overline(Z)^Z$、$overline(X)^Z$、$overline(Z)^X$、$overline(X)^X$ 是逻辑算符*像*的两个分量，所以它们自己也要满足 @eq:app-css 的辛配对。
  - 一个例子：$overline(Z)_m$ 的像写成 $(overline(Z)^Z_m | overline(Z)^X_m)$，它必须与纯 $X$ 稳定子 $(0 | H_X)$ 对易。辛内积只剩 $overline(Z)^Z_m H_X^T$，故
    $ overline(Z)^Z_m H_X^T = 0, quad "另外" quad H_Z H_X^T = 0. $
    这两条在 C.3 里用来证明提升方程的常数块为零。
  - *输入自检*：$n_Z + n_X + k = n$；$H_Z$、$H_X$ 各自行满秩；$overline(Z) overline(X)^T = I_k$。任一条不成立，后面方程的规格就已经错了。
    ]],
    tone1: "wash",
    tone2: "plain",
    // gap: 10pt,
  )
]

#speaker-note[#talk-notes.at(26)]

== 保辛条件的分块三组方程与约束计数 <app:symp>

#slide[
  #page-2cards(
    [$U Lambda U^T = Lambda$ 展开成可求解的形式],
    [#app-body[
      $ U = mat(A, B; C, D) = mat(U_(Z Z), U_(Z X); U_(X Z), U_(X X)), quad Lambda = mat(0, I_n; I_n, 0). $
  $ U Lambda U^T = mat(B A^T + A B^T, B C^T + A D^T; D A^T + C B^T, D C^T + C D^T). $ <eq:app-expand>
  令它等于 $Lambda$，就得到四个块方程：
  $ U_(Z X) U_(Z Z)^T + U_(Z Z) U_(Z X)^T = 0, quad U_(X X) U_(X Z)^T + U_(X Z) U_(X X)^T = 0, $ <eq:app-symp-blocks>
  $ U_(Z X) U_(X Z)^T + U_(Z Z) U_(X X)^T = I_n, quad U_(X X) U_(Z Z)^T + U_(X Z) U_(Z X)^T = I_n. $ <eq:app-s78>
  - $U Lambda U^T$ 左上块约束的是"$Z$ 型生成元的像之间"仍然对易，右下块对应 $X$ 型；交叉块规定两类像之间的辛配对。
  - @eq:app-s78 互为转置，所以只有三组独立条件。
    ]],
    [约束计数],
    [#app-body[
      - 前两组左端对称，且 $bb(F)_2$ 上对角元是 $a b + b a = 0$，各取 $j < i$ 的 $n(n-1)/2$ 个元素；第三组取全部 $n^2$ 个元素。总计
        $ n^2 + 2 dot n(n-1)/2 = n (2 n - 1). $ <eq:app-s10>
      - 这个数就是 D.2 里系数矩阵 $cal(A)$ 的*行数*：一条二次方程在提升之后变成一行线性方程。但它只是去掉对称重复后的条数，不是秩。在 @eq:码结构、@eq:目标映射 的线性条件下方程之间仍可能相关，实际秩要由 $cal(A)$ 算出来。
      - 只对 $U$ 的某一个分块做普通消元是不行的：四个块被这些对易关系牵连在一起，这正是 E.2 里消元顺序必须专门设计的原因。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
]

#speaker-note[#talk-notes.at(27)]
// =====================================================================================
// B · 对应正文 §3.1 三条约束与线性条件

== 三条约束如何"合并"成一个线性方程组 <app:merge>

#slide[
  #page-2cards(
    [第一步：把 $U$ 与两条约束都按块展开],
    [#app-body[
      把 $U$ 分成四个 $n times n$ 的块：
  $ U = mat(U_(Z Z), U_(Z X); U_(X Z), U_(X X)). $
  再把 @eq:码结构 逐块展开，得到四条：
  $ H_Z U_(Z Z) = H_Z, quad H_Z U_(Z X) = 0, quad H_X U_(X Z) = 0, quad H_X U_(X X) = H_X. $
  @eq:目标映射 也给出四条：
  $ overline(Z) U_(Z Z) = overline(Z)^Z, quad overline(Z) U_(Z X) = overline(X)^Z, quad overline(X) U_(X Z) = overline(Z)^X, quad overline(X) U_(X X) = overline(X)^X. $
    ]],
    [关键：受约束的是同一对未知块],
    [#app-body[
      #set list(spacing: 15pt)
      - 约束 $(U_(Z Z), U_(Z X))$ 的其实只有两种行：$H_Z$ 来自码结构，$overline(Z)$ 来自目标映射。
      - 约束 $(U_(X Z), U_(X X))$ 的同理：$H_X$ 来自码结构，$overline(X)$ 来自目标映射。
      - 两种行左乘的未知块*完全相同*，差的只是"行"。这就是可以合并的理由：*未知块相同、行不同，就可以把行叠起来*。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(28)]
]

#slide[
  #page-2cards(
    [第二步：合并——把行上下堆叠],
    [#app-body[
      把作用在同一对未知块上的行堆起来，得到两个新的系数矩阵，以及对应的常数列块：
      $ M_Z = mat(overline(Z); H_Z), quad M_X = mat(overline(X); H_X), $
      $ M_Z (U_(Z Z), U_(Z X)) = mat(overline(Z)^Z, overline(X)^Z; H_Z, 0) = (Q_(Z Z), Q_(Z X)), $ <eq:app-stack-z>
      $ M_X (U_(X Z), U_(X X)) = mat(overline(Z)^X, overline(X)^X; 0, H_X) = (Q_(X Z), Q_(X X)). $ <eq:app-stack-x>
      "合并"是*按未知块把线性条件的行上下堆叠*。$M_Z$ 管上半两块，$M_X$ 管下半两块，两个系统互不耦合。
    ]],
    [合并的效果],
    [#app-body[
      #set list(spacing: 15pt)
      - 同一半的两列（$U_(Z Z)$ 与 $U_(Z X)$）共享同一个系数矩阵 $M_Z$，所以共享同一组自由变量、只差右端——这正是 @app:vars 里"一个特解加核空间"的形式。两块也因此能*共用同一个右逆*来构造特解，见 @app:particular。
      - 三条约束用*同一*线性方程组表示，需代进 @eq:保辛条件 之后：@app:lift 得到展开式，@app:linear 把它整理成 $cal(A) u = B'$。
      - 也就是说，@eq:码结构 与 @eq:目标映射 是被"参数化吸收"进去的，而不是以额外的行出现。
    ]],
    tone1: "plain",
    tone2: "wash",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(29)]
]

== 核空间参数化：未知量从 $4 n^2$ 降到 $2 n (n - k)$ <app:vars>

#slide[
  #page-2cards(
    [先找允许的调整方向],
    [#app-body[
      把逻辑 $Z$ 与 $Z$ 型稳定子的行放在一起：
      $ M_Z = mat(overline(Z); H_Z). $
      指定的算符映射要求$M_Z U_(Z Z) = C_(Z Z)$。若 $B_(Z Z)$ 是一个特解，则
      $ M_Z (U_(Z Z) - B_(Z Z)) = 0. $
      因此，差矩阵的每一列都在 $ker M_Z$ 中。我们要找的，就是这些允许的调整方向。
    ]],
    [这些方向由稳定子给出],
    [#app-body[
      由 @app:css 中的对易关系，
      $ M_Z H_X^T
        = mat(overline(Z) H_X^T; H_Z H_X^T)
        = 0. $
      所以 $H_X^T$ 的列都在 $ker M_Z$ 中。

      在 $M_Z$ 行满秩的前提下，$dim ker M_Z = n - (k + n_Z) = n_X$。而 $H_X^T$ 恰有 $n_X$ 个独立列，因此
      $ "col"(H_X^T) = ker M_Z. $ <eq:app-kernel>

      同理，$"col"(H_Z^T) = ker M_X$，维数为 $n_Z$。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(30)]
]

#slide[
  #page-2cards(
    [用组合系数表示所有线性解],
    [#app-body[
      每个允许的调整列都是核基的线性组合。把各列的组合系数收集成矩阵，就得到
      $ U_(Z Z) = B_(Z Z) + H_X^T R, quad U_(Z X) = B_(Z X) + H_X^T S. $ <eq:app-param-z>
      同理，
      $ U_(X Z) = B_(X Z) + H_Z^T T, quad U_(X X) = B_(X X) + H_Z^T V. $ <eq:app-param-x>

      - $B$ 是固定的特解，构造见 @app:particular。
      - $R, S$ 的尺寸为 $n_X times n$；$T, V$ 的尺寸为 $n_Z times n$。
      - 补充材料记作
        $ R = U^1_(Z Z), quad S = U^1_(Z X), $
        $ T = U^1_(X Z), quad V = U^1_(X X). $
    ]],
    [减少未知量，再施加辛约束],
    [#app-body[
      原来四个 $n times n$ 块共有 $4 n^2$ 个未知量。现在只需确定四个系数矩阵，则未知量为：
      $ 2 n n_X + 2 n n_Z = 2 n (n - k). $

      *任意选择这些系数，都满足前述线性映射约束*，因为核空间调整不会改变映射结果。

      但要得到合法的 Clifford 变换，还必须满足辛条件
      $ U J U^T = J. $

      因此，下一步是在 $R, S, T, V$ 上求解辛约束；这里的参数数目并不是最终可任意选择的自由度。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(31)]
]

== 用主元构造特解 $B$，并消掉常数块 <app:particular>

#slide[
  #page-2cards(
    [对增广矩阵做行最简形消元],
    [#app-body[
      对增广矩阵作行最简形消元，同时保存可逆的行操作矩阵 $L_Z$：
  $ L_Z (M_Z, Q_(Z Z), Q_(Z X)) = (M'_Z, Q'_(Z Z), Q'_(Z X)). $ <eq:app-pivot>
      设 $M'_Z$ 第 $a$ 行的主元列是 $p_a$，取 $Gamma_Z$ 的第 $a$ 列为标准基向量 $e_(p_a)$，则
  $ M'_Z Gamma_Z = I_(k + n_Z), quad M_Z (Gamma_Z L_Z) = I_(k + n_Z). $ <eq:app-rightinv>
  $M'_Z$ 行满秩，所以每个主元列都存在；$Gamma_Z$ 相当于为行最简矩阵做了一个右逆。
    ]],
    [右逆把任意右端变成特解],
    [#app-body[
      记 $E_Z = Gamma_Z L_Z$，它就是 $M_Z$ 的一个右逆。直接取
  $ B_(Z Z) = Gamma_Z L_Z Q_(Z Z), quad B_(Z X) = Gamma_Z L_Z Q_(Z X); $
  $ B_(X Z) = Gamma_X L_X Q_(X Z), quad B_(X X) = Gamma_X L_X Q_(X X). $
      验证：
  $ M'_Z B_(Z Z) = (M'_Z Gamma_Z) (L_Z Q_(Z Z)) = Q'_(Z Z). $ <eq:app-b-verify>
  - 关键之处：$B_(Z Z)$ 与 $B_(Z X)$ *共用同一个右逆* $E_Z$；下面两块共用 $E_X$。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(32)]
]

#slide[
  #page-2cards(
    [共用右逆让常数块变成"夹心"形式],
    [#app-body[
      把右逆形式代进 $B_(Z X) B_(Z Z)^T + B_(Z Z) B_(Z X)^T$：
  $ B_(Z X) B_(Z Z)^T + B_(Z Z) B_(Z X)^T = E_Z (Q_(Z Z) Q_(Z X)^T + Q_(Z X) Q_(Z Z)^T) E_Z^T. $ <eq:app-const-block>
      因为两块共用 $E_Z$，括号里的表达式被整个"夹"在 $E_Z$ 与 $E_Z^T$ 之间。这就是共用右逆的用处：常数块的结构被完全暴露出来。
    ]],
    [括号里为什么是零],
    [#app-body[
      括号内第 $(m, m')$ 个元素形如
  $ overline(Z)^Z_m (overline(X)^Z_(m'))^T + overline(X)^Z_m (overline(Z)^Z_(m'))^T = 0. $ <eq:app-const-zero>
      它的意思是"目标逻辑 $Z$ 的像之间仍然两两对易"，由 @app:css 的辛配对保证（$U$ 不改变对易关系）。$X$ 半块同理，也等于零。

      于是提升方程的常数向量只有第三块非零：
  $ B' = (0; 0; B'_3). $ <eq:app-bprime>
      *提醒*：$B$ 依赖主元选择。换一组主元会换 $B$，也会改变 @app:sparse 里"稀疏特解是否相容"的结论。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(33)]
]

// =====================================================================================
// C · 对应正文 §3.2 二次约束与线性化

== 二次项提升：只有四种固定组合要变成新变量 <app:lift>

#slide[
  #page-2cards(
    [把参数化代进保辛条件之后],
    [#app-body[
      #set par(leading: 0.8em, spacing: 1em)
      把 $U_(Z Z) = H_X^T U^1_(Z Z) + B_(Z Z)$ 一类的表达式代进保辛条件的三组方程，展开后每一项属于三类之一：只含自由变量 $u$ 的、$u$ 与特解 $b$ 交叉的、只含 $b$ 的常数项。

      以第一组方程的一个矩阵元为例（$j < i$，求和范围从略）：
  $ 0 = sum_(eta, xi) (h^X_(eta i) h^X_(xi j) + h^X_(xi i) h^X_(eta j)) sum_zeta u^(Z X)_(eta zeta) u^(Z Z)_(xi zeta) + "（交叉项与常数项）". $
    ]],
    [关键观察],
    [#app-body[
      #set list(spacing: 15pt)
      - $h$ 与特解元素 $b$ 全是*已知常数*；$u$ 只以一种固定形式出现：对 $zeta$ 求和的内积 $sum_zeta u^(Z X)_(eta zeta) u^(Z Z)_(xi zeta)$，也就是矩阵乘积 $U^1_(Z X) (U^1_(Z Z))^T$ 的第 $(eta, xi)$ 个元素。
      - 所以二次性并不散布在 $U$ 的任意两个元素之积上，只集中在极少数几种组合里——这就是可以直接"提升"的依据。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(34)]
]

#slide[
  #page-2cards(
    [定义四个提升矩阵],
    [#app-body[
  $ tilde(u)^(Z X, Z Z)_(eta xi) equiv sum_zeta u^(Z X)_(eta zeta) u^(Z Z)_(xi zeta), quad tilde(u)^(X Z, X X)_(eta xi) equiv sum_zeta u^(X Z)_(eta zeta) u^(X X)_(xi zeta), $
  $ tilde(u)^(X Z, Z X)_(eta xi) equiv sum_zeta u^(X Z)_(eta zeta) u^(Z X)_(xi zeta), quad tilde(u)^(X X, Z Z)_(eta xi) equiv sum_zeta u^(X X)_(eta zeta) u^(Z Z)_(xi zeta). $ <eq:app-lift-def>
      范围：前两个 $1 <= eta, xi <= n_X$（或 $n_Z$），后两个 $1 <= eta <= n_Z$、$1 <= xi <= n_X$。
    ]],
    [写成矩阵：它们就是正文的四个 $F$],
    [#app-body[
  $ tilde(U)^(Z X, Z Z) = U^1_(Z X) (U^1_(Z Z))^T, quad tilde(U)^(X Z, X X) = U^1_(X Z) (U^1_(X X))^T, \ tilde(U)^(X Z, Z X) = U^1_(X Z) (U^1_(Z X))^T, quad tilde(U)^(X X, Z Z) = U^1_(X X) (U^1_(Z Z))^T. $
      - 提升变量共 $(n_Z + n_X)^2 = (n - k)^2$ 个，不到线性变量 $2 n (n-k)$ 的一半；两者合计 $(n-k)(3 n - k)$。
      - *这只是暂借*：把 $tilde(u)$ 当独立变量之后方程线性化了，但解完必须用上面的定义把它换回 $u$ 的乘积。未完成匹配之前得到的只是*放宽后*的解，不保证保辛——这一步在 @app:matching。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(35)]
]

== 向量化与系数矩阵 $cal(A)$ 的规模 <app:linear>

#slide[
  #page-2cards(
    [把八个块拉直成一个向量],
    [#app-body[
      每个矩阵按行转置后纵向拼接：$u_(Z Z) equiv "vec"_r (U^1_(Z Z))$，其余同理。八个部分对齐为
  $ u = (u_(Z Z); u_(Z X); u_(X Z); u_(X X); tilde(u)^(Z X, Z Z); tilde(u)^(X Z, X X); tilde(u)^(X Z, Z X); tilde(u)^(X X, Z Z)). $ <eq:app-vec>
      于是所有展开式整理成一张普通的线性方程组
  $ cal(A) u = B', quad B' = (0; 0; B'_3). $ <eq:app-au>
      常数向量的前两块为零，正是 @app:particular 证过的结论。
    ]],
    [系数矩阵的块结构],
    [#app-body[
  $ cal(A) = mat(A_(Z Z), A_(Z X), 0, 0, A^(Z X, Z Z), 0, 0, 0;
    0, 0, A_(X Z), A_(X X), 0, A^(X Z, X X), 0, 0;
    A'_ (Z Z), A'_ (Z X), A'_ (X Z), A'_ (X X), 0, 0, A^(X X, Z Z), A^(X X, Z Z)). $ <eq:app-Amat>
      - 三个方程块对应八个变量块，所以 $cal(A)$ 分成 $3 times 8$ 块，其中大量块直接为零，即高度稀疏。
      - 第三行最后两块*完全相同*，因为交叉方程里只出现 $tilde(U)^(X Z, Z X) + tilde(U)^(X X, Z Z)$ 这个和。@app:kernel 的第七类核方向与 @app:sparse 的稀疏特解都靠这一点。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(36)]
]

#slide[
  #page-2cards(
    [方程数与未知量数],
    [#app-body[
      #set list(spacing: 15pt)
      - 行数：去重后的二次约束条数 $n (2 n - 1)$（见 @app:symp）。
      - 列数：线性变量 $N_"linear" = 2 n (n - k)$，提升变量 $N_"lift" = (n - k)^2$，合计 $(n - k)(3 n - k)$。
      - 于是系数矩阵的形状是
        $ cal(A) in bb(F)_2^(n (2 n - 1) times (n - k)(3 n - k)). $
      - $k = 0$ 时，提升变量恰好是线性变量的一半。
    ]],
    [一个具体例子],
    [#app-body[
      #set list(spacing: 15pt)
      - $d = 7$ 环面码：$n = 2 d^2 = 98$、$k = 2$。$U$ 是 $196 times 196$（约 $3.8 times 10^4$ 个元素），$cal(A)$ 是 $19110 times 28032$。直接枚举 $2^38416$ 显然不可行。
      - *注意区分*：矩阵的边长按 $n^2$ 增长，*不*等于求解代价也是 $O(n^2)$。论文估计整体复杂度"略高于 $O(n^4)$"，实际开销还受消元中的填充与主元顺序影响。
      - 作对比：态矢量方法的表示空间是 $4^n$ 维。
    ]],
    tone1: "wash",
    tone2: "plain",
    // gap: 10pt,
    rsize: 0.45
  )
  #speaker-note[#talk-notes.at(37)]
]

== 提升矩阵的七类核方向 <app:kernel>

#slide[
  #page-2cards(
    [条带的正交补给出前四类],
    [#app-body[
      固定行指标 $eta$，$cal(A)$ 的第 $eta$ 条带的行由特解行 $b^(Z X)$、$b^(X X)$ 联合生成；由 @app:particular 的构造可以知道，这个集合的秩是 $n_X + k$。所以它的正交补维数是
  $ n - (n_X + k) = n_Z. $ <eq:app-orth>
      分别取 $w^Z_1, dots, w^Z_(n_Z)$ 与 $w^X_1, dots, w^X_(n_X)$ 为相应正交补的*行基*。
    ]],
    [四类基向量：每个基只有一行非零],
    [#app-body[
  $ u^((1)) : (u_(Z Z))^(p q)_(eta zeta) = delta_(eta p) (w^Z_q)_zeta, quad 1 <= eta, p <= n_X, 1 <= q <= n_Z, $
  $ u^((2)) : (u_(Z X))^(p q)_(eta zeta) = delta_(eta p) (w^X_q)_zeta, quad 1 <= eta, p, q <= n_X, $
  $ u^((3)) : (u_(X Z))^(p q)_(eta zeta) = delta_(eta p) (w^Z_q)_zeta, quad 1 <= eta, p, q <= n_Z, $
  $ u^((4)) : (u_(X X))^(p q)_(eta zeta) = delta_(eta p) (w^X_q)_zeta, quad 1 <= eta, p <= n_Z, 1 <= q <= n_X. $ <eq:app-kernel-1to4>
      矩阵语言：每个基在对应块里只有*一行*非零，那一行取 $w^Z$ 或 $w^X$ 中的一条；同一条行向量搬到该块的其他行即得另一个基。加进去后与所有相关系数条带的内积都是零，所以方程左端不变。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(38)]
]

#slide[
  #page-2cards(
    [第五、六类：只改提升矩阵的对称部分],
    [#app-body[
      #set list(spacing: 15pt)
      方程里只出现 $tilde(U) + tilde(U)^T$，所以这两类只改提升矩阵的*对称部分*：
  $ (tilde(u)^(Z X, Z Z))^(p p)_(eta xi) = delta_(eta p) delta_(xi p), quad (tilde(u)^(Z X, Z Z))^(p q)_(eta xi) = delta_(eta p) delta_(xi q) + delta_(eta q) delta_(xi p) quad (p < q), $
      第六类同型，换成 $tilde(U)^(X Z, X X)$，范围 $1 <= eta, xi, p, q <= n_Z$。
      - 对角的那一个*不能省略*：$bb(F)_2$ 上 $x + x = 0$，$tilde(U) + tilde(U)^T$ 对对角项完全不敏感。
    ]],
    [第七类],
    [#app-body[
      #set list(spacing: 15pt)
      第七类同步修改两个交叉提升块：
  $ Delta tilde(U)^(X Z, Z X) = Delta tilde(U)^(X X, Z Z) quad ==> quad H_Z^T (Delta tilde(U)^(X Z, Z X) + Delta tilde(U)^(X X, Z Z)) H_X = 0, $ <eq:app-kernel-7>
      因为系数矩阵第三行的最后两块系数相同，方程只看它们的和。
      - 直接计算可以验证这些向量确实在核里，例如 $A^(Z X, Z Z) (tilde(u)^(Z X, Z Z))^(p p) = h^X_(p i) h^X_(p j) + h^X_(p i) h^X_(p j) = 0$。
      - 七类是七种*构造模式*，不是七个向量。要断言它们张成整个 $ker cal(A)$，还必须算 $cal(A)$ 的秩；本附录不预设这一点。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(39)]
]

== 提升方程的稀疏特解 <app:sparse>

#slide[
  #page-2cards(
    [增广矩阵 $(cal(A), B')$ 的消元安排],
    [#app-body[
      SM 没有满足于"任取一个高斯消元解"，而是专门安排行与变量的顺序，让零块结构显出来：
  + 把第三块行（交叉方程）移到最前面。
  + 各块内部按条带独立消元，常数向量 $b$ 留在各条带里；第 5、6 列不动，第 7、8 列本来就相同，消元后仍然相同。
  + $A_(Z X)$ 的条带行来自 $B_(Z Z)$（含*逻辑 $Z$ 与 $Z$ 稳定子*），而 $A'_ (Z X)$ 的条带行来自 $B_(X Z)$（*只含逻辑 $Z$*）。所以可以用下面那组去消上面那组——这正是 @app:particular 里两块共用右逆 $E_Z$ 的用处。$A_(X Z)$、$A'_ (X Z)$ 同理。
  + 重排行，再对两个相同的交叉提升块消元，得到行最简形。
    ]],
    [特解的形状：只剩一条乘积关系要修],
    [#app-body[
      行最简形里有四个系数块连着*零常数项*，所以对应变量可以取零；两个相同的交叉提升块又说明 $tilde(U)^(X Z, Z X)$ 与 $tilde(U)^(X X, Z Z)$ 可任选一个为零（SM 取前者为零）。于是
  $ u^b_(Z X) = u^b_(X Z) = tilde(U)^(Z X, Z Z)_b = tilde(U)^(X Z, X X)_b = tilde(U)^(X Z, Z X)_b = 0, quad u^b_(Z Z), " " u^b_(X X), " " tilde(U)^(X X, Z Z)_b " 可能非零". $
      - 四条乘积定义因此前三条自动成立，只剩 $tilde(U)^(X X, Z Z)_b = U^(1 b)_(X X) (U^(1 b)_(Z Z))^T$ 需要检查。@app:matching 处理它。
      - $u^b_(Z X) = 0$ 说的是*自由变量* $U^1_(Z X) = 0$。原矩阵里 $U_(Z X) = H_X^T U^1_(Z X) + B_(Z X) = B_(Z X)$ 一般并不为零；$U_(X Z)$ 同理。
      - *相容性*：这个漂亮的零块形状依赖 $B$ 的选择与受限系统是否相容。实现对 $d = 3$ 环面码的 $I$、$H_1$、$S_1$、$"CNOT"_(12)$ 都相容，但也能构造出 $n_Z$、$n_X$ 同时非零而 $S = T = 0$ 不相容的例子；此时要重选右逆，或改用一般的提升解。零块形状不是无条件结论。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(40)]
]

== 乘积匹配与显式修正 <app:matching>

#slide[
  #page-2cards(
    [交叉约束给出的两个恒等式],
    [#app-body[
      由 @eq:码结构 的下半组（$H_X U_(X Z) = 0$、$H_X U_(X X) = H_X$）配合参数化表达式，
  $ H_X B_(X X) = H_X, quad H_X B_(X Z) = 0. $
      $B_(Z Z)$、$B_(X Z)$ 的行分别落在 $Q_(Z Z)$、$Q_(X Z)$ 的行空间中，而 $Q$ 的行是逻辑算符*像*的 $Z$ 分量，与纯 $X$ 链 $(0 | H_X)$ 对易（见 @app:css），所以
  $ B_(Z Z) H_X^T = B_(X Z) H_X^T = 0. $ <eq:app-Borth>
    ]],
    [左乘 $H_X$，只剩一个单位阵条件],
    [#app-body[
      把交叉方程 $U_(X X) U_(Z Z)^T + U_(X Z) U_(Z X)^T = I_n$ 在稀疏特解上左乘 $H_X$：含 $H_Z^T$ 的项被 $H_X H_Z^T = 0$ 消掉，其余常数项被 @eq:app-Borth 消掉，配上 $H_X B_(X X) = H_X$，只剩
  $ H_X = H_X (U^(1 b)_(Z Z))^T H_X. $ <eq:app-HXstep>
      $H_X$ 行满秩，两边右乘它的一个右逆再转置：
  $ U^(1 b)_(Z Z) H_X^T = I_(n_X). $
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(41)]
]

#slide[
  #page-2cards(
    [失配：最后一条乘积关系差多少],
    [#app-body[
      稀疏特解已经把前三条乘积关系做平，只剩 $tilde(U)^(X X, Z Z) = U^1_(X X) (U^1_(Z Z))^T$。把两边的差定义成失配：
  $ Delta U^(X X, Z Z) = U^(1 b)_(X X) (U^(1 b)_(Z Z))^T - tilde(U)^(X X, Z Z)_b. $ <eq:app-mismatch>
      修正的方向取第四类核方向，也就是只动 $U^1_(X X)$：
  $ Delta U^1_(X X) = C W^X, quad C in bb(F)_2^(n_Z times n_X). $
      要求 $Delta U^1_(X X) (U^(1 b)_(Z Z))^T = Delta U^(X X, Z Z)$，就得到关于 $C$ 的方程
  $ U^(1 b)_(Z Z) (W^X)^T C^T = (Delta U^(X X, Z Z))^T. $ <eq:app-solveC>
    ]],
    [读出修正量：一次就补平],
    [#app-body[
      取 $W^X = H_X$（$H_X$ 的 $n_X$ 行正是该核的一组行基），由 $U^(1 b)_(Z Z) H_X^T = I_(n_X)$ 立刻读出 $C = Delta U^(X X, Z Z)$，于是
  $ U^1_(X X) = U^(1 b)_(X X) + Delta U^(X X, Z Z) H_X. $ <eq:app-final>
      - 这个改动是一个核方向，所以线性方程仍然成立；$U^1_(Z X)$、$U^1_(X Z)$ 与三个提升块都没动，前三条乘积关系也不变。*到此*才真正得到满足 @eq:保辛条件 的解，而不只是放宽方程的解。
      - *存在性前提*：SM 假设 $n_Z >= n_X$，否则把失配转置后改用第一类核方向 $u^((1))$。也可先用 $u^((1))$ 把 $U^(1 b)_(Z Z)$ 调成行满秩，则上面的系数矩阵满秩、$C$ 必存在。
      - 最后把四个块代回参数化表达式，即得同时满足 @eq:码结构、@eq:目标映射 与 @eq:保辛条件 的 $U$，可以进入门分解。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(42)]
]

// =====================================================================================
// D · 对应正文 §3.3–§3.5 物理门分解与辛高斯消元

== 四种物理门的辛矩阵与相位 <app:gates>

#slide[
  #page-2cards(
    [单比特门的辛矩阵],
    [#app-body[
      行向量顺序固定为 $(Z_1, Z_2 | X_1, X_2)$。
  $ P_H = mat(0, 1; 1, 0), quad P_S = mat(1, 0; 1, 1). $ <eq:app-gates-single>
      - $H$ 交换 $Z$、$X$，所以矩阵是交换两行的形式。
      - $S$ 把 $X$ 送到 $Z X$，即 $Z$ 分量多出一份，所以矩阵是下三角的"加一"形式。
    ]],
    [两比特门的辛矩阵],
    [#app-body[
  $ P_("CNOT"_12) = mat(1, 0, 0, 0; 1, 1, 0, 0; 0, 0, 1, 1; 0, 0, 0, 1), quad P_("SWAP"_12) = mat(0, 1, 0, 0; 1, 0, 0, 0; 0, 0, 0, 1; 0, 0, 1, 0). $ <eq:app-gates-two>
      $n$ 个比特时，只把这些 $4 times 4$ 块放到 $2 n times 2 n$ 矩阵的对应行列，其余位置取单位阵。
      - 每一行都可以直接读出一条 Pauli 生成元的像，例如 $P_("CNOT"_12)$ 的第二行说明 $X_1 -> X_1 X_2$。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(43)]
]

== 左上块可逆之后的严格消元 <app:elimination>

#slide[
  #page-2cards(
    [保辛条件约束了剩余块],
    [#app-body[
      先用 CNOT/SWAP 的可逆列操作把左上块化成 $I_n$，记结果为
  $ U' = mat(I_n, B'; C', D'). $
      由 $U' Lambda U'^T = Lambda$ 与 $U'^T Lambda U' = Lambda$ 可得
  $ B' = (B')^T, quad C' = (C')^T, quad D' = I_n + C' B'. $ <eq:app-shear>
    ]],
    [精确分解成两张剪切矩阵],
    [#app-body[
      #set list(spacing: 15pt)
  $ U' = mat(I_n, 0; C', I_n) mat(I_n, B'; 0, I_n). $
      - 右乘 $mat(I_n, B'; 0, I_n)$，再右乘 $mat(I_n, 0; C', I_n)$，即得 $I_(2 n)$。
      - 所以"能否消干净"这个问题，被化成了"两张剪切矩阵能否消干净"。
    ]],
    tone1: "wash",
    tone2: "plain",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(45)]
]

#slide[
  #page-2cards(
    [剪切矩阵对应的门],
    [#app-body[
      #set list(spacing: 15pt)
      - 对称下三角剪切：对角项 $(i, i)$ 用 $S_i$ 清除。
      - 非对角项 $(i, j)$（$i > j$）与 $(j, i)$ 因对称性成对出现，用 $H_i "CNOT"_(j i) H_i$ *一次清掉两个*。
      - 上三角剪切不过是下三角剪切在全体 $H$ 共轭下的结果（$H$ 交换 $Z$、$X$ 两半）。
    ]],
    [奇异情形与逆序综合],
    [#app-body[
      #set list(spacing: 15pt)
      - 若初始左上块 $A$ 奇异，并不表示失败：先用 $H$ 换入成对列恢复主元，再进入这个可逆情形——这就是正文四步消元里的第二步。
      - *综合与读数*：每一步都是辛门，所以过程保辛；由 $U P_1 dots.c P_T = I_(2 n)$ 得 $U = P_T^(-1) dots.c P_1^(-1)$。
      - 最终线路按*逆序*使用物理逆门（Fig. 1 的时间轴指向左侧），$T$ 就是化简前的物理门数。
      - 两比特的完整例子（每一步都能手算）见 @app:toy；四种门的矩阵见 @app:gates。
    ]],
    tone1: "plain",
    tone2: "wash",
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(46)]
]

== 两比特辛消元的逐步演示 <app:toy>

#slide[
  #page-2col(
    [三次右乘把 $U_0$ 消到 $I_4$],
    [#app-body[
      $ U_0 = mat(0, 0, 1, 0; 0, 1, 1, 0; 1, 1, 0, 1; 0, 1, 0, 1). $
    $ U_0 = P_("CNOT"_12) P_(S_2) P_(H_1). $ <eq:app-toy>
    + 右乘 $P_(H_1)$：交换第 1、3 列。
    + 右乘 $P_(S_2)$：把第 4 列加到第 2 列。
    + 右乘 $P_("CNOT"_12)$：前后两半同步操作，得到 $I_4$。
    右侧动画每帧高亮当前操作的列，并逐步验证 $U_t Lambda U_t^T = Lambda$。这个 $4 times 4$ 例子可以逐项手算，用来复核 @app:gates 的列操作表与 @app:elimination 的逆序读数规则。
    ]],
    right: [
      #align(center + horizon)[#image(
        if sys.inputs.at("appendix-static", default: "false") == "true" { "img/appendix-elimination-poster.png" } else { "img/appendix-elimination.gif" },
        width: 100%, height: 330pt, fit: "contain")]
    ],
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[#talk-notes.at(47)]
]

// =====================================================================================
// E · 对应正文 §4 结果（具体计数）

== $d = 3$ 环面码的具体输入 <app:d3>

#slide[
  #page-2col(
    [周期格点的稳定子与逻辑支撑],
    [#app-body[
      #set list(spacing: 15pt)
      $ n = 18, quad n_Z = n_X = 8, quad k = 2. $
      两类各有 9 个稳定子，去掉一条整体依赖后剩 8 个独立生成元。例如
    $ S_Z = Z_(11) Z_(14) Z_(15) Z_(17), \
    S_X = X_8 X_(10) X_(11) X_(14). $
    四条逻辑行的支撑是
    $ overline(Z)_1 : {1, 7, 13}, quad overline(X)_1 : {1, 2, 3}, \ overline(Z)_2 : {4, 5, 6}, quad overline(X)_2 : {4, 10, 16}. $
    目标 $overline(H)_1 overline(I)_2$ 交换第一对逻辑行，固定第二对与全部选定稳定子。右图给出物理比特的编号，据此可以逐行写出 $H_Z$、$H_X$ 与四条逻辑行。
    - 验证：$H_Z H_X^T = 0$、$overline(Z) overline(X)^T = I_2$、$n_Z + n_X + k = n$。
    ]],
    right: [
      #align(center + horizon)[#image(
        if sys.inputs.at("appendix-static", default: "false") == "true" { "img/sm_s5_crop.png" } else { "img/sm_s5_crop.png" },
        width: 100%, height: 330pt, fit: "contain")]
    ],
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[#talk-notes.at(48)]
]

== 环面码的解、门序列与检验 <app:seq>

#slide[
  #page-2col(
    [两个交叉块恰好是逻辑行的外积],
    [#app-body[
      #set list(spacing: 15pt)
      SM 给出的一个解满足
    $ U_(Z Z) = U_(X X)^T, quad U_(Z X) = overline(X)_1^T overline(X)_1, quad U_(X Z) = overline(Z)_1^T overline(Z)_1 $
    - $overline(X)_1$、$overline(Z)_1$ 是长度 $n$ 的行向量，所以 $overline(X)_1^T overline(X)_1$ 是 $n times n$ 的秩一矩阵。这说明解与想交换的那对逻辑算符直接相关，不是随机搜出来的一张大表。
    - 逐项检验三类原始条件：
    $ U Lambda U^T = Lambda, quad H U = H, quad L U = L_"target". $ <eq:app-check>
    $H$ 是稳定子行，$L$ 是逻辑行。
    - 门数：75 个 CNOT、5 个 SWAP、1 个 $H$，共 81 个物理门；把 5 个 SWAP 各折合 3 个 CNOT 后是 90 个 CNOT。
    - 右侧动画从 $U$ 出发，按矩阵乘积的*逆序*逐门变换到 $I_(36)$。中间矩阵只需保辛，不要求每一步都固定原稳定子；只要求整个过程满足 @eq:app-check。
    ]],
    right: [
      #align(center + horizon)[#image(
        if sys.inputs.at("appendix-static", default: "false") == "true" { "img/appendix-toric-poster.png" } else { "img/appendix-toric.gif" },
        width: 100%, height: 330pt, fit: "contain")]
    ],
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[#talk-notes.at(49)]
]

// == 有限双曲码的商群与陪集 <app:hypergroup>

// #slide[
//   #page-2cards(
//     [从无限双曲铺砌得到有限商群],
//     [#app-body[
//       对正则 $\{r, s\}$ 铺砌，保向对称群是
//   $ G^+_(r,s) = chevron.l rho, sigma | rho^r = sigma^s = (rho sigma)^2 = e chevron.r, $
//       其中 $rho$、$sigma$ 分别是绕面中心与顶点的旋转。$1/r + 1/s < 1/2$ 时铺砌落在双曲平面上，这个群是无限的。
//       取一个无挠、正规、有限指数的子群 $H_(r,s)$，商群
//   $ G = G^+_(r,s) / H_(r,s), quad abs(G) = [G^+_(r,s) : H_(r,s)] < infinity $ <eq:app-finite-quotient>
//       才可能给出有限的双曲格点。实现上用 Todd–Coxeter 算法配合 GAP 求出。
//     ]],
//     [陪集的轨道数给出几何对象的数量],
//     [#app-body[
//       取定一个三角形 $x$，$G$ 的元素把它送到不同位置。面旋转子群 $G_(rho) = {e, rho, dots, rho^(r-1)}$ 的轨道是一个 $r$-边形，每个陪集对应一个 $Z$ 稳定子；同理 $G_(sigma)$ 给出顶点与 $X$ 稳定子；而 $G_(rho sigma) = {e, rho sigma}$ 直接给出一条边，也就是一个物理比特。由轨道–稳定子关系
//   $ F = abs(G) / r, quad V = abs(G) / s, quad E = abs(G) / 2 = n. $ <eq:app-cosets>
//       - $F$、$V$、$E$ 分别是面、顶点、边的数目，也就是 $Z$ 稳定子、$X$ 稳定子与物理比特的*候选*数目。
//       - *无挠*排除旋转造成的锥点；*有限指数*才保证商群有限；正规性让商群结构清楚。此外还要确认商出来的曲面连通、闭合且可定向。
//     ]],
//     tone1: "wash",
//     tone2: "plain",
//     gap: 10pt,
//   )
//   #speaker-note[#talk-notes.at(50)]
// ]

// == 关联矩阵的秩与逻辑比特数 <app:hyper>

// #slide[
//   #page-2cards(
//     [链复形保证两类稳定子对易],
//     [#app-body[
//       用顶点–边关联矩阵定义 $H_X$，用面边界矩阵定义 $H_Z$。每个面的边界在任一顶点都有偶数条入射边，所以
//   $ H_Z H_X^T = 0. $ <eq:app-boundary>
//       对闭合、连通、可定向的曲面：所有面边界之和为零（每条边恰好出现两次），所有顶点星之和也为零；这两组关系各只有*一条*独立依赖。于是
//   $ n_Z = F - 1, quad n_X = V - 1, quad k = n - n_Z - n_X = E - F - V + 2 = 2 g. $ <eq:app-euler>
//       $g$ 是亏格（手柄数）。$k = 2 g$ 就是正文"每个手柄带两个逻辑比特"的出处。
//     ]],
//     [由群的阶得到码参数],
//     [#app-body[
//       联立 @eq:app-cosets 与 @eq:app-euler，并代入 $n = E = abs(G) / 2$：
//   $ k = abs(G) (1/2 - 1/r - 1/s) + 2 = n (1 - 2/r - 2/s) + 2. $
//       例如 $\{4, 5\}$ 且 $abs(G) = 120$ 时，$(F, V, E) = (30, 24, 60)$，于是 $n_Z = 29$、$n_X = 23$、$k = 60 - 29 - 23 = 8$；Euler 示性数 $F - E + V = -6$，亏格 $g = 4$。
//       - 这个计数以 @eq:app-finite-quotient 构造出的商确实给出上述曲面为前提。群的阶只决定对象的*数量*，并不能单独证明码距或逻辑门的局域性。
//       - 也正因为 $n_Z != n_X$，$\{4, 5\}$ 码不是自对偶的；正文用它说明方法不依赖"两类稳定子数目相等"这一几何便利。
//     ]],
//     tone1: "wash",
//     tone2: "plain",
//     gap: 10pt,
//   )
//   #speaker-note[#talk-notes.at(51)]
// ]
