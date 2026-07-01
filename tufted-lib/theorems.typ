#let theorem-counter = counter("tufted-theorem")
#let corollary-counter = counter("tufted-corollary")
#let remark-counter = counter("tufted-remark")
#let definition-counter = counter("tufted-definition")
#let lemma-counter = counter("tufted-lemma")
#let proposition-counter = counter("tufted-proposition")

#let reset-theorems() = {
  theorem-counter.update(0)
  corollary-counter.update(0)
  remark-counter.update(0)
  definition-counter.update(0)
  lemma-counter.update(0)
  proposition-counter.update(0)
}

#let theorem(title, body, name: [定理]) = context {
  let number = theorem-counter.get().first() + 1
  theorem-counter.step()

  if target() == "html" {
    html.div(
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
  } else {
    block[
      #set text(font: "KaiTi")
      *#name #number.#if title != [] { [（#title）] }*
      #body
    ]
  }
}

#let corollary(title, body, name: [推论]) = context {
  let number = corollary-counter.get().first() + 1
  corollary-counter.step()

  if target() == "html" {
    html.div(
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
  } else {
    block[
      #set text(font: "KaiTi")
      *#name #number.#if title != [] { [（#title）] }*
      #body
    ]
  }
}

#let remark(title, body, name: [注]) = context {
  let number = remark-counter.get().first() + 1
  remark-counter.step()

  if target() == "html" {
    html.div(
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
  } else {
    block[
      #set text(font: "KaiTi")
      *#name #number.#if title != [] { [（#title）] }*
      #body
    ]
  }
}

#let definition(title, body, name: [定义]) = context {
  let number = definition-counter.get().first() + 1
  definition-counter.step()

  if target() == "html" {
    html.div(
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
  } else {
    block[
      #set text(font: "KaiTi")
      *#name #number.#if title != [] { [（#title）] }*
      #body
    ]
  }
}

#let lemma(title, body, name: [引理]) = context {
  let number = lemma-counter.get().first() + 1
  lemma-counter.step()

  if target() == "html" {
    html.div(
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
  } else {
    block[
      #set text(font: "KaiTi")
      *#name #number.#if title != [] { [（#title）] }*
      #body
    ]
  }
}

#let proposition(title, body, name: [命题]) = context {
  let number = proposition-counter.get().first() + 1
  proposition-counter.step()

  if target() == "html" {
    html.div(
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
  } else {
    block[
      #set text(font: "KaiTi")
      *#name #number.#if title != [] { [（#title）] }*
      #body
    ]
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
    block[
      #set text(font: "KaiTi")
      _#title._
      #body
      #h(1fr) $square.stroked$
    ]
  }
}
