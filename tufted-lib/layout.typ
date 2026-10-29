// TODO: figures and figures with captions inside margin notes

#let margin-note(content) = context {
  if target() == "html" {
    html.span(class: "marginnote", content)
  } else {
    block(
      width: 100%,
      fill: rgb("#f0f2f5"),
      stroke: rgb("#d0d8e0"),
      radius: 4pt,
      inset: 8pt,
      above: 0.6em,
      below: 0.8em,
      content,
    )
  }
}

// TODO: implement <figure class="fullwidth">
// possible requires introspection or `set html.figure(class: "fullwidth")` support

#let full-width(content) = context {
  if target() == "html" {
    html.div(class: "fullwidth", content)
  } else {
    block(width: 100%, content)
  }
}
