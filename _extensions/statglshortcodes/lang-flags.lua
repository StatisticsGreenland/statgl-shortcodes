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

function Meta(meta)
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