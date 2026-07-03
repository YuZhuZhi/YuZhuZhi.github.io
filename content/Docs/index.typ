#import "../index.typ": template, tufted
#show: template.with(
  title: "文章列表",
  description: "一些科普文章、一些教程、一些笔记",
)

// #tufted.full-width[
//   #image("../imgs/albion-2.png")
//   _--霜天夜雨落花残，墨色浮生总孑然。寒尽春生始流转，万千思缕剪不断。\
//   她笑语盈盈：且莫叹。回首我处，为君灯火阑珊。--_
// ]

#html.elem(
  "div",
  attrs: (class: "docs-tabs"),
)[
  #html.elem("input", attrs: (class: "docs-tab-input", type: "radio", name: "docs-tab", id: "docs-tab-quantum", checked: "checked"), "")
  #html.elem("input", attrs: (class: "docs-tab-input", type: "radio", name: "docs-tab", id: "docs-tab-math"), "")
  #html.elem("input", attrs: (class: "docs-tab-input", type: "radio", name: "docs-tab", id: "docs-tab-physics"), "")

  #html.elem(
    "div",
    attrs: (class: "docs-tab-buttons", role: "tablist", aria-label: "文章分类"),
  )[
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-quantum", role: "tab"))[量子计算]
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-math", role: "tab"))[数学]
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-physics", role: "tab"))[物理]
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-quantum"))[
    = 量子计算

    + #link("量子计算/前置知识/")[前置知识]
    + #link("量子计算/量子态与量子门/")[量子态与量子门]
    + #link("量子计算/布洛赫球/")[布洛赫球]
    + #link("量子计算/超密编码与量子隐形传态/")[超密编码与量子隐形传态]
    + #link("量子计算/Deutsch-Jozsa算法与Simon算法/")[Deutsch-Jozsa算法与Simon算法]
    + #link("量子计算/量子傅里叶变换与相位估计/")[量子傅里叶变换与相位估计]
    + #link("量子计算/振幅放大与振幅估计/")[振幅放大与振幅估计]
    + #link("量子计算/QAOA量子近似优化算法/")[QAOA量子近似优化算法]
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-math"))[
    = 数学

    - 高等数学

    - 线性代数

    - 概率论与数理统计

    - 信号与系统
      + #link("数学/信号系统/简单信号与系统的性质")[简单信号与系统的性质]
      + #link("数学/信号系统/单位冲激函数与卷积")[单位冲激函数与卷积]
      + #link("数学/信号系统/连续时间傅里叶")[连续时间傅里叶]
      + #link("数学/信号系统/离散时间傅里叶")[离散时间傅里叶]
      + #link("数学/信号系统/拉普拉斯变换")[拉普拉斯变换]
      + #link("数学/信号系统/Z变换")[Z变换]
      + #link("数学/信号系统/积分变换与微分方程")[积分变换与微分方程]
      + #link("数学/信号系统/滤波，采样与调制")[滤波，采样与调制]

    - 离散数学
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-physics"))[
    = 物理
  ]
]

#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()
#html.br()

#tufted.full-width[
  #image("../imgs/albion-5.jpg") \
  _--霜天夜雨落花残，墨色浮生总孑然。寒尽春来始流转，万千思缕剪不断。\
  她笑语盈盈：且莫叹。回首我处，为君灯火阑珊。--_
]

