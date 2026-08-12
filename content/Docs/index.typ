#import "../index.typ": template, butterfly-template, tufted
#show: butterfly-template.with(
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
  #html.elem("input", attrs: (class: "docs-tab-input", type: "radio", name: "docs-tab", id: "docs-tab-computer"), "")
  #html.elem("input", attrs: (class: "docs-tab-input", type: "radio", name: "docs-tab", id: "docs-tab-essay"), "")

  #html.elem(
    "div",
    attrs: (class: "docs-tab-buttons", role: "tablist", aria-label: "文章分类"),
  )[
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-quantum", role: "tab"))[量子计算]
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-math", role: "tab"))[数学]
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-physics", role: "tab"))[物理]
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-computer", role: "tab"))[计算机]
    #html.elem("label", attrs: (class: "docs-tab-button", "for": "docs-tab-essay", role: "tab"))[杂文]
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-quantum"))[
    = 量子算法

    + #link("量子计算/前置知识/")[前置知识]
    + #link("量子计算/量子态与量子门/")[量子态与量子门]
    + #link("量子计算/布洛赫球/")[布洛赫球]
    + #link("量子计算/超密编码与量子隐形传态/")[超密编码与量子隐形传态]
    + #link("量子计算/Deutsch-Jozsa算法与Simon算法/")[Deutsch-Jozsa算法与Simon算法]
    + #link("量子计算/量子傅里叶变换与相位估计/")[量子傅里叶变换与相位估计]
    + #link("量子计算/振幅放大与振幅估计/")[振幅放大与振幅估计]
    + #link("量子计算/QAOA量子近似优化算法/")[QAOA量子近似优化算法]
    + #link("量子计算/BB84协议/")[BB84协议]
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-math"))[
    = *高等数学*

    = *线性代数*

    = *概率论与数理统计*
      + #link("数学/概率论/概率论(一)——一维随机变量的分布、期望与方差/")[一维随机变量的分布、期望与方差]
      + #link("数学/概率论/概率论(二)——二维随机变量/")[二维随机变量]
      + #link("数学/概率论/概率论(三)——大数定律与中心极限定理/")[大数定律与中心极限定理]
      + #link("数学/概率论/概率论(四)——抽样分布/")[抽样分布]
      + #link("数学/概率论/概率论(五)——参数估计/")[参数估计]
      + #link("数学/概率论/概率论(六)——假设检验/")[假设检验]

    = *信号与系统*
      + #link("数学/信号系统/简单信号与系统的性质")[简单信号与系统的性质]
      + #link("数学/信号系统/单位冲激函数与卷积")[单位冲激函数与卷积]
      + #link("数学/信号系统/连续时间傅里叶")[连续时间傅里叶]
      + #link("数学/信号系统/离散时间傅里叶")[离散时间傅里叶]
      + #link("数学/信号系统/拉普拉斯变换")[拉普拉斯变换]
      + #link("数学/信号系统/Z变换")[Z变换]
      + #link("数学/信号系统/积分变换与微分方程")[积分变换与微分方程]
      + #link("数学/信号系统/滤波，采样与调制")[滤波，采样与调制]

    = *离散数学*
      + #link("数学/离散数学/命题，逻辑公式与推理论证")[命题，逻辑公式与推理论证]
      + #link("数学/离散数学/一阶逻辑")[一阶逻辑]
      + #link("数学/离散数学/集合与计数")[集合与计数]
      + #link("数学/离散数学/关系")[关系]
      + #link("数学/离散数学/函数")[函数]
      + #link("数学/离散数学/排列组合与数列递推")[排列组合与数列递推]
      + #link("数学/离散数学/代数系统")[代数系统]
      + #link("数学/离散数学/图和树")[图和树]
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-physics"))[
    = 力学
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-computer"))[
    = *计算机图形学 · 光线追踪（基于 Rust 的路径追踪）*
      + #link("计算机/计算机图形学/光线追踪（一）——射线与摄像机/")[射线与摄像机]
      + #link("计算机/计算机图形学/光线追踪（二）——球体、材质与景深/")[球体、材质与景深]
      + #link("计算机/计算机图形学/光线追踪（三）——BVH加速结构/")[BVH 加速结构]
      + #link("计算机/计算机图形学/光线追踪（四）——运动模糊与纹理映射/")[运动模糊与纹理映射]
      + #link("计算机/计算机图形学/光线追踪（五）——四边形与光源/")[四边形与光源]
  ]

  #html.elem("section", attrs: (class: "docs-tab-panel docs-tab-panel-essay"))[
    = 杂文
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
