#let theorem-counter = counter("tufted-theorem")

#let reset-theorems() = {
  theorem-counter.update(0)
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
