#import "tufted-lib/tufted.typ" as tufted

// 各扩展使用独立缓存键；只在对应资源发生变化时递增。
#let site-css = (
  "/assets/site-extensions.css",
  "/assets/custom.css",
  "/assets/code-theme-one-dark-pro.css?v=1",
  "/assets/vendor/live2d-widget/waifu.css",
  "/assets/live2d-widget.css?v=3",
  "/assets/cursor-glow.css?v=20260730-13",
)

#let site-js = (
  "/assets/live2d-widget.js?v=12",
  "/assets/cursor-glow.js?v=20260730-13",
)

/// 在 `config.typ` 中配置全局模板配置 template
/// 之后的每个页面都会从上个页面导入这个模板函数
/// 在每个具体页面中，都可以通过 `#show: template` 来应用模板
/// 也可以通过 `template.with(...)` 来覆盖某些配置项，从而为某个页面定制参数
#let template = tufted.tufted-web.with(
  /// 网站顶部导航栏的链接字典。格式为 `("链接地址": "显示名称")`。
  // 例如，如果你想添加一个 Entry 页，你需要添加 `"/Entry/": "Entry"`
  // 然后在 `content/` 路径中新建 `Entry/`路径，在其中添加 `index.typ` 作为 Entry 页的内容
  header-links: (
    "/": "首页",
    "/Docs/": "文章",
    "/Blog/": "随笔",
  ),

  /// 站点扩展样式，与上游模板样式分离。
  css: site-css,
  js-scripts: site-js,
  
  /// 网站的站点标题。会显示在浏览器标签页以及 SEO/社交分享卡片中。
  website-title: "不认识御伫之？很正常！",
  /// 网站作者。用于生成 <meta name="author"> 标签。（可选）
  author: "@YuZhuZhi",
  /// 网站描述。用于 SEO 搜索引擎摘要和社交媒体分享预览。（可选）
  description: "YuZhuZhi 的个人博客，记录生活与学习点滴",
  /// 站点的根 URL (例如 "https://example.com")。用于生成 Canonical URL 元数据。（可选）
  website-url: "https://YuZhuZhi.github.io/",
  /// 网站的默认语言，例如 "zh" 或 "en"，默认为 "zh"。
  lang: "zh",
  /// 订阅源配置 (字符串数组)，指定包含在 RSS 订阅源中的内容目录列表。（可选）
  /// 例如，`("/Blog/",)` 会将 `Blog` 目录下的所有文章包含在订阅源中。
  feed-dir: ("/Blog/",),
  
  /// 自定义页眉元素列表 (content 数组)。显示在页面顶部。
  header-elements: (
    [Ciallo～(∠・ω< )⌒☆],
    [今天又被谁偷瞄了呢(\*╹▽╹\*)],
  ),
  /// 自定义页脚元素列表 (content 数组)，显示在页面底部。
  footer-elements: (
    "© 2026 YuZhuZhi",
    [梦里寻她千百度],
  ),
)

/// 仅供首页、文章列表和随笔列表使用的蝴蝶特效模板。
#let butterfly-template = template.with(
  css: site-css + ("/assets/home-butterflies.css?v=20260730-2",),
  js-scripts: site-js + ("/assets/home-butterflies.js?v=20260730-2",),
)

/// 首页额外显示累计浏览次数。Komarev 提供的是图片徽章，适合静态站点直接使用。
#let home-template = butterfly-template.with(
  footer-elements: (
    [© 2026 YuZhuZhi · #html.img(
      src: "https://komarev.com/ghpvc/?username=YuZhuZhi-site&label=Views&color=3884ff&style=flat",
      alt: "Website views",
      class: "site-view-counter",
      loading: "lazy",
      decoding: "async",
    )],
    [梦里寻她千百度],
  ),
)

// 更多参数可参考网站配置文档。
