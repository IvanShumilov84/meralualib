--[[
  Тест модуля debug.lua
--]]

def_pth = require("_script_path")

pth = def_pth.script_path("..\\meralualib")
def_pth.lib_path(pth)

dbg = require("emulate")
for k, v in pairs(dbg) do
  print(k, v)
end

print(dbg.getValue)
dbg.getValue("test_string")
dbg.getValue("test_string", 10)

print(dbg.setValue)
dbg.setValue("test_string", 10)

print(dbg.getRecorderStatus)
dbg.getRecorderStatus()
dbg.getRecorderStatus(100)