#import "layout.typ": margin-note

// Images and tables already have native HTML output. Elements created only for
// HTML must also stay native, since they have no paged representation to render.
#let has-native-html-figure-body(body) = {
  if type(body) == content {
    if body.func() in (image, table, html.elem) { return true }
    for (_, value) in body.fields() {
      if has-native-html-figure-body(value) { return true }
    }
  } else if type(body) == array {
    for item in body {
      if has-native-html-figure-body(item) { return true }
    }
  } else if type(body) == dictionary {
    for (_, value) in body {
      if has-native-html-figure-body(value) { return true }
    }
  }
  false
}

#let template-figures(content) = {
  // Redefine figure caption to use marginnote
  show figure.caption: it => html.span(
    class: "marginnote",
    it.supplement + sym.space.nobreak + it.counter.display() + it.separator + it.body,
  )

  // Add lazy-loading related attributes to raster images in HTML output.
  show image: it => context {
    if target() == "html" and type(it.source) == str {
      let alt = if it.alt == none { "" } else { it.alt }

      let dims = measure(it)
      let img-w = int(dims.width.pt())
      let img-h = int(dims.height.pt())

      // When use scale to resize an image (e.g., `width: 50%`),
      // the measured dimensions are zero.
      // `layout` is not available when exporting to HTML.
      if img-w > 0 and img-h > 0 {
        html.img(
          src: it.source,
          alt: alt,
          loading: "lazy",
          decoding: "async",
          width: img-w,
          height: img-h,
        )
      } else {
        html.img(
          src: it.source,
          alt: alt,
          loading: "lazy",
          decoding: "async",
        )
      }
    } else {
      it
    }
  }

  // Redefine figure itself
  show figure: it => if target() == "html" {
    let native = has-native-html-figure-body(it.body)
    let body = {
      it.caption
      if native {
        it.body
      } else {
        // Render paged-only content (Fletcher diagrams, drawings, etc.) as SVG.
        html.frame(it.body)
      }
    }
    if native {
      html.figure(body)
    } else {
      html.figure(class: "figure-svg", body)
    }
  }

  content
}
