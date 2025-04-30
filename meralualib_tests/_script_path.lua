--[[
  Модуль определения пути и регистрация пакетов lua в системе

  Размесить модуль в системной директории поиска файлов lua, либо прописать путь к данному модулю в систетмной переменной 
  package.path

  Для системы семейства Windows достаточно разместить в директории с установленным интерпретатором lua, например 
  ./bin/lua

--]]
--[[ TODO:
  Добавить авторегистрацию (компирование) файла в системной директории
--]]

--- Функция определения абсолютного пути в файловой системе к вызывающему скрипту
--- позволяет добавить относительный путь к местораспоожению файла или пакета в этом 
--- случае возвращается комбинация путей
--- @param pth? string
--- @return string
local function script_path (pth)
  pth = type(pth) == "string" and pth or ""
  local str = debug.getinfo(2, "S").source:sub(2)
  return (str:match("(.*[/\\])") or ".\\") .. pth
end

local str_path = ''

local function register_script_path()
  local SCR_NAME = "_script_path.lua"
  local spth = script_path(SCR_NAME)
  local path = package.path
  local regs_ = path:match("[^;][^;]+[^;]")
  assert(regs_ ~= nil, "Error, the target path not found")
  regs_ = regs_:match(".+[^%?%.lua]") .. SCR_NAME

  f = io.open(spth, "r")
  local tb = {}
  if f then 
    while true do
      local str_ = f:read()
      if str_ == nil then 
        break 
      end
      table.insert(tb, str_)
    end
    f:close()  
  end
  f = io.open(regs_, "w")
  if f then
    for k in ipairs(tb) do
      f:write(tb[k], "\n")
    end 
    f:close()
  end
end
register_script_path()

return {
  ["script_path"] = script_path,

  --- Функция добавляет путь к файлу или пакету в системной переменной
  --- @param pth? string --путь к файлу или пакету
  --- @param srs? string --определяет окончание пути к файлу или спецификатор, расширение
  --- @return nil
  ["lib_path"] = function (pth, srs)
    pth = type(pth) == "string" and pth or ""
    srs = type(srs) == "string" and srs or "\\?.lua;"
    package.path = pth .. srs .. package.path
    str_path = pth .. srs
  end,

  --- Функция добавляет путь к откомпилированному файлу или пакету в системной переменной
  --- @param pth? string --путь к файлу или пакету
  --- @param srs? string --определяет окончание пути к файлу или спецификатор, расширение
  --- @return nil
  ["clib_path"] = function (pth, srs)
    pth = type(pth) == "string" and pth or ""
    srs = type(srs) == "string" and srs or "\\?.dll;"
    package.cpath = pth .. srs .. package.cpath
    str_path = pth .. srs
  end,

  ["get_path"] = function ()
    return str_path
  end
}
