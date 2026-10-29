-- release-dates.lua
-- Injects release-date / next-release into document metadata at the pandoc
-- (render) stage, sourced from _data/release_dates.json keyed by the
-- language-agnostic qmd path (e.g. "statistics/inuit/BE/population.qmd").
--
-- Why a sidecar instead of frontmatter:
--   Quarto's freeze hash is md5() of the entire .qmd file, frontmatter
--   included. Writing volatile publication dates into frontmatter therefore
--   re-executes the page (and every generated language sibling) on each
--   publication, defeating freeze. The pandoc render stage runs on every
--   render regardless of freeze, so injecting the dates here keeps the
--   displayed values current while the expensive computation stays cached.
--
-- Consumed by template.html via $release-date$ / $next-release$.
-- A value already present in a page's frontmatter is left untouched (override).
--
-- Opt-out: set `show-release-date: false` in a page's frontmatter to suppress
-- the entire release-meta block (both release-date and next-release). The flag
-- lives in frontmatter, but because it is read here at the render stage and not
-- by any executed code, it does not bust the freeze hash for that page. KPI
-- cards and all other content are unaffected.

local cache = nil

-- Treat a frontmatter value as an explicit false: Lua boolean false, or a
-- string spelled false/no/0/off (case-insensitive). Anything else is "not set
-- to false", so the default (dates shown) holds.
local function is_false(v)
  if v == false then return true end
  if type(v) == "table" then  -- MetaString / MetaInlines come through as tables
    v = pandoc.utils.stringify(v)
  end
  if type(v) == "string" then
    local s = v:lower():gsub("%s+", "")
    return s == "false" or s == "no" or s == "0" or s == "off"
  end
  return false
end

local function decode_json(txt)
  if quarto and quarto.json and quarto.json.decode then
    return quarto.json.decode(txt)
  end
  local ok, mod = pcall(require, "pandoc.json")
  if ok and mod and mod.decode then return mod.decode(txt) end
  if pandoc and pandoc.json and pandoc.json.decode then
    return pandoc.json.decode(txt)
  end
  return nil
end

local function load_dates()
  if cache ~= nil then return cache end
  cache = {}
  local root = (quarto and quarto.project and quarto.project.directory) or "."
  local path = root .. "/_data/release_dates.json"
  local fh = io.open(path, "r")
  if not fh then return cache end
  local txt = fh:read("*a")
  fh:close()
  local ok, decoded = pcall(decode_json, txt)
  if ok and type(decoded) == "table" then cache = decoded end
  return cache
end

local function strip_lang(rel)
  return rel:match("^da/(.+)$") or rel:match("^kl/(.+)$") or rel:match("^en/(.+)$")
end

local function page_key()
  local input = quarto and quarto.doc and quarto.doc.input_file
  if not input then return nil end
  input = input:gsub("\\", "/")
  -- Prefer stripping the known project root, then the leading lang dir.
  local root = quarto and quarto.project and quarto.project.directory
  if root then
    root = root:gsub("\\", "/"):gsub("/$", "")
    if input:sub(1, #root + 1) == root .. "/" then
      local rel = input:sub(#root + 2)
      return strip_lang(rel) or rel
    end
  end
  -- Fallback: split on the first leading lang directory anywhere in the path.
  return input:match("/da/(.+)$") or input:match("/kl/(.+)$")
      or input:match("/en/(.+)$") or strip_lang(input)
end

function Meta(meta)
  -- Opt-out flag: suppress the whole release-meta block for this page.
  -- Clear any injected/frontmatter values so template.html renders nothing.
  if is_false(meta["show-release-date"]) then
    meta["release-date"] = nil
    meta["next-release"] = nil
    return meta
  end

  local key = page_key()
  if not key then return meta end
  local dates = load_dates()[key]
  if type(dates) ~= "table" then return meta end
  if meta["release-date"] == nil and dates["release-date"] ~= nil then
    meta["release-date"] = pandoc.MetaString(tostring(dates["release-date"]))
  end
  if meta["next-release"] == nil and dates["next-release"] ~= nil then
    meta["next-release"] = pandoc.MetaString(tostring(dates["next-release"]))
  end
  return meta
end
