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
--- позволяет добавить относительный путь к местораспоожению файла или пакета 
--- в этом случае возвращается комбинация путей
--- @param pth? string
--- @return string
local function script_path (pth)
  pth = type(pth) == "string" and pth or ""
  local str = debug.getinfo(2, "S").source:sub(2)
  return (str:match("(.*[/\\])") or ".\\") .. pth
end

--- Функция норамалилации глобального пути 
--- удаляет относительные переходы и заменяет их на полный путь
--- 
--- @param str string
--- @return string
local function full_path_normal(str)
  local nstr = str
  while (nstr:match("[\\/]%.%.")) do
    nstr = nstr:gsub("[\\/][_%w]*[\\/][..][^(\\/)]", "")
  end
  return nstr
end

--- Функция авторегистрации скрипта в системе Lua
--- Принимает аргументы командной строки: --
--- "-retpth" - функция возвращает полный путь к загруженному файлу
--- "-prtpth" - вывод в консоль полного пути при помощи команды print(patch)
local function register_script_path()
  local SCR_NAME = "_script_path.lua"
  local spth = script_path(SCR_NAME)
  local path = package.path
  local regs_ = path:match("[^;][^;]+[^;]")
  assert(regs_ ~= nil, "Error, the target path not found")
  regs_ = regs_:match(".+[^%?%.lua]") .. SCR_NAME
  local ret_ = ""
  for i = 1, #arg do
    ret_= arg[1] == "-retpth" and regs_ or ""
    if arg[i] == "-prtpth" then
      print("script_path = ", regs_)
    end
  end

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
  return ret_
end

register_script_path()

return {
  --- Функция определения абсолютного пути в файловой системе к вызывающему скрипту
  --- позволяет добавить относительный путь к местораспоожению файла или пакета 
  --- в этом случае возвращается комбинация путей
  ["script_path"] = script_path,
  --- Функция норамалилации глобального пути 
  --- удаляет относительные переходы и заменяет их на полный путь
  ["full_path_normal"] = full_path_normal,

  --- Функция добавляет путь к файлу или пакету в системной переменной
  --- @param pth? string --путь к файлу или пакету
  --- @param srs? string --определяет окончание пути к файлу или спецификатор, расширение
  --- @param fnorm? boolean -- определяет нормализовать ли заданный путь
  --- @return nil
  ["lib_path"] = function (pth, srs, fnorm)
    pth = type(pth) == "string" and pth or ""
    srs = type(srs) == "string" and srs or "\\?.lua;"
    fnorm = type(fnorm) == "boolean" and fnorm or true
    if fnorm == true then 
      pth = full_path_normal(pth)
    end
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

