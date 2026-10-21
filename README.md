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

## ⚠️ 已知限制：公式里的上划线/下划线

Typst 的 HTML 导出（截至 0.15.1）会**丢弃** `math.overline`、`math.underline` 和
`math.cancel`：`$overline(x)$`、`$x$`、`$underline(x)$` 导出的 MathML 完全相同
（`<math><mi>𝑥</mi></math>`），所以网页上看不出线的存在，随后也没有任何 CSS/JS
可以补救。上游 issue：[typst/typst#8509](https://github.com/typst/typst/issues/8509)。

相对地，`hat`、`tilde`、`dot`、`arrow`、`accent(...)`、`overbrace(...)` 都能正常
导出为 `<mover>`。经浏览器实测可用的替代写法：

| 写法 | 结果 |
| --- | --- |
| `$accent(alpha, macron)$` | ✅ 单个符号的上划线正常显示（建议用于共轭等） |
| `$overbrace(A B C)$` | ✅ 会随内容拉伸，但形状是花括号而非直线 |
| `$accent(A B C, macron)$` | ⚠️ 横线不拉伸，只盖住中间一小段 |
| `#overline[$A B C$]` | ❌ 浏览器不会绘制（span 里只有 `<math>` 时不画装饰线） |
| `$underline(x)$` | ❌ 与 `overline` 一样被丢弃，且暂无等价写法 |

演示文稿（导出为 SVG）不受影响，那里仍是 Typst 的排版结果。

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

## 双平台部署（GitHub Pages + EdgeOne Pages / Makers）

两端使用同一套源码和 `uv run build.py build -f`，发布 `_site/`：

- `.github/workflows/deploy.yml` 保留 GitHub Pages 部署，访问 `https://yuzhuzhi.github.io/`。
- `.github/workflows/edgeone.yml` 在推送 `main` 或手动运行时独立构建并发布 EdgeOne，访问 `https://yuzhuzhi.cn/`。失败不会阻止 GitHub Pages 工作流。
- `config.typ` 的 `website-url` 统一为 `https://yuzhuzhi.cn/`，用于 Canonical、Open Graph、Sitemap、RSS 和 robots.txt；不会把镜像站访客重定向到该域名。普通导航、样式、脚本和模型使用相对或根相对路径。`build.py` 为未经过网站 HTML 模板的 Touying 演示文稿补充相同规则的 Canonical。

### 首次配置

1. 登录腾讯云 EdgeOne Pages（新文档称 Makers），选择**直接上传**类型创建静态网站项目，例如 `yuzhuzhi`。不要选择 Git 仓库自动构建：Typst 构建在 GitHub Actions 中完成，云端接收 `_site/`，无需另设云端构建命令、框架或 Python/Typst 环境。已有项目也必须是直接上传类型。
2. 确认项目加速区域：`global` 为全球，`overseas` 为海外；以控制台实际项目为准。使用包含中国大陆的区域时，按控制台要求完成域名 ICP 备案。
3. 在同一账号的 Makers 控制台 **API Token** 页创建 Token，设置合适的有效期。需要能向目标直接上传项目发布生产部署；不要使用腾讯云账户的 SecretId / SecretKey 代替，也不要提交 Token。官方 Token 文档目前只列出描述和有效期，没有可单独配置的项目权限范围；若控制台新增权限选项，仅授予目标项目部署所需权限。
4. 在 GitHub 仓库 **Settings → Secrets and variables → Actions** 配置：

   | 类型 | 名称 | 值 |
   | --- | --- | --- |
   | Secret | `EDGEONE_API_TOKEN` | 上一步创建的 Makers API Token |
   | Variable | `EDGEONE_PROJECT_NAME` | 控制台中准确的项目名称，例如 `yuzhuzhi` |
   | Variable | `EDGEONE_AREA` | 与项目一致的 `global` 或 `overseas` |

   项目名和区域必须显式填写，避免默认值误部署到其他项目。CLI 在项目名不存在时可能创建新项目，运行前请核对名称。
5. 在 Actions 中手动运行 **Deploy EdgeOne**，确认生产部署成功。可先通过控制台提供的预览地址检查资源；若测试域名有访问限制，以控制台说明为准。
6. 在 EdgeOne 项目的自定义域名中添加 `yuzhuzhi.cn`，按提示完成域名所有权验证、DNS 配置并申请或绑定 HTTPS 证书。不要配置跨域重定向规则。

### DNSPod 配置

域名注册完成不等于解析已生效。在 DNSPod 的 `yuzhuzhi.cn` 解析页，按 EdgeOne **该项目自定义域名页面**给出的内容添加记录：

| 主机记录 | 类型 | 记录值来源 |
| --- | --- | --- |
| `@` | `CNAME` | EdgeOne 为 `yuzhuzhi.cn` 分配的 CNAME 目标，只填主机名，不带 `https://` 或路径 |
| 控制台指定的验证主机记录 | `TXT` / `CNAME`（若要求） | EdgeOne 域名所有权验证或证书验证页面给出的准确类型和值 |

不要猜测 CNAME 目标，也不要指向 `yuzhuzhi.github.io`。如果同名已有冲突的 A / AAAA / CNAME 记录，先确认用途再按 DNSPod 提示处理。只有要启用 `www.yuzhuzhi.cn` 时才另行在 EdgeOne 绑定 `www` 并添加对应记录。本工作流不会修改 DNS。

GitHub 仓库 **Settings → Pages** 继续使用 GitHub Actions，Custom domain 保持空白，不添加 `CNAME` 文件，以保留 `yuzhuzhi.github.io` 的独立访问。

### EdgeOne HTML 浏览器缓存

`edgeone.json` 为首页 `/`、以 `/` 结尾的目录 URL（如 `/Docs/` 和文章目录）以及 `.html` URL 设置 `Cache-Control: public, max-age=600, must-revalidate`。浏览器在 10 分钟内可直接复用 HTML，过期后重新验证；新部署不能主动清除访客浏览器内的缓存，因此旧页面最多可能保留 10 分钟。CSS、JavaScript、图片、RSS 等文件 URL 不匹配这些规则，继续采用平台原有策略。

EdgeOne 工作流在构建后把配置复制到 `_site/edgeone.json`，确保直接上传时包含规则；GitHub Pages 工作流不复制此配置。更新配置后需重新发布 EdgeOne 才会在线生效。规则语法依据[官方 edgeone.json 文档](https://edgeone.ai/document/162316940304400384)和[缓存说明](https://edgeone.ai/document/180002216702672896)。

部署后在 Edge DevTools Network 中保持 **Disable cache 未勾选**，先访问 `/Docs/`，进入文章，再点击页眉“文章”返回目录。检查初次响应头包含 `max-age=600`，随后 10 分钟内返回目录应显示内存或磁盘缓存，而不是每次联网收到 `304`。浏览器后退若命中 BFCache，可能完全没有新 Document 请求，需要与普通导航分别判断。

### 验证

- 推送 `main` 后，在 Actions 确认 **Deploy** 和 **Deploy EdgeOne** 分别成功，并在 EdgeOne 控制台确认此次生产部署。
- 分别访问两个 HTTPS 域名的首页、`/Docs/`、深层文章及 Touying 演示文稿；检查数学公式、图片、样式、脚本、搜索和 Live2D。刷新深层路径后仍应正常，地址栏应保持原域名。Live2D Cubism Core、部分 CDN 样式等原有外部服务仍依赖网络可达性。
- 用浏览器 Network 或 `curl -I https://yuzhuzhi.github.io/`、`curl -I https://yuzhuzhi.cn/` 检查首页没有跳往另一域名的 `Location`；Canonical 指向新域名属于元数据，不是 HTTP 跳转。
- 两端 `/sitemap.xml`、`/robots.txt`、`/feed.xml` 和页面 Canonical 都应使用 `https://yuzhuzhi.cn/`。现有未使用网站模板的辅助文档和代码展示页未输出 Canonical；本次保留其原有内容。
- 本地执行 `uv run build.py build -f` 检查退出码。当前内容有 2 份 Touying 幻灯片，没有文件名含 `pdf` 的 Typst 源文件或现成 PDF，因此当前构建不产出 PDF；日后添加 PDF 内容后还需验证两端对应文件链接。

CLI 于 2026-10-21 核实：固定使用 `edgeone@1.6.44 makers deploy ./_site --name … --env production --area … --token … --skip-ai-gateway-sync`。`pages` 是已弃用的兼容别名；`--skip-ai-gateway-sync` 关闭本静态网站不需要的 AI Gateway 同步。`EDGEONE_API_TOKEN` 由工作流传给 `--token`，不依赖 CLI 自动读取此变量。

官方资料：[EdgeOne CLI](https://edgeone.ai/document/162228053922476032)、[API Token](https://edgeone.ai/document/177158578324279296)。本地构建成功不能证明云端部署、DNS、HTTPS 或外部资源加载成功，完成首次配置后仍需执行以上远程验收。

## 🔗 说明

本模板项目基于 [MIT License](https://github.com/Yousa-Mirage/Tufted-Blog-Template/blob/main/LICENSE) 开源。

相关链接：

- [Tufted Typst on GitHub](https://github.com/vsheg/tufted)
- [Typst Universe](https://typst.app/universe/package/tufted)
- [Tufte CSS](https://edwardtufte.github.io/tufte-css/)
- [tufted.vsheg.com](https://tufted.vsheg.com) — Tufted 包作者提供的在线演示网站和简单文档
