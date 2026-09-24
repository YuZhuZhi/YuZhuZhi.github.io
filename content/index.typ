#import "../config.typ": template, butterfly-template, home-template, tufted
#show: home-template

// tufted.margin-note 可以让你在边栏中放置内容
// 宽大的边栏是 tufte 样式的特点，将注释放于其中并与正文并排，便于对照

// 其它页面用 `#import "../index.typ": overline, underline` 复用这两个记号。
// 这里直接指向内建的数学元素：`template-math` 按元素识别它们，遇到就整条公式
// 改用 SVG 导出（MathML 会丢掉横线与下划线，只剩底下的内容）。
#let overline = math.overline
#let underline = math.underline

#tufted.margin-note[
    // #figure(caption: [这是御伫之常用的头像])[#image("imgs/albion.jpg", width: 50%)]
    #image("imgs/albion-avatar.jpg", width: 50%)
]

#tufted.margin-note[
    这是御伫之喜爱与常用的头像
]

#html.hr()

= 御伫之YuZhuZhi 是谁？

根据一些目前可公开的情报，理论上来说，御伫之可能是一个人。

- 学校：#link("https://www.sysu.edu.cn/sysuen/")[中山大学（Sun Yat-sen University）]。
- 兴趣：量子计算、物理、一些代码小玩具。
- 技能：C++、Python、C\#、Typst、LaTeX。 \ （技能等级均为Lv.1/Lv.100）
- 开源：维护若干仓库，内容为课程笔记、课程作业和一些没用的小工具。
- 网页：#text(fill: blue)[#link("https://github.com/YuZhuZhi")[GitHub]]；#text(fill: blue)[#link("https://www.zhihu.com/people/yuzhuzhi")[知乎]]。

#html.hr()

= 本博客有什么内容？

一些科普文章、一些教程、一些笔记、一些代码小玩具、一些其他的东西。
#footnote[此人经常犯一些低级错误，所以有些内容可能不太靠谱，读者请自行甄别。]

#tufted.remark[看板娘小提示][
    - 阅读中遇见不明觉厉的词？轻轻*拖选*一下呐 \~ *链接*什么的，人家早就准备好啦！\ 请在对话框中查收喔！
    - 那个……小声说一句喔 \~ 现在 Typst 的 HTML 导出还不太完美，尤其*数学公式*\ 容易抽风#footnote[例如 $overline(x)$ 、 $underline(x)$ 导出为 MathML 时上横线与下划线会丢失，因此含这两个记号的公式改用 SVG 图片导出。]，可能会让您看得有点费劲…… 真的很抱歉啦，求轻拍！(＞＜)
    - 找不到我？请多加载一会，或尝试刷新页面或清理浏览器缓存喔！
]

#html.hr()

// = 代表作

// - #link("https://www.bilibili.com/video/BV1b7411H7t7/?spm_id_from=333.1387.0.0&vd_source=9f0989cf46e495ed836dd439540db3ca")[当广东北江实验学校Minecraft化！]

// #html.hr()

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
    #image("imgs/albion-bottom.jpg") \
    _--梦中、她起舞翩翩。月光薄纱轻笼，足尖掠过水面，漾开银白的涟漪一片。_\
    _恍惚间、都散却。只余零落蹁跹的蝴蝶几点。--_
]

