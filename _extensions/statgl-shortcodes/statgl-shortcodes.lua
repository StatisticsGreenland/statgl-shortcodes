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

function datawrapper(args, kwargs)
  local id = kwargs["id"]
  local height = kwargs["height"] or "400px"

  if not id then
    error("Missing required argument: id")
  end

  local html = string.format([[
    <div style="min-height:%s" id="datawrapper-vis-%s">
      <script type="text/javascript" defer src="https://datawrapper.dwcdn.net/%s/embed.js" charset="utf-8" data-target="#datawrapper-vis-%s"></script>
      <noscript><img src="https://datawrapper.dwcdn.net/%s/full.png" alt="" /></noscript>
    </div>
  ]], height, id, id, id, id)

  return pandoc.RawBlock("html", html)
end

function sectioncard(args, kwargs, meta)
  local icon = kwargs["icon"] or "bi-box"
  local title = kwargs["title"] or "Title"
  local text = kwargs["text"] or "Description text"
  local link = kwargs["link"] or "#"

  local html = string.format([[
<div class="card h-100 shadow-sm border-0" role="button" onclick="window.location='%s'" style="cursor: pointer;">
  <div class="card-body text-center">
    <i class="bi %s" style="font-size: 6rem;color:#004459;"></i>
    <div class="section-title">%s</div>
    <p class="card-text">%s</p>
  </div>
</div>
]], link, icon, title, text)

  return pandoc.RawBlock("html", html)
end

function shorty(args, kwargs, meta)

  local utils = pandoc.utils

  local title = utils.stringify(kwargs["title"] or "")
  local subtitle = utils.stringify(kwargs["subtitle"] or "")
  local description = utils.stringify(kwargs["description"] or "")
  local plot_title = utils.stringify(kwargs["plot_title"] or "")
  local plot_html = utils.stringify(kwargs["plot"] or "")
  local plot_link = utils.stringify(kwargs["plot_link"] or "")
  local img = utils.stringify(kwargs["img"] or "")
  local tbl_title = utils.stringify(kwargs["tbl_title"] or "")
  local tbl = utils.stringify(kwargs["tbl"] or "")
  local tbl_link = utils.stringify(kwargs["tbl_link"] or "")
  local accordion_title = utils.stringify(kwargs["accordion"] or "Links")

  -- Clean up any {=html} markers that might be present
  plot_html = plot_html:gsub("`{=html}", "")
  plot_html = plot_html:gsub("`", "")
  plot_html = plot_html:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace

  plot_link = '<span style="font-size: 0.7em;">' .. plot_link .. '</span>' 
  plot_link = pandoc.write(pandoc.read(plot_link, "markdown"), "html")
  
  tbl_link = '<span style="font-size: 0.7em;">' .. tbl_link .. '</span>' 
  tbl_link = pandoc.write(pandoc.read(tbl_link, "markdown"), "html")

  local links = {}
  for key, val in pairs(kwargs) do
    if key:match("^link_") then
      table.insert(links, val)
    end
  end

  local rendered_links = {}
  for _, mdlink in ipairs(links) do
    local html = pandoc.write(pandoc.read(mdlink, "markdown"), "html")
    html = html:gsub("^<p>(.*)</p>\n?$", "%1")
    table.insert(rendered_links, string.format("<li>%s</li>", html))
  end

  local link_list = table.concat(rendered_links, "\n")
  local randcase = string.char(math.random(97, 97 + 25))

  link_list = string.format([[
  <p>
  <div class="accordion" id="accordionExample">
  <div class="accordion-item">
    <div class="accordion-header" id="heading-%s">
      <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse-%s" aria-expanded="false" aria-controls="%s">
        %s
      </button>
    </div>
    <div id="collapse-%s" class="accordion-collapse collapse" aria-labelledby="heading-%s" data-bs-parent="#accordionExample">
      <div class="accordion-body">
        %s
      </div>
    </div>
  </div>
  </div>
  </p>
  ]], randcase, randcase, randcase, accordion_title, randcase, randcase, link_list)

  local html = string.format([[
    <div class="card mb-4">
      <div class="card-body">
        <h2 class="card-title">%s</h2>
        <div class="card-subtitle mb-2 text-muted">%s</div>
        <p class="card-text">%s</p>
        <div class="grid">
          <div class="g-col-12 g-col-md-6">
            %s
            %s
            %s
          </div>
          <div class="g-col-12 g-col-md-6">
             <div class="grid" style="width:100%%;">
             <div class="g-col-12">
  <div class="card-title">%s</div>
</div>
<div class="g-col-12" style="display:flex;align-items:center;justify-content:center;">
  <img src="%s" class="img-fluid" style="height:250px;width:250px;">
</div>
              <div class="g-col-12">
                %s
                %s
              </div>
             </div>
          </div>
        </div>
        %s
      </div>
    </div>
  ]], title, subtitle, description, plot_title, plot_html, plot_link, tbl_title, img, tbl, tbl_link, link_list)

  return pandoc.RawBlock("html", html)
end

function randstring(chars)
  local s = ''
  for i=1,chars do
    s = s .. string.char(math.random(97,122))
  end
  return(s)
end

function explain(args, kwargs, meta)
  local word = pandoc.utils.stringify(kwargs["word"] or "")
  local explanation = pandoc.utils.stringify(kwargs["explanation"] or "")
  local randcase = randstring(10)

  local html = string.format([[
  <button class="btn btn-primary" type="button" data-bs-toggle="collapse" data-bs-target="#collapse-%s" aria-expanded="false" aria-controls="collapse-%s" style="margin-top:15px">
    %s
  </button>
  <div class="collapse" id="collapse-%s">
    <div class="card card-body">
      %s
    </div>
  </div>
  ]], randcase, randcase, word, randcase, explanation)

  return pandoc.RawBlock("html", html)
end

function plotbox(args, kwargs, meta)
  local title = pandoc.utils.stringify(kwargs["title"] or "")
  local description = pandoc.utils.stringify(kwargs["description"] or "")
  local plot_html = pandoc.utils.stringify(kwargs["plot"] or "")
  local link = pandoc.utils.stringify(kwargs["link"] or "")
  local more = pandoc.utils.stringify(kwargs["more"] or "")
  local accordion_title = pandoc.utils.stringify(kwargs["accordion"] or "")

  -- Clean up any {=html} markers that might be present
  plot_html = plot_html:gsub("`{=html}", "")
  plot_html = plot_html:gsub("`", "")
  plot_html = plot_html:gsub("^%s+", ""):gsub("%s+$", "")

-- Handle escaped § first (\\§ → placeholder)
  more = more:gsub("\\§", "@@@LITERAL_SECTION@@@")

  more = more:gsub("%s*§§§%s*", "@@@BLOCK@@@")
             :gsub("%s*§%s*", "\n")
             :gsub("@@@BLOCK@@@", "\n\n")
             :gsub("@@@LITERAL_SECTION@@@", "§")

  local link_html = pandoc.write(pandoc.read(link, "markdown"), "html")
  local more_html = pandoc.write(pandoc.read(more, "markdown"), "html")
  local randcase = randstring(10)

  if more ~= "" then
    more_html = string.format([[
        <p>
  <div class="accordion" id="accordionExample">
  <div class="accordion-item">
    <div class="accordion-header" id="heading-%s">
      <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse-%s" aria-expanded="false" aria-controls="%s">
        %s
      </button>
    </div>
    <div id="collapse-%s" class="accordion-collapse collapse" aria-labelledby="heading-%s" data-bs-parent="#accordionExample">
      <div class="accordion-body">
        %s
      </div>
    </div>
  </div>
  </div>
  </p>
    ]], randcase, randcase, randcase, accordion_title, randcase, randcase, more_html)
  end

  local html = string.format([[
    <p>
    <div class="card">
      <div class="card-body">
        <h2 class="card-title">%s</h2>
        <p class="card-text">%s</p>
        %s
        %s
        %s
      </div>
    </div>
    </p>
  ]], title, description, plot_html, link_html, more_html)

  return pandoc.RawBlock("html", html)

end

function feature(args, kwargs, meta)
  local eyebrow   = pandoc.utils.stringify(kwargs["eyebrow"] or "")
  local title     = pandoc.utils.stringify(kwargs["title"] or "")
  local subtitle  = pandoc.utils.stringify(kwargs["subtitle"] or "")
  local body      = pandoc.utils.stringify(kwargs["body"] or "")
  local link      = pandoc.utils.stringify(kwargs["link"] or "")
  local icon      = pandoc.utils.stringify(kwargs["icon"] or "")
  local style     = pandoc.utils.stringify(kwargs["style"] or "")
  local accordion = pandoc.utils.stringify(kwargs["accordion"] or "")
  local more      = pandoc.utils.stringify(kwargs["more"] or "")

  local onclick = ""
  local style = "style=" .. style
  local role = ""
  local iconstyle
  local body_html = ""

  if body ~= "" then
    body = body:gsub("%s*§§§%s*", "@@@BLOCK@@@")
               :gsub("%s*§%s*", "\n")
               :gsub("@@@BLOCK@@@", "\n\n")
               :gsub("@@@LITERAL_SECTION@@@", "§")

    body_html = pandoc.write(pandoc.read(body, "markdown"), "html")
  end

  if icon ~= "" then
    icon = string.format([[
      <div>
        <i class="bi %s" style = "font-size:2rem;"></i>
      </div>]], icon)
    iconstyle = 'style="display: flex; align-items: center; gap: 1.5em;"'
  end

  if more ~= "" then
    more = more:gsub("%s*§§§%s*", "@@@BLOCK@@@")
               :gsub("%s*§%s*", "\n")
               :gsub("@@@BLOCK@@@", "\n\n")
               :gsub("@@@LITERAL_SECTION@@@", "§")

    more_html = pandoc.write(pandoc.read(more, "markdown"), "html")
  end

  if accordion ~= "" then
    local randcase = randstring(10)
    more = string.format([[
    <div style ="margin:15px;">
      <div class="accordion" id="accordionExample">
        <div class="accordion-item">
          <div class="accordion-header" id="heading-%s">
            <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse-%s" aria-expanded="false" aria-controls="%s">
              %s
            </button>
          </div>
          <div id="collapse-%s" class="accordion-collapse collapse" aria-labelledby="heading-%s" data-bs-parent="#accordionExample">
            <div class="accordion-body">
              %s
            </div>
          </div>
        </div>
      </div>
    </div>
    ]], randcase, randcase, randcase, accordion, randcase, randcase, more_html)
  end

  if link ~= "" and accordion == "" then
    onclick = ' onclick="window.location.href=\'' .. link .. '\'"'
    style = style .. '"cursor: pointer;"'
    role = 'role="button"'
  end

  local html = string.format([[
    <div class="card" %s %s %s>
      <div class="card-body" %s>
        %s
        <div style="hyphens:auto;">
          <div style="font-size:small;">%s</div>
          <div style="font-size:larger;font-weight:900;">%s</div>
          <div style="font-size:smaller">%s</div>
          <div>%s</div>
        </div>
      </div>
      %s
   </div>
  ]], role, onclick, style, iconstyle, icon, eyebrow, title, subtitle, body_html, more)

  return(pandoc.RawBlock("html", html))
  --return(body_html)
end

function contact(args, kwargs, meta)

  local title = kwargs["title"] or ""
  local name  = kwargs["name"]  or ""
  local phone = kwargs["phone"] or ""
  local mail  = kwargs["mail"]  or ""
  local icon  = pandoc.utils.stringify(kwargs["icon"] or "")

  if icon == "" then
    icon = "bi-person-lines-fill"
  end

  local html = string.format([[
    <div class = "card p-3">
      <div style="font-size:x-large;font-weight:900;">%s</div>
      <div class = "grid">
        <div class = "g-col-1">
          <i class="bi %s" style = "font-size:4rem;"></i>
        </div>
        <div class = "g-col-11">
          <p class="mb-1"><strong>%s</strong></p>
          <p class="mb-1"><i class="bi bi-telephone-fill me-1"></i> %s</p>
          <p><i class="bi bi-envelope-fill me-1"></i> <a href="mailto:%s">%s</a></p>

        </div>
      </div>
    </div>
  ]], title, icon, name, phone, mail, mail)

  return(pandoc.RawBlock("html", html))
  --return(icon)
end

