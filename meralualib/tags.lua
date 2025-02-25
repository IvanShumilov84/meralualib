-- 

local def_pth = require("_script_path")
local pth = def_pth.script_path()
def_pth.lib_path(pth .. "\\..\\meralualib")


Abs = require("Abs")
f = require("file")

local Tags = {}
Tags.alloc_ = Abs:alloc_{maxinst = 1}

function Tags:new()

  local tg = {}
  tg.tags = {}

  --- Функция создает теги на основе переданной таблицы имен и инициализирующих значений
  ---@param ttags {name: string, defval: number} -- таблица имен тегов и инициализирующих значений
  ---@param pth_dir string -- путь к специальному файлу с созданными тегами для добавления в Recorder или СИАМ
  function tg:CreateNewTags(ttags, pth_dir)
    --[[
    на входе таблица в формате 
    {
      ["name"] = "tag_name" ["defval"] = 0
      ["name"] = "tag_name" ["defval"] = 0
    }
    -- Теги для которых значение по умолчанию не задано инициализируются нулем.
    -- Если путь к файлу не задан, то путь сохранения специального файла либо в директориии вызова функции, либо зависит от цепочки вызовов.
    --]]
    pth_dir = pth_dir ~= nil and type(pth_dir) == "string" and pth_dir or pth .."\\..\\"

    assert (type(ttags) == "table", "Assert in function InitTags, the input parameter must be a table") 
    local strings_tname = {}
    table.insert(strings_tname, '--Скрипт создан автоматически, не изменять вручную')
    for t_id, tag in ipairs(ttags) do
      tag = tag
      assert(type(tag.name) == "string", "Assert in function InitTags, the key of the table must be a string") 
      tag.defval = tag.defval or 0
      self.tags[tag.name] = tag.defval
      table.insert(strings_tname, '--setValue("' .. tag.name .. '")')
      --setValue(tag.name, tag.defval)
    end

    table.insert(strings_tname, 'function lua_main() end')
    f.wfile(pth_dir .. "initnewtags.lua", strings_tname, "list", nil, nil)
  end

  setmetatable(tg, self)
  self.__index = self

  return tg
end


return Tags

