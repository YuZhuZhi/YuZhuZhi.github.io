# Touying 幻灯片模板（内置于本仓库）

本目录存放 [touying-exporter](https://github.com/touying-typ/touying-exporter) 的 HTML
模板，供 `build.py` 把使用 [Touying](https://github.com/touying-typ/touying) 编写的
`.typ` 文件导出为自包含的 HTML 演示文稿（impress.js 幻灯片）。构建脚本只读取
`template.html.j2`，不依赖上游的 Python 包。

## 为什么不直接使用上游的 Python 包

上游把它做成了一个 Python 包（`pip install touying`），内部通过 `typst-py` 编译，
再用 Jinja2 把逐页 SVG 填进模板。本仓库的选择是：保留上游模板，自己调用命令行
`typst` 完成编译与填充。

| 方案 | 需要引入 | 代价 |
| --- | --- | --- |
| 依赖上游 Python 包 | `typst-py`、`python-pptx`、`pillow`、`jinja2` | 引入第二套 Typst 引擎，`.typ` 只能使用该引擎支持的语法版本；为少数页面给模板项目增加运行时依赖 |
| 内置模板 + 调用已有 `typst` CLI | 无（复用网站本来就需要的 `typst`） | 需要自己维护模板同步与填充逻辑 |

## 内置文件的来源

| 文件 | 来源 | 说明 |
| --- | --- | --- |
| `template.html.j2` | `https://raw.githubusercontent.com/touying-typ/touying-exporter/main/touying/template.html.j2` | 上游 HTML 模板，含 impress.js 2.0.0、演讲者备注与导航插件；未作任何修改 |
| `LICENSE` | 同一仓库 | MIT License，Copyright (c) 2024 OrangeX4 |

2026-09-14 下载时 `template.html.j2` 的大小为 65079 字节，
`sha256 = c0346ac8b6a263b5323114fff765b33f15db0507881ef5efbaa48da6c3855462`。

## 导出流程

`build.py` 中的「幻灯片（Touying）导出」一节实现以下步骤（与上游 `touying compile`
的处理一致）：

1. `typst compile --format svg --input page-path=… <源文件> <临时目录>/page-{p}.svg`
   得到每一页幻灯片；字体在 SVG 中已转为路径，浏览器无需安装字体。
2. 把每页 SVG 顶层的 `width="…pt" height="…pt"` 改为 `width="100%" height="100%"`，
   缩放交给 impress.js。
3. 用 `typst eval "query(<pdfpc-file>).map(it => it.value)"` 读取 Touying 写入
   `<pdfpc-file>` 的演讲者备注；Typst 0.15 以下没有 `eval` 命令时回退到
   `typst query`。
4. 把每页 SVG 里以 data URI 内嵌的位图提取成 `images/embed-*.{png,jpg,gif,…}`
   独立文件（多页复用的同一张只写一份），SVG 中改写成相对路径。
5. 把 SVG 与备注填入模板，写出 `<输出目录>/<页面路径>/index.html`。

字体由 `fonts/`（见 [fonts/README.md](../fonts/README.md)）提供，并加上
`--ignore-system-fonts`：这样同一份 `.typ` 在 CI 的 Linux 与本地 Windows 上会
得到相同的字形与分页。

## 与上游输出的差异

用同一份 `.typ` 分别运行上游 `touying compile` 与本脚本，逐字比较后确认：除下列
差异与空白行外完全一致（每一页内联的 SVG 完全相同）。

- `<title>` 使用页面名（如 `第一讲`），上游固定为 `Touying`；
- 删除上游示例用的 `<meta name="description" content="Simple example touying slide show">`
  与 `<meta name="author" content="OrangeX4">`，避免把示例信息当成网站信息；
- `<html lang>` 取自 `config.typ` 中的 `lang`，上游固定为 `en`；
- 演讲者备注按 HTML 文本转义（上游不转义，备注里的 `<` 会破坏页面）；
- 内嵌位图提取为独立文件。上游把图片以 base64 内嵌在 HTML 中，一份 24 页、含
  插图的演示文稿接近 10 MB，浏览器必须下载完整个文档才会执行文档末尾的
  `impress().init()`；提取后 HTML 约 1 MB，图片可并行加载与缓存。
- 提示条改为「默认隐藏，浏览器确实不支持时才显示」。上游是
  `.impress-supported .fallback-message { display: none }`，也就是在 impress.js
  初始化完成之前（文档越大越久）都会显示那段黄色提示条。

## 在网站中使用

把演示文稿放在 `content/` 下即可，输出路径与普通页面相同。例如
`content/Slides/第一讲/index.typ`：

```typst
#import "@preview/touying:0.6.1": *
#import themes.simple: *

#show: simple-theme.with(
  aspect-ratio: "16-9",
  config-info(title: [第一讲], author: [YuZhuZhi]),
)

= 第一节

== 第一页

正文。

#speaker-note[按 P 键打开演讲者控制台时显示的备注。]
```

构建后访问 `/Slides/第一讲/` 就是演示文稿。要点：

- **判定方式**：源文件导入了名字含 `touying` 的 Typst 包（如
  `@preview/touying:0.6.1`、`@preview/modern-sysu-touying:0.1.0`）即导出为演示文稿；
  代码块（``` 围栏）中的示例代码不会触发判定。
- **手动覆盖**：在源文件中写 `// build: slides` 强制按演示文稿导出（可用于任何分页
  Typst 文档），或写 `// build: page` 强制按普通网页编译。
- **幻灯片操作**：方向键或空格翻页，`P` 打开演讲者控制台（含备注与计时），`B` 黑屏，
  右下角工具栏提供页码跳转。
- **PDF**：文件名中包含 `pdf` 的文件仍然只编译为 PDF（与网页构建规则一致），
  因此 `<名字>-pdf.typ` 可以用于生成可打印版本；若需要，也可以再放一份同内容的
  `index.typ` 供网页演示。
- **依赖**：演示文稿不导入 `config.typ`/`tufted`，它是一份独立的分页文档；
  公式、图片与普通 Typst 文档写法相同，图片照常放在同目录或子目录中。
- **字体**：幻灯片构建忽略系统字体，只使用仓库 `fonts/` 中的字体；需要别的字体时
  把字体文件放进 `fonts/`，不要依赖别人机器上装了什么。

## 更新上游模板

1. 下载新的 `template.html.j2`（覆盖本目录中的同名文件）与 `LICENSE`；
2. 更新本文档中的大小、`sha256` 与下载日期；
3. 运行 `python build.py slides --force`，确认没有出现
   「内置模板结构已变化」或「仍有未处理的模板标记」等报错；
4. 与上游 `touying compile` 的输出比较，确认差异仍只有本文档列出的几项。

模板结构变化（例如幻灯片循环的写法改变）时，`build.py` 会直接报错而不是静默产出
错误的页面，此时需要同步修改 `render_slide_template`。
