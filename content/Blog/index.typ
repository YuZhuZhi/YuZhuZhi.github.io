#import "../index.typ": template, tufted
#show: template.with(
  title: "随笔",
  description: "一些随笔记录",
)

#tufted.full-width[
  #image("../imgs/albion-1.png")
]

= 随笔

// 中文博客样例可参考 #link("https://yousa-mirage.github.io/Blog")[我的个人网站]。

== 2026

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 12),
  path: "2026-06-12-regular/",
  title: "好痛苦",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 10),
  path: "2026-06-10-starting-to-organize-this-website/",
  title: "开始整理这个网站",
)

// == 2025

// #tufted.blog-entry(
//   date: datetime(year: 2025, month: 10, day: 30),
//   path: "2025-10-30-normal-distribution/",
//   title: "Normal Distribution",
// )
// #tufted.blog-entry(
//   date: datetime(year: 2025, month: 4, day: 16),
//   path: "2025-04-16-monkeys-apes",
//   title: "Monkeys vs Apes",
// )

// == 2024

// #tufted.blog-entry(
//   date: "2024-10-04",
//   path: "2024-10-04-iterators-generators/",
//   title: "Iterators vs Generators in Python",
// )
