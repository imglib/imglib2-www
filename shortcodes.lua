-- Custom Quarto shortcodes for imglib2-www
-- Usage: {{< code org="..." repo="..." branch="..." path="..." line-start="N" >}}

function code(args, kwargs)
  local function str(key, default)
    local val = kwargs[key]
    if val then return pandoc.utils.stringify(val) end
    return default or ""
  end

  local org        = str("org")
  local repo       = str("repo")
  local branch     = str("branch", "main")
  local path       = str("path")
  local line_start = str("line-start", "1")
  local line_end   = str("line-end", "99999")
  local label      = kwargs["label"] and pandoc.utils.stringify(kwargs["label"]) or nil

  -- GitHub URL with line range (emgithub always embeds the specified range)
  local github_url = "https://github.com/" .. org .. "/" .. repo .. "/blob/" .. branch .. "/" .. path
  local file_url   = github_url .. "#L" .. line_start .. "-" .. line_end

  -- Percent-encode the target URL for the emgithub query parameter
  local encoded = file_url
    :gsub(":", "%%3A")
    :gsub("/", "%%2F")
    :gsub("#", "%%23")

  local embed_url = "https://emgithub.com/embed-v2.js?target=" .. encoded
    .. "&showBorder=on&showLineNumbers=on&showFileMeta=on&showCopy=on"

  local html = ""
  if label then
    html = '<b><a href="' .. file_url .. '">' .. label .. '</a></b><br>\n'
  end
  html = html .. '<script src="' .. embed_url .. '"></script>'

  return pandoc.RawBlock("html", html)
end
