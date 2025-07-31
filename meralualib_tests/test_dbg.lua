
def_pth = require("_script_path")
pth = def_pth.script_path()
def_pth.lib_path(pth .. "..\\meralualib")

test_dbg = require("dbg")

local counter = 0

-- Главная функция скрипта, вызвается с заданной периодичностью
--setValue("block_button", 0)
function lua_main()
	setValue("block_button", 0)
	if counter < 10 then
		counter = counter + 1
		setValue("Counter", counter)
	end
	if counter >= 10 then 
		setValue("block_button", 1)
	end
end

-- Создание лога функцией io.write
test_dbg.clog{["data"] = {397, ["str"] = 10, 1000, 3092}}
-- Создание лога с указанием логирующей функции (кастомизация)
test_dbg.exlog{func = print, ["data"] = {397, ["str"] = 10, 1000, 3092}}

-- Создание кастомизированной функции-логера
test_loger = test_dbg.Createloger()
test_loger{["data"] = {397, ["str"] = 10, 1000, 3092}}