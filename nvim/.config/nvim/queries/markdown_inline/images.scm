; extends

(inline_link
  (link_destination) @image.src
  (#match? @image.src "\\.(png|jpe?g|gif|webp|bmp|tiff|svg|ico|avif|heic|mmd|mermaid)($|\\?|#)")
  (#gsub! @image.src "^<" "")
  (#gsub! @image.src ">$" "")
) @image
