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
// #import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
// #import "@preview/cetz:0.4.2": canvas, draw, vector, matrix
// #import "@preview/theorion:0.5.0": *
#import "@preview/tablex:0.0.9": tablex, rowspanx, colspanx, hlinex
#import themes.aqua: *

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

== 本文的贡献

#slide[
  #page-2cards(
    [三条贡献],
    [
    + *通用性*：对#highlight[任意] CSS 码求#highlight[任意]指定的 Clifford 逻辑操作，把"保持码结构"与"实现目标逻辑映射"写成 $bb(F)_2$ 上的方程组。
    + *可解性*：用辛表示把 Clifford 操作编码成 $2 n times 2 n$ 的二进制矩阵（$O(n^2)$ 个比特）；二次约束线性化后是稀疏线性方程组，复杂度略高于 $O(n^4)$，不是指数级。
    + *流程*：解出的 $U$ 分解为单比特门与双比特门序列（四种基本门 + 辛高斯消元），再用 CNOT 消去模板压缩门数；门与稳定子输入 Stim 可得逻辑错误率。
    ],
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
    - 生成元分成纯 $Z$ 型与纯 $X$ 型两组，可以被写为校验矩阵 $H_Z$（$n_Z times n$）与 $H_X$（$n_X times n$）。
    - 要求 $Z$ 型与 $X$ 型稳定子两两对易，等价于
      #align(center)[$ H_Z H_X^T = 0, $]
      意味着这两个稳定子共同作用的比特数为偶数。推导见 @app:css。
    - 逻辑算符条件：$H_X A_Z^T = 0$、$H_Z A_X^T = 0$，且算符本身不落在稳定子群中。多数 LDPC 码都是 CSS 码；非 CSS 码可映射为 CSS，代价是更多物理比特。
  ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    提醒：约束为什么这么写、保辛条件怎么推，这些细节放在附录 A–D，正文只讲用法。纠错码决定 H_X H_Z，其中的逻辑算符需要受它约束求解。
  ]
]

== Clifford 操作与辛条件

#slide[
  #page-2cards(
    [Clifford 操作 = 保辛的二进制矩阵],
    [
    - 酉操作的作用是 $P -> U_"op"^dagger P U_"op"$；Clifford 操作把 Pauli 链映为 Pauli 链，意味着 $U^dagger P U = plus.minus P'$。
    - 忽略相位后 $U$ 是 $bb(F)_2^(2 n)$ 上的线性映射，可用 $2 n times 2 n$ 二进制矩阵表示：$A_P -> A_P U$。
    - *行约定*：第 $j$ 行是 $Z_j$ 的像，第 $(n+j)$ 行是 $X_j$ 的像。
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
  #speaker-note[
    把 $A Lambda B^T = A (U Lambda U^T) B^T$ 对基向量取，就得到 @eq:保辛条件；分块三条恒等式的展开见附录 A（@app:symp）。注意 3 的每个矩阵元都是 $U$ 中两个元素之积：这就是后文"二次约束"的来源。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 三、代数方法

= 代数方法

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
  #speaker-note[
    熟悉稳定子形式的听众只需强调 $k = n - m$ 与式 (1)；后面算双曲码逻辑比特数（$60 - 52 = 8$）用的就是 $k = n - m$。
  ]
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
  #speaker-note[
    把 $A Lambda B^T = A (U Lambda U^T) B^T$ 对基向量取，就得到 @eq:保辛条件；分块三条恒等式的展开见附录 A。
  ]
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
  #speaker-note[
    重点解释第 ③ 步的 $H "CNOT" H$：同时清除一对互相关联的非零元，而不破坏已经做好的 $I_n$ 块。
  ]
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
  #speaker-note[
    这页专门讲图：先指虚线框对应四步，再指下排线路说明"一次矩阵操作 = 一个物理门"，最后强调时间轴向左。
  ]
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
  #speaker-note[
    化简为什么重要：环面码上的拟合指数从 $alpha = 2.51$ 降到 $2.28$，全部来自这里。
    提问预案："只用到五个 CNOT 的模板，更长的恒等式还有收益吗？" —— 见 5.2 的开放问题。
  ]
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
  #speaker-note[
    把两条规则的根据讲清楚：对易关系决定能不能换顺序，恒等式决定能不能减门。
    可以顺带提问：引入更长的恒等式模板还能再省多少门？
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
  #speaker-note[
    先讲图：方格、边上的比特、面与顶点对应的稳定子，再说明逻辑算符沿非平凡闭环。
    现场算规模：$d = 7$ 时 $n = 2 times 49 = 98$，$U$ 是 $196 times 196$。
    $d = 3$ 的完整结果在 SM 中
  ]
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
  #speaker-note[
    先把 $alpha$ 的两个值说清（都来自论文），再说"与一轮稳定子测量同量级"这个对照。
    右图强调两个相反趋势：总量上升、单位门下降 —— 后者才是容错的希望所在。
    论文没有给出每个 $d$ 的具体 CNOT 数（需查 SM 或自行复现）
  ]
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
  #speaker-note[
    Fig. 5(b) 里圆点是"一步法"的 $overline(S) overline(H)$，三角形是分两步；论文说一步法少约三分之一门数。
    顺带提醒：这条线路的用途是制备相位偏移 Bell 态。
  ]
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
  #speaker-note[
    讲三层：局部铺砌规则 → 可铺砌条件 → 粘合成闭曲面带来的拓扑自由度。
    数两个关键数字：60 个比特、52 个独立稳定子、8 个逻辑比特（复习 $k = n - m$）。
  ]
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
  #speaker-note[
    这一页把双曲码资源收口，并给出三行汇总，方便听众拍照。
    "资源"一列是标度或量级，不是某次运行的确切门数。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 五、讨论与总结

= 余篇散入斜阳里 \ 且听满座起春风

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录：SM（补充材料）详解

= 附录

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录版式工具
//   * 附录里的插图一律按等比缩放塞进图框（contain），保证整张图都看得见；
//     "上图下注"版式里图注与出处竖排在图片*右侧*（不占图片下沿，图可以更大）；
//     "左注右图"版式里图注与出处放在窄栏图片的下方。
//   * 三个版式：上下（图 + 注）/ 左右（注 + 图）/ 两卡。

#let fig-box(image-path, source, caption: none, height: 100%, fig-height: 200pt, inset: 10pt) = block(
  width: 100%,
  height: height,
  fill: white,
  stroke: 0.7pt + green-line,
  radius: 4pt,
  inset: inset,
)[
  #align(center)[#image(image-path, width: 100%, height: fig-height, fit: "contain")]
  #if caption != none {
    align(center)[#text(size: 13pt, fill: mute-ink)[#caption]]
  }
  #align(center)[#text(size: 12pt, fill: mute-ink)[#source]]]

// 图框（图注在侧边）：图片占左侧，图注与出处竖排在右侧窄栏里；
// 用于"上图下注"的整页版式，图注不再压在图片下沿。
#let fig-box-side-caption(
  image-path,
  source,
  caption: none,
  box-height: 280pt,
  fig-height: 240pt,
  inset: 10pt,
  caption-width: 26%,
  gap: 12pt,
) = block(
  width: 100%,
  height: box-height,
  fill: white,
  stroke: 0.7pt + green-line,
  radius: 4pt,
  inset: inset,
)[
  #grid(
    columns: (1fr, caption-width),
    rows: (box-height - 2 * inset,),
    column-gutter: gap,
    align(horizon + center)[#image(image-path, width: 100%, height: fig-height, fit: "contain")],
    block(height: 100%, stroke: (left: 1pt + green-line), inset: (left: 8pt))[
      #align(horizon + left)[
        #if caption != none {
          text(size: 13pt, fill: mute-ink)[#caption]
          v(6pt)
        }
        #text(size: 12pt, fill: mute-ink)[#source]
      ]
    ],
  )
]

// 上图下注：frac 是图框占整页高度的比例；图注与出处写在图片右侧
#let page-fig(frac, image-path, source, caption, notes-title, notes, tone: "wash", gap: 12pt, caption-width: 26%) = layout(size => {
  let avail = size.height - gap
  let r1 = avail * frac
  let r2 = avail - r1
  block(width: 100%, height: size.height)[
    #grid(
      rows: (r1, r2),
      row-gutter: gap,
      fig-box-side-caption(
        image-path,
        source,
        caption: caption,
        box-height: r1,
        fig-height: r1 - 22pt,
        caption-width: caption-width,
      ),
      fit-card(notes-title, notes, tone: tone, avail: r2, width: size.width),
    )
  ]
})

// 左注右图：说明卡占满整页高度
#let page-fig-side(title, body, image-path, source, caption: none, tone: "wash", fractions: (1.05fr, 1fr), gap: 12pt, fig-height: 300pt) = layout(size => {
  let fs = fractions.map(to-frac)
  let total = fs.sum()
  let col1 = (size.width - gap) * fs.at(0) / total
  block(width: 100%, height: size.height)[
    #grid(
      columns: fractions,
      rows: (size.height,),
      column-gutter: gap,
      fit-card(title, body, tone: tone, avail: size.height, width: col1),
      fig-box(image-path, source, caption: caption, height: 100%, fig-height: fig-height),
    )
  ]
})

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 A：辛条件的拆分与约束计数

== 附录 A：辛条件的拆分、约束计数与对角为零 <app:symp>

#slide[
  #page-2cards(
    [把 @eq:保辛条件 按 $n times n$ 分块展开],
    [
      - 取 $U = mat(U_(Z Z), U_(Z X); U_(X Z), U_(X X))$、$Lambda = mat(0, I_n; I_n, 0)$，分块乘法把 $U Lambda U^T = Lambda$ 拆成四条恒等式：
        $ U_(Z X) U_(Z Z)^T + U_(Z Z) U_(Z X)^T = 0 $ <eq:辛D1>
        $ U_(Z X) U_(X Z)^T + U_(Z Z) U_(X X)^T = I_n $ <eq:辛D2>
        $ U_(X X) U_(Z Z)^T + U_(X Z) U_(Z X)^T = I_n $ <eq:辛D3>
        $ U_(X X) U_(X Z)^T + U_(X Z) U_(X X)^T = 0 $ <eq:辛D4>
      - @eq:辛D2 的转置正好是 @eq:辛D3，所以这两条合起来只贡献 $n^2$ 条约束；@eq:辛D1、@eq:辛D4 转置后回到自身。
    ],
    [约束数：从 $2 n times 2 n$ 降到 $n (2 n - 1)$],
    [
      - 在 $bb(F)_2$ 上的运算使 @eq:辛D1、@eq:辛D4 左端的*对角元自动为零*（形如 $a b + b a = 0$），只剩非对角部分，各自只给出 $frac(n(n-1), 2)$ 条。合计
        $ n^2 + 2 times frac(n(n-1), 2) = n (2 n - 1) $ <eq:约束数>
      - 即 $U$ 有 $(2 n)^2$ 个元素，独立约束只有 $n (2 n - 1)$ 条，其余由"对称性 + $1 = -1$"自动满足。
      - 这些*二次*方程，加上线性的 @eq:码结构 与 @eq:目标映射，就是算法要解的全部条件。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页就是正文里"分块三条恒等式的展开见附录 A（@app:symp）"所指的内容。
    现场演算的顺序：先写四条 → 说第 2 条与第 3 条互为转置（@eq:辛D2、@eq:辛D3）→ 再落 $bb(F)_2$ 上对角为零，得到 $n(2n-1)$。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 C：分块与自由变量削减

== 附录 B：$U$ 的分块与自由变量削减 <sm:vars>

#slide[
  #page-2cards(
    [分块之后：$2 n$ 列共享同一个基础解系],
    [ #set text(size: 15pt)
      - 把 $U$ 按 $n times n$ 分块：
        $ U = mat(U_(Z Z), U_(Z X); U_(X Z), U_(X X)) $ <eq:U分块>
        再把 @eq:保辛条件 与 @eq:码结构 按同样的分块写开：
        $ mat(overline(Z); H_Z) mat(U_(Z Z), U_(Z X)) = mat(overline(Z)^Z, overline(Z)^X; H_Z, 0) quad, quad mat(overline(X); H_X) mat(U_(X Z), U_(X X)) = mat(overline(X)^Z, overline(X)^X; 0, H_X) $ <eq:码结构分块>
      - 关键观察：$U_(Z Z)$ 与 $U_(Z X)$ 的 $2 n$ 个列向量满足 $k + n_Z$ 条方程，这些方程*系数矩阵完全相同、仅常数项不同*。
      - 所以这 $2 n$ 个列共享一维数为 $n - (k + n_Z) = n_X$ 的基础解系，可以统一写成"自由变量 $times$ 基础解系 $+$ 特解"：
        $ U_(Z Z) = H_X^T U_(Z Z)^1 + B_(Z Z), quad U_(Z X) = H_X^T U_(Z X)^1 + B_(Z X) $ <eq:Z半块>
        $ U_(X Z) = H_Z^T U_(X Z)^1 + B_(X Z), quad U_(X X) = H_Z^T U_(X X)^1 + B_(X X) $ <eq:X半块>
    ],
    [],
    [ #set text(size: 15pt)
      - $n_X$ 个独立的 $X$ 型稳定子与任何 $Z$ 型算符都对易，它们正是 $H_X^T$ 的 $n_X$ 列 —— 这就是 $Z$ 半块可以自由组合的方向数；把两半交换（$Z <-> X$）就得到 $X$ 半块的 $n_Z$ 个自由度。
      - 于是变量数从 $U$ 的全部元素 $4 n^2$ 降到
        $ 4 n^2 -> 2 n (n_X + n_Z) = 2 n (n - k) $ <eq:变量数>
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    讲法：先给分块形状，再强调"同一个系数矩阵、不同常数项"——这是线性代数里最标准的结论。
    最后落一句 $4n^2 -> 2n(n-k)$：这是全篇可行性的根据，也是后文"$O(n^2)$ 个未知量"的来源。
    特解块 $B$ 由算法给出，可以选得*很稀疏*：具体构造见附录 H（@eq:主元 与 @eq:特解构造），最终解的形状见 @sm:kernel。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 B：代入之后的方程与二次项

== 附录 C：代入自由变量后的方程与二次项

#slide[
  #page-2cards(
    [把 @eq:Z半块、@eq:X半块 代入 @eq:辛D1、@eq:辛D3、@eq:辛D4],
    [
      - 代入后 @eq:辛D1、@eq:辛D3、@eq:辛D4 各自变成一条*逐元素*方程：每条都由三类求和构成 —— *二次项*（$H_X$ 的两个元素 $times$ 两个自由变量元素，即 @eq:二次项 那一类）、*交叉项*（$H_X$、$B$ 与自由变量的乘积）、*常数项*（$B$ 的两两乘积）。
      - 未知量只剩自由变量 $U^1$ 与二次项 $tilde(U)$，$H_Z$、$H_X$、$B$ 全部成为已知系数。记法：$h^X_(eta i) equiv (H_X)_(eta i)$、$u^(Z X)_(i j) equiv (U_(Z X)^1)_(i j)$、$b^(Z X)_(i j) equiv (B_(Z X))_(i j)$，$H_Z$ 与其余 $B$ 块同理。
      - 两种写法的分工：前两条方程只对 $j < i$ 写一次；第三条用右端的 $delta_(i j)$ 同时给出对角与非对角，共 $n^2$ 条。
    ],
    [为什么可以把乘积当成新变量],
    [
      - 逐元素写开后可以看到：二次项永远以*固定组合*出现，只有四类
        $ tilde(u)^(Z X, Z Z)_(eta xi) = sum_(zeta = 1)^n u^(Z X)_(eta zeta) u^(Z Z)_(xi zeta) $ <eq:二次项>
        $ tilde(u)^(X Z, X X)_(eta xi) = sum_(zeta) u^(X Z)_(eta zeta) u^(X X)_(xi zeta), quad tilde(u)^(X Z, Z X)_(eta xi) = sum_(zeta) u^(X Z)_(eta zeta) u^(Z X)_(xi zeta), quad tilde(u)^(X X, Z Z)_(eta xi) = sum_(zeta) u^(X X)_(eta zeta) u^(Z Z)_(xi zeta) $
      - 于是把每一组乘积整体记成新变量，方程组立刻变成*线性*的；代价是解完之后要做一次"匹配"：只保留满足 $tilde(u) = u u$ 的那部分解。
      - 由于二次项的结构是固定的，所以匹配这一步的开销很小（具体做法见 @sm:kernel 与 @sm:proof 两页）。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这一页是"线性化"的动机：不是随手换元，而是先看出二次项只有四类固定组合。
    如果听众问"为什么要分组"，答：分组后 $tilde(U)$ 的尺寸与对应的自由变量块一一对应，向量化时才能排成一个整齐的长向量（见 @app:linear）。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 D：二次项、变量总数与线性方程组

== 附录 D：二次项、变量总数与线性方程组 <app:linear>

#slide[
  #page-fig(
    0.62,
    "img/sm_s1.png",
    "Fig. S1",
    [以最小的 ${4,5}$ 双曲码（60 比特、8 逻辑比特、29 个 $Z$ 稳定子、23 个 $X$ 稳定子）为例的向量化示意：各块的长度就是变量个数],
    [线性化：两种形式、一个长向量、一个线性方程组],
    [
      - 变量有*两种形式*：一是四个自由变量矩阵块 $U_(Z Z)^1$、$U_(Z X)^1$、$U_(X Z)^1$、$U_(X X)^1$，二是把它们与四个 $tilde(U)$ 块按行转置后竖排成的长向量 $u$（Fig. S1）。
      - 计数：线性变量 $2 n (n - k)$ 个，二次变量 $(n_Z + n_X)^2 = (n - k)^2$ 个；因为 $n - k < 2 n$，二次变量不到线性变量的一半。合计
        $ 2 n (n - k) + (n - k)^2 = (n - k)(3 n - k) $ <eq:总变量数>
      - 向量化之后，@eq:辛D1、@eq:辛D3、@eq:辛D4 合成一个标准线性方程组
        $ A u = B' $ <eq:线性方程>
        其中 $A$ 是 $n (2 n - 1) times (n - k)(3 n - k)$ 的稀疏矩阵，$B'$ 是常数项。行数与列数都是 $O(n^2)$ 量级。
      - 注意：$tilde(U)$ 只是*形式*变量，解出来之后还要与 $U$ 匹配（附录 I）；若不做这一步，$u$ 里任意一个解都还不是合法的 $U$。
    ],
  )
  #speaker-note[
    这页回答"线性化到底怎么做的"：先把二次项归成四个块（@eq:二次项），再整体向量化，最后写成 $A u = B'$。
    图里的例子正好是那个 ${4,5}$ 码，可以和正文 4.4 的数字（60 / 29 / 23 / 8）对上。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 E：系数矩阵的结构与规模清点

== 附录 E：系数矩阵 $A$ 的分块结构与规模清点

#slide[
  #page-2cards(
    [$A$ 的 $3 times 8$ 分块与 $B'$ 的形状],
    [
      - 按"三条方程 $times$ 八类变量"分块，$A$ 的大部分块直接为零：第一行只连 $U_(Z Z), U_(Z X), tilde(U)^(Z X, Z Z)$；第二行只连 $U_(X Z), U_(X X), tilde(U)^(X Z, X X)$；第三行连四个线性块与两个二次块。
      - *右下角两块完全相同*（$A^(X X, Z Z)$ 出现两次）—— 这正是后文可以取 $tilde(u)^(X Z, Z X) = 0$ 的原因。
      - 常数项的形状是
        $ B' = mat(0; 0; B_3') $ <eq:常数项>
         前两块为零：因为它们对应的方程右端本来就是零（证明见附录 H）。
      - 求 $u$ 就是"求 $A$ 的核空间 $+$ 一个特解"：$u = u^b + sum_(s) c_s u^((s))$。
    ],
    [规模清点与稀疏性],
    [
      - 规模：$A$ 的行数是 $n (2 n - 1)$、列数是 $(n - k)(3 n - k)$。
      - *例*：$d = 7$ 环面码 $n = 2 d^2 = 98$、$k = 2$，于是行 $= 98 times 195 = 19110$、列 $= 96 times 292 = 28032$；对应的 $U$ 是 $196 times 196$，约 $3.8 times 10^4$ 个元素。
      - *稀疏性*：每个方程只涉及少数几个变量（$H_Z$、$H_X$ 的每行权重都很小），实际消元代价远低于稠密矩阵。量级*略高于 $O(n^4)$*，与 $4^n$ 相比是"多项式 vs 指数"的差别。
      - *对比*：态矢量方法要在 $4^n$ 维空间里工作，$n = 98$ 时 $4^98 approx 10^59$，完全无法枚举。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这一页把"$O(n^2)$ 个变量、$O(n^4)$ 的代价"落到具体数字上：$d = 7$ 的行列数是现场可以手算的。
    提问预案："为什么不用通用稀疏求解器？"——因为这里还要处理二次项匹配与非唯一解，见 @sm:kernel 与 @sm:proof。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 F：七类核向量与稀疏特解

== 附录 F：解的结构：七类核向量与一个稀疏特解 <sm:kernel>

#slide[
  #page-fig(
    0.60,
    "img/sm_s2.png",
    "Fig. S2",
    [核空间的七类基向量（上）与稀疏特解（下）；不同颜色表示不同块，色块位置就是非零元所在],
    [核空间与特解长什么样],
    [
      - *前四类* $u^((1))$–$u^((4))$：每个基向量在对应块里只有*一行*非零，这一行取自 $n_Z$ 个向量 ${w_q^Z}$ 或 $n_X$ 个向量 ${w_q^X}$；把非零行挪到另一行就得到另一个基向量。
        $ (u_(Z Z))^(p q)_(eta zeta) = delta_(eta p) (w_q^Z)_zeta, quad (u_(Z X))^(p q)_(eta zeta) = delta_(eta p) (w_q^X)_zeta $ <eq:核向量前四类>
      - *后三类* $u^((5))$–$u^((7))$：来自二次项，$tilde(U)^(Z X, Z Z)$ 与 $tilde(U)^(X Z, X X)$ 可以取*任意对称矩阵*，唯一的要求是 $tilde(U)^(X Z, Z X) = tilde(U)^(X X, Z Z)$。
        $ (tilde(u)^(Z X, Z Z))^(p q)_(eta xi) = delta_(eta p) delta_(xi q) + delta_(eta q) delta_(xi p), quad (tilde(u)^(X Z, X X))^(p q)_(eta xi) = delta_(eta p) delta_(xi q) + delta_(eta q) delta_(xi p) $ <eq:核向量后三类>
      - *稀疏特解* $u^b$：只有 $u_(Z Z)$、$u_(X X)$、$tilde(u)^(X Z, Z X)$、$tilde(u)^(X X, Z Z)$ 四块非零，其中 $tilde(u)^(X Z, Z X)$ 取零（由 $A$ 右下两块相同直接选）。一般解 $=$ 特解 $+$ 核空间的任意组合。
    ],
  )
  #speaker-note[
    这页是"解长什么样"的图示：七类基向量 + 一个很稀疏的特解，组合出全部解。
    听众问"解唯一吗"：不唯一，核空间维数就是自由度；换一个组合就换一条门序列。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 G：核空间的来源

== 附录 G：核空间从哪里来：条带结构与秩 <sm:proof>

#slide[
  #page-fig-side(
    [证明的第一半：核心不是猜基向量，而是读条带],
    [
      - $A$ 的非零块可以按指标 $eta$ 切成一条条*竖带*，每条带宽 $n$（Fig. S3）。把条带的行逐项写出来会发现：这些行都是 $b^(Z X)$ 与 $b^(X X)$ 的线性组合，而 $b$ 就是特解块 $B$ 的行。
      - 把一条竖带单独拿出来得到窄矩阵 $tilde(A)^(Z Z)_eta$，尺寸 $n (3 n - 1) / 2 times n$：它*列不满秩*，所以核空间非空。
      - *秩是多少*：这些行向量的秩为 $n_X + k$，于是核空间维数
        $ n - (n_X + k) = n_Z $ <eq:核空间维数>
        这正好解释了前四类基向量里 ${w_q^Z}$ 只有 $n_Z$ 个（$q$ 的上限）。
      - 另一侧完全对称：秩 $n_Z + k$，核空间维数 $n_X$ —— 给出 ${w_q^X}$ 的 $n_X$ 个向量。两组合起来就是 @eq:核向量前四类 与 @eq:核向量后三类。
    ],
    "img/sm_s3.png",
    "Fig. S3",
    caption: [系数矩阵 $A$ 的结构：非零块只落在若干条带上；灰虚线框出的两块用来演示"条带的行由 $b$ 的线性组合生成"],
    fig-height: 340pt,
  )
  #speaker-note[
    这页只讲证明骨架：条带结构 → 窄矩阵不满秩 → 秩 $n_X + k$ → 核空间维数 $n_Z$。
    强调"秩 $n_X + k$"里为什么会有 $k$：条带的行由逻辑算符与稳定子共同生成。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 H：特解块与常数项

== 附录 H：特解块 $B$ 的构造与 $B'$ 前两块为零

#slide[
  #page-2cards(
    [特解块 $B$ 的一种构造],
    [
      - 解线性条件 @eq:码结构分块 时，把增广矩阵 $(M_Z, Q_(Z Z), Q_(Z X))$ 做初等行变换化到行最简形：
        $ L_Z (M_Z, Q_(Z Z), Q_(Z X)) = (M'_Z, Q'_(Z Z), Q'_(Z X)) $
        其中 $M_Z$ 把逻辑 $Z$ 算符与 $Z$ 稳定子堆在一起，共 $k + n_Z$ 行。
      - $M_Z$ 行满秩 ⇒ $M'_Z$ 没有零行。每行只留主元、丢掉其余非零元，再转置得到 $Gamma_Z$，于是
        $ M'_Z Gamma_Z = I_(n_Z + k) $ <eq:主元>
      - 特解就取
        $ B_(Z Z) = Gamma_Z L_Z Q_(Z Z), quad B_(Z X) = Gamma_Z L_Z Q_(Z X) $ <eq:特解构造>
      - 换一种行变换就换一组 $B$ —— 特解不唯一，但"自由变量 $+$ 特解"的结构 @eq:Z半块、@eq:X半块 不变。
    ],
    [$B'$ 前两块为什么是零],
    [
      - 与 @eq:常数项 对应，要证的是 $0 = B_(Z X) B_(Z Z)^T + B_(Z Z) B_(Z X)^T$（$X$ 半块同理）。
      - 代入 @eq:特解构造 后，中间只剩 $Q_(Z Z) Q_(Z X)^T + Q_(Z X) Q_(Z Z)^T$；把 $Q$ 按"逻辑算符 $+$ 稳定子"逐块展开，可以看到每一项都是零：
        - $H_Z (overline(X)_m)^T = 0$ 与 $(overline(X)_m^Z) H_Z^T = 0$：逻辑算符与稳定子对易；
        - $0 = overline(Z)_m (overline(X)_(m'))^T + overline(X)_m^Z (overline(Z)^Z_(m'))^T$：逻辑算符之间的辛配对。
      - 与 $Z$ 半块同理，$X$ 半块给出的 $B_(X X) B_(X Z)^T + B_(X Z) B_(X X)^T = 0$ 也成立。于是 $B'$ 只剩第三块，特解特别稀疏。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页是"证明要点"里最技术的一页，讲课节奏：先说 $B$ 只是线性方程的一组特解（@eq:特解构造），再说 $B'$ 前两块为零靠的是对易关系。
    如果时间紧，只需一句："前两块为零 ⇒ 特解只有四块非零 ⇒ 匹配只需要处理一块（下一页）。"
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 I：二次项匹配

== 附录 I：二次项的匹配：用核向量消除失配

#slide[
  #page-2cards(
    [差在哪里：$Delta tilde(U)^(X X, Z Z)$],
    [
      - 特解 $u^b$ 还没满足二次关系。把 $U_(X X)^(1 b) (U_(Z Z)^(1 b))^T$ 与 $tilde(U)^(X X, Z Z)_b$ 的差记为
        $ U_(X X)^(1 b) (U_(Z Z)^(1 b))^T - tilde(U)^(X X, Z Z)_b = Delta tilde(U)^(X X, Z Z) $ <eq:失配>
      - 用第四类核向量的组合去补 —— 只有这一类的指标范围（$n_Z$ 行 $times$ $n_X$ 列）与 $U_(X X)^1$ 吻合：
        $ Delta U_(X X)^1 = sum_(p = 1)^(n_Z) sum_(q = 1)^(n_X) c_(p q) U_(X X)^(1, p q) = C W^X $ <eq:组合>
        其中 $C$ 是 $n_Z times n_X$ 的系数矩阵，$W^X$ 的第 $q$ 行就是 $(w_q^X)_zeta$（@eq:核向量前四类）。
      - 换句话说：失配不是被"消掉"，而是被*重新分配给核空间的自由度*。
    ],
    [为什么一定有解：满秩论证],
    [
      - 要求 $Delta U_(X X)^1 (U_(Z Z)^(1 b))^T = Delta tilde(U)^(X X, Z Z)$，代入 @eq:组合 得
        $ [U_(Z Z)^(1 b) (W^X)^T] C^T = (Delta tilde(U)^(X X, Z Z))^T $ <eq:组合系数>
        每一列 $C^T$ 都是一个普通线性方程组。
      - *满秩*：$W^X$ 的各行线性无关 ⇒ $(W^X)^T$ 列满秩；若 $U_(Z Z)^(1 b)$ 不满行秩，先用第一类核向量把它调成满行秩（在 $n_Z >= n_X$ 时做得到）⇒ @eq:组合系数 的系数矩阵满秩 ⇒ $C$ 必有解。
      - 若 $n_Z < n_X$，把 @eq:码结构分块 转置后改用第一类核向量，重复同一过程。
      - *收尾*：把 $Delta U_(X X)^1$ 加到 $U_(X X)^(1 b)$ 上、其余块保持不变，代回 @eq:Z半块 与 @eq:X半块 就得到变换矩阵 $U$ —— 算法到此闭环。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页回答"解一定存在吗"：存在性靠 $(W^X)^T$ 列满秩 + 用第一类核向量把 $U_(Z Z)^(1 b)$ 调成满行秩。
    顺带说明"$n_Z < n_X$ 就转置重做"是一个对称性技巧，而不是额外的算法分支。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 J：单比特门的辛矩阵

== 附录 J：单比特门的辛矩阵

#slide[
  #page-2cards(
    [Hadamard 与相位门：$2 times 2$ 的辛矩阵],
    [
      - Hadamard 交换 $Z$ 与 $X$（在 $bb(F)_2^2$ 上就是把两个分量对调）：
        $ P_H = mat(0, 1; 1, 0) $ <eq:PH>
      - 相位门把 $X$ 变成 $Y$ 而保持 $Z$ 不变（$X -> Z X$、$Z -> Z$）：
        $ P_S = mat(1, 0; 1, 1) $ <eq:PS>
      - 保辛可以直接验：$P_H Lambda_2 P_H^T = Lambda_2$、$P_S Lambda_2 P_S^T = Lambda_2$，其中 $Lambda_2 = mat(0, 1; 1, 0)$。
      - 这正是它们能够进入辛高斯消元的原因 —— 消元过程中任意一步都不允许破坏 @eq:保辛条件。
    ],
    [为什么它们本身就是"初等矩阵"（四个非零位置）],
    [
      - 作用在第 $i$ 个比特上时，$2 n$ 维行向量只有第 $i$、$(i+n)$ 个分量会变，所以 $U$ 与 $I_(2 n)$ 只在*
        $(i, i)$、$(i, i+n)$、$(i+n, i)$、$(i+n, i+n)$* 这四个位置不同，而且这四个位置的值正好继承上面的 $2 times 2$ 矩阵。
      - 读法（与正文 3.3 的表格一致）：@eq:PH 交换第 $i$ 与第 $(i+n)$ 列；@eq:PS 把第 $(i+n)$ 列加到第 $i$ 列。
      - 于是"一个单比特门 $=$ 一次列交换或列加法"，这就是把 $U -> I_(2 n)$ 的过程翻译成线路的依据。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    单比特门这页可以现场板书验证：$P_H$ 交换两列、$P_S$ 做一次列加，正好对 $H$ 与 $S$ 在 Pauli 链上的作用。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 K：双比特门的辛矩阵

== 附录 K：双比特门的辛矩阵 <app:gates>

#slide[
  #page-2cards(
    [CNOT 与 SWAP：$4 times 4$ 的辛矩阵],
    [
      - CNOT（控制 1、目标 2）：$Z_2 -> Z_1 Z_2$、$X_1 -> X_1 X_2$，而 $Z_1$、$X_2$ 不变，于是
        $ P_("CNOT"_(1 2)) = mat(1, 0, 0, 0; 1, 1, 0, 0; 0, 0, 1, 1; 0, 0, 0, 1) $ <eq:PCNOT>
      - SWAP 交换两个比特的 Pauli 算符（$Z_1 <-> Z_2$、$X_1 <-> X_2$）：
        $ P_("SWAP"_(1 2)) = mat(0, 1, 0, 0; 1, 0, 0, 0; 0, 0, 0, 1; 0, 0, 1, 0) $ <eq:PSWAP>
      - 这两个矩阵都满足 @eq:保辛条件，可以直接乘一遍验证。
    ],
    [放进 $2 n times 2 n$ 与对应的列操作],
    [
      - 放进 $n$ 比特系统：把 $4 times 4$ 矩阵填到第 $i$、$j$ 与第 $(i+n)$、$(j+n)$ 行与列的交叉位置，其余位置取 $I$；$n = 2$ 时就是这两个矩阵本身（正文 3.3 的表格可以逐条核对）。
      - 列操作读法：CNOT 是"第 $j$ 列加到第 $i$ 列，*同时*第 $(i+n)$ 列加到第 $(j+n)$ 列"；SWAP 是"同时交换两对列"。
      - 四种门（$H$、$S$、CNOT、SWAP）就是消元的*全部*动作，它们都保辛；普通高斯消元里的其它初等操作不在其中，所以消元顺序必须专门设计（正文 3.4、附录 M）。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    双比特门这页把 $4 times 4$ 矩阵与"同时作用在左右两半"讲清楚，为四步消元做铺垫。
    现场可以指一下 $P_("CNOT")$ 里的两个 $1$：一个实现"$j$ 列加到 $i$ 列"，另一个实现"$(i+n)$ 列加到 $(j+n)$ 列"。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 L：CSS 条件

== 附录 L：$H_Z H_X^T = 0$ 与逻辑算符条件 <app:css>

#slide[
  #page-2cards(
    [从"两两对易"到矩阵条件],
    [
      - *对易判据*：$Z_a$ 与 $X_b$ 反对易，当且仅当它们*共同作用的比特数为奇数*（每个共同比特贡献一次 $Z X$ 型的反对易）。
      - 记 $H_Z$ 的第 $a$ 行为 $r_a in bb(F)_2^n$、$H_X$ 的第 $b$ 行为 $s_b$，则共同比特数为 $r_a dot s_b mod 2$。要求所有 $Z$ 型与 $X$ 型稳定子两两对易，就是 $r_a dot s_b = 0$ 对所有 $a, b$ 成立，即
        $ H_Z H_X^T = 0. $ <eq:稳定子条件>
      - *同型自动对易*：$Z Z = I$、$X X = I$，所以 $Z$ 与 $Z$、$X$ 与 $X$ 之间的条件不用查，只需查 $Z$ 型与 $X$ 型之间的重叠比特数。
      - 这也解释了 @eq:码结构分块 为什么写成"逻辑算符 $+$ 稳定子"堆叠的形式：$M_Z = (overline(Z); H_Z)$ 与 $M_X = (overline(X); H_X)$ 都是行满秩的。
    ],
    [逻辑算符的条件与它们之间的关系],
    [
      - 逻辑 $Z$ 型算符要与所有 $X$ 型稳定子对易：$H_X A_Z^T = 0$；逻辑 $X$ 型算符满足 $H_Z A_X^T = 0$。
      - *非平凡性*：还要排除"该算符等于若干稳定子的乘积"的情形，否则它是稳定子而不是逻辑算符。
      - *逻辑算符之间*：$overline(Z)_m$ 与 $overline(X)_(m')$ 在 $m = m'$ 时反对易、$m != m'$ 时对易。这条关系在附录 H 里被用来证明 $B'$ 的前两块为零。
      - 这三组条件合起来，才能保证解出的 $U$ 既保持码结构，又确实实现目标逻辑操作。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页是给"想从稳定子定义推一遍"的听众准备的；时间紧可以直接跳到附录 M（四步消元）。
    一句话总结：$H_Z H_X^T = 0$ 是 CSS 码的定义性条件，逻辑算符条件全部由它派生。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 M：四步消元的判定规则

== 附录 M：四步消元的判定规则与边界情形

#slide[
  #page-2cards(
    [$U -> I_(2 n)$：四步，每步只允许特定门],
    [
      + *双比特门*：只看 $U$ 左侧 $2 n times n$ 的部分，用 CNOT / SWAP 把它化为列阶梯形；右侧 $n$ 列被"对偶地"同步作用。$U$ 满秩 ⇒ 这一步不会遇到全零列。
      + *$H$ 换列*：若左上还没出现 $I_n$，说明右半有带零元的列，用 $H$ 把右半的列换进来，再回到第一步；通常此时左上与右下两个块都已是 $I_n$。
      + *消左下*：单个元素 $(i+n, i)$ 用 $S_i$ 消去；成对元素 $(i+n, j)$ 与 $(j+n, i)$（$i < j$）用 $H_i "CNOT"_(j i) H_i$ 一起清掉 —— 只看一个会破坏另一个。
      + *消右上*：右上若还有非零元，继续用 $H$ 处理，最终 $U -> I_(2 n)$，分解结束。
    ],
    [读数规则与剩下的自由度],
    [
      - *为什么不能随便消*：可用的只有 @app:gates 里的四类辛操作，每一步都必须保持 $U Lambda U^T = Lambda$，所以顺序要专门设计（Fig. 1 的四个虚线框）。
      - *门序列怎么读*：由 $U P_1 dots.c P_T = I_(2 n)$ 得 $U = P_T dots.c P_1$，所以最终线路要把消元过程*逆序*读出（Fig. 1 的时间轴指向左侧），$T$ 是化简前的物理门数。
      - *剩下的自由度*：消元顺序、逻辑算符的选取、以及用哪一组核向量组合（@sm:kernel），都会给出不同的解与不同的门数 —— 这也是门数只做模板级化简（正文 3.6）的原因。
      - *化简*：一个 SWAP 折算三个 CNOT，再用五 CNOT 模板迭代替换（Fig. 2），得到最终门数与 CNOT 当量。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这一页是正文 3.4 的"规则化"版本：每一步只说明"用什么门、消什么非零元、为什么不会破坏已完成的 $I_n$"。
    重点讲第 ③ 步的 $H "CNOT" H$：它一次清掉一对互相关联的非零元。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 N：d = 3 环面码的设置

== 附录 N：具体例子①：$d = 3$ 环面码的设置 <sm:d3>

#slide[
  #page-2col(
    [$d = 3$ 环面码：先把编号与算符定下来],
    [
      - *规模*：$d = 3$ 时 $n = 2 d^2 = 18$ 个物理比特、$k = 2$ 个逻辑比特 —— 就是右图里编号 1–18 的那些比特。
      - *编号约定*：比特放在方格的边上（圆点），面给 $Z$ 稳定子、顶点给 $X$ 稳定子；图上同时画出了两条逻辑 $Z$ 链（$overline(Z)_1$、$overline(Z)_2$）与两条逻辑 $X$ 链（$overline(X)_1$、$overline(X)_2$）。
      - *得到矩阵*：编号一定，$H_Z$、$H_X$ 与 $overline(Z)_1, overline(Z)_2, overline(X)_1, overline(X)_2$ 就全部成为具体的 0/1 向量，@eq:码结构 与 @eq:目标映射 也随之变成具体方程。
      - *目标操作*：$overline(H)_1 overline(I)_2$ —— 只对第一个逻辑比特做 Hadamard（$overline(Z)_1 -> overline(X)_1$、$overline(X)_1 -> overline(Z)_1$，第二个逻辑比特不变），正是正文 4.1 那个几何方法做不到的操作。
      - *下一步*：把这三组约束交给算法解出 $U$，再分解成物理门（附录 O、P）。
    ],
    image-path: "img/sm_s5_crop.png",
    source: [Fig. S5：$d = 3$ 环面码的比特编号与逻辑算符],
    img-height: 300pt,
    tone: "wash",
    fractions: (1.2fr, 1fr),
  )
  #speaker-note[
    这页把例子的"起手式"讲清楚：先固定编号，再写矩阵。
    提醒：编号约定可以换，换编号只会让解与门序列换一副样子，不影响"能不能做"。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 O：d = 3 的一个解

== 附录 O：具体例子②：$d = 3$ 的一个解 <sm:sol>

#slide[
  #page-fig(
    0.74,
    "img/sm_s53.png",
    [SM §4：$d = 3$ 的一个解],
    [$(U_(H I))_(Z Z) = (U_(H I))_(X X)^T$ 的显式矩阵（隐去全部 0），以及 $Z X$、$X Z$ 两块的定义],
    [],
    [
      - 三条分块关系：$(U_(H I))_(Z Z) = (U_(H I))_(X X)^T$；$(U_(H I))_(Z X) = overline(X)_1^T overline(X)_1$；$(U_(H I))_(X Z) = overline(Z)_1^T overline(Z)_1$。
      - $Z X$ 块是"逻辑 $X_1$ 的外积"、$X Z$ 块是"逻辑 $Z_1$ 的外积"：目标映射"只对第一个逻辑比特做 $H$"就落在这两块上；$Z Z$ 与 $X X$ 互为转置，对应 @eq:保辛条件 的对称结构。
      - 所有 0 都隐去，矩阵看上去就是一张稀疏点阵；这与附录 F、H 的结论一致 —— 特解可以取得很稀疏，且 $Z X$、$X Z$ 在特解中为零。
      - *解不唯一*：换一组核向量组合就换一条门序列；下面给出这一条解对应的完整门序列。
    ],
  )
  #speaker-note[
    看点是"目标映射如何体现在解的分块里"：$Z X$ 块是逻辑 $X_1$ 的外积、$X Z$ 块是逻辑 $Z_1$ 的外积。
    顺带强调解不唯一 —— 这也解释了为什么门数只能在模板级别优化。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 P：d = 3 的完整门序列

== 附录 P：具体例子③：$d = 3$ 的完整门序列与门数 <sm:seq>

#slide[
  #page-2cards(
    [$d = 3$ 的物理门序列],
    [
      #set text(size: 11pt)
      - *记法*：$[j i]$ 表示 $"CNOT"_(i j)$，$(i j)$ 表示 $"SWAP"_(i j)$；
      - *顺序*：靠后的门先施加，也就是线路要从右往左读；
      - 序列：
        `[1 7][7 1][2 8][8 2][3 9][7 13][9 3][8 14][1 7][9 15][2 8][3 9][5 17][13 7][7 13][14 8][8 14][15 9][6 18][4 5][17 5]`
        `[9 15][4 6][5 17][4 1][4 2][5 2][5 3][18 6][6 18][6 1][6 3][13 14][14 15][10 17][11 17][15 16][8 2][10 18][10 5]`
        `[16 15][16 17][7 1][12 18][9 3][15 16][10 6][15 18][11 5][15 2][13 1][14 9][15 5][14 13][12 6][15 6][17 16][16 17]`
        `[16 9][15 13][17 18][18 17][18 9][16 13][16 14][17 18][17 1][17 14][18 14]H_(18)[1 18][2 18][3 18][13 8]`
        `(13 18)(14 18)(15 18)(16 18)(17 18)[13 1][13 7]`
    ],
    [门数清点与一次自洽核对],
    [
      - *清点结果*：这条序列含 *75 个 CNOT*、*5 个 SWAP*、*1 个 $H_(18)$*，共 81 个物理门；把 SWAP 折算成 3 个 CNOT，两比特门等于 *90 个 CNOT 当量*。
      - *量级核对*：$d = 3$ 时 90 个 CNOT 当量，若 $N = N_0 d^alpha$ 且取正文 4.2 的化简前指数 $alpha = 2.51$，则 $N_0 = 90 / 3^2.51 approx 5.7$；用它外推到 $d = 11$ 得 $N approx 5.7 times 11^2.51 approx 2300$，与正文 Fig. 4(a) 中"简化前"曲线在 $d = 11$ 处的读数（约 2300）一致。
      - *边界说明*：论文没有说明这条序列属于化简前还是化简后，所以上面只是量级核对；$N_0$ 与 $N$ 都由我们自己反推（清点）。
      - *可以继续挖*：81 个门里有多少是冗余的？把逻辑算符选取与消元顺序一起优化，能否把 $N_0$ 压低？
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页是全场最"实"的一页：81 个门全写出来了。
    讲法：先解释记法与"从后往前"，再给 75 / 5 / 1 的清点，最后用 $N_0$ 外推说明与正文 Fig. 4(a) 自洽。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 Q：双曲码对称群

== 附录 Q：双曲曲面码的对称群：从无限群到有限码

#slide[
  #page-2cards(
    [对称群：保持 $\{r, s\}$ 铺砌的旋转与平移],
    [
      - 保持 $\{r, s\}$ 铺砌的旋转与平移由有限生成群描述：
        $ G^+_(r,s) = chevron.l rho, sigma | rho^r = sigma^s = (rho sigma)^2 = e chevron.r $ <eq:群表示>
        其中 $rho$、$sigma$ 是绕两类不同中心的旋转（在双曲度量下分别是 $2 pi / r$ 与 $2 pi / s$），$e$ 是单位元。
      - 这个群是*无限*的 —— 对应"双曲格点可以无限放大"。要得到有限物理比特数的码，需要*粘合*（gluing）。
      - *群论语言*：取一个*无挠正规子群* $H_(r,s)$（任何非单位元的阶都无限），做商群
        $ G^H_(r,s) = G^+_(r,s) slash H_(r,s) $
        商群把无限的部分吸收掉，剩下有限个元素，对应粘合后的有限格点。
      - *怎么算*：用 Todd–Coxeter 算法，在代数软件 GAP 里实现；$|G|$ 就是商群的元素个数。
    ],
    [群元素的几何含义：稳定子、比特与逻辑比特],
    [
      - 取子群 $G^H_(r,s,rho) = {e, rho, rho^2, dots, rho^(r-1)}$：它对基本三角形 $x$ 的轨道 $G^H_(r,s,rho) x$ 是一个 $r$-边形，正好对应一个 $Z$ 稳定子；$rho$ 的*陪集划分*给出全部 $Z$ 稳定子。
      - 同理，换用生成元 $sigma$ 就得到 $X$ 稳定子（$s$ 个面交于一个顶点）。
      - $G^H_(r,s, rho sigma) = {e, rho sigma}$ 只含两个元素 —— 它给出的正是一条边，即一个*物理比特*。
      - 于是码的三个参数（面和、顶点数、边数）全部由 $|G|$ 决定，这就是下一页两个计数公式的来源。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页给正文 4.4 那些数字（60 / 30 / 24 / 8）一个群论来源：稳定子 = 子群的陪集，比特 = 边 = $rho sigma$ 的陪集。
    一句话总结："双曲码的对称性不是装饰，它就是码的参数表。"
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 R：双曲码计数公式

== 附录 R：双曲码的计数公式与 $\{4, 5\}$ 核对 <sm:hyper>

#slide[
  #page-2cards(
    [把稳定子、比特与逻辑比特数都数出来],
    [
      - 设商群元素个数为 $|G|$。面、顶点、边分别对应 $rho$、$sigma$、$rho sigma$ 的陪集，于是
        $ F = |G| slash r, quad V = |G| slash s, quad E = |G| slash 2 $ <eq:面顶点边>
      - 每个多边形/顶点各有一个冗余稳定子（整体约束），所以
        $ n_Z = F - 1, quad n_X = V - 1, quad n = E $ <eq:计数>
      - 逻辑比特数由 $k = n - n_Z - n_X$ 给出：
        $ k = |G| (1/2 - 1/r - 1/s) + 2 = n (1 - 2/r - 2/s) + 2 $ <eq:逻辑比特数>
      - 由于 $1/r + 1/s < 1/2$，方括号里的系数为正：$k$ 与 $n$ 近似成正比，编码率 $k / n$ 不随规模衰减。
    ],
    [$\{4, 5\}$ 最小实现的一次核对],
    [
      - 取 $\{4, 5\}$：$n = 60$ 个物理比特，每个比特对应 2 个元素（边有两个方向），所以 $|G| = 2 n = 120$。
      - 代入 @eq:面顶点边：$F = 120 slash 4 = 30$、$V = 120 slash 5 = 24$、$E = 120 slash 2 = 60$。
      - 代入 @eq:计数：$n_Z = 30 - 1 = 29$、$n_X = 24 - 1 = 23$（与 Fig. S1 的注记一致），独立稳定子共 52 个，于是 $k = 60 - 52 = 8$。
      - 用 @eq:逻辑比特数 复核：$k = 120 (1/2 - 1/4 - 1/5) + 2 = 120 times 0.05 + 2 = 8$ —— 与正文 4.4 完全一致。
      - *注*：合法的 $n$ 由群 $G^H_(r,s)$ 的结构限制，不是任意整数都能取；这也是"先定群、再算码参数"的原因。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这页把正文 4.4 的参数一次算完：$120 -> 30 / 24 / 60 -> 29 / 23 -> 8$。
    建议现场只算最后一行：$120 times 0.05 + 2 = 8$，最有说服力。
  ]
]

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// 附录 S：SM 与正文的对照

== 附录 S：SM 与正文的对照与阅读路线 <sm:overview>

#slide[
  #page-2cards(
    [SM 小节与本附录的对应关系],
    [
      #light-table(
        (auto, 1.5fr, auto, 1fr),
        ("SM 小节", "内容", "本附录", "对应正文"),
        (
          ([§1.1], [条件的分块形式、自由变量削减、辛条件的拆分与计数、二次方程组], [A–D], [@eq:保辛条件、@eq:码结构；3.2]),
          ([§1.2], [求解流程：向量化、系数矩阵、七类核向量、稀疏特解、二次项匹配], [D–I], [3.2、3.3]),
          ([§2.1], [系数矩阵的条带结构与核空间维数], [G], [3.2 的复杂度讨论]),
          ([§2.2], [$B'$ 前两块为零、消元四步、特解的形状], [H], [3.2 的一致性回代]),
          ([§3], [四个门的 $2 times 2$ / $4 times 4$ 辛矩阵], [J、K], [3.3 的表格]),
          ([§4], [$d = 3$ 环面码：比特编号、一个解、完整门序列], [N–P], [4.1、4.2]),
          ([§5], [双曲码对称群、稳定子与逻辑比特计数], [Q、R], [4.4、4.5]),
        ),
        size: 12pt,
        inset: 5pt,
      )
    ],
    [记号约定与阅读路线],
    [
      - *两个"特解"要分清*：$B$ 是线性条件 @eq:码结构分块 的特解（构造见附录 H：@eq:主元、@eq:特解构造）；$u^b$ 是二次约束线性化后 $A u = B'$ 的特解（Fig. S2、S4，见附录 F、H）。
      - 其余记号：$U^1$ 自由变量；$tilde(U)$ 二次项；$M_Z, L_Z, Gamma_Z, Q$ 见附录 H；$w_q^Z, w_q^X, W^X, C$ 见 @eq:核向量前四类 与 @eq:组合系数。
      - *时间紧的路线*：@app:symp（约束怎么来）$->$ @app:linear（怎么变成线性方程）$->$ @sm:seq（具体门序列）。
      - *要追证明*：先 @sm:proof（条带与秩），再 @sm:kernel（七类核向量），最后 @app:linear 的匹配（附录 I）。
      - 凡是我们自己清点或反推的数字（$d = 7$ 的行列数、$d = 3$ 的 90 个 CNOT 当量、$N_0$）都在文中写明"清点"。
    ],
    tone1: "wash",
    tone2: "plain",
  )
  #speaker-note[
    这一页当目录用：听众问"某个细节在哪"，直接指这张表。
    最后提醒一次分工：正文讲结论与用法，附录 A–I 讲算法与证明，附录 N–P 给完整例子，附录 Q、R 补双曲码的群论来源。
  ]
]
