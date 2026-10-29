-- Phosphor Icons: alias table, weight rules and <i> markup live in
-- phosphor.lua (shared with the phosphor-icons.lua filter). Card-sized
-- icons are thin, small inline icons regular; an explicit weight in the
-- icon spec ("ph-fill ph-house") wins. Legacy "bi-*" names are aliased.
local PH = dofile(pandoc.path.join({ pandoc.path.directory(PANDOC_SCRIPT_FILE), "phosphor.lua" }))

function kpicard(args, kwargs, meta)
  local title = pandoc.utils.stringify(kwargs["title"] or "")
  local subtitle = pandoc.utils.stringify(kwargs["subtitle"] or "")
  local value = pandoc.utils.stringify(kwargs["value"] or "")
  local link = pandoc.utils.stringify(kwargs["link"] or "")
  local style = pandoc.utils.stringify(kwargs["style"] or "")
  local filter_show = pandoc.utils.stringify(kwargs["filter_show"] or "")
  local delta = pandoc.utils.stringify(kwargs["delta"] or "")
  local delta_title = pandoc.utils.stringify(kwargs["delta_title"] or "")
  local delta_arrow = pandoc.utils.stringify(kwargs["delta_arrow"] or "")

  local style_attr = ""
  if style ~= "" then
    style_attr = ' style="' .. style .. '"'
  end

  -- Optional bottom-right delta indicator. Arrow direction is read off the
  -- sign of the delta string: leading "-" (or U+2212) gives a down arrow,
  -- anything else an up arrow. Suppress with delta_arrow = "false".
  local delta_html = ""
  if delta ~= "" or delta_title ~= "" then
    local value_html = ""
    if delta ~= "" then
      local arrow = ""
      if delta_arrow ~= "false" then
        local trimmed = delta:gsub("^%s+", "")
        if trimmed:match("^%-") or trimmed:match("^\u{2212}") then
          arrow = '<span class="KeyDeltaArrow" aria-hidden="true">&#9660;</span> '
        else
          arrow = '<span class="KeyDeltaArrow" aria-hidden="true">&#9650;</span> '
        end
      end
      value_html = string.format('<div class="KeyDeltaValue">%s%s</div>', arrow, delta)
    end
    local title_html = ""
    if delta_title ~= "" then
      title_html = string.format('<div class="KeyDeltaTitle">%s</div>', delta_title)
    end
    delta_html = string.format([[
        <div class="KeyDelta">
          %s
          %s
        </div>]], value_html, title_html)
  end

  local card_html = ""

  if link ~= "" then
    -- Accessible anchor version
    card_html = string.format([[
      <a class="card KeyBox" href="%s"%s>
        <div class="KeyValue">%s</div>
        <div class="KeyTitle">%s</div>
        <div class="KeySubtitle">%s</div>%s
      </a>
    ]], link, style_attr, value, title, subtitle, delta_html)

  else
    -- Non-link fallback
    card_html = string.format([[
      <div class="card KeyBox"%s>
        <div class="KeyValue">%s</div>
        <div class="KeyTitle">%s</div>
        <div class="KeySubtitle">%s</div>%s
      </div>
    ]], style_attr, value, title, subtitle, delta_html)
  end

  -- Optional filter_show wrapper: hides card based on page-wide filter state.
  -- Format: "<filter_id>:<value>"  e.g. "station:Nuuk", "station:*" (any value
  -- selected), or "station:" (no selection / default).
  local html = card_html
  if filter_show ~= "" then
    html = string.format(
      '<div data-filter-show="%s">%s</div>',
      filter_show, card_html
    )
  end

  return pandoc.RawBlock("html", html)
end

-- Read `final:` from the frontmatter of the qmd a card links to, so
-- hand-placed cards get the same card--final / card--draft colouring as
-- EJS listing cards. Returns " card--final", " card--draft" or "".
local function final_status_class(link)
  if link == "" or link == "#" or link:match("^%a[%w+.-]*:") then return "" end
  local target = link:gsub("[#?].*$", "")
  if not target:match("%.qmd$") then return "" end

  local path
  if target:sub(1, 1) == "/" then
    local root = (quarto and quarto.project and quarto.project.directory) or "."
    path = root .. target
  else
    local input = quarto and quarto.doc and quarto.doc.input_file
    if not input then return "" end
    local dir = input:match("^(.*)[/\\]") or "."
    path = dir .. "/" .. target
  end

  local f = io.open(path, "r")
  if not f then return "" end
  local src = f:read("*a")
  f:close()

  local yaml = src:gsub("\r\n", "\n"):match("^%-%-%-\n(.-)\n%-%-%-")
  if not yaml then return "" end
  local v = ("\n" .. yaml):match("\nfinal:%s*['\"]?(%a+)")
  if v == "true" then return " card--final" end
  if v == "false" then return " card--draft" end
  return ""
end

function sectioncard(args, kwargs, meta)
  local U     = pandoc.utils.stringify
  local icon  = PH.classes(U(kwargs["icon"] or ""), "thin", "ph-package")
  local title = U(kwargs["title"] or "Title")
  local text  = U(kwargs["text"]  or "Description text")
  local link  = U(kwargs["link"]  or "#")
  local status = final_status_class(link)

  local html = string.format([[
<a class="sectioncard card h-100 text-start text-md-center%s" href="%s" aria-label="%s">
  <div class="card-body d-flex flex-row flex-md-column align-items-center gap-3 gap-md-1">
    <i class="%s sectioncard-icon me-2 me-md-0" aria-hidden="true"></i>
    <div class="sectioncard-textblock">
      <div class="section-title">%s</div>
      <p class="card-text sectioncard-text">%s</p>
    </div>
  </div>
</a>
]], status, link, title, icon, title, text)

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
    if s == nil then return false end

    -- coerce non-strings (e.g. pandoc inlines) to a string
    if type(s) ~= "string" then
      s = U(s)
    end

    if s == "" then return false end
    return s:match("^%s*<[%w!%?/]") ~= nil
  end

  local function looks_like_widget(s)
    if not s or s == "" then return false end
    if s:match("html%-widget") then return true end
    if s:match("highchart")    then return true end
    return false
  end

  local function trim_to_string(x)
    if x == nil then return "" end
    if type(x) ~= "string" then
      x = U(x)
    end
    -- trim leading/trailing whitespace
    x = x:gsub("^%s+", ""):gsub("%s+$", "")
    return x
  end

  -- helper: build a single plot column (no link/docs here) -------
  local function build_plotcol(plot_html, plot_subtitle_html, height)
    if not plot_html or plot_html == "" then
      return ""
    end

    -- widget path: lazy-load container
    if looks_like_widget(plot_html) then
      local id_suffix   = tostring(math.random(100000, 999999))
      local plot_id     = "plot-" .. id_suffix
      local tpl_id      = "tpl-"  .. id_suffix
      local height_attr = ""

      if height and height ~= "" then
        height_attr = ' style="height:' .. escfmt(height) .. ';"'
      end

      return string.format([[
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
      </div>]],
        plot_subtitle_html or "",
        escfmt(plot_id), height_attr,
        escfmt(tpl_id),  plot_html,
        escfmt(plot_id), escfmt(tpl_id)
      )
    else
      -- table / plain HTML path
      return string.format([[
      <div class="shorty-plotcol">
        %s
        <div class="plot-frame">
          <div class="plot-area">
            <div class="shorty-table-wrapper">
              %s
            </div>
          </div>
        </div>
      </div>]],
        plot_subtitle_html or "",
        plot_html
      )
    end
  end

  -- inputs -------------------------------------------------------
  local title         = U(kwargs["title"]         or "")
  local subtitle      = U(kwargs["subtitle"]      or "")
  local description   = U(kwargs["description"]   or "")
  local link          = U(kwargs["link"]          or "")
  local img           = U(kwargs["img"]           or "")
  local icon          = U(kwargs["icon"]          or "")

  local plot_raw      = U(kwargs["plot"]          or "")
  local plot2_raw     = U(kwargs["plot2"]         or "")
  local plot_title    = U(kwargs["plot_title"]    or "")
  local plot2_title   = U(kwargs["plot2_title"]   or "")
  local plot_subtitle = U(kwargs["plot_subtitle"] or "")
  local plot2_subtitle= U(kwargs["plot2_subtitle"] or "")

  local height        = U(kwargs["height"]        or "")
  local width         = U(kwargs["width"]         or "")
  local anchor_id     = U(kwargs["anchor"] or "")
  local filter_series = U(kwargs["filter_series"] or "")
  local filter_show   = U(kwargs["filter_show"]   or "")
  local toc_level_raw = U(kwargs["toc_level"]     or "")

  -- optional image -----------------------------------------------
  local img_html = ""
  if img ~= "" then
    img_html = string.format(
      '<div class="shorty-image mb-3"><img src="%s" class="img-fluid" alt=""></div>',
      escfmt(img)
    )
  end

  -- plot HTML ----------------------------------------------------
  local plot_html  = ""
  local plot2_html = ""

  if plot_raw ~= "" then
    if looks_like_html(plot_raw) then
      plot_html = plot_raw
    else
      plot_html = md_to_html(plot_raw)
    end
  end

  if plot2_raw ~= "" then
    if looks_like_html(plot2_raw) then
      plot2_html = plot2_raw
    else
      plot2_html = md_to_html(plot2_raw)
    end
  end

  local has_plot1 = (plot_html  ~= "" and plot_html  ~= nil)
  local has_plot2 = (plot2_html ~= "" and plot2_html ~= nil)

  ----------------------------------------------------------------
  -- docs (doc1_title/doc1_text, …, doc6_title/doc6_text)
  ----------------------------------------------------------------
    ----------------------------------------------------------------
  -- docs (doc1_title/doc1_text, …, doc6_title/doc6_text)
  ----------------------------------------------------------------
  local docs = {}
  for i = 1, 6 do
    local t      = U(kwargs["doc" .. i .. "_title"] or "")
    local body_v = kwargs["doc" .. i .. "_text"]    -- keep original
    local body_s = trim_to_string(body_v)           -- normalized for checks

    -- only create an item if there is *something* real here
    if t ~= "" or body_s ~= "" then
      table.insert(docs, { title = t, body = body_v })
    end
  end

  local docs_html = ""
  if #docs > 0 then
    local base_id = "shortydocs-" .. tostring(math.random(100000, 999999))
    docs_html = '<div class="accordion shorty-docs mt-3" id="' .. escfmt(base_id) .. '">'

    for idx, d in ipairs(docs) do
      local item_id   = base_id .. "-item-" .. idx

      -- --- body: HTML vs markdown -------------------------------
      local body_src  = d.body or ""
      local body_html = ""
      if body_src ~= "" then
        if looks_like_html(body_src) then
          body_html = body_src
        else
          body_html = md_to_html(body_src)
        end
      end

      -- wrap body like plots so tables are "contained"
      if body_html ~= "" then
        body_html = string.format([[
<div class="plot-frame">
  <div class="plot-area">
    <div class="shorty-table-wrapper">
      %s
    </div>
  </div>
</div>]], body_html)
      end

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
        escfmt(body_html)  -- escape % for string.format, keep HTML as-is
      )
    end

    docs_html = docs_html .. "</div>"
  end
  ----------------------------------------------------------------
  ----------------------------------------------------------------

  -- link under plot(s) -------------------------------------------
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
    subtitle_html = '<div class="shorty-subtitle">' .. md_to_html(subtitle) .. '</div>'
  end

  local description_html = ""
  if description ~= "" then
    description_html = '<div class="shorty-description">' .. md_to_html(description) .. '</div>'
  end

  -- centered image / icon ----------------------------------------
  -- icon = "ph-vault" -> Phosphor glyph, flanked by rule lines
  --                     (see .shorty-icon). img wins if both are given.
  img_html = ""
  if img ~= "" then
    img_html = string.format(
      '<div class="shorty-image text-center mb-3"><img src="%s" class="img-fluid" alt=""></div>',
      escfmt(img)
    )
  elseif icon ~= "" then
    img_html = string.format(
      '<div class="shorty-icon mb-3" aria-hidden="true"><i class="%s"></i></div>',
      escfmt(PH.classes(icon, "thin"))
    )
  end

-- Title is emitted as a real pandoc.Header (not raw HTML) so Quarto's
-- TOC picks it up. The textcol wrapper is therefore split into an opening
-- part (before the header) and a "rest" part (after it).
-- TOC handling for the title.
--
-- Quarto builds its TOC from headers that sit at the document's top level: it
-- wraps each in a <section id="…"> during normalization and the TOC is built
-- from those sections. A header *nested* inside the card's Divs is never
-- wrapped, so it never reaches the TOC — id or not.
--
-- So we emit two things:
--   * title_block: a real, top-level (visually hidden) Header carrying the
--     anchor id. Quarto wraps it in a <section> (the following card lands
--     inside that section), and it shows up in the TOC with the real title.
--   * title_html: the visible card title, kept inside the card as before, so
--     the layout is unchanged.
-- `toc_level` controls TOC behaviour with a single arg:
--   unset / ""                -> show in TOC at the default level (3)
--   "0" / "false" / "none"    -> not in the TOC at all
--   "1".."6"                  -> show in the TOC at that header level
--                               (nest under section headings by going deeper;
--                                remember Quarto's toc-depth must allow it)
local toc_level   = 3
local show_in_toc = true
do
  local tl = toc_level_raw:lower():gsub("%s+", "")
  if tl ~= "" then
    if tl == "0" or tl == "false" or tl == "none" or tl == "no" then
      show_in_toc = false
    else
      local n = tonumber(tl)
      if n and n >= 1 and n <= 6 then
        toc_level = math.floor(n)
      end
    end
  end
end

local title_block = nil
local title_html  = ""
if title ~= "" then
  -- Filter-generated headers don't receive Quarto's auto identifier, so
  -- assign one: the `anchor` arg if given, else a slug derived from the title.
  local function slugify(s)
    s = pandoc.text.lower(s)
    s = s:gsub("[%z\1-\31]", "")
    s = s:gsub("%s+", "-"):gsub("[^%w%-_]", ""):gsub("%-+", "-")
    s = s:gsub("^%-+", ""):gsub("%-+$", "")
    return s
  end

  local header_id = anchor_id ~= "" and anchor_id or slugify(title)
  if header_id == "" then
    header_id = "shorty-" .. tostring(math.random(100000, 999999))
  end

  -- Visible title inside the card. anchor.js resolves the anchor icon's href
  -- as id -> data-anchor-id -> slug of the text content, so without an
  -- attribute it would mint its own slug-of-title id and the icon would point
  -- past the real anchor. When the hidden TOC header exists, its <section>
  -- owns the id, so the visible h3 gets data-anchor-id (no duplicate id).
  -- Without a TOC header there is no section, so the h3 carries the id itself.
  if show_in_toc then
    title_html = '<h3 class="card-title" aria-hidden="true" data-anchor-id="'
      .. escfmt(header_id) .. '">' .. escfmt(title) .. '</h3>'
  else
    title_html = '<h3 class="card-title" aria-hidden="true" id="'
      .. escfmt(header_id) .. '">' .. escfmt(title) .. '</h3>'
  end

  if show_in_toc then
    -- Hidden top-level header for the TOC anchor.
    -- NB: Quarto copies a header's classes onto the <section> it wraps it in,
    -- so we must NOT use a generic hide-anything class like `visually-hidden`
    -- (it would hide the whole section, card included). Instead we tag it and
    -- hide it with an element-qualified rule (h3.shorty-toc-anchor, etc.) in
    -- styles.css, which the copied class on the <section> element can't match.
    local attr = pandoc.Attr(header_id, {"shorty-toc-anchor"})
    -- A title such as "2. Foo" or "> Foo" parses as a list/blockquote rather
    -- than a paragraph; Header needs Inlines, so fall back to the literal text.
    local parsed = pandoc.read(title, "markdown").blocks
    local title_inlines
    if #parsed == 1 and (parsed[1].t == "Para" or parsed[1].t == "Plain") then
      title_inlines = parsed[1].content
    else
      title_inlines = pandoc.Inlines{ pandoc.Str(title) }
    end
    title_block = pandoc.Header(toc_level, title_inlines, attr)
  end
end

  local text_rest = string.format([[
    %s        <!-- visible title -->
    %s        <!-- subtitle -->
    %s        <!-- centered img -->
    %s        <!-- description -->]],
    title_html,
    subtitle_html,
    img_html,
    description_html
  )

  -- plot titles / subtitles ---------------------------------------
  -- plot_title is the chart heading, plot_subtitle the line under it
  -- (typically the unit). Either may be given alone.
  local function plot_head(t, st)
    local out = ""
    if t ~= "" then
      out = out .. '<p class="shorty-plot-title">' .. escfmt(t) .. '</p>'
    end
    if st ~= "" then
      out = out .. '<p class="shorty-plot-subtitle">' .. escfmt(st) .. '</p>'
    end
    return out
  end
  local plot_subtitle_html  = plot_head(plot_title,  plot_subtitle)
  local plot2_subtitle_html = plot_head(plot2_title, plot2_subtitle)

  -- plot block (1 or 2 plots, link + docs under plots) ----------
  local plot_block = ""

  if has_plot1 or has_plot2 then
    if has_plot1 and has_plot2 then
      -- two plots side by side
      local col1 = build_plotcol(plot_html,  plot_subtitle_html,  height)
      local col2 = build_plotcol(plot2_html, plot2_subtitle_html, height)

      plot_block = string.format([[
<div class="grid shorty-plotrow">
  <div class="g-col-12 g-col-md-6">
    %s
  </div>
  <div class="g-col-12 g-col-md-6">
    %s
  </div>
</div>
%s
%s]],
        col1,
        col2,
        plot_link_html,
        docs_html
      )
    else
      -- single plot
      local only_html          = has_plot1 and plot_html or plot2_html
      local only_subtitle_html = has_plot1 and plot_subtitle_html or plot2_subtitle_html

      local col = build_plotcol(only_html, only_subtitle_html, height)

      plot_block = string.format([[
      <div class="shorty-plotrow shorty-one-plot">
        %s
      </div>
      %s
      %s]],
        col,
        plot_link_html,
        docs_html
      )
    end
  end

  -- outer wrapper (built as pandoc Divs so DOM nesting matches the old output;
  -- the TOC header is returned separately, at top level, further below) -------

  -- textcol: visible title + remaining text, all as raw HTML
  local textcol = pandoc.Div(
    {pandoc.RawBlock("html", text_rest)},
    pandoc.Attr("", {"shorty-textcol"})
  )

  -- g-col-12: textcol + plot block
  local gcol_children = pandoc.List({})
  gcol_children:insert(textcol)
  if plot_block ~= "" then
    gcol_children:insert(pandoc.RawBlock("html", plot_block))
  end
  local gcol     = pandoc.Div(gcol_children, pandoc.Attr("", {"g-col-12"}))
  local grid     = pandoc.Div({gcol},     pandoc.Attr("", {"grid", "shorty-grid"}))
  local cardbody = pandoc.Div({grid},     pandoc.Attr("", {"card-body"}))

  -- Optional filter attrs on the outer card.
  --   filter_series="station" -> data-filter-series="station" so the bus
  --     filters Highcharts series inside this card by series.tags.station.
  local card_kv = {}
  if filter_series ~= "" then
    table.insert(card_kv, {"data-filter-series", filter_series})
  end

  -- Optional width tier: lets a single card break out of the ~900px content
  -- column for wide tables. Mapped to a tier class; the actual widening is
  -- gutter-limited in styles.css so it can never cause horizontal overflow.
  --   ""                       -> normal content width (unchanged)
  --   "outset" / "wide"        -> shorty-w-outset  (modest widen)
  --   "page"                   -> shorty-w-page     (wider)
  --   "screen" / "full"        -> shorty-w-screen   (fills the gutters)
  local card_classes = {"card", "panel-card", "mb-4", "shorty"}
  do
    local w = width:lower():gsub("%s+", "")
    local tier = nil
    if w == "outset" or w == "wide" then
      tier = "shorty-w-outset"
    elseif w == "page" then
      tier = "shorty-w-page"
    elseif w == "screen" or w == "full" then
      tier = "shorty-w-screen"
    end
    if tier then
      table.insert(card_classes, "shorty-wide")
      table.insert(card_classes, tier)
    end
  end

  local card = pandoc.Div(
    {cardbody},
    pandoc.Attr("", card_classes, card_kv)
  )

  -- Optional filter_show wrapper around the whole card (same semantics as
  -- on kpicard: "<filter_id>:<value>", "<id>:*", or "<id>:").
  local card_node = card
  if filter_show ~= "" then
    card_node = pandoc.Div(
      {card},
      pandoc.Attr("", {}, {{"data-filter-show", filter_show}})
    )
  end

  -- Return the hidden TOC header (top-level, so Quarto wraps it in a <section>
  -- and the card lands inside it) followed by the card itself.
  if title_block then
    return pandoc.List({title_block, card_node})
  end
  return card_node
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
        <i class="%s"></i>
      </div>
    ]], PH.classes(icon, "thin"))
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
          </div>
        </div>
        %s
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
  local icon  = U(kwargs["icon"]  or "ph-user-circle")
  local style = U(kwargs["style"] or "")
  if icon == "" then icon = "ph-user-circle" end
  icon = PH.classes(icon, "thin")

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
      '<li class="contact-line"><i class="ph ph-map-pin me-2"></i><span>%s</span></li>',
      joined))
  end

  -- Phone (obfuscated)
  if phone_codes ~= "" then
    table.insert(lines, string.format(
      '<li class="contact-line"><i class="ph ph-phone me-2"></i>' ..
      '<span class="staff-phone" data-phone-codes="%s"></span></li>',
      phone_codes))
  end

  -- Email (obfuscated)
  if email_codes ~= "" then
    table.insert(lines, string.format(
      '<li class="contact-line"><i class="ph ph-envelope me-2"></i>' ..
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
            <i class="%s" aria-hidden="true"></i>
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
      <span class="readmore__icon"><i class="ph ph-plus"></i></span>
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
  local icon_class   = PH.classes(U(kwargs["icon"] or ""), "regular", "ph-file-pdf")
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
            <i class="%s me-2"></i>
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
  local icon    = PH.classes(U(kwargs["icon"]    or ""), "thin", "ph-identification-badge") -- left
  local chevron = PH.classes(U(kwargs["chevron"] or ""), "regular", "ph-arrow-circle-right")   -- right
  local target  = U(kwargs["target"] or "_blank")
  local rel     = U(kwargs["rel"] or "noopener")
  local style   = U(kwargs["style"] or "")

  local target_attr = (target ~= "") and (' target="'..h(target)..'"') or ""

  local html = string.format([[
<div class="card shadow-sm border-0 externcard position-relative" style="%s" role="link" aria-label="%s">
    <div class="card-body d-flex align-items-center justify-content-between p-4 gap-3">
      <div class="d-flex align-items-center gap-3 min-w-0">
        <i class="%s externcard-icon flex-shrink-0" aria-hidden="true"></i>
        <div class="min-w-0">
          <div class="externcard-title mb-1">%s</div>
          %s
        </div>
      </div>
      <i class="%s externcard-chevron flex-shrink-0" aria-hidden="true"></i>
    </div>
    <a class="stretched-link" href="%s"%s rel="%s"></a>
  </div>
  ]],
    h(style),
    h(title),
    h(icon),
    h(title),
    (text ~= "" and ('<div class="externcard-subtitle">'..h(text)..'</div>') or ""),
    h(chevron),
    h(url), target_attr, h(rel)
  )

  return pandoc.RawBlock("html", html)
end

function inflationcalc(args, kwargs, meta)
  local U  = pandoc.utils.stringify
  local id = U(kwargs["anchor"] or "inflation-calculator")

  local eyebrow  = U(kwargs["eyebrow"]  or "Beregner")
  local title    = U(kwargs["title"]    or "Inflationsberegner")
  local subtitle = U(kwargs["subtitle"] or
    "Se hvad et beløb fra et tidligere tidspunkt svarer til i priserne på et andet tidspunkt.")

  -- Form labels (scraped by generate_twins.R for translation)
  local amount_label = U(kwargs["amount_label"] or "Beløb")
  local from_label   = U(kwargs["from_label"]   or "Fra")
  local to_label     = U(kwargs["to_label"]     or "Til")
  local result_label = U(kwargs["result_label"] or "Omregnet beløb i priser for")

  -- Markup uses the site's CSS grid (.grid/.g-col-*) like every other card;
  -- Bootstrap's .row/.col-* are not part of Quarto's build, so the old
  -- three-column form stacked at every width. Styling: .inflation-* in styles.css.
  local eyebrow_html = ""
  if eyebrow ~= "" then
    eyebrow_html = '<div class="inflation-eyebrow">' .. eyebrow .. '</div>'
  end

  local html = [[
<div class="panel-card card inflation-card" id="{{ID}}">
  <div class="card-body">
    {{EYEBROW_HTML}}
    <h2 class="card-title anchored">{{TITLE}}</h2>
    <p class="inflation-subtitle">{{SUBTITLE}}</p>
    <div class="grid inflation-form">
      <div class="g-col-12 g-col-md-4">
        <label for="{{ID}}-amount" class="form-label">{{AMOUNT_LABEL}}</label>
        <div class="input-group">
          <span class="input-group-text">kr.</span>
          <input type="number" class="form-control" id="{{ID}}-amount"
                 value="1000" min="0" step="1" inputmode="decimal">
        </div>
      </div>
      <div class="g-col-6 g-col-md-4">
        <label for="{{ID}}-from" class="form-label">{{FROM_LABEL}}</label>
        <select class="form-select" id="{{ID}}-from"></select>
      </div>
      <div class="g-col-6 g-col-md-4">
        <label for="{{ID}}-to" class="form-label">{{TO_LABEL}}</label>
        <select class="form-select" id="{{ID}}-to"></select>
      </div>
    </div>
    <div class="inflation-result" aria-live="polite">
      <div class="inflation-result-label">{{RESULT_LABEL}} <span id="{{ID}}-to-label"></span></div>
      <div class="inflation-result-value"><span id="{{ID}}-result">—</span> kr.</div>
      <div class="inflation-result-meta" id="{{ID}}-meta">Henter prisindeks fra Statistikbanken …</div>
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
  html = html:gsub("{{EYEBROW_HTML}}", eyebrow_html)
  html = html:gsub("{{TITLE}}", title)
  html = html:gsub("{{SUBTITLE}}", subtitle)
  html = html:gsub("{{AMOUNT_LABEL}}", amount_label)
  html = html:gsub("{{FROM_LABEL}}", from_label)
  html = html:gsub("{{TO_LABEL}}", to_label)
  html = html:gsub("{{RESULT_LABEL}}", result_label)

  return pandoc.RawBlock("html", html)
end

function pagebreak(args, kwargs, meta)
  return pandoc.RawBlock("html", table.concat({
    '<div class="pagebreak"></div>',
    '<div class="pagebreak-anchor">&#8203;</div>'
  }, "\n"))
end

function hvorstaarjeg(args, kwargs, meta)
  local U = pandoc.utils.stringify

  -- escape % for gsub replacement strings
  -- parentheses around gsub discard the second return value (count),
  -- which would otherwise be passed as the maxn argument to the outer gsub.
  local function esc(s)
    return (tostring(s):gsub("%%", "%%%%"))
  end

  -- minimal JSON string encoder (handles the chars we'll encounter in labels)
  local function json_str(s)
    s = tostring(s)
    s = (s:gsub('\\', '\\\\'))
    s = (s:gsub('"',  '\\"'))
    s = (s:gsub('\n', '\\n'))
    s = (s:gsub('\r', '\\r'))
    s = (s:gsub('</', '<\\/'))  -- guard against </script> inside JSON block
    return '"' .. s .. '"'
  end

  -- ── identity / header ────────────────────────────────────────────────────
  local id       = U(kwargs["id"]       or "hvor-staar-jeg")
  local eyebrow  = U(kwargs["eyebrow"]  or "Beregner")
  local title    = U(kwargs["title"]    or "Hvor står jeg?")
  local subtitle = U(kwargs["subtitle"] or
    "Hvad tjener folk i Grønland — og hvor er du i indkomstfordelingen?")
  local data     = U(kwargs["data"]     or "")

  if data == "" then
    return pandoc.RawBlock(
      "html",
      '<div class="alert alert-warning">Shortcode <code>hvorstaarjeg</code> mangler argumentet <code>data</code>.</div>'
    )
  end

  -- ── static UI labels (rendered directly in HTML) ─────────────────────────
  local privacy_note = U(kwargs["privacy_note"] or
    "Beregningen bruger disponibel personindkomst. Vi gemmer ikke dine oplysninger.")
  local income_label = U(kwargs["income_label"] or "Din disponible årsindkomst")
  -- Note: the default intentionally contains an <em> tag; plain-text overrides are fine.
  local guess_label  =   kwargs["guess_label"]
  if guess_label then
    guess_label = U(guess_label)
  else
    guess_label = "Gæt — hvor mange procent tjener <em>mindre</em> end dig?"
  end
  local btn_reveal   = U(kwargs["btn_reveal"] or "Se din placering")
  local btn_reset    = U(kwargs["btn_reset"]  or "Prøv igen")

  -- ── JS-side i18n strings (passed via embedded JSON) ──────────────────────
  -- {guess} and {diff} are placeholders filled in at runtime by the JS.
  local result_suffix = U(kwargs["result_suffix"] or
    "af personer i Grønland tjener <em>mindre</em> end dig.")
  local guess_higher  = U(kwargs["guess_higher"] or
    "Du gættede {guess} % — det faktiske tal er <b>{diff} procentpoint højere</b>.")
  local guess_lower   = U(kwargs["guess_lower"] or
    "Du gættede {guess} % — det faktiske tal er <b>{diff} procentpoint lavere</b>.")
  local guess_exact   = U(kwargs["guess_exact"] or "Du ramte præcis!")

  local i18n_json = string.format(
    '{"resultSuffix":%s,"guessHigher":%s,"guessLower":%s,"guessExact":%s}',
    json_str(result_suffix),
    json_str(guess_higher),
    json_str(guess_lower),
    json_str(guess_exact)
  )

  local html = [[
<div class="panel-card card pct-card" id="{{ID}}">
  <div class="card-body d-flex flex-column gap-3">

    <div>
      <div class="text-uppercase small fw-semibold text-muted mb-1">{{EYEBROW}}</div>
      <h2 class="card-title anchored">{{TITLE}}</h2>
      <p class="text-muted small mb-0">{{SUBTITLE}}</p>
    </div>

    <script type="application/json" class="pct-data">{{DATA}}</script>
    <script type="application/json" class="pct-i18n">{{I18N}}</script>

    <div class="pct-step1">
      <p class="text-muted small mb-3">{{PRIVACY_NOTE}}</p>

      <div class="mb-3">
        <label for="{{ID}}-indkomst" class="form-label">{{INCOME_LABEL}}</label>
        <div style="position:relative">
          <input
            type="number"
            class="form-control"
            id="{{ID}}-indkomst"
            min="0"
            max="2000000"
            step="10000"
            value="200000"
            style="padding-right:3.25rem">
          <span style="position:absolute;right:.75rem;top:50%;transform:translateY(-50%);
                       color:var(--muted);pointer-events:none;font-size:.9em">kr.</span>
        </div>
      </div>

      <div class="mb-1">
        <label for="{{ID}}-gaet" class="form-label d-flex justify-content-between align-items-baseline">
          <span>{{GUESS_LABEL}}</span>
          <span id="{{ID}}-gaet-vis" class="pct-guess-value ms-3 text-nowrap">50 %</span>
        </label>
        <input
          type="range"
          class="form-range"
          id="{{ID}}-gaet"
          min="0"
          max="100"
          value="50">
      </div>

      <div class="mt-3">
        <button type="button" class="btn btn-primary pct-reveal-btn">
          {{BTN_REVEAL}}
        </button>
      </div>
    </div>

    <div class="pct-step2 d-none">
      <div class="pct-resultat mb-3"></div>

      <div class="pct-bar-wrap">
        <div class="pct-bar-container"></div>
        <div class="pct-axis">
          <span>0 %</span>
          <span>50 %</span>
          <span>100 %</span>
        </div>
      </div>

      <div class="mt-3">
        <button type="button" class="btn btn-outline-secondary btn-sm pct-reset-btn">
          {{BTN_RESET}}
        </button>
      </div>
    </div>

  </div>
</div>

<script src="/_extensions/StatisticsGreenland/statglshortcodes/hvorstaarjeg.js"></script>
<script>
  if (window.initHvorStaarJeg) {
    window.initHvorStaarJeg("{{ID}}");
  } else {
    console.error("hvorstaarjeg.js not loaded: initHvorStaarJeg missing");
  }
</script>
]]

  html = html:gsub("{{ID}}",           esc(id))
  html = html:gsub("{{EYEBROW}}",      esc(eyebrow))
  html = html:gsub("{{TITLE}}",        esc(title))
  html = html:gsub("{{SUBTITLE}}",     esc(subtitle))
  html = html:gsub("{{DATA}}",         data)           -- raw JSON, no esc needed
  html = html:gsub("{{I18N}}",         esc(i18n_json))
  html = html:gsub("{{PRIVACY_NOTE}}", esc(privacy_note))
  html = html:gsub("{{INCOME_LABEL}}", esc(income_label))
  html = html:gsub("{{GUESS_LABEL}}",  esc(guess_label))
  html = html:gsub("{{BTN_REVEAL}}",   esc(btn_reveal))
  html = html:gsub("{{BTN_RESET}}",    esc(btn_reset))

  return pandoc.RawBlock("html", html)
end

----------------------------------------------------------------------
-- filter: page-wide selector that drives `data-filter-*` subscribers.
--
--   {{< filter
--       id="station"
--       label="Lokalitet"
--       options='`r jsonlite::toJSON(stations)`'
--       all_label="Alle lokaliteter"
--   >}}
--
-- Subscribers (anywhere on the page) opt in via attributes:
--   * data-filter-show="station:Nuuk" -> visible only when station=Nuuk
--   * data-filter-show="station:*"    -> visible only when any value picked
--   * data-filter-show="station:"     -> visible only when no value picked
--   * data-filter-series="station"    -> Highcharts series inside this
--                                        element are toggled by their
--                                        series.tags.station value
----------------------------------------------------------------------
function filter(args, kwargs, meta)
  local U = pandoc.utils.stringify

  local function esc(s)
    return (tostring(s):gsub("%%", "%%%%"))
  end

  local function h(s)
    s = U(s or "")
    return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
            :gsub('"',"&quot;"):gsub("'","&#39;"))
  end

  local id          = U(kwargs["id"]          or "filter")
  local label       = U(kwargs["label"]       or "")
  local all_label   = U(kwargs["all_label"]   or "Alle")
  local max_width   = U(kwargs["max_width"]   or "24rem")
  local options_raw = U(kwargs["options"]     or "[]")
  local default_val = U(kwargs["default"]     or "")

  -- options arrives as a JSON array string, typically from
  -- `r jsonlite::toJSON(vec)`. Parse it tolerantly: split on quote-comma
  -- boundaries so we don't need a JSON parser in Lua.
  local opts = {}
  -- strip leading/trailing brackets/whitespace
  local body = options_raw:gsub("^%s*%[", ""):gsub("%]%s*$", "")
  -- match quoted strings
  for s in body:gmatch('"([^"]*)"') do
    table.insert(opts, s)
  end
  -- fallback for unquoted comma list
  if #opts == 0 and body ~= "" then
    for s in body:gmatch("[^,]+") do
      local v = s:gsub("^%s+", ""):gsub("%s+$", "")
      if v ~= "" then table.insert(opts, v) end
    end
  end

  local options_html = string.format(
    '<option value="">%s</option>', h(all_label)
  )
  for _, v in ipairs(opts) do
    local selected_attr = (v == default_val) and ' selected' or ''
    options_html = options_html ..
      string.format('<option value="%s"%s>%s</option>', h(v), selected_attr, h(v))
  end

  -- JS snippet to apply the default value after registration.
  local default_js = ""
  if default_val ~= "" then
    default_js = string.format(
      '\n    window.StatglFilter.set("%s", "%s");',
      h(id), h(default_val)
    )
  end

  local label_html = ""
  if label ~= "" then
    label_html = string.format(
      '<label for="%s" class="form-label fw-semibold">%s</label>',
      h(id), h(label)
    )
  end

  local html = string.format([[
<div class="statgl-filter-wrap mb-4" data-statgl-filter="%s">
  %s
  <select id="%s" class="form-select statgl-filter-select" style="max-width: %s;">
    %s
  </select>
</div>
<script src="/_extensions/StatisticsGreenland/statglshortcodes/statgl-filter.js"></script>
<script>
  if (window.StatglFilter && window.StatglFilter.register) {
    window.StatglFilter.register("%s");%s
  } else {
    document.addEventListener("DOMContentLoaded", function() {
      if (window.StatglFilter && window.StatglFilter.register) {
        window.StatglFilter.register("%s");%s
      } else {
        console.error("statgl-filter.js not loaded: StatglFilter missing");
      }
    });
  }
</script>
]],
    h(id),
    label_html,
    h(id),
    h(max_width),
    options_html,
    h(id), esc(default_js),
    h(id), esc(default_js)
  )

  return pandoc.RawBlock("html", html)
end