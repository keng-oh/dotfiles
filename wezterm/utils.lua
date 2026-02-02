local M = {}

function M.is_darwin(wezterm)
  return wezterm.target_triple ~= nil and string.find(wezterm.target_triple, 'darwin') ~= nil
end

function M.file_exists(path)
  if path == nil or path == '' then
    return false
  end
  local f = io.open(path, 'r')
  if f ~= nil then
    f:close()
    return true
  end
  return false
end

function M.first_existing(paths)
  for _, path in ipairs(paths) do
    if M.file_exists(path) then
      return path
    end
  end
  return nil
end

return M
