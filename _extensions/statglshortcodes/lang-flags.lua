local utils = pandoc.utils

-- helper: turn any Meta value into a lowercased string
local function meta_to_lang(v)
  if not v then
    return nil
  end
  -- if it's already a string
  if type(v) == "string" then
    return v:lower()
  end
  -- if it's a pandoc Meta* value, stringify it
  local ok, s = pcall(utils.stringify, v)
  if ok and s and s ~= "" then
    return s:lower()
  end
  return nil
end

-- hreflang alternates. The three language versions of a page share one path
-- with the language directory swapped (that is how generate_twins.R lays
-- them out), so the alternates follow from the input path. Only languages
-- whose qmd exists are listed; template.html emits one
-- <link rel="alternate" hreflang=…> per entry. Absolute URLs, as search
-- engines require; site-url in _quarto.yml overrides the default.
local SITE_URL = "https://stat.gl"
local LANGS = { "kl", "da", "en" }

local function file_exists(p)
  local f = io.open(p, "r")
  if f then f:close() return true end
  return false
end

local function hreflang_links(meta)
  if not quarto or not quarto.doc or not quarto.project then return nil end
  local input = quarto.doc.input_file
  local root  = quarto.project.directory
  if not input or not root then return nil end
  input = input:gsub("\\", "/")
  root  = root:gsub("\\", "/")
  if input:sub(1, #root) ~= root then return nil end
  local rel = input:sub(#root + 2)
  local lang_dir, rest = rel:match("^(%a%a)/(.*)$")
  if not lang_dir then return nil end
  local site_url = meta_to_lang(meta["site-url"]) or SITE_URL
  site_url = site_url:gsub("/$", "")
  local out = rest:gsub("%.qmd$", ".html")
  out = out:gsub("index%.html$", "")
  local links = {}
  for _, l in ipairs(LANGS) do
    if file_exists(root .. "/" .. l .. "/" .. rest) then
      table.insert(links, pandoc.MetaMap({
        lang = pandoc.MetaString(l),
        href = pandoc.MetaString(site_url .. "/" .. l .. "/" .. out)
      }))
    end
  end
  if #links > 1 then return pandoc.MetaList(links) end
  return nil
end

function Meta(meta)
  local alternates = hreflang_links(meta)
  if alternates then meta.hreflang_links = alternates end

  -- render timestamp for the footer: UTC ISO instant, formatted in the
  -- viewer's local time zone by JS in template.html
  meta.render_stamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

  -- try all the likely keys
  local lang =
    meta_to_lang(meta.lang) or
    meta_to_lang(meta.language) or
    meta_to_lang(meta["statgl-lang"]) or
    meta_to_lang(meta["site-lang"])  -- in case you set something like this later

  if not lang then
    return meta
  end

  -- set flags
  meta.lang_is_da = (lang == "da" or lang == "da-dk")
  meta.lang_is_kl = (lang == "kl")
  meta.lang_is_en = (lang == "en" or lang == "en-us" or lang == "en-gb")

  -- also normalize the actual lang, so your <html lang="$lang$"> is nice
  meta.lang = lang

  return meta
end