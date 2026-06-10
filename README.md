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
- 🌐 内置 GitHub Actions 工作流，一键部署网站
- 🌙 支持浅色/深色模式自动选择和一键切换
- 📄 丰富的示例和文档，无需任何前置知识，[简单学习 Typst](https://github.com/Yousa-Mirage/Tufted-Blog-Template/wiki/Typst-%E5%BF%AB%E9%80%9F%E5%85%A5%E9%97%A8%E8%B5%84%E6%96%99) 后即可开始编写

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
