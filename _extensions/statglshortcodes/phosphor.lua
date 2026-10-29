-- phosphor.lua -- Phosphor Icons for statwww.
--
-- Single source of truth for
--   * the legacy Bootstrap Icons -> Phosphor alias table,
--   * weight-by-context rules,
--   * the <i> markup every emitter (shortcodes, filters, EJS via the
--     phosphor-icons.lua filter) ends up with.
--
-- Icon spec (what pages and shortcodes pass as icon="..."):
--   "ph-house"               Phosphor name, weight decided by context
--   "ph-fill ph-house"       explicit weight wins over context
--   "ph-house ms-2"          extra classes pass through
--   "bi-house-door"          legacy Bootstrap name -> aliased to Phosphor
--   "bi-whatever-unknown"    no alias -> left as a Bootstrap glyph
--
-- Weights: thin light regular bold fill duotone.
-- Priority: explicit in spec > context (caller) > "-fill" hint in a
-- legacy name > regular.

local M = {}

M.version = "2.1.2"   -- @phosphor-icons/web

M.weight_class = {
  thin = "ph-thin", light = "ph-light", regular = "ph",
  bold = "ph-bold", fill = "ph-fill", duotone = "ph-duotone",
}

local weight_of_class = {}
for w, c in pairs(M.weight_class) do weight_of_class[c] = w end

-- Legacy Bootstrap Icons name -> Phosphor name (without ph- prefix).
-- Keep sorted-ish by theme; add here when Lars' pages need a new one.
M.aliases = {
  -- documents / publications
  ["journal-text"]            = "notebook",
  ["journal-check"]           = "list-checks",
  ["file-earmark-text"]       = "file-text",
  ["file-earmark-pdf"]        = "file-pdf",
  ["filetype-pdf"]            = "file-pdf",
  ["file-earmark-spreadsheet"]= "file-xls",
  ["file-earmark-bar-graph"]  = "chart-bar",
  ["file-earmark-person"]     = "identification-card",
  ["book"]                    = "book",
  ["bookmark"]                = "bookmark-simple",
  ["blockquote-left"]         = "quotes",
  ["clipboard-check"]         = "clipboard-text",
  ["pencil"]                  = "pencil-simple",
  ["download"]                = "download-simple",
  ["box"]                     = "package",
  -- people
  ["people"]                  = "users",
  ["people-fill"]             = "users",
  ["person-circle"]           = "user-circle",
  ["person-dash"]             = "user-minus",
  ["person-plus"]             = "user-plus",
  ["person-badge"]            = "identification-badge",
  ["id-badge"]                = "identification-badge",
  ["person-heart"]            = "hand-heart",
  ["house-heart"]             = "hand-heart",
  ["person-standing"]         = "gender-male",
  ["person-standing-dress"]   = "gender-female",
  ["baby"]                    = "baby",
  ["skull"]                   = "skull",
  ["fingerprint"]             = "fingerprint",
  -- economy
  ["safe"]                    = "vault",
  ["wallet2"]                 = "wallet",
  ["bank"]                    = "bank",
  ["bank2"]                   = "bank",
  ["cash-coin"]               = "coins",
  ["cash-stack"]              = "money",
  ["piggy-bank"]              = "piggy-bank",
  ["piggy-bank-fill"]         = "piggy-bank",
  ["receipt"]                 = "receipt",
  ["cart2"]                   = "shopping-cart",
  ["tags-fill"]               = "tag",
  ["percent"]                 = "percent",
  ["briefcase"]               = "briefcase",
  ["briefcase-fill"]          = "briefcase",
  ["speedometer2"]            = "gauge",
  ["building"]                = "buildings",
  ["building-fill"]           = "buildings",
  ["building-exclamation"]    = "building",
  ["bricks"]                  = "wall",
  ["truck"]                   = "truck",
  ["car-front"]               = "car",
  ["airplane"]                = "airplane",
  ["arrow-left-right"]        = "arrows-left-right",
  -- charts
  ["bar-chart-line"]          = "chart-bar",
  ["bar-chart-line-fill"]     = "chart-bar",
  ["bar-chart-steps"]         = "chart-bar-horizontal",
  ["pie-chart"]               = "chart-pie",
  ["graph-up"]                = "chart-line-up",
  ["graph-down"]              = "chart-line-down",
  ["graph-up-arrow"]          = "trend-up",
  ["diagram-2-fill"]          = "tree-structure",
  ["diagram-3"]               = "tree-structure",
  ["diagram-3-fill"]          = "tree-structure",
  ["pentagon-fill"]           = "pentagon",
  -- education / social / health
  ["mortarboard"]             = "graduation-cap",
  ["mortarboard-fill"]        = "graduation-cap",
  ["backpack-fill"]           = "backpack",
  ["heart-pulse"]             = "heartbeat",
  ["heart-pulse-fill"]        = "heartbeat",
  ["hospital"]                = "hospital",
  ["life-preserver"]          = "lifebuoy",
  ["award-fill"]              = "medal",
  ["cup-straw"]               = "wine",
  ["house-door"]              = "house",
  -- nature / energy / fisheries
  ["tsunami"]                 = "waves",
  ["water"]                   = "drop",
  ["cloud"]                   = "cloud",
  ["cloud-haze2-fill"]        = "cloud-fog",
  ["snow2"]                   = "snowflake",
  ["thermometer-half"]        = "thermometer",
  ["brightness-high"]         = "sun",
  ["moon-stars-fill"]         = "moon-stars",
  ["lightning-charge"]        = "lightning",
  ["lightning-charge-fill"]   = "lightning",
  ["leaf"]                    = "leaf",
  ["recycle"]                 = "recycle",
  ["binoculars"]              = "binoculars",
  ["camera-reels"]            = "film-reel",
  ["globe"]                   = "globe",
  ["globe-europe-africa"]     = "globe-hemisphere-east",
  ["geo-alt"]                 = "map-pin",
  ["geo-alt-fill"]            = "map-pin",
  -- ui
  ["arrow-right"]             = "arrow-right",
  ["arrow-right-circle"]      = "arrow-circle-right",
  ["search"]                  = "magnifying-glass",
  ["calendar"]                = "calendar",
  ["calendar3"]               = "calendar",
  ["clock-history"]           = "clock-counter-clockwise",
  ["hourglass-split"]         = "hourglass-medium",
  ["check2"]                  = "check",
  ["check-circle-fill"]       = "check-circle",
  ["x-circle"]                = "x-circle",
  ["plus"]                    = "plus",
  ["exclamation-circle"]      = "warning-circle",
  ["exclamation-octagon"]     = "warning-octagon",
  ["shield-check"]            = "shield-check",
  ["shield-lock"]             = "lock-key",
  ["sliders"]                 = "sliders-horizontal",
  ["stars"]                   = "sparkle",
  ["translate"]               = "translate",
  ["telephone"]               = "phone",
  ["envelope"]                = "envelope",
  ["code-slash"]              = "code",
  ["table"]                   = "table",
  ["upload"]                  = "upload-simple",
  ["person-lock"]             = "user-circle-check",
}

-- Marker classes that imply a weight when the spec itself has none.
-- Used by the legacy filter, where the caller's context is unknown.
-- Card-sized slots are thin (2026-10-02); small inline icons stay regular.
M.context_classes = {
  ["sectioncard-icon"]        = "thin",
  ["sc-icon"]                 = "thin",
  ["externcard-icon"]         = "thin",
  ["archive-card-icon"]       = "thin",
  ["pdf-publication-icon"]    = "thin",
  ["tema-card-icon"]          = "thin",
  ["feature-icon"]            = "thin",
  ["shorty-icon"]             = "thin",
  ["contact-icon"]            = "thin",
}

local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

-- Resolve a spec into { weight = "regular"|..., name = "house"|nil,
-- legacy = "bi-foo"|nil, extra = {"ms-2", ...}, hint = "fill"|nil }.
function M.parse(spec)
  local r = { extra = {} }
  for tok in trim(spec):gmatch("%S+") do
    if weight_of_class[tok] then
      r.weight = weight_of_class[tok]
    elseif tok:sub(1, 3) == "ph-" and not r.name then
      r.name = tok:sub(4)
    elseif tok:sub(1, 3) == "bi-" and not r.name and not r.legacy then
      local ph = M.aliases[tok:sub(4)]
      if ph then
        r.name = ph
        if tok:match("%-fill$") then r.hint = "fill" end
      else
        r.legacy = tok
      end
    elseif tok ~= "bi" and tok ~= "ph" then
      table.insert(r.extra, tok)
    end
  end
  return r
end

-- Class string for an <i>. ctx = weight name implied by the caller
-- ("duotone" for cards, "regular" inline), may be nil. default is used
-- when spec is empty (Quarto hands shortcodes "" for absent kwargs).
function M.classes(spec, ctx, default)
  if trim(spec) == "" then spec = default or "" end
  local r = M.parse(spec)
  local out = {}
  if r.name then
    local w = r.weight or ctx or r.hint or "regular"
    table.insert(out, M.weight_class[w] or "ph")
    table.insert(out, "ph-" .. r.name)
  elseif r.legacy then
    table.insert(out, "bi")
    table.insert(out, r.legacy)
  else
    return nil
  end
  for _, c in ipairs(r.extra) do table.insert(out, c) end
  return table.concat(out, " ")
end

-- Full <i> element. opts.weight = context weight, opts.class = extra
-- classes, opts.attrs = raw attribute string.
function M.icon(spec, opts)
  opts = opts or {}
  local full = trim(spec)
  if opts.class and opts.class ~= "" then full = full .. " " .. opts.class end
  local cls = M.classes(full, opts.weight)
  if not cls then return "" end
  local attrs = opts.attrs and (" " .. opts.attrs) or ' aria-hidden="true"'
  return string.format('<i class="%s"%s></i>', cls, attrs)
end

-- Rewrite every legacy <i class="bi ..."> inside an HTML string.
-- Weight comes from (1) data-icon-weight="..." on the tag, (2) a
-- context marker class, (3) the -fill hint, (4) regular.
function M.rewrite_html(html)
  if not html:find([[class=["']bi%s]]) then return html end
  return (html:gsub('<i(%s+[^>]-)class=(["\'])bi%s+([^"\']*)%2([^>]*)>',
    function(pre, q, spec, post)
      local attrs = pre .. post
      local ctx = attrs:match('data%-icon%-weight=["\']([%a]+)["\']')
      if not ctx then
        for tok in spec:gmatch("%S+") do
          if M.context_classes[tok] then ctx = M.context_classes[tok]; break end
        end
      end
      local cls = M.classes(spec, ctx)
      if not cls then return nil end
      local strip = '%s*data%-icon%-weight=["\'][%a]+["\']'
      pre  = pre:gsub(strip, "")
      post = post:gsub(strip, "")
      if not pre:match("%s$") then pre = pre .. " " end
      return '<i' .. pre .. 'class=' .. q .. cls .. q .. post .. '>'
    end))
end

return M
