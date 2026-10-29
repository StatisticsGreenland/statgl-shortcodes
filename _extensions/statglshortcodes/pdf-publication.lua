-- pdf-publication.lua
--
-- Adds a download card (and optional archive accordion) to any page that
-- declares a `pdf:` key in its YAML front matter.
--
-- YAML usage:
--
--   # Minimal: just a download card
--   pdf: virksomhedsprogram_2025.pdf
--
--   # With archive folder (auto-discovered, year extracted from filename)
--   pdf:
--     file: virksomhedsprogram_2025.pdf
--     archive: virksomhedsplan/
--
--   # Full control
--   pdf:
--     file: virksomhedsprogram_2025.pdf
--     title: "Hent publikationen"
--     position: top                 # or 'bottom' (default: top)
--     archive:
--       folder: virksomhedsplan/
--       title: "Tidligere udgaver"
--       label_base: "Virksomhedsprogram"
--
-- Paths are resolved the same way as everything else in a qmd: relative to
-- the qmd's own directory.

local utils = pandoc.utils
local U = utils.stringify

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------

local function h(s)
  s = tostring(s or "")
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
           :gsub('"', "&quot;"):gsub("'", "&#39;"))
end

local function slugify(s)
  s = (s or ""):gsub("%s+", "-"):gsub("[^%w%-_]", ""):gsub("%-+", "-")
  return s:lower()
end

local function basename(p)
  return (p:gsub("^.*/", ""))
end

-- URL-decode for display purposes (e.g. "2025%20Plan.pdf" -> "2025 Plan.pdf")
local function pretty_name(p)
  local name = basename(p)
  return (name:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

-- Pull a string field out of a Meta value (returns nil if absent or empty)
local function ms(t, k)
  if t == nil then return nil end
  local v = t[k]
  if v == nil then return nil end
  if type(v) == "string" then
    return (v ~= "" and v) or nil
  end
  local ok, s = pcall(U, v)
  if ok and s and s ~= "" then return s end
  return nil
end

-- Decide whether a Meta value should be treated as a map of named fields
-- (rather than a plain string scalar) by looking for any recognised key.
local function is_map_with_keys(v, keys)
  if type(v) ~= "table" then return false end
  for _, k in ipairs(keys) do
    if v[k] ~= nil then return true end
  end
  return false
end

local function extract_year(fname)
  return fname:match("20%d%d") or fname:match("19%d%d")
end

-- Cross-version directory listing (mirrors the pdf_archive shortcode)
local function list_directory(dir)
  local items = {}
  if pandoc.system and pandoc.system.list_directory then
    for _, name in ipairs(pandoc.system.list_directory(dir) or {}) do
      table.insert(items, name)
    end
  else
    local cmd = string.format('ls -1 %q 2>/dev/null', dir)
    local p = io.popen(cmd)
    if p then
      for line in p:lines() do table.insert(items, line) end
      p:close()
    end
  end
  return items
end

-- Directory of the qmd being rendered. Used to resolve the archive folder on
-- disk, since the filter's CWD is the project root on a full-project render
-- (mirrors the input-path convention in release-dates.lua).
local function input_dir()
  local input = quarto and quarto.doc and quarto.doc.input_file
  if not input then return nil end
  input = input:gsub("\\", "/")
  return (input:match("^(.*)/[^/]*$"))
end

-- ---------------------------------------------------------------------------
-- language-aware default labels
-- ---------------------------------------------------------------------------

local DEFAULTS = {
  da = {
    title         = "Hent publikationen som PDF",
    archive_title = "Tidligere udgaver",
    label_base    = "Publikation",
  },
  kl = {
    -- Placeholders — replace with vetted Greenlandic translations
    title         = "Saqqummersitaq pdf-imik aaqqissuussaq",
    archive_title = "Saqqummersitat siusinerusukkut",
    label_base    = "Saqqummersitaq",
  },
  en = {
    title         = "Download publication as PDF",
    archive_title = "Previous editions",
    label_base    = "Publication",
  },
}

local function lang_defaults(meta)
  local lang = ms(meta, "lang") or "da"
  lang = lang:sub(1, 2):lower()
  return DEFAULTS[lang] or DEFAULTS.da
end

-- ---------------------------------------------------------------------------
-- HTML builders
-- ---------------------------------------------------------------------------

local function build_download_row(file, title)
  local name = pretty_name(file)
  return string.format([[
<a class="pdf-publication-link" href="%s" download aria-label="%s">
  <i class="ph-thin ph-file-pdf pdf-publication-icon" aria-hidden="true"></i>
  <div class="pdf-publication-text">
    <div class="pdf-publication-title">%s</div>
    <div class="pdf-publication-subtitle">%s</div>
  </div>
  <i class="ph ph-download-simple pdf-publication-chevron" aria-hidden="true"></i>
</a>]],
    h(file), h(title), h(title), h(name))
end

local function build_archive(items, title, id_base)
  local rows = {}
  for _, it in ipairs(items) do
    table.insert(rows, string.format([[
          <li>
            <i class="ph ph-file-pdf flex-shrink-0" aria-hidden="true"></i>
            <a href="%s" target="_blank" rel="noopener">%s</a>
          </li>]],
      h(it.href), h(it.label)))
  end
  return string.format([[
<div class="accordion feature-accordion pdf-publication-archive" id="%s">
  <div class="accordion-item">
    <div class="accordion-header" id="%s-header">
      <button class="accordion-button collapsed" type="button"
              data-bs-toggle="collapse"
              data-bs-target="#%s-body"
              aria-expanded="false"
              aria-controls="%s-body">
        %s
      </button>
    </div>
    <div id="%s-body" class="accordion-collapse collapse"
         aria-labelledby="%s-header" data-bs-parent="#%s">
      <div class="accordion-body">
        <ul class="pdf-archive-list">
          %s
        </ul>
      </div>
    </div>
  </div>
</div>]],
    h(id_base), h(id_base), h(id_base), h(id_base),
    h(title),
    h(id_base), h(id_base), h(id_base),
    table.concat(rows, "\n"))
end

local function items_from_folder(folder, label_base, exclude)
  local items = {}
  -- List on the qmd-relative path; keep href relative to the output page.
  local dir = input_dir()
  local fs_folder = (dir and not folder:match("^/")) and (dir .. "/" .. folder) or folder
  for _, name in ipairs(list_directory(fs_folder)) do
    if name:lower():match("%.pdf$") and name ~= exclude then
      local y = extract_year(name)
      local sep = (folder:sub(-1) == "/") and "" or "/"
      local href = folder .. sep .. name
      local label = (y and (label_base .. " " .. y)) or name
      table.insert(items, { href = href, label = label, year = y, file = name })
    end
  end
  table.sort(items, function(a, b)
    if a.year ~= b.year then
      if a.year == nil then return false end
      if b.year == nil then return true end
      return a.year > b.year
    end
    return a.file > b.file
  end)
  return items
end

-- ---------------------------------------------------------------------------
-- read & validate the `pdf:` meta key
-- ---------------------------------------------------------------------------

local CFG_KEYS = { "file", "path", "title", "position", "archive" }
local ARCH_KEYS = { "folder", "title", "label_base" }

local function read_pdf_config(meta, defaults)
  local pdf = meta.pdf
  if pdf == nil then return nil end

  local cfg = {
    file          = nil,
    title         = defaults.title,
    position      = "top",
    archive       = nil,
    archive_title = defaults.archive_title,
    label_base    = defaults.label_base,
  }

  if not is_map_with_keys(pdf, CFG_KEYS) then
    -- string shorthand: pdf: foo.pdf
    cfg.file = U(pdf)
  else
    cfg.file     = ms(pdf, "file") or ms(pdf, "path")
    cfg.title    = ms(pdf, "title") or cfg.title
    cfg.position = (ms(pdf, "position") or "top"):lower()

    local arch = pdf.archive
    if arch ~= nil then
      local a = {
        folder     = nil,
        title      = cfg.archive_title,
        label_base = cfg.label_base,
      }
      if is_map_with_keys(arch, ARCH_KEYS) then
        a.folder     = ms(arch, "folder")
        a.title      = ms(arch, "title")      or a.title
        a.label_base = ms(arch, "label_base") or a.label_base
      else
        a.folder = U(arch)
      end
      cfg.archive = a
    end
  end

  if not cfg.file or cfg.file == "" then return nil end
  if cfg.position ~= "top" and cfg.position ~= "bottom" then
    cfg.position = "top"
  end
  return cfg
end

-- ---------------------------------------------------------------------------
-- main entry point
-- ---------------------------------------------------------------------------

function Pandoc(doc)
  local defaults = lang_defaults(doc.meta)
  local cfg = read_pdf_config(doc.meta, defaults)
  if not cfg then return doc end

  local download_html = build_download_row(cfg.file, cfg.title)

  local archive_html = ""
  if cfg.archive and cfg.archive.folder then
    local items = items_from_folder(
      cfg.archive.folder,
      cfg.archive.label_base,
      pretty_name(cfg.file)   -- don't list the current publication twice
    )
    if #items > 0 then
      local id_base = "pdf-archive-" .. slugify(cfg.archive.folder)
      archive_html = build_archive(items, cfg.archive.title, id_base)
    end
  end

  local wrapper = string.format(
    [[<div class="card panel-card pdf-publication my-4">%s%s</div>]],
    download_html,
    archive_html
  )
  local block = pandoc.RawBlock("html", wrapper)

  if cfg.position == "bottom" then
    table.insert(doc.blocks, block)
  else
    table.insert(doc.blocks, 1, block)
  end

  return doc
end
