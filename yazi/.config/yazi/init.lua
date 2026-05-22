require("yafg"):setup({
  editor = "nano",                    -- Editor command (default: "hx")
  args = { },            -- Additional editor arguments (default: {})
  file_arg_format = "+{row} {file}",  -- File argument format (default: "{file}:{row}:{col}")
})

th.git = th.git or {}
th.git.modified_sign = "M"
th.git.deleted_sign = "D"
th.git.clean_sign = "✔"
th.git.added_sign = "+"
th.git.ignored_sign = "i"
th.git.updated_sign = "N"
th.git.untracked = "u"

--require("git"):setup {
--  -- Order of status signs showing in the linemode
--  -- BS: This _kills_ certain folders /shrug
--  order = 1500,
--}

-- 3. Zoxide Setup (Update database on navigation)
require("zoxide"):setup({
	update_db = true,
})

require("full-border"):setup {
    type = ui.Border.ROUNDED,
}

-- Line Mode
-- Helper to get the current Git branch
local function get_branch()
    local output = io.popen("git branch --show-current 2>/dev/null"):read("*l")
    return (output and output ~= "") and (" (" .. output .. ")") or ""
end

local branch_name = get_branch()

-- 1. Disable the Header (to hide the top-left date)
function Header:render() return ui.Line {} end

-- 2. Official-style Custom Linemode (Permissions, Size, Date, Branch)
function Linemode:size_and_mtime()
  local year = os.date("%Y")
  local time = math.floor(self._file.cha.mtime or 0)
  local time_str = os.date(os.date("%Y", time) == year and "%b %d %H:%M" or "%b %d  %Y", time)
  local size_str = self._file:size() and ya.readable_size(self._file:size()) or "-"
  local size_str_pad = string.format("%7s", size_str)

  -- Convert mode to permissions string (rwxr-xr-x format)
  local function mode_to_perm(mode)
    if not mode then return "" end
    local perm = ""
    local bits = {"r", "w", "x"}
    for i = 8, 0, -1 do
      local bit = math.floor(mode / (2 ^ i)) % 2
      perm = perm .. (bit == 1 and bits[(8 - i) % 3 + 1] or "-")
    end
    return perm
  end

  local perm_str = ""
  if ya.target_family() == "unix" and self._file.cha.mode then
    local perms = mode_to_perm(self._file.cha.mode)
    local user = ya.user_name(self._file.cha.uid) or tostring(self._file.cha.uid)
    local group = ya.group_name(self._file.cha.gid) or tostring(self._file.cha.gid)
    --perm_str = perms .. " " .. user .. ":" .. group .. " "
    perm_str = perms .. " " .. user .. " "
  end

  return ui.Line {
    ui.Span(perm_str):fg("magenta"),       -- Permissions (rwxr-xr-x user:group)
    ui.Span(size_str_pad .. " "),              -- Size
    ui.Span(time_str):fg("gray"),          -- Date
    --ui.Span(branch_name or ""):fg("blue"), -- Git Branch
  }
end
