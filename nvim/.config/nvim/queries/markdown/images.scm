; extends

(fenced_code_block
  (info_string (language) @lang)
  (#match? @lang "^(mermaid|diagram-mermaid)$")
  (code_fence_content) @image.content
  (#set! injection.language "mermaid")
  (#set! image.ext "chart.mmd")
) @image
