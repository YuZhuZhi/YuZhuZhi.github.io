#import "../index.typ": template, tufted

#show: template.with(
  title: "替换网站看板娘计划",
  description: "",
  date: datetime(year: 2026, month: 8, day: 1),
  lang: "cn",
)

= 替换网站看板娘计划

在完成了 #link("../2026-07-30-enhance-visual-appearance/")[大幅提升网页视觉效果] 中，我对网站的整体视觉效果进行了大幅度的修改。尤其是引入了*看板娘*。不过眼尖的读者一定有发现，该看板娘并不符合本网站的设计元素风格，因此决定实施替换。

但是，替换看板娘不是一件简单的事，毕竟现在不再能使用已有的开源模型了——也就是说，我必须重头开始做一个 Live2D 模型。

这便涉及到以下几个步骤：
+ 首先，完成角色的原画设计。
+ 完成原画的分层拆分。
+ 使用 Live2D Cubism 进行建模。

当然，这三大步只是一个极其粗略的概括，实际上每一步都包含了大量的细节工作。当前，我已完成原画设计的分层拆分，接下来便是使用 Live2D Cubism 进行建模了。

#tufted.remark[][
  我使用了 #link("https://github.com/shitagaki-lab/see-through")[See-through] @See-through 进行原画的分层拆分。该工具可以将一张原画自动拆分为至多 23 个图层。虽然对制作 Live2D 模型来说 23 个图层是远不够的，且拆分也并不很完美，但对于一个门外汉来说，已经达到了相当惊艳的效果，为我节省了极大的工作量。非常感谢该工具的作者们！
]

#tufted.remark[][
  使用 See-through @See-through 完成初步拆分之后，我对其中的图层进行了手动的修正、补充和进一步拆分。目前，应当是足以开始 Live2D Cubism 的建模工作了。
]

#tufted.remark[][
  不过，目前 Live2D 没有相关自动化流程，因此必须学习之后进行手动建模。希望不久的将来可以完成初步建模并替换掉现有的看板娘。
]

#figure()[
  #image("albion-cudism.png")
]

#bibliography("reference.bib", style: "ieee")
