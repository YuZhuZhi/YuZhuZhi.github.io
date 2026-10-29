#let theorem-counter = counter("tufted-theorem")
#let corollary-counter = counter("tufted-corollary")
#let remark-counter = counter("tufted-remark")
#let definition-counter = counter("tufted-definition")
#let lemma-counter = counter("tufted-lemma")
#let proposition-counter = counter("tufted-proposition")
#let problem-counter = counter("tufted-problem")

#let reset-theorems() = {
  theorem-counter.update(0)
  corollary-counter.update(0)
  remark-counter.update(0)
  definition-counter.update(0)
  lemma-counter.update(0)
  proposition-counter.update(0)
  problem-counter.update(0)
}

// Paper-sized counterpart of the theorem cards in assets/site-extensions.css.
#let pdf-environment(heading, body, accent, background, font: "KaiTi") = {
  let content = [
    #text(fill: accent, weight: "bold")[#heading]

    #body
  ]
  if font != none {
    content = text(font: font, content)
  }
  block(
    width: 100%,
    breakable: true,
    fill: background,
    stroke: (left: 2.5pt + accent),
    radius: 5pt,
    inset: (left: 11pt, right: 10pt, top: 8pt, bottom: 9pt),
    above: 1em,
    below: 1em,
    content,
  )
}

#let theorem(title, body, name: [定理], label: none) = context {
  let number = theorem-counter.get().first() + 1
  theorem-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-theorem",
      {
        html.div(
          class: "tufted-theorem-heading",
          {
            [#name #number.]
            if title != [] {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-theorem-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-theorem", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-theorem", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != [] { [（#title）] }], body, rgb("#b91c1c"), rgb("#f5eeee"))
    if label != none { [#figure(kind: "tufted-theorem", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

#let corollary(title, body, name: [推论], label: none) = context {
  let number = corollary-counter.get().first() + 1
  corollary-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-corollary",
      {
        html.div(
          class: "tufted-corollary-heading",
          {
            [#name #number.]
            if title != [] {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-corollary-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-corollary", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-corollary", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != [] { [（#title）] }], body, rgb("#a21caf"), rgb("#f4eff5"))
    if label != none { [#figure(kind: "tufted-corollary", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

#let remark(title, body, name: [注], label: none) = context {
  let number = remark-counter.get().first() + 1
  remark-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-remark",
      {
        html.div(
          class: "tufted-remark-heading",
          {
            [#name #number.]
            if title != [] {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-remark-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-remark", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-remark", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != [] { [（#title）] }], body, rgb("#118d8d"), rgb("#eff5f5"), font: none)
    if label != none { [#figure(kind: "tufted-remark", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

#let definition(title, body, name: [定义], label: none) = context {
  let number = definition-counter.get().first() + 1
  definition-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-definition",
      {
        html.div(
          class: "tufted-definition-heading",
          {
            [#name #number.]
            if title != [] {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-definition-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-definition", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-definition", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != [] { [（#title）] }], body, rgb("#c2410c"), rgb("#f5f0ed"))
    if label != none { [#figure(kind: "tufted-definition", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

#let lemma(title, body, name: [引理], label: none) = context {
  let number = lemma-counter.get().first() + 1
  lemma-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-lemma",
      {
        html.div(
          class: "tufted-lemma-heading",
          {
            [#name #number.]
            if title != [] {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-lemma-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-lemma", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-lemma", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != [] { [（#title）] }], body, rgb("#0f766e"), rgb("#eef4f3"))
    if label != none { [#figure(kind: "tufted-lemma", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

#let proposition(title, body, name: [命题], label: none) = context {
  let number = proposition-counter.get().first() + 1
  proposition-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-proposition",
      {
        html.div(
          class: "tufted-proposition-heading",
          {
            [#name #number.]
            if title != [] {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-proposition-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-proposition", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-proposition", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != [] { [（#title）] }], body, rgb("#2563eb"), rgb("#f1f3f8"))
    if label != none { [#figure(kind: "tufted-proposition", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

// 题目（习题）环境：正文优先，便于直接书写 `#tufted.problem[题目内容]`；
// 如需在编号后附加小标题，使用命名参数 `title: [标题]`。
#let problem(body, title: none, name: [题目], label: none) = context {
  let number = problem-counter.get().first() + 1
  problem-counter.step()

  if target() == "html" {
    let html-body = html.div(
      class: "tufted-problem",
      {
        html.div(
          class: "tufted-problem-heading",
          {
            [#name #number.]
            if title != none {
              [（#title）]
            }
          },
        )
        html.div(class: "tufted-problem-body", body)
      },
    )
    if label != none {
      [#figure(kind: "tufted-problem", supplement: name, caption: none)[#html-body] #label]
    } else {
      figure(kind: "tufted-problem", supplement: name, caption: none)[#html-body]
    }
  } else {
    let pdf-body = pdf-environment([#name #number.#if title != none { [（#title）] }], body, rgb("#7c3aed"), rgb("#f2f0f8"))
    if label != none { [#figure(kind: "tufted-problem", supplement: name, caption: none)[#pdf-body] #label] } else { pdf-body }
  }
}

#let proof(body, title: [证明]) = context {
  if target() == "html" {
    html.div(
      class: "tufted-proof",
      {
        html.div(
          class: "tufted-proof-body",
          {
            html.span(class: "tufted-proof-heading", [#title. ])
            body
          },
        )
        html.div(class: "tufted-proof-qed", [$square.stroked$])
      },
    )
  } else {
    pdf-environment(
      [#title.],
      [#body #align(right)[$square.stroked$]],
      rgb("#6b7280"),
      rgb("#f8f8f8"),
      font: none,
    )
  }
}
