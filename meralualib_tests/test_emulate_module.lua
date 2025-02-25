--[[
  Тест модуля debug.lua
--]]

def_pth = require("_script_path")

pth = def_pth.script_path("..\\meralualib")
def_pth.lib_path(pth)

emlulate = require("emulate")
for k, v in pairs(emlulate) do
  print(k, v)
end

print(emlulate.getValue)
emlulate.getValue("test_string")
emlulate.getValue("test_string", 10)

print(emlulate.setValue)
emlulate.setValue("test_string", 10)

print(emlulate.getRecorderStatus)
emlulate.getRecorderStatus()
emlulate.getRecorderStatus(100)