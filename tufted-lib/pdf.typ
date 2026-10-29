// White-paper counterpart to the site's article theme. No navigation,
// sidebar, header, footer, or page number is added to the document.
#import "refs.typ": template-refs

#let pdf-article(body) = {
  show: template-refs
  set page(
    paper: "a4",
    margin: (x: 2.15cm, y: 2.25cm),
    fill: white,
    header: none,
    footer: none,
  )
  set text(
    font: ("Noto Serif SC", "Times New Roman"),
    size: 10.5pt,
    fill: rgb("#2c2c2c"),
    lang: "zh",
  )
  set par(justify: true, leading: 0.75em, spacing: 0.9em)
  show heading.where(level: 1): set text(size: 18pt, weight: "bold", fill: rgb("#1a1a1a"))
  show heading.where(level: 2): set text(size: 15pt, weight: "bold", fill: rgb("#1a1a1a"))
  show heading.where(level: 3): set text(size: 12.5pt, weight: "bold", fill: rgb("#1a1a1a"))
  show heading.where(level: 4): set text(size: 11pt, weight: "bold", fill: rgb("#1a1a1a"))
  body
}
