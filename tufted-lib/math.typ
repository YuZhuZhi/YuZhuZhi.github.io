// ─────────────────────────────────────────────────────────────────────────────
// 公式的 HTML 导出策略
//
// Typst 0.15 起，HTML 导出默认把数学写成原生 MathML。但 MathML 导出会忽略少数
// 数学元素（编译时给出 `warning: <元素> was ignored during MathML export`），
// 元素本身不会出现在输出里，公式只剩下公共部分：
//
//   $overline(x)$ => <math><mi>x</mi></math>   横线丢失
//   $underline(x)$ => <math><mi>x</mi></math>  下划线丢失
//   $cancel(x)$ => <math><mi>x</mi></math>     取消线丢失
//
// 因此含这些元素的公式改用 SVG 导出（即 0.15 之前的行为），其余公式保持
// MathML。判断依据是内容树中的元素，所以别名与自定义函数同样会被识别，见
// `contains-svg-only-element`。
// ─────────────────────────────────────────────────────────────────────────────

#let svg-only-elements = (math.overline, math.underline, math.cancel)

/// 判断数学内容里是否含有 `svg-only-elements` 中的元素。
///
/// 只看内容树中的元素，不检查源码文本，因此下面三种写法都会得到相同结果：
/// - 直接调用：`$overline(x)$`
/// - 别名：`#let ov = math.overline`，`$ov(x)$`
/// - 自定义函数：`#let close(x) = $overline(#x)$`，`$close(x)$`
///
/// 参数:
///   body: 待检查的内容，可以是任意类型（非内容直接返回 `false`）
///
/// 返回:
///   bool: 是否含有需要按 SVG 导出的元素
#let contains-svg-only-element(body) = {
  if type(body) == content {
    if body.func() in svg-only-elements { return true }
    for (_, value) in body.fields() {
      if contains-svg-only-element(value) { return true }
    }
  } else if type(body) == array {
    // 数组与字典都要逐层深入：`math.mat` 的行列就是「数组套数组」。
    for item in body {
      if contains-svg-only-element(item) { return true }
    }
  } else if type(body) == dictionary {
    for (_, value) in body {
      if contains-svg-only-element(value) { return true }
    }
  }

  false
}

/// 该公式是否需要按 SVG 导出。
///
/// 0.15 之前 HTML 导出的数学本来就是 SVG，保持原样；0.15 起只在 MathML 会丢
/// 失元素时才回退到 SVG。
///
/// 参数:
///   it: 数学公式元素
///
/// 返回:
///   bool: 是否按 SVG 导出
#let needs-svg-export(it) = {
  sys.version < version(0, 15, 0) or contains-svg-only-element(it.body)
}

#let template-math(content) = {
  set math.equation(numbering: "(1)")

  let html-math(it) = if sys.version < version(0, 15, 0) {
    html.frame(it)
  } else if contains-svg-only-element(it.body) {
    // 重新构造一份去掉编号的公式再渲染：HTML 导出目前不输出公式编号，若沿用
    // 带编号的公式，编号会被一并画进 SVG，与其余公式不一致。
    html.frame(math.equation(it.body, block: it.block, numbering: none))
  } else {
    it
  }

  // `math-svg` 标记按 SVG 导出的公式，供样式与复制脚本区分。
  let math-class(base, it) = if needs-svg-export(it) { base + " math-svg" } else { base }

  // 注意：`html-math(it)` 必须整体套在 `html.span` / `html.figure` 里再返回。
  // 重组出的公式会再次进入这两条 show 规则，若直接以 `html.frame(...)` 作为规则
  // 的结果，Typst 会报 `maximum show rule depth exceeded`。
  show math.equation.where(block: false): it => {
    if target() == "html" {
      html.span(class: math-class("math-inline", it), role: "math", html-math(it))
    } else {
      it
    }
  }

  show math.equation.where(block: true): it => {
    if target() == "html" {
      html.figure(class: math-class("math-block", it), role: "math", html-math(it))
    } else {
      it
    }
  }

  content
}
