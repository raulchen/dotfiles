-- Utility module for AI plugin helpers

local M = {}

-- Export copilot_accept function for use by other plugins (e.g., blink.lua)
function M.copilot_accept()
  local ok, copilot = pcall(require, "copilot.suggestion")
  if not ok or not copilot then
    return false
  end

  if copilot.is_visible() then
    copilot.accept()
    return true
  else
    return false
  end
end

return M
