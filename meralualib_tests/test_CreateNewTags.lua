

def_pth = require("_script_path")
pth = def_pth.script_path()
def_pth.lib_path(pth .. "\\..\\meralualib")

tg = require("tags")
uts = require("utils")


--T_ = tg:new() -- 

s = {
  {name = "a1 Параметр двигателя", ["defval"] = 100},
  {["name"] = "a2"},
  {name = "Канал СИАМ", ["defval"] = 1234}
}

  --- справка по вызовам
  ----@param ttags {name: string, defval: number} -- таблица имен тегов и инициализирующих значений
  ----@param option {env: string, unique: boolean, addsiam: boolean, pth_dir: string} -- дополнительные опции

--tg:set_en_addsiam(0)

tg:CreateNewTags(s, {pth_dir = pth})

s2 = {
  {name = "b1 Второй параметр", defval = 342, info = "this is a comment ...."},
  {name = "b2 Давление в трубопроводе", defval = 0, info = "Comment 12345 .... sh;lkjd"},
  {name = "b3 Режим СИАМ"},
  {name = "b4", defval = 1000}
}

tg:set_en_addsiam()

tg:CreateNewTags(s2, {pth_dir = pth})
--tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})
--tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})
--tg:CreateNewTags(s2, {addsiam = true, pth_dir = pth})


print(tg:get_name_env())
print(tg:getCountEnvs())
print(tg:set_name_env("Test1"))
print(tg:get_name_env())
print(tg:getCountEnvs())
print(uts.get_count_keys(tg))
test_tbl = uts.tbl_exec(tg, print, {cnt = 3})
print()