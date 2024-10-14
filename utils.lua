-- Блок поиска файлов по относительным путям.

function script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*[/\\])") or ".\\"
end

-- pth = script_path()
-- package.path = pth .."../?.lua;" .. package.path

-- pth - содержит полный путь к текущей директории
-- specif - спецификатор пути и поиска файлов
function add_path(pth, specif)
  pth = pth ~= nil and type(pth) == "string" and pth  or ""
  specif = specif ~= nil and type(specif) == "string" and specif or ""
  local pth_ = pth .. specif
  package.path = pth_ .. package.path
  return pth_
end

function add_current_lua_path()
  return add_path(script_path(), "../?.lua;")
end

fspec = {
  ["script_path"] = script_path,
  ["add_path"] = add_path,
  ["add_current_lua_path"] = add_current_lua_path
}

if SYSTEM_DEBUG_PRINT then
  print(add_current_lua_path())
  print("\n", package.path)
end


return fspec