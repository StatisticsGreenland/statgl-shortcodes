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

  -- helpers
  local function escfmt(s)  -- escape % for string.format
    if not s or s == "" then return s end
    return s:gsub("%%", "%%%%")
  end
  local function md_to_html(md)
    if md == "" then return "" end
    return pandoc.write(pandoc.read(md, "markdown"), "html")
  end

  -- inputs
  local title           = utils.stringify(kwargs["title"] or "")
  local subtitle        = utils.stringify(kwargs["subtitle"] or "")
  local description     = utils.stringify(kwargs["description"] or "")

  -- plot 1
  local plot_title      = utils.stringify(kwargs["plot_title"] or "")
  local plot_subtitle   = utils.stringify(kwargs["plot_subtitle"] or "")
  local plot_html       = utils.stringify(kwargs["plot"] or "")
  local plot_link       = utils.stringify(kwargs["plot_link"] or "")
  local plot_height     = utils.stringify(kwargs["plot_height"] or "300px")

  -- plot 2
  local plot2_title     = utils.stringify(kwargs["plot2_title"] or "")
  local plot2_subtitle  = utils.stringify(kwargs["plot2_subtitle"] or "")
  local plot2_html      = utils.stringify(kwargs["plot2"] or "")
  local plot2_link      = utils.stringify(kwargs["plot2_link"] or "")
  local plot2_height    = utils.stringify(kwargs["plot2_height"] or plot_height)

  local img             = utils.stringify(kwargs["img"] or "")
  local accordion_title = utils.stringify(kwargs["accordion"] or "Mere")
  local more_raw        = utils.stringify(kwargs["more"] or "")

  -- trim + dedent (fixes Markdown turning indented text into code blocks)
  local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$","")) end

  local function dedent(s)
    local minindent
    for line in s:gmatch("[^\r\n]*\r?\n?") do
      if line:match("%S") then
        local indent = line:match("^%s*"):len()
        minindent = (minindent and math.min(minindent, indent)) or indent
      end
    end
    if not minindent or minindent == 0 then return s end
    local pat = "^" .. string.rep(" ", minindent)
    return (s:gsub("\r\n", "\n"):gsub("\n" .. pat, "\n"):gsub("^" .. pat, ""))
  end

  -- allow generic 'link' and 'link2' shorthands
  if plot_link == "" then
    local generic_link = utils.stringify(kwargs["link"] or "")
    if generic_link ~= "" then plot_link = generic_link end
  end
  if plot2_link == "" then
    local generic_link2 = utils.stringify(kwargs["link2"] or "")
    if generic_link2 ~= "" then plot2_link = generic_link2 end
  end

  -- clean plot html (correct raw-HTML fence + whitespace)
  local function clean_plot_html(html)
    html = html
      :gsub("`{=html}", "")
      :gsub("`", "")
      :gsub("^%s+", "")
      :gsub("%s+$", "")
    html = html:gsub("^%s*<p>(.*)</p>%s*$", "%1")
    return html
  end

  plot_html  = clean_plot_html(plot_html)
  plot2_html = clean_plot_html(plot2_html)

  -- description -> html (strip outer <p>)
  local description_html = ""
  if description ~= "" then
    description_html = md_to_html(description)
    description_html = description_html:gsub("^<p>(.*)</p>\n?$", "%1")
  end

  -- turn links into small html spans
  if plot_link ~= "" then
    plot_link = md_to_html('<span style="font-size:0.7em;">' .. plot_link .. '</span>')
  end
  if plot2_link ~= "" then
    plot2_link = md_to_html('<span style="font-size:0.7em;">' .. plot2_link .. '</span>')
  end

  -- extra links link_*
  local links = {}
  for key, val in pairs(kwargs) do
    if key:match("^link_") then table.insert(links, val) end
  end
  local rendered_links = {}
  for _, mdlink in ipairs(links) do
    local html = md_to_html(mdlink)
    html = html:gsub("^<p>(.*)</p>\n?$", "%1")
    table.insert(rendered_links, string.format("<li>%s</li>", html))
  end

  -- "more" content with custom line-break tokens (robust)
  local more_html = ""
  if more_raw ~= "" then
    local more_md = dedent(more_raw):gsub("\r\n", "\n")
    -- paragraph breaks
    more_md = more_md
      :gsub("\\\\§\\\\§", "\n\n")  -- \§\§ (double backslashes after Lua escaping)
      :gsub("\\§\\§",   "\n\n")    -- edge cases
      :gsub("§§",       "\n\n")    -- plain §§

    -- hard line breaks
    more_md = more_md
      :gsub("\\\\§", "  \n")       -- \§
      :gsub("\\§",   "  \n")       -- edge cases

    more_md = trim(more_md)
    more_html = md_to_html(more_md)
  end

  -- build accordion body if anything to show
  local accordion_block = ""
  do
    local body_parts = {}
    if more_html ~= "" then table.insert(body_parts, '<div class="shorty-more">' .. more_html .. '</div>') end
    if #rendered_links > 0 then
      table.insert(body_parts, '<ul class="shorty-links">' .. table.concat(rendered_links, "\n") .. '</ul>')
    end

    if #body_parts > 0 then
      local randcase = string.char(math.random(97, 122)) .. tostring(math.random(1000,9999))
      local acc_id = "acc-" .. randcase
      local body_html = table.concat(body_parts, "\n")
      accordion_title = escfmt(accordion_title)
      body_html = escfmt(body_html)

      accordion_block = string.format([[
        <div class="accordion panel-accordion" id="%s">
          <div class="accordion-item">
            <div class="accordion-header" id="heading-%s">
              <button class="accordion-button collapsed" type="button"
                data-bs-toggle="collapse" data-bs-target="#collapse-%s"
                aria-expanded="false" aria-controls="%s">%s</button>
            </div>
            <div id="collapse-%s" class="accordion-collapse collapse"
                 aria-labelledby="heading-%s" data-bs-parent="#%s">
              <div class="accordion-body">%s</div>
            </div>
          </div>
        </div>
      ]], acc_id, randcase, randcase, randcase, accordion_title, randcase, randcase, acc_id, body_html)
    end
  end

  -- ---------- plot builder (lazy render with native animation)
  local function build_plot_block(ptitle, psubtitle, phtml, plink, pheight)
    local has_content = (ptitle ~= "" or phtml ~= "" or plink ~= "")
    if not has_content then return "" end

    local sub_html = ""
    if psubtitle ~= "" then
      psubtitle = escfmt(psubtitle)
      sub_html = string.format(
        '<div class="text-muted" style="font-size:0.9em;margin-bottom:0.3rem;">%s</div>',
        psubtitle
      )
    end

    local pid  = "plot-" .. tostring(math.random(100000, 999999))
    local tid  = "tpl-"  .. tostring(math.random(100000, 999999))

    ptitle  = escfmt(ptitle)
    phtml   = escfmt(phtml)

    if plink ~= "" then
      plink = plink:gsub("^<p>(.*)</p>\n?$", "%1")
      plink = escfmt(plink)
    end

    pheight = escfmt(pheight)

    local block = string.format([[
      <div class="card-title">%s</div>
      %s
      <div id="%s" class="plot-frame" style="height:%s;"></div>
      <template id="%s"><div class="plot-area">%s</div></template>
      %s
      <script>
        (function(){
          var holder = document.getElementById('%s');
          var tpl    = document.getElementById('%s');
          if(!holder || !tpl) return;
          function renderNow(){
            var frag = tpl.content.cloneNode(true);
            holder.appendChild(frag);
            if (window.HTMLWidgets && typeof HTMLWidgets.staticRender === 'function') {
              try { HTMLWidgets.staticRender(); } catch(e){}
            }
            if (window._initRevealTables) window._initRevealTables(holder);
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
    ]], ptitle, sub_html, pid, pheight, tid, phtml, plink, pid, tid)

    return block
  end

  local has_plot1 = (plot_title ~= "" or plot_html ~= "" or plot_link ~= "")
  local has_plot2 = (plot2_title ~= "" or plot2_html ~= "" or plot2_link ~= "")
  local has_img   = (img ~= "")

  local plot_block1 = has_plot1 and build_plot_block(plot_title,  plot_subtitle,  plot_html,  plot_link,  plot_height)  or ""
  local plot_block2 = has_plot2 and build_plot_block(plot2_title, plot2_subtitle, plot2_html, plot2_link, plot2_height) or ""

  -- ---------- image block
  local img_block = ""
  if has_img then
    img = escfmt(img)
    img_block = string.format([[
      <div class="grid">
        <div class="g-col-12" style="display:flex;align-items:center;justify-content:center;">
          <img src="%s" class="img-fluid" style="max-height:250px;">
        </div>
      </div>
    ]], img)
  end

  -- ---------- grid logic (two plots side by side)
  local grid_block = ""
  if has_plot1 and has_plot2 then
    grid_block = string.format([[
      <div class="grid shorty-grid">
        <div class="g-col-12 g-col-md-6">
          <div class="shorty-plotcol">
            %s
          </div>
        </div>
        <div class="g-col-12 g-col-md-6">
          <div class="shorty-plotcol">
            %s
          </div>
        </div>
      </div>
    ]], plot_block1, plot_block2)
  elseif has_plot1 then
    grid_block = string.format([[
      <div class="grid shorty-grid">
        <div class="g-col-12">
          <div class="shorty-plotcol">
            %s
          </div>
        </div>
      </div>
    ]], plot_block1)
  elseif has_plot2 then
    grid_block = string.format([[
      <div class="grid shorty-grid">
        <div class="g-col-12">
          <div class="shorty-plotcol">
            %s
          </div>
        </div>
      </div>
    ]], plot_block2)
  end

  if has_img then
    grid_block = grid_block .. "\n" .. img_block
  end

  -- ---------- subtitle
  local subtitle_html = ""
  if subtitle ~= "" then
    subtitle = escfmt(subtitle)
    subtitle_html = string.format('<div class="text-muted" style="margin-bottom:0.5rem;">%s</div>', subtitle)
  end

  -- ---------- final card
  title            = escfmt(title)
  description_html = escfmt(description_html)

  local html = string.format([[
    <div class="card panel-card mb-4">
      <div class="card-body">
        <h2 class="card-title">%s</h2>
        %s
        %s
        %s
        %s
      </div>
    </div>
  ]], title, subtitle_html,
      (description_html ~= "" and string.format('<p class="card-text">%s</p>', description_html) or ""),
      grid_block, accordion_block)

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