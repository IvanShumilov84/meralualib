-- Auto generated Lua script for MERA Recorder
-- Инициализируйте ваши постоянные переменные здесь
counter = 0
test_lib = require("utils")

test_lib.add_current_lua_path()

test_lb = require("meralualib/timers")

ton_1 = test_lb["Ton"]:new()
local lanch = 0

-- Главная функция скрипта, вызывается с заданной периодичностью
function lua_main()

	ton_1:calc(true, 20)
	if lanch == 0 then
		setValue("Counter", 100)
		lanch = 1
	end 
	--setValue("Counter", ton_1.q and 1 or 0)
	setValue("Ton_et", ton_1.et)
end

