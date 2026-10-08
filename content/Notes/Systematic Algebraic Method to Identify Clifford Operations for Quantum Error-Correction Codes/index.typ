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

// 每页讲稿及问答由 speak/notes.typ 统一维护，不进入观众视图。
#import "speak/notes.typ": entries
#import "speak/questions.typ": extra-questions
#let talk-notes = range(entries.len()).map(i => {
  let entry = entries.at(i)
  let first-question = entry.body + "\n\n可能提问：" + entry.question + "\n参考回答：" + entry.answer
  first-question + extra-questions.at(i).map(qa => "\n\n可能提问：" + qa.question + "\n参考回答：" + qa.answer).join("")
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
    - 保辛条件：对任意 $A, B$，$A Lambda B^T = (A U) Lambda (B U)^T = A (U Lambda U^T) B^T$，因此
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
    + *码结构（@eq:码结构）*：
      $ mat(H_Z, 0; 0, H_X) U = mat(H_Z, 0; 0, H_X). $ <eq:码结构>
      论文为求解方便*直接要求每个稳定子生成元在变换之后回到自身*。更一般的情形允许稳定子置换/重组，但会引入组合问题。
    + *目标映射（@eq:目标映射）*：
      $ mat(overline(Z), 0; 0, overline(X)) U = mat(overline(Z)^Z, overline(X)^Z; overline(Z)^X, overline(X)^X). $ <eq:目标映射>
      $overline(Z)$、$overline(X)$ 各是 $k times n$；右端四块表示像的 $Z$/$X$ 部分，可由 $overline(Z)$、$overline(X)$ 的行线性表示。
  ],
    [两个例子的目标映射],
    [
    - $overline(H)_1 overline(I)_2$：$overline(Z)_1 -> overline(X)_1$、$overline(X)_1 -> overline(Z)_1$，其余不变#highlight[（式 (7)）]。
    - $overline(S)_1 overline(I)_2$：$overline(X)_1 -> overline(Z)_1 overline(X)_1$，其余不变#highlight[（式 (8)）]。
    - 于是"设计线路"变成"求满足 @eq:保辛条件 @eq:码结构 @eq:目标映射 的 $U$"，解出后分解成物理门。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(10)]
]

== 二次约束与线性化

#slide[
  #page-2cards(
    [难点在 @eq:保辛条件：它是二次的],
    [
    - 把 $U$ 的元素记作 $U_(i j)$， @eq:保辛条件 的每个矩阵元都是"两个元素相乘再求和"：
      #align(center)[$ (U Lambda U^T)_(i j) = sum_(k = 1)^n U_(i, k+n) U_(j k) + sum_(k = n+1)^(2 n) U_(i, k-n) U_(j k). $]
      因此 @eq:保辛条件 给出 $O(n^2)$ 个*二次*方程（分块展开见 @app:symp），而 @eq:码结构，@eq:目标映射 都是线性的。
    - *线性化*：对出现在这些二次方程中的每一对元素引入新变量 $v_(a b c d) = U_(a b) U_(c d)$；代入后 @eq:保辛条件 变成关于 $(U, v)$ 的线性方程，再与 @eq:码结构，@eq:目标映射 合并。
    - *规模*：论文指出线性方程组的行数（方程数）与列数（未知量数）都在 $O(n^2)$ 量级且*高度稀疏* —— 每个方程只涉及少数几个变量。
  ],
    [复杂度与一致性回代],
    [
    - *复杂度*：稀疏消元的总代价"略高于 $O(n^4)$"，不是指数级；对比态矢量方法的 $4^n$ 维空间。量级估计见 @app:linear。
    - *一致性回代*：$v$ 是形式变量，必须满足 $v_(a b c d) = U_(a b) U_(c d)$；论文在解空间里做"二次变量与 $U$ 元素的匹配"，并指出这一步开销很小。
    - *规模示例*：$d = 7$ 环面码 $n = 2 d^2 = 98$，$U$ 是 $196 times 196$，元素约 $3.8 times 10^4$ 个 —— 而直接枚举 $2^38416$ 不可行。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(11)]
]

== 物理门分解

#slide[
  #page-2cards(
    [门的种类与它们对 $U$ 的作用],
    [
    #light-table(
      (0.3fr, 0.8fr, 1.3fr),
      ("门", "对 Pauli 链的作用（物理效果）", "对 $U$ 的列操作（右乘初等矩阵）"),
      (
        ([$H_i$], [$Z_i <-> X_i$], [交换第 $i$ 列与第 $(i+n)$ 列]),
        ([$S_i$], [$X_i -> Z_i X_i$（相差相位）], [把第 $(i+n)$ 列加到第 $i$ 列]),
        ([$"CNOT"_(i j)$], [$X_i -> X_i X_j$、$Z_j -> Z_i Z_j$], [第 $j$ 列加到第 $i$ 列；第 $(i+n)$ 列加到第 $(j+n)$ 列]),
        ([$"SWAP"_(i j)$], [$Z_i <-> Z_j$、$X_i <-> X_j$], [交换第 $i$、$j$ 列；交换第 $(i+n)$、$(j+n)$ 列]),
      ),
      size: 16pt
    )
  ],
    [只允许这四类辛操作，把 $U$ 化为 $I_(2 n)$],
    [
    - 这四类初等矩阵*不构成*全部初等操作，但都是*辛*的，即每步保持 @eq:保辛条件 ：$U Lambda U^T = Lambda$，所以高斯消元时顺序必须专门设计。
    - 记初等矩阵为 $P_k$：$U P_1 dots.c P_T = I_(2 n)$ ⟹ $U = P_T dots.c P_1$，门序列按*逆序*读出，$T$ 是化简前的物理门数。
    - $n = 2$ 的显式 $4 times 4$ 矩阵见 @app:gates，可以直接核对上表的列操作。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[#talk-notes.at(12)]
]

== 辛高斯消元

#slide[
  #page-2cards(
    [$U --> I_(2 n)$ 四步消元],
    [
      + *双比特门*：只看 $U$ 左侧 $2 n times n$ 部分，用 CNOT/SWAP 操作把它化为列阶梯形；右侧 $n$ 列会被同步作用。
      + *$H$ 门换列*：若左上还没出现 $I_n$，说明右半存在带零元的列（$U$ 满秩，不会出现全零列），因此用 $H$ 把右半的列换进来再重复*第一步*。通常此时左上、右下两个块都已是 $I_n$。
      + *消左下*：单个元素 $(i+n, i)$ 用 $S_i$ 消去；成对元素 $(i+n, j)$ 与 $(j+n, i)$（$i < j$）用 $H_i "CNOT"_(j i) H_i$ 一起消掉。
      + *消右上*：右上角若还有非零元，再继续使用 $H$ 门处理，最终 $U -> I_(2 n)$，分解结束。
    ],
    [边界情形与读数规则],
    [
      - 只剩左下非零、只剩右上非零等边界情形，论文逐类给出了消除手法；完整证明在 SM 中。
      - *为什么可以这样消*：这四类初等矩阵不构成全部初等操作，但都是辛的，每步都保持 $U Lambda U^T = Lambda$，所以消元顺序必须专门设计。
      - *门序列怎么读*：由 $U P_1 dots.c P_T = I_(2 n)$ 得 $U = P_T dots.c P_1$，最终线路要把消元过程*逆序*读出（Fig. 1 的时间轴指向左侧）；$T$ 就是化简前的物理门数。
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
      - *方程规模*：$d = 3, 5, 7, 9, 11$ 对应 $U$ 的维数 $36, 100, 196, 324, 484$。
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
      - *做法*：直接按 @sec:三条约束 @eq:目标映射 写出整个 $(overline(S)_1 overline(H)_1) overline(I)_2$ 的目标，只需要解*一条*物理门序列，而不是"先解 $overline(S)$、再解 $overline(H)$"两条串联。
      - *收益*：一步实现比两步方案少约三分之一的门数，而且只比两步方案中 $overline(S)$ 的那一步略多。
      - *用途*：Fig. 5(a) 的线路可制备相位偏移 Bell 态 $(ket(00)_L + i ket(11)_L)/sqrt(2)$，用于检验纠缠的基本不等式。
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

// 沿用正文的 page-2cards / page-2col，字号与样式仅在卡片正文中设置。
#let app-body(body, size: 18.5pt) = {
  set text(font: ("Libertinus Serif", "Noto Serif SC"), size: size)
  set par(leading: 0.36em, spacing: 0.36em)
  set list(spacing: 0.25em, tight: true)
  set enum(spacing: 0.25em, tight: true)
  body
}

== A：CSS 输入与逻辑 Pauli 的配对 <app:css>

#slide[
  #page-2cards(
    [行向量约定与独立生成元],
    [#app-body[
      全部矩阵运算在 $bb(F)_2$ 上进行。把 $n$ 比特 Pauli 算符记为行向量 $(z | x)$。以下给出一些基本关系和约束：
  $ H_Z in bb(F)_2^(n_Z times n), quad H_X in bb(F)_2^(n_X times n), quad
    k = n - n_Z - n_X. $
  $ H_Z H_X^T = 0, quad H_Z overline(X)^T = 0, quad
    H_X overline(Z)^T = 0, quad overline(Z) overline(X)^T = I_k. $ <eq:app-css>
  @eq:app-css 的前三项分别约束稳定子之间、及逻辑算符与稳定子之间的对易关系；最后一项给出 $k$ 对反对易的逻辑算符。$H_Z,H_X$ 均取行满秩，逻辑行须在相应稳定子的商空间中独立。
    ]],
    [目标必须保持这套对易关系],
    [#app-body[
      将目标逻辑算符与保持不变的稳定子行堆叠为矩阵 $Q$。所求物理作用 $U$ 必须满足 @eq:码结构 和 @eq:目标映射；这两组等式线性地限制 $U$ 的四个块。

  目标算符还必须保留 @eq:app-css 的辛配对，否则线性方程即使可解，也不可能对应 Clifford 操作。算法先解线性条件，再施加保辛条件。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(25)]
]

== B：保辛条件的三组方程 <app:symp>

#slide[
  #page-2cards(
    [把 $U Lambda U^T = Lambda$ 展开到可求解的形式],
    [#app-body[
      $ U = mat(A, B; C, D), quad Lambda = mat(0, I_n; I_n, 0). $
  $ U Lambda U^T = mat(B A^T + A B^T, B C^T + A D^T;
    D A^T + C B^T, D C^T + C D^T). $ <eq:app-expand>
  左上块约束 $Z$ 型生成元像之间的对易，右下块对应 $X$ 型生成元像；交叉块规定两类像的配对。
    ]],
    [三个方程块与约束计数],
    [#app-body[
      两个交叉块互为转置，故只保留下列三组条件：
  $ B A^T + A B^T = 0, quad D C^T + C D^T = 0, quad
    D A^T + C B^T = I_n. $ <eq:app-symp-blocks>
  - 前两式的左端对称，且对角元为 $a b + b a = 0$，各取 $j<i$ 的 $n(n-1)/2$ 个元素。
  - 第三式取全部 $n^2$ 个元素，总计 $n(2n-1)$ 条二次方程。
  - 这只是去掉对称重复项后的条数。在线性码条件限制下，方程之间仍可能相关。后续对 @eq:app-symp-blocks 作变量代换和提升。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(26)]
]

== C：线性条件与自由变量的削减 <sm:vars>

#slide[
  #page-2cards(
    [每个半块的 $2n$ 列共享同一个核空间],
    [#app-body[
      $ M_Z = mat(overline(Z); H_Z), quad M_X = mat(overline(X); H_X). $
  令 $Q_(Z Z),Q_(Z X),Q_(X Z),Q_(X X)$ 为目标像与固定稳定子的堆叠：
  $ M_Z (U_(Z Z), U_(Z X)) = (Q_(Z Z), Q_(Z X)), quad
    M_X (U_(X Z), U_(X X)) = (Q_(X Z), Q_(X X)). $
    ]],
    [用核空间参数化所有线性解],
    [#app-body[
      因 $M_Z H_X^T=0$，且 $dim ker M_Z=n-(k+n_Z)=n_X$，
  $ ker M_Z = "col"(H_X^T), quad ker M_X = "col"(H_Z^T). $
  记四个自由变量块为 $R,S,T,V$：
  $ U_(Z Z)=H_X^T R+B_(Z Z), quad U_(Z X)=H_X^T S+B_(Z X), $
  $ U_(X Z)=H_Z^T T+B_(X Z), quad U_(X X)=H_Z^T V+B_(X X). $
  $R,S$ 为 $n_X times n$，$T,V$ 为 $n_Z times n$，自由变量从 $4n^2$ 降到 $2n(n-k)$。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(27)]
]

== D：通过主元构造特解 $B$ <sm:particular>

#slide[
  #page-2cards(
    [右逆把任意常数列变成一组特解],
    [#app-body[
      对增广矩阵做行最简形消元，并保存可逆的行操作矩阵 $L_Z$：
  $ L_Z (M_Z, Q_(Z Z), Q_(Z X)) = (M'_Z, Q'_(Z Z), Q'_(Z X)). $
  设 $M'_Z$ 第 $a$ 行的主元列为 $p_a$。取 $Gamma_Z$ 第 $a$ 列为标准基向量 $e_(p_a)$，则
  $ M'_Z Gamma_Z = I_(k+n_Z), quad M_Z (Gamma_Z L_Z)=I_(k+n_Z). $
  因此可直接取
  $ B_(Z Z)=Gamma_Z L_Z Q_(Z Z), quad
    B_(Z X)=Gamma_Z L_Z Q_(Z X). $
    ]],
    [特解的自对易常数项为何消失],
    [#app-body[
      令 $E_Z=Gamma_Z L_Z$，则 $M_Z E_Z=I$，从而 $M_Z B_(Z Z)=Q_(Z Z)$；其余三块同理。两块共用一个右逆，这是下一步消去常数项的关键。

  $ B_(Z X)B_(Z Z)^T+B_(Z Z)B_(Z X)^T $
  $ =E_Z (Q_(Z X)Q_(Z Z)^T+Q_(Z Z)Q_(Z X)^T) E_Z^T=0. $ <eq:app-zero-constant>
  括号内每项是两条目标 $Z$ 型生成元像的辛配对。它们由原先互相对易的生成元得到，故和为零。$X$ 半块同理。因此提升方程的前两个常数块为零。

  主元选择改变 $B$，也会改变后续稀疏解的相容性，不能把一次选择推广为任意右逆。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(28)]
]

== E：二次项提升与一条完整的展开式 <sm:lift>

#slide[
  #page-2cards(
    [引入的是四个内积矩阵，而非所有逐元素乘积],
    [#app-body[
      $ F_1=S R^T, quad F_2=T V^T, quad F_3=T S^T, quad F_4=V R^T. $
  其形状依次为 $n_X times n_X$、$n_Z times n_Z$、$n_Z times n_X$、$n_Z times n_X$。
  例如 $U_(Z X) U_(Z Z)^T+U_(Z Z) U_(Z X)^T=0$ 展开成
  $ 0 = H_X^T (F_1+F_1^T) H_X + K_Z + K_Z^T
    + B_(Z X) B_(Z Z)^T + B_(Z Z) B_(Z X)^T, $
  $ K_Z = H_X^T R B_(Z X)^T + H_X^T S B_(Z Z)^T. $
    ]],
    [提升后的线性方程与恢复条件],
    [#app-body[
      - 当 $F_1$ 先作为独立变量时，以上每一项都对 $(R,S,F_1)$ 线性。
  - 第二组方程使用 $F_2+F_2^T$。交叉方程中的二次部分为 $H_Z^T (F_3+F_4)H_X$。
  - 提升扩大了解空间。解出后必须恢复四条 $F_i$ 的乘积关系，才得到原方程的解。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(29)]
]

== F：向量化与系数矩阵的规模 <app:linear>

#slide[
  #page-2cards(
    [按行展开八个块，统一解 $cal(A)u=b$],
    [#app-body[
      $ "vec"_r(R)=(r_(1 1),dots,r_(1 n),r_(2 1),dots)^T, $
  $ u=("vec"_r(R);"vec"_r(S);"vec"_r(T);"vec"_r(V);
    "vec"_r(F_1);"vec"_r(F_2);"vec"_r(F_3);"vec"_r(F_4)). $
    ]],
    [系数矩阵的结构与变量计数],
    [#app-body[
      #text(size: 17pt)[
    $ cal(A)=mat(A_R,A_S,0,0,A_1,0,0,0;
      0,0,A_T,A_V,0,A_2,0,0;
      A'_R,A'_S,A'_T,A'_V,0,0,A_3,A_3). $
  ]
  第三行的最后两块相同，因为交叉方程只含 $F_3+F_4$。
  $ N_"linear"=2n(n-k), quad N_"lift"=(n-k)^2, $
  $ cal(A) in bb(F)_2^(n(2n-1) times (n-k)(3n-k)). $
  $d=7$ 环面码：$n=98,k=2$，得到 $19110 times 28032$ 的系数矩阵。
  当 $k=0$ 时提升变量恰为线性变量的一半。矩阵规模为 $O(n^2)$，不等于消元成本为 $O(n^2)$。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(30)]
]

== G：提升矩阵的七类核方向 <sm:proof>

#slide[
  #page-2cards(
    [前四类：从线性块的正交补构造],
    [#app-body[
      固定 $R$ 的行号 $eta$ 后，第一组方程中 $R_(eta zeta)$ 的系数为
  $ h^X_(eta i)b^(Z X)_(j zeta)+h^X_(eta j)b^(Z X)_(i zeta). $
  交叉方程的对应系数为 $h^X_(eta j)b^(X X)_(i zeta)$。因此这一条带的行落在 $B_(Z X)$、$B_(X X)$ 的联合行空间中。其正交补维数为 $n_Z$；交换两类生成元可得到另一个正交补。

  $ Delta R=C_1W^Z, quad Delta S=C_2W^X, quad Delta T=C_3W^Z, quad Delta V=C_4W^X. $ <eq:app-linear-kernel>
  $W^Z,W^X$ 分别取对应正交补的行基。对 @eq:app-linear-kernel 每一行与系数条带取内积，均为零。
    ]],
    [后三类：利用特征二的对称性],
    [#app-body[
      第五、六类分别修改 $F_1,F_2$ 的对称部分，因为 $F_i+F_i^T=0$。其基包含对角矩阵 $E_(p p)$ 与 $E_(p q)+E_(q p)$（$p<q$）；前者不可省略。

  第七类同步修改两个交叉提升块：
  $ Delta F_3=Delta F_4=E_(p q) quad => quad H_Z^T(Delta F_3+Delta F_4)H_X=0. $ <eq:app-cross-kernel>
  这些是后续匹配乘积所用的核方向。它们按支撑分为七类；要判定是否张成整个核，还须计算 $cal(A)$ 的秩。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(31)]
]

== H：提升方程的稀疏特解 <sm:sparse>

#slide[
  #page-2cards(
    [消元安排与零块选择],
    [#app-body[
      对增广矩阵 $(cal(A),b)$ 作相容的主元选择与行消元：
  + 将交叉方程移到前面。前四列按条带消元，两个相同的交叉提升块保持相同。
  + 利用包含“逻辑算符与稳定子”的条带，消去只含逻辑算符的对应行。
  + 重排行并完成交叉提升块的消元。与零常数块相连的变量可取零。
  由此选取的特解形状为
  $ S^b=T^b=F_1^b=F_2^b=F_3^b=0, quad
    R^b,V^b,F_4^b " 可能非零". $
    ]],
    [四条乘积关系中只剩一条需要修正],
    [#app-body[
      $ F_1=S R^T=0, quad F_2=T V^T=0, quad F_3=T S^T=0. $
  剩余要求是 $F_4^b=V^b (R^b)^T$。置零的是自由变量 $S,T$，原矩阵中的 $U_(Z X)=B_(Z X)$、$U_(X Z)=B_(X Z)$ 仍可能非零。
  置零依赖特解 $B$ 的选择，需检验受限系统的相容性，不能把任意 $B$ 直接套入该形状。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(32)]
]

== I：乘积匹配与显式修正 <sm:matching>

#slide[
  #page-2cards(
    [交叉约束给出修正所需的满秩性],
    [#app-body[
      固定 $X$ 稳定子给出 $H_X B_(X X)=H_X$、$H_X B_(X Z)=0$。此外，$B_(Z Z)$、$B_(X Z)$ 的行属于逻辑 $Z$ 与 $Z$ 稳定子的张成空间，所以
  $ B_(Z Z)H_X^T=B_(X Z)H_X^T=0. $ <eq:app-B-orthogonal>
  把稀疏提升解的交叉方程左乘 $H_X$；含 $H_Z^T$ 的项由 $H_X H_Z^T=0$ 消去，其余常数项由 @eq:app-B-orthogonal 消去，留下
  $ H_X=H_X (R^b)^T H_X. $ <eq:app-rank-step>
  $H_X$ 行满秩。右乘其右逆并转置 @eq:app-rank-step，得到 $R^b H_X^T=I_(n_X)$。
    ]],
    [沿核方向修正唯一未满足的乘积关系],
    [#app-body[
      定义失配 $Delta=V^b (R^b)^T+F_4^b$。第四类核方向允许 $Delta V=C W^X$，且可取 $W^X=H_X$。由上一卡的恒等式，
  $ V=V^b+Delta H_X, quad V(R^b)^T=F_4^b. $ <eq:app-match>
  这里 $Delta H_X(R^b)^T=Delta$，故 @eq:app-match 直接成立；修改仍在 $cal(A)$ 的核中，前三条乘积关系也不变。

  这一修正以存在稀疏提升解为前提。若选取的 $B$ 使受限系统无解，就须重新选右逆或使用一般的提升解。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(33)]
]

== J：物理门的辛矩阵与相位 <app:gates>

#slide[
  #page-2cards(
    [行向量顺序固定为 $(Z_1,Z_2 | X_1,X_2)$],
    [#app-body[
      $ P_H=mat(0,1;1,0), quad P_S=mat(1,0;1,1), $
  $ P_("CNOT"_12)=mat(1,0,0,0;1,1,0,0;0,0,1,1;0,0,0,1), quad
    P_("SWAP"_12)=mat(0,1,0,0;1,0,0,0;0,0,0,1;0,0,1,0). $
  - $H_i$：交换第 $i$、$i+n$ 列。$S_i$：第 $i+n$ 列加到第 $i$ 列。
  - $"CNOT"_(i j)$：第 $j$ 列加到第 $i$ 列，同时第 $i+n$ 列加到第 $j+n$ 列。
  - $"SWAP"_(i j)$：同步交换两半中的 $i,j$ 列。各门均满足 $P Lambda P^T=Lambda$。
    ]],
    [二进制逆矩阵与物理逆门须分开],
    [#app-body[
      这里 $P_S^2=I$，但物理 $S^(-1)=S^dagger$，且 $S^2=Z$。综合后须跟踪 Pauli 符号，用 Pauli 修正匹配所需符号，才能保证稳定子的 $+1$ 码空间。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(34)]
]

== K：可逆对角块后的严格消元 <sm:elimination>

#slide[
  #page-2cards(
    [补充推导：当左上块可逆，剩余步骤由辛条件确定],
    [#app-body[
      对 $U=mat(A,B;C,D)$，先用 CNOT/SWAP 的可逆列操作将 $A$ 化为 $I$。设所得矩阵为 $U'=mat(I,B';C',D')$。
  由行、列两种保辛恒等式可得
  $ B'=(B')^T, quad C'=(C')^T, quad D'=I+C'B'. $
  因而有精确分解
  $ U'=mat(I,0;C',I)mat(I,B';0,I). $
    ]],
    [剪切矩阵对应的门与逆序综合],
    [#app-body[
      右乘 $mat(I,B';0,I)$ 后，再右乘 $mat(I,0;C',I)$ 即得 $I_(2n)$。
  - 对称下三角剪切的对角项用 $S_i$ 清除，非对角项 $(i,j)$ 用 $H_i "CNOT"_(j i)H_i$ 同时清除。
  - 上三角剪切由全体 $H$ 共轭下三角剪切得到。若初始 $A$ 奇异，先通过 $H$ 换入成对列以恢复主元，再进入此分解。
  逐步保辛。由 $U P_1 dots.c P_T=I$ 得 $U=P_T^(-1) dots.c P_1^(-1)$，使用逆序的物理逆门。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(35)]
]

== L：两比特辛消元的逐步演示 <sm:toy>

#slide[
  #page-2col(
    [三次右乘把 $U_0$ 消到 $I_4$],
    [#app-body[
      $ U_0=mat(0,0,1,0;0,1,1,0;1,1,0,1;0,1,0,1). $
    $ U_0=P_("CNOT"_12)P_(S_2)P_(H_1). $
    + 右乘 $P_(H_1)$，交换第 1、3 列。
    + 右乘 $P_(S_2)$，第 4 列加到第 2 列。
    + 右乘 $P_("CNOT"_12)$，同步操作两半，得到 $I_4$。
    右图高亮当前操作的列，每帧验证 $U_t Lambda U_t^T=Lambda$。
    ]],
    right: [
      #align(center + horizon)[#image(
        if sys.inputs.at("appendix-static", default: "false") == "true" { "img/appendix-elimination-poster.png" } else { "img/appendix-elimination.gif" },
        width: 100%, height: 330pt, fit: "contain")]
    ],
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[#talk-notes.at(36)]
]

== M：$d=3$ 环面码的具体输入 <sm:d3>

#slide[
  #page-2col(
    [周期格点的稳定子与逻辑支撑],
    [#app-body[
      $ n=18, quad n_Z=n_X=8, quad k=2. $
    各有 9 个稳定子，去掉一个整体依赖。例如
    $ S_Z=Z_(11)Z_(14)Z_(15)Z_(17), $
    $ S_X=X_8 X_(10)X_(11)X_(14). $
    逻辑行的支撑为
    $ overline(Z)_1:{1,7,13}, quad overline(X)_1:{1,2,3}, $
    $ overline(Z)_2:{4,5,6}, quad overline(X)_2:{4,10,16}. $
    目标 $overline(H)_1 overline(I)_2$ 交换第一对逻辑行，固定第二对及全部稳定子。
    ]],
    right: [
      #align(center + horizon)[#image(
        if sys.inputs.at("appendix-static", default: "false") == "true" { "img/sm_s5_crop.png" } else { "img/sm_s5_crop.png" },
        width: 100%, height: 330pt, fit: "contain")]
    ],
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[#talk-notes.at(37)]
]

== N：环面码的解、门序列与核验 <sm:seq>

#slide[
  #page-2col(
    [两个交叉块是逻辑行的外积],
    [#app-body[
      $ U_(Z X)=overline(X)_1^T overline(X)_1, $
    $ U_(X Z)=overline(Z)_1^T overline(Z)_1, quad U_(Z Z)=U_(X X)^T. $
    按门序列重建 $U$，逐项核验
    $ U Lambda U^T=Lambda, quad H U=H, quad L U=L_"target". $
    $H$ 为稳定子行，$L$ 为逻辑行。
    清点：75 CNOT、5 SWAP、1 H，共 81 门，折算为 90 CNOT 当量。
    动画从 $U$ 开始，按矩阵乘积的逆序逐门消元到 $I_(36)$。每一步均保辛，中间矩阵不必固定原稳定子。
    ]],
    right: [
      #align(center + horizon)[#image(
        if sys.inputs.at("appendix-static", default: "false") == "true" { "img/appendix-toric-poster.png" } else { "img/appendix-toric.gif" },
        width: 100%, height: 330pt, fit: "contain")]
    ],
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[#talk-notes.at(38)]
]

== O：有限双曲码的商群与陪集 <sm:hypergroup>

#slide[
  #page-2cards(
    [从无限双曲铺砌得到有限商群],
    [#app-body[
      对正则 $\{r,s\}$ 铺砌，保向对称群满足
  $ G^+_(r,s)=chevron.l rho,sigma | rho^r=sigma^s=(rho sigma)^2=e chevron.r. $
  $rho$、$sigma$ 分别是面中心与顶点的旋转。当 $1/r+1/s<1/2$ 时，铺砌位于双曲平面，其对称群无限。选取无挠、正规、有限指数的子群 $N$，得到
  $ G=G^+_(r,s)/N, quad |G|=[G^+_(r,s):N]<infinity. $ <eq:app-finite-quotient>
  无挠性用于排除旋转锥点；有限指数才保证商群有限。还须确认所得曲面连通、闭合且可定向。
    ]],
    [陪集的轨道数给出几何对象的数量],
    [#app-body[
      在有限商群中，面、顶点、边的稳定子依次为 $chevron.l rho chevron.r$、$chevron.l sigma chevron.r$、$chevron.l rho sigma chevron.r$。对应阶数为 $r,s,2$，轨道–稳定子关系给出
  $ F=abs(G)/r, quad V=abs(G)/s, quad E=abs(G)/2=n. $ <eq:app-cosets>
  $E$ 是物理比特数，因为每条边放置一个比特。面边界和顶点星将分别成为 $Z$ 型、$X$ 型稳定子。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(39)]
]

== P：关联矩阵的秩与逻辑比特数 <sm:hyper>

#slide[
  #page-2cards(
    [链复形保证两类稳定子对易],
    [#app-body[
      用顶点–边关联矩阵定义 $H_X$，用面边界矩阵定义 $H_Z$。每个面的边界在任一顶点有偶数条入射边，因此
  $ H_Z H_X^T=0. $ <eq:app-boundary>
  对闭合连通可定向曲面，全部面边界之和为零，全部顶点星之和也为零；这两组关系各只有一条独立依赖。于是
  $ n_Z=F-1, quad n_X=V-1, quad k=E-F-V+2=2g. $ <eq:app-euler>
    ]],
    [由群的阶得到码参数],
    [#app-body[
      联立 @eq:app-cosets 与 @eq:app-euler，得到
  $ k=n(1-2/r-2/s)+2. $
  例如 $\{4,5\}$ 且 $|G|=120$ 时，$(F,V,E)=(30,24,60)$，从而 $n_Z=29,n_X=23,k=8$，Euler 示性数为 $-6$，亏格为 $4$。

  该计数以 @eq:app-finite-quotient 构造的商确实给出上述曲面为前提。群的阶只决定对象的数量，并不单独证明距离或逻辑门的局域性。
    ]],
    gap: 10pt,
  )
  #speaker-note[#talk-notes.at(40)]
]
