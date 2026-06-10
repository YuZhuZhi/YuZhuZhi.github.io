#import "../index.typ": template, tufted
#import "@preview/lilaq:0.6.0" as lq
// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "开始整理这个网站",
  description: "没什么好描述的",
  date: datetime(year: 2026, month: 6, day: 10),
  lang: "cn",
)

= 这是标题

这是正文内容。自2026年6月10日起，开始整理这个网站。以后会在这里发布一些东西，但目前以整理以前的资料为主。#footnote[主要是要将以前写的Markdown格式的文章重写为Typst格式]
