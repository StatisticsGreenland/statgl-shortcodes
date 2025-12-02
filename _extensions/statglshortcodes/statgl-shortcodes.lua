function kpicard(args, kwargs, meta)
local title = pandoc.utils.stringify(kwargs["title"] or "")
local subtitle = pandoc.utils.stringify(kwargs["subtitle"] or "")
  local value = pandoc.utils.stringify(kwargs["value"] or "")
  local link = pandoc.utils.stringify(kwargs["link"] or "")
  local style = pandoc.utils.stringify(kwargs["style"] or "")


  local onclick_attr = ""
  local cursor_style = "" .. style
  
if link ~= "" then
  onclick_attr = ' onclick="window.location.href=\'' .. link .. '\'"'
  cursor_style = ' style="cursor: pointer;' .. style .. '"'
elseif style ~= "" then
  cursor_style = ' style="' .. style .. '"'
end

  local html = string.format([[
    <div class="card KeyBox"%s%s>
      <div class="KeyValue">%s</div>
      <div class="KeyTitle">%s</div>
      <div class="KeySubtitle">%s</div>
    </div>
  ]], onclick_attr, cursor_style, value, title, subtitle)

  return pandoc.RawBlock("html", html)
end

function sectioncard(args, kwargs, meta)
  local U     = pandoc.utils.stringify
  local icon  = U(kwargs["icon"]  or "bi-box")
  local title = U(kwargs["title"] or "Title")
  local text  = U(kwargs["text"]  or "Description text")
  local link  = U(kwargs["link"]  or "#")

  local html = string.format([[
<a class="sectioncard card h-100 text-start text-md-center" href="%s" aria-label="%s">
  <div class="card-body d-flex flex-row flex-md-column align-items-center gap-3 gap-md-1">
    <i class="bi %s sectioncard-icon me-2 me-md-0" aria-hidden="true"></i>
    <div class="sectioncard-textblock">
      <div class="section-title">%s</div>
      <p class="card-text sectioncard-text">%s</p>
    </div>
  </div>
</a>
]], link, title, icon, title, text)

  return pandoc.RawBlock("html", html)
end

function shorty(args, kwargs, meta)
  local utils = pandoc.utils
  local U     = utils.stringify

  -- helpers ------------------------------------------------------
  local function escfmt(s)
    if not s or s == "" then return s end
    return s:gsub("%%", "%%%%")
  end

  local function md_to_html(md)
    if not md or md == "" then return "" end
    return pandoc.write(pandoc.read(md, "markdown"), "html")
  end

  local function looks_like_html(s)
    if not s or s == "" then return false end
    return s:match("^%s*<[%w!%?/]") ~= nil
  end

  local function looks_like_widget(s)
    if not s or s == "" then return false end
    if s:match("html%-widget") then return true end
    if s:match("highchart")    then return true end
    return false
  end

  -- inputs -------------------------------------------------------
  local title         = U(kwargs["title"]         or "")
  local subtitle      = U(kwargs["subtitle"]      or "")
  local description   = U(kwargs["description"]   or "")
  local link          = U(kwargs["link"]          or "")
  local plot_raw      = U(kwargs["plot"]          or "")
  local plot_subtitle = U(kwargs["plot_subtitle"] or "")
  local height        = U(kwargs["height"]        or "")

  -- plot HTML ----------------------------------------------------
  local plot_html = ""
  if plot_raw ~= "" then
    if looks_like_html(plot_raw) then
      plot_html = plot_raw
    else
      plot_html = md_to_html(plot_raw)
    end
  end

  -- docs (doc1_title/doc1_text, …, doc6_title/doc6_text) --------
  local docs = {}
  for i = 1, 6 do
    local t = U(kwargs["doc" .. i .. "_title"] or "")
    local b = U(kwargs["doc" .. i .. "_text"]  or "")
    if t ~= "" or b ~= "" then
      table.insert(docs, { title = t, body = b })
    end
  end

  local docs_html = ""
  if #docs > 0 then
    local base_id = "shortydocs-" .. tostring(math.random(100000, 999999))
    docs_html = '<div class="accordion shorty-docs mt-3" id="' .. escfmt(base_id) .. '">'

    for idx, d in ipairs(docs) do
      local item_id = base_id .. "-item-" .. idx
      docs_html = docs_html .. string.format([[
      <div class="accordion-item">
        <strong class="accordion-header" id="%s-header">
          <button class="accordion-button collapsed" type="button"
                  data-bs-toggle="collapse"
                  data-bs-target="#%s-body"
                  aria-expanded="false" aria-controls="%s-body">
            %s
          </button>
        </strong>
        <div id="%s-body" class="accordion-collapse collapse" aria-labelledby="%s-header">
          <div class="accordion-body">
            %s
          </div>
        </div>
      </div>]],
        escfmt(item_id),
        escfmt(item_id),
        escfmt(item_id),
        escfmt(d.title),
        escfmt(item_id),
        escfmt(item_id),
        md_to_html(d.body or "")
      )
    end

    docs_html = docs_html .. "</div>"
  end

  -- link under plot ----------------------------------------------
  local plot_link_html = ""
  if link ~= "" then
    local body = link
    if not looks_like_html(body) then
      body = md_to_html(body)
    end
    plot_link_html = string.format(
      '<div class="shorty-link shorty-link-underplot mt-2">%s</div>',
      body
    )
  end

  -- text block (markdown in subtitle + description) --------------
  local subtitle_html = ""
  if subtitle ~= "" then
    -- allow markdown in subtitle
    subtitle_html = '<div class="shorty-subtitle">' .. md_to_html(subtitle) .. '</div>'
  end

  local description_html = ""
  if description ~= "" then
    -- allow markdown in description (**bold**, lists, `code`, etc.)
    description_html = '<div class="shorty-description">' .. md_to_html(description) .. '</div>'
  end

  local text_block = string.format([[
    <div class="shorty-textcol">
      %s
      %s
      %s
    </div>]],
    (title ~= "" and ('<h2 class="card-title">' .. escfmt(title) .. '</h2>') or ""),
    subtitle_html,
    description_html
  )

  -- plot subtitle ------------------------------------------------
  local plot_subtitle_html = ""
  if plot_subtitle ~= "" then
    plot_subtitle_html =
      '<p class="shorty-plot-subtitle">' .. escfmt(plot_subtitle) .. '</p>'
  end

  -- plot block (with link + docs under plot) ---------------------
  local plot_block = ""

  if plot_html ~= "" then
    if looks_like_widget(plot_html) then
      -- widget path: lazy-load container
      local id_suffix = tostring(math.random(100000, 999999))
      local plot_id   = "plot-" .. id_suffix
      local tpl_id    = "tpl-"  .. id_suffix
      local height_attr = (height ~= "" and (' style="height:' .. escfmt(height) .. ';"') or "")

      plot_block = string.format([[
      <div class="shorty-plotcol">
        %s
        <div id="%s" class="plot-frame"%s></div>
        <template id="%s"><div class="plot-area">%s</div></template>

        <script>
          (function(){
            var holder = document.getElementById('%s');
            var tpl    = document.getElementById('%s');
            if(!holder || !tpl) return;

            function renderNow(){
              var frag = tpl.content && tpl.content.cloneNode(true);
              if (frag && frag.childNodes.length > 0) {
                holder.appendChild(frag);
              } else {
                holder.innerHTML = tpl.innerHTML;
              }

              if (window.HTMLWidgets && typeof HTMLWidgets.staticRender === 'function') {
                try { HTMLWidgets.staticRender(); } catch(e){}
              }

              if (window._initRevealTables) {
                try { window._initRevealTables(holder); } catch(e){}
              }
            }

            if (!('IntersectionObserver' in window)) { renderNow(); return; }

            var played = false;
            var io = new IntersectionObserver(function(entries){
              entries.forEach(function(entry){
                if (played) return;
                if (entry.isIntersecting && entry.intersectionRatio > 0.2) {
                  played = true;
                  renderNow();
                  io.disconnect();
                }
              });
            }, { threshold: [0, 0.2, 0.5, 1] });

            io.observe(holder);
          })();
        </script>

        %s
        %s
      </div>]],
        plot_subtitle_html,
        escfmt(plot_id), height_attr,
        escfmt(tpl_id),  escfmt(plot_html),
        escfmt(plot_id), escfmt(tpl_id),
        plot_link_html,
        docs_html
      )

    else
      -- table / plain HTML path
      plot_block = string.format([[
      <div class="shorty-plotcol">
        %s
        <div class="plot-frame">
          <div class="plot-area">
            <div class="shorty-table-wrapper">
              %s
            </div>
          </div>
        </div>
        %s
        %s
      </div>]],
        plot_subtitle_html,
        plot_html,
        plot_link_html,
        docs_html
      )
    end
  end

  -- outer wrapper ------------------------------------------------
  local html = string.format([[
<div class="card panel-card mb-4 shorty">
  <div class="card-body">
    <div class="grid shorty-grid">
      <div class="g-col-12">
        %s
        %s
      </div>
    </div>
  </div>
</div>]],
    text_block,
    plot_block
  )

  return pandoc.RawBlock("html", html)
end

function feature(args, kwargs, meta)
  local U = pandoc.utils.stringify

  local eyebrow   = U(kwargs["eyebrow"] or "")
  local title     = U(kwargs["title"] or "")
  local subtitle  = U(kwargs["subtitle"] or "")
  local body      = U(kwargs["body"] or "")
  local link      = U(kwargs["link"] or "")
  local icon      = U(kwargs["icon"] or "")
  local image     = U(kwargs["image"] or "")        -- NEW: optional image
  local style     = U(kwargs["style"] or "")
  local accordion = U(kwargs["accordion"] or "")    -- legacy single-title
  local more      = U(kwargs["more"] or "")         -- legacy single-body

  local onclick_attr, cursor_style = "", ""
  if link ~= "" then
    onclick_attr = ' onclick="window.open(\'' .. link .. '\', \'_blank\')"'
    cursor_style = ' style="cursor: pointer;' .. style .. '"'
  elseif style ~= "" then
    cursor_style = ' style="' .. style .. '"'
  end

  local function md_to_html(md)
    if md == "" then return "" end
    return pandoc.write(pandoc.read(md, "markdown"), "html")
  end

  -- Soft markdown with §/§§§ support
  local function normalize(md)
    if md == "" then return "" end
    md = md:gsub("%s*§§§%s*", "@@@BLOCK@@@")
           :gsub("%s*§%s*", "\n")
           :gsub("@@@BLOCK@@@", "\n\n")
           :gsub("@@@LITERAL_SECTION@@@", "§")
    return md_to_html(md)
  end

  local body_html = normalize(body)

  -- Left media block: image (preferred) or icon
  local media_html = ""
  if image ~= "" then
    media_html = string.format([[
      <div class="fx-media">
        <img src="%s" class="fx-media-img rounded-3" alt="">
      </div>
    ]], image)
  elseif icon ~= "" then
    media_html = string.format([[
      <div class="fx-media fx-icon">
        <i class="bi %s"></i>
      </div>
    ]], icon)
  end

  ---------------------------------------------------------------------------
  -- HARMONICA (docs accordion)
  ---------------------------------------------------------------------------
  local docs = {}
  for k, v in pairs(kwargs) do
    local n = tostring(k):match("^doc(%d+)_title$")
    if n then
      local t = U(v)
      local b = U(kwargs["doc"..n.."_text"] or "")
      table.insert(docs, { n = tonumber(n), title = t, text = b })
    end
  end
  table.sort(docs, function(a,b) return a.n < b.n end)

  local accordion_html = ""
  if #docs > 0 then
    local rid = randstring(10)
    local items = {}
    for _, d in ipairs(docs) do
      local id   = rid .. "-" .. d.n
      local t    = pandoc.utils.stringify(d.title)
      local body = normalize(d.text)
      items[#items+1] = string.format([[
        <div class="accordion-item">
          <div class="accordion-header" id="heading-%s">
            <button class="accordion-button collapsed" type="button"
              data-bs-toggle="collapse" data-bs-target="#collapse-%s"
              aria-expanded="false" aria-controls="%s">%s</button>
          </div>
          <div id="collapse-%s" class="accordion-collapse collapse"
               aria-labelledby="heading-%s" data-bs-parent="#acc-%s">
            <div class="accordion-body">%s</div>
          </div>
        </div>
      ]], id, id, id, t, id, id, rid, body)
    end
    accordion_html = string.format('<div class="accordion feature-accordion" id="acc-%s">%s</div>',
                                   rid, table.concat(items, "\n"))
  elseif accordion ~= "" or more ~= "" then
    local rid = randstring(10)
    accordion_html = string.format([[
      <div class="accordion feature-accordion" id="acc-%s">
        <div class="accordion-item">
          <div class="accordion-header" id="heading-%s">
            <button class="accordion-button collapsed" type="button"
              data-bs-toggle="collapse" data-bs-target="#collapse-%s"
              aria-expanded="false" aria-controls="%s">%s</button>
          </div>
          <div id="collapse-%s" class="accordion-collapse collapse"
               aria-labelledby="heading-%s" data-bs-parent="#acc-%s">
            <div class="accordion-body">%s</div>
          </div>
        </div>
      </div>
    ]], rid, rid, rid, rid, U(accordion), rid, rid, rid, normalize(more))
  end

  -- Title with optional direct link (keeps card onclick too)
  local title_html = title

  -- Final card (namespaced fx-* classes control layout)
  local html = string.format([[
    <div class="card feature-card"%s%s>
      <div class="card-body">
        <div class="fx-row">
          %s
          <div class="feature-text fx-text">
            <div class="feature-eyebrow">%s</div>
            <div class="feature-title">%s</div>
            <div class="feature-subtitle">%s</div>
            <div class="feature-copy">%s</div>
            %s
          </div>
        </div>
      </div>
    </div>
  ]], onclick_attr, cursor_style, media_html, eyebrow, title_html, subtitle, body_html, accordion_html)

  return pandoc.RawBlock("html", html)
end

function contact(args, kwargs, meta)
  local U = pandoc.utils.stringify

  local title = U(kwargs["title"] or "Kontaktperson for denne statistik")
  local name  = U(kwargs["name"]  or "")
  local role  = U(kwargs["role"]  or "")
  local phone = U(kwargs["phone"] or "")
  local mail  = U(kwargs["mail"]  or "")
  local icon  = U(kwargs["icon"]  or "bi-person-circle")
  local style = U(kwargs["style"] or "")
  if icon == "" then icon = "bi-person-circle" end

  --------------------------------------------------------------------------
  -- address: accept list, \n, or <br>, same behaviour as your original code
  --------------------------------------------------------------------------
  local address_lines = {}
  local addr = kwargs["address"]

  if type(addr) == "table" then
    for _, a in ipairs(addr) do
      local s = U(a)
      if s ~= "" then table.insert(address_lines, s) end
    end
  else
    local s = U(addr or "")
    if s ~= "" then
      s = s:gsub("\\n", "\n"):gsub("<br%s*/?>", "\n")
      for line in s:gmatch("[^\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then table.insert(address_lines, line) end
      end
    end
  end

  --------------------------------------------------------------------------
  -- Strong obfuscation: convert text -> char codes (ASCII)
  --------------------------------------------------------------------------
  local function to_codes(s)
    local codes = {}
    for i = 1, #s do
      table.insert(codes, string.byte(s, i))
    end
    return table.concat(codes, "-")   -- "43-50-57-57-32-"
  end

  local phone_codes = phone ~= "" and to_codes(phone) or ""
  local email_codes = mail  ~= "" and to_codes(mail)  or ""

  --------------------------------------------------------------------------
  -- Inline style
  --------------------------------------------------------------------------
  local style_attr = (style ~= "" and (' style="' .. style .. '"') or "")

  --------------------------------------------------------------------------
  -- Build <li> lines for the card
  --------------------------------------------------------------------------
  local lines = {}

  if role ~= "" then
    table.insert(lines, string.format(
      '<li class="contact-line"><span class="contact-role">%s</span></li>', role))
  end

  if #address_lines > 0 then
    local joined = table.concat(address_lines, "<br>")
    table.insert(lines, string.format(
      '<li class="contact-line"><i class="bi bi-geo-alt me-2"></i><span>%s</span></li>',
      joined))
  end

  -- Phone (obfuscated)
  if phone_codes ~= "" then
    table.insert(lines, string.format(
      '<li class="contact-line"><i class="bi bi-telephone me-2"></i>' ..
      '<span class="staff-phone" data-phone-codes="%s"></span></li>',
      phone_codes))
  end

  -- Email (obfuscated)
  if email_codes ~= "" then
    table.insert(lines, string.format(
      '<li class="contact-line"><i class="bi bi-envelope me-2"></i>' ..
      '<a class="staff-email" href="#" data-email-codes="%s"></a></li>',
      email_codes))
  end

  --------------------------------------------------------------------------
  -- Full card HTML
  --------------------------------------------------------------------------
  local html = string.format([[
    <div class="card contact-card"%s>
      <div class="card-body">
        <div class="contact-title">%s</div>
        <div class="contact-row">
          <div class="contact-icon">
            <i class="bi %s" aria-hidden="true"></i>
          </div>
          <div class="contact-text">
            <div class="contact-name">%s</div>
            <ul class="contact-lines">
              %s
            </ul>
          </div>
        </div>
      </div>
    </div>
  ]], style_attr, title, icon, name, table.concat(lines, "\n"))

  return pandoc.RawBlock("html", html)
end

function explain(args, kwargs, meta)
  local utils = pandoc.utils

  local word        = utils.stringify(kwargs["word"] or "")
  local explanation = utils.stringify(kwargs["explanation"] or "")
  local rid         = randstring(10)

  -- helper: markdown → html
  local function md_to_html(md)
    if md == "" then return "" end
    return pandoc.write(pandoc.read(md, "markdown"), "html")
  end

  -- convert and clean explanation
  local explanation_html = ""
  if explanation ~= "" then
    explanation_html = md_to_html(explanation)
    explanation_html = explanation_html:gsub("^<p>(.*)</p>\n?$", "%1") -- strip outer <p>
  end

  local html = string.format([[
  <div class="explainer">
    <button class="btn explainer-btn"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#collapse-%s"
            aria-expanded="false"
            aria-controls="collapse-%s">
      %s
    </button>

    <div class="collapse explainer-collapse" id="collapse-%s">
      <div class="card explainer-card border-0 shadow-sm">
        <div class="card-body">
          %s
        </div>
      </div>
    </div>
  </div>
  ]], rid, rid, word, rid, explanation_html)

  return pandoc.RawBlock("html", html)
end

function randstring(chars)
  local s = ''
  for i=1,chars do
    s = s .. string.char(math.random(97,122))
  end
  return(s)
end

function readmore(args, kwargs, meta)
  -- Safely stringify attributes (they can be tables)
  local function s(v)
    if type(v) == "table" then return pandoc.utils.stringify(v) end
    return v
  end

  local height    = s(kwargs["height"])          -- may be nil / ""
  local collapsed = s(kwargs["collapsed"]) or "Læs mere"
  local expanded  = s(kwargs["expanded"])  or "Vis mindre"

  -- Only add style attr if height is a non-empty string
  local style = ""
  if height and height ~= "" then
    style = string.format(' style="--readmore-height:%s"', height)
  end

  local html = string.format([[
<div class="readmore"%s data-collapsed="%s" data-expanded="%s">
  <div class="readmore__content">
]], style, collapsed, expanded)

  return pandoc.RawBlock("html", html)
end

function readmore_end(args, kwargs, meta)
  return pandoc.RawBlock("html", [[
  </div>
  <div class="readmore__button-wrapper">
    <button type="button" class="readmore__toggle" aria-expanded="false" title="Læs mere">
      <span class="readmore__icon">+</span>
    </button>
  </div>
</div>]])
end

local U = pandoc.utils.stringify

local function slugify(s)
  s = s:gsub("%s+", "-"):gsub("[^%w%-_]", ""):gsub("%-+", "-")
  return s:lower()
end

local function html_escape(s)
  return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
           :gsub('"',"&quot;"):gsub("'","&#39;"))
end

local function extract_year(fname)
  return fname:match("20%d%d") or fname:match("19%d%d")
end

-- Cross-version directory listing (Pandoc 3.* or fallback to io.popen)
local function list_directory(dir)
  local items = {}

  if pandoc.system and pandoc.system.list_directory then
    -- Pandoc ≥ 3.1
    for _, name in ipairs(pandoc.system.list_directory(dir) or {}) do
      table.insert(items, name)
    end
  else
    -- Fallback (macOS/Linux/WSL). If you're on Windows CMD, consider 'dir /b'.
    local cmd = string.format('ls -1 %q 2>/dev/null', dir)
    local p = io.popen(cmd)
    if p then
      for line in p:lines() do table.insert(items, line) end
      p:close()
    end
  end

  return items
end

function pdf_archive(args, kwargs, meta)
  local dir          = U(kwargs["dir"] or "virksomhedsplan")
  local label_base   = U(kwargs["label_base"] or "Virksomhedsplan")
  local collapsed    = U(kwargs["collapsed"] or "true")
  local target_blank = U(kwargs["target_blank"] or "true")
  local icon_class   = U(kwargs["icon"] or "bi-filetype-pdf")
  local id_base      = U(kwargs["id"] or ("pdf-archive-" .. slugify(dir)))

  -- Read dir and keep only PDFs (case-insensitive)
  local files = {}
  for _, name in ipairs(list_directory(dir)) do
    if name:lower():match("%.pdf$") then
      table.insert(files, { path = dir .. "/" .. name, file = name })
    end
  end

  if #files == 0 then
    local warn = string.format(
      [[<div class="alert alert-warning" role="alert">
         Ingen PDF-filer fundet i <code>%s/</code>.
       </div>]], html_escape(dir))
    return pandoc.RawBlock("html", warn)
  end

  -- Build metadata + sort
  local rows, years = {}, {}
  for _, f in ipairs(files) do
    local y = extract_year(f.file)
    local label = (y and (label_base .. " " .. y)) or f.file
    table.insert(rows, { path = f.path, file = f.file, year = y, label = label })
    if y then table.insert(years, y) end
  end

  table.sort(rows, function(a, b)
    if a.year ~= b.year then
      if a.year == nil then return false end
      if b.year == nil then return true end
      return a.year > b.year
    else
      return a.file > b.file
    end
  end)

  local miny, maxy
  for _, y in ipairs(years) do
    if not miny or y < miny then miny = y end
    if not maxy or y > maxy then maxy = y end
  end

  local auto_title = (miny and maxy)
      and string.format("Arkiv (PDF, %s–%s)", miny, maxy)
       or string.format("Arkiv (PDF, %d filer)", #rows)
  local title = U(kwargs["title"] or auto_title)

  local collapsed_bool = (collapsed ~= "false")
  local expanded_attr  = collapsed_bool and "false" or "true"
  local btn_class      = collapsed_bool and "accordion-button collapsed" or "accordion-button"
  local collapse_class = collapsed_bool and "accordion-collapse collapse" or "accordion-collapse collapse show"
  local target_attr    = (target_blank ~= "false") and ' target="_blank" rel="noopener"' or ""

  local out = {}
  table.insert(out, string.format([[
<div class="accordion" id="%s">
  <div class="accordion-item">
    <h2 class="accordion-header" id="%s-header">
      <button class="%s" type="button" data-bs-toggle="collapse"
              data-bs-target="#%s-body" aria-expanded="%s" aria-controls="%s-body">
        %s
      </button>
    </h2>
    <div id="%s-body" class="%s" aria-labelledby="%s-header" data-bs-parent="#%s">
      <div class="accordion-body">
        <ul class="mb-0">]],
    html_escape(id_base),
    html_escape(id_base),
    btn_class,
    html_escape(id_base),
    expanded_attr,
    html_escape(id_base),
    html_escape(title),
    html_escape(id_base),
    collapse_class,
    html_escape(id_base),
    html_escape(id_base)
  ))

  for _, r in ipairs(rows) do
    table.insert(out, string.format([[
          <li class="mb-1">
            <i class="bi %s me-2"></i>
            <a href="%s"%s>%s</a>
          </li>]],
      html_escape(icon_class),
      html_escape(r.path),
      target_attr,
      html_escape(r.label)
    ))
  end

  table.insert(out, [[
        </ul>
      </div>
    </div>
  </div>
</div>]])

  return pandoc.RawBlock("html", table.concat(out, "\n"))
end

local U = pandoc.utils.stringify

local function h(s)
  s = U(s or "")
  return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
          :gsub('"',"&quot;"):gsub("'","&#39;"))
end

function externcard(args, kwargs, meta)
  local title   = U(kwargs["title"] or "Ekstern kilde")
  local text    = U(kwargs["text"]  or "")
  local url     = U(kwargs["url"]   or "#")
  local icon    = U(kwargs["icon"]  or "bi-id-badge")            -- left icon
  local chevron = U(kwargs["chevron"] or "bi-arrow-right-circle")-- right icon
  local target  = U(kwargs["target"] or "_blank")
  local rel     = U(kwargs["rel"] or "noopener")
  local style   = U(kwargs["style"] or "")

  local target_attr = (target ~= "") and (' target="'..h(target)..'"') or ""

  local html = string.format([[
<div class="card shadow-sm border-0 externcard position-relative" style="%s" role="link" aria-label="%s">
    <div class="card-body d-flex align-items-center justify-content-between p-4 gap-3">
      <div class="d-flex align-items-center gap-3 min-w-0">
        <i class="bi %s externcard-icon flex-shrink-0" aria-hidden="true"></i>
        <div class="min-w-0">
          <div class="externcard-title mb-1">%s</div>
          %s
        </div>
      </div>
      <i class="bi %s externcard-chevron flex-shrink-0" aria-hidden="true"></i>
    </div>
    <a class="stretched-link" href="%s"%s rel="%s"></a>
  </div>
  ]],
    h(style),
    h(title),
    h(icon),
    h(title),
    (text ~= "" and ('<div class="externcard-subtitle text-muted">'..h(text)..'</div>') or ""),
    h(chevron),
    h(url), target_attr, h(rel)
  )

  return pandoc.RawBlock("html", html)
end

function inflationcalc(args, kwargs, meta)
  local U  = pandoc.utils.stringify
  local id = U(kwargs["id"] or "inflation-calculator")

  local eyebrow  = U(kwargs["eyebrow"]  or "Beregner")
  local title    = U(kwargs["title"]    or "Inflationsberegner")
  local subtitle = U(kwargs["subtitle"] or
    "Se hvad et beløb fra et tidligere tidspunkt svarer til i priserne på et andet tidspunkt.")

  local html = [[
<div class="panel-card card inflation-card" id="{{ID}}">
  <div class="card-body d-flex flex-column gap-3">

    <!-- Header block -->
    <div>
      <div class="text-uppercase small fw-semibold text-muted mb-1">
        {{EYEBROW}}
      </div>
      <h2 class="card-title anchored">{{TITLE}}</h2>
      <p class="text-muted small mb-0">{{SUBTITLE}}</p>
    </div>

    <!-- Form body -->
    <div class="mt-2">
      <div class="row g-3 align-items-end">
        <div class="col-12 col-md-4">
          <label for="{{ID}}-amount" class="form-label">Beløb</label>
          <div class="input-group">
            <span class="input-group-text">kr.</span>
            <input type="number" class="form-control" id="{{ID}}-amount"
                   value="1000" min="0" step="1">
          </div>
        </div>

        <div class="col-6 col-md-4">
          <label for="{{ID}}-from" class="form-label">Fra</label>
          <select class="form-select" id="{{ID}}-from"></select>
        </div>

        <div class="col-6 col-md-4">
          <label for="{{ID}}-to" class="form-label">Til</label>
          <select class="form-select" id="{{ID}}-to"></select>
        </div>
      </div>
    </div>

    <!-- Result footer -->
    <div class="mt-3 pt-2 border-top" style="border-top-color: var(--hairline);">
      <p class="mb-1 text-muted">
        Omregnet beløb i priser for <span id="{{ID}}-to-label"></span>:
      </p>
      <p class="fs-4 fw-bold mb-0">
        <span id="{{ID}}-result">—</span> kr.
      </p>

      <p class="mt-2 mb-0 text-muted small" id="{{ID}}-meta">
        Henter prisindeks fra Statistikbanken …
      </p>
    </div>

  </div>
</div>

<script src="/_extensions/StatisticsGreenland/statglshortcodes/inflationcalc.js"></script>
<script>
  if (window.initInflationCalc) {
    window.initInflationCalc("{{ID}}");
  } else {
    console.error("inflationcalc.js not loaded: initInflationCalc missing");
  }
</script>
]]

  html = html:gsub("{{ID}}", id)
  html = html:gsub("{{EYEBROW}}", eyebrow)
  html = html:gsub("{{TITLE}}", title)
  html = html:gsub("{{SUBTITLE}}", subtitle)

  return pandoc.RawBlock("html", html)
end