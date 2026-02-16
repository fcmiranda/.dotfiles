Name = "sesh"
NamePretty = "Sesh Sessions"

local function shell_escape(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function GetEntries()
  local entries = {}
  local handle = io.popen("/usr/bin/sesh list -d -c -t -T -z 2>/dev/null")
  if not handle then
    return entries
  end

  for session in handle:lines() do
    if session and session ~= "" then
      local escaped = shell_escape(session)
      local action = "/usr/bin/sesh connect --switch -- " .. escaped .. " || /usr/bin/uwsm-app -- /usr/bin/xdg-terminal-exec -e /usr/bin/sesh connect -- " .. escaped

      table.insert(entries, {
        Text = session,
        Sub = "sesh",
        Actions = {
          activate = action,
        },
      })
    end
  end

  handle:close()
  return entries
end
