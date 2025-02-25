

def_pth = require("_script_path")
pth = def_pth.script_path()
def_pth.lib_path(pth .. "\\..\\meralualib")

tg = require("tags")


T_ = tg:new()

s = {
  {name = "a1 Параметр двигателя", ["defval"] = 100},
  {["name"] = "a2"},
  {name = "Канал СИАМ", ["defval"] = 1234}
}

T_:CreateNewTags(s)

