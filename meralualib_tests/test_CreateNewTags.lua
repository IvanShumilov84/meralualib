

def_pth = require("_script_path")
pth = def_pth.script_path()
def_pth.lib_path(pth .. "\\..\\meralualib")

tg = require("tags")
uts = require("utils_")


--T_ = tg:new() -- 

s = {
  {name = "a1 Параметр двигателя", ["defval"] = 100},
  {["name"] = "a2"},
  {name = "Канал СИАМ", ["defval"] = 1234}
}

  --- справка по вызовам
  ----@param ttags {name: string, defval: number} -- таблица имен тегов и инициализирующих значений
  ----@param option {env: string, unique: boolean, addsiam: boolean, pth_dir: string} -- дополнительные опции


tg:CreateNewTags(s, {pth_dir = pth, addsiam = true})

s2 = {
  {name = "b1 Второй параметр", defval = 342},
  {name = "b2 Давление в трубопроводе", defval = 0},
  {name = "b3 Режим СИАМ"},
  {name = "b4", defval = 1000}
}

tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})
--tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})
--tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})
--tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})


print(tg:get_name_env())
print(tg:getCountEnvs())
print(tg:set_name_env("Test1"))
print(tg:get_name_env())
print(tg:getCountEnvs())
print(uts.get_count_keys(tg))
test_tbl = uts.tbl_exact(tg, print, {cnt = 3})
print()