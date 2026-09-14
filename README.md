# 御伫之的个人网站

<div align="center">

<!-- [简体中文](README.md) | [English](README_en.md) -->

</div>

本网站使用由[Yousa-Mirage](https://github.com/Yousa-Mirage)开发的模板[Tufted-Blog-Template](https://github.com/Yousa-Mirage/Tufted-Blog-Template)构建，这是一个基于 [Typst](https://typst.app/) 和 [Tufted](https://github.com/vsheg/tufted) 的静态网站构建模板。

## 📚 网站内容

待补充

## ✨ 特点

- 🚀 使用 Typst 编写内容，简洁强大，编译极快
- 🎨 基于 Tufte CSS 设计，极简主义、内容至上，提供清晰、沉浸的阅读体验
- 📦 内置基于 Python 的跨平台构建脚本，支持增量编译
- 📝 支持生成 HTML 网页和 PDF 文档，支持链接到 PDF
- 🖼️ 支持把 [Touying](https://github.com/touying-typ/touying) 幻灯片导出为网页演示文稿
- 🌐 内置 GitHub Actions 工作流，一键部署网站
- 🌙 支持浅色/深色模式自动选择和一键切换
- 📄 丰富的示例和文档，无需任何前置知识，[简单学习 Typst](https://github.com/Yousa-Mirage/Tufted-Blog-Template/wiki/Typst-%E5%BF%AB%E9%80%9F%E5%85%A5%E9%97%A8%E8%B5%84%E6%96%99) 后即可开始编写

## 🖼️ 幻灯片（Touying）

`content/` 下使用 Touying 编写的 `.typ` 文件不会被编译成普通网页，而是导出为
自包含的 HTML 演示文稿（impress.js 幻灯片），放在与普通页面相同的路径上。例如
`content/Slides/第一讲/index.typ` 构建后访问 `/Slides/第一讲/` 就是一份可以翻页、
支持演讲者备注的演示文稿。

```typst
#import "@preview/touying:0.6.1": *
#import themes.simple: *

#show: simple-theme.with(aspect-ratio: "16-9")

= 第一节

== 第一页

正文。
```

判定方式是源文件导入了名字含 `touying` 的 Typst 包；也可以在源文件中用
`// build: slides`（强制导出演示文稿）或 `// build: page`（强制作为普通网页）
手动覆盖。导出流程、与上游 touying-exporter 的差异以及模板更新方法见
[touying-exporter/README.md](touying-exporter/README.md)。

幻灯片构建**只使用**仓库 `fonts/` 目录中的字体（当前为 Noto Serif SC）。GitHub
Actions 的运行器没有任何中文字体，如果不自带字体，CI 编译出的中文会变成空心方框；
自带字体同时保证本地与线上得到相同的字形和分页。想换字体就把字体文件放进
`fonts/`，详见 [fonts/README.md](fonts/README.md)。

单独构建演示文稿：

```sh
uv run build.py slides
```

## 📂 项目结构

```plaintext
Tufted-Blog-Template/
├── .github/workflows      # GitHub Actions 自动构建、部署
├── _site/                 # 构建输出目录 (自动生成)
├── assets/                # 静态资源 (CSS、JS、字体、图标等)
│   ├── tufted.css             # 主样式表
│   ├── custom.css             # 自定义样式表（用户可编辑）
│   ├── copy-code.js           # 代码块复制功能
│   ├── line-numbers.js        # 代码行号显示
│   └── format-headings.js     # 标题格式化
├── content/               # 网站内容源文件 (.typ)
│   ├── index.typ               # 网站首页
│   ├── Blog/                   # 博客页
│   ├── CV/                     # 简历页
│   ├── Docs/                   # 编写文档页
│   └── .../                    # 可自行修改或添加其他页面
├── fonts/                 # 构建用字体（不随站点发布，保证 CI 与本地一致）
├── touying-exporter/      # Touying 幻灯片的 HTML 模板 (内置于本仓库)
├── tufted-lib/            # Typst 样式库和功能模块
│   ├── tufted.typ             # 主模板和配置
│   ├── layout.typ             # 页面布局定义
│   ├── math.typ               # 数学公式处理
│   ├── figures.typ            # 图片和图表处理
│   ├── refs.typ               # 参考文献处理
│   └── notes.typ              # 脚注和侧边注处理
├── build.py               # Python 构建脚本
└── config.typ             # 网站全局配置
```

## 🔗 说明

本模板项目基于 [MIT License](https://github.com/Yousa-Mirage/Tufted-Blog-Template/blob/main/LICENSE) 开源。

相关链接：

- [Tufted Typst on GitHub](https://github.com/vsheg/tufted)
- [Typst Universe](https://typst.app/universe/package/tufted)
- [Tufte CSS](https://edwardtufte.github.io/tufte-css/)
- [tufted.vsheg.com](https://tufted.vsheg.com) — Tufted 包作者提供的在线演示网站和简单文档
