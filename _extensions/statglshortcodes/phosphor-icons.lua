-- phosphor-icons.lua -- Quarto filter.
--
--  1. Injects the self-hosted Phosphor web font (thin, regular, fill)
--     as an HTML dependency, so every page gets phosphor/phosphor.css and
--     the woff2 files copied into site_libs.
--  2. Rewrites legacy Bootstrap Icons markup <i class="bi bi-*"> found in
--     raw HTML (page prose, EJS listing output, older shortcode output)
--     into Phosphor markup via the alias table in phosphor.lua. Names
--     without an alias are left as Bootstrap glyphs, so unmigrated pages
--     never break.
--
-- Weight for legacy markup: data-icon-weight="duotone|fill|..." on the
-- tag, else a context marker class (see phosphor.context_classes), else
-- regular.

local here = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local PH = dofile(pandoc.path.join({ here, "phosphor.lua" }))

local function add_dependency()
  if not quarto.doc.is_format("html") then return end
  quarto.doc.add_html_dependency({
    name = "phosphor-icons",
    version = PH.version,
    stylesheets = { "phosphor/phosphor.css" },
    resources = {
      { name = "Phosphor-Thin.woff2",    path = "phosphor/Phosphor-Thin.woff2" },
      { name = "Phosphor.woff2",         path = "phosphor/Phosphor.woff2" },
      { name = "Phosphor-Fill.woff2",    path = "phosphor/Phosphor-Fill.woff2" },
    },
  })
end

local function rewrite(el)
  if not quarto.doc.is_format("html") then return nil end
  if el.format ~= "html" and el.format ~= "html5" then return nil end
  local new = PH.rewrite_html(el.text)
  if new == el.text then return nil end
  el.text = new
  return el
end

return {
  { Pandoc = function(doc) add_dependency(); return nil end },
  { RawBlock = rewrite, RawInline = rewrite },
}
