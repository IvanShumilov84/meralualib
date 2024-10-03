require("_script_path")

	 --  Подгружаем библиотеку.
	local lib = require("../meralualib")

local tbl_ConvLib = require("../convertfunc")

--  Фунцкия конвертации реал в бул.
local real_to_bool = tbl_ConvLib["real_to_bool"]
--  Фунцкия конвертации бул в реал.
local bool_to_real = tbl_ConvLib["bool_to_real"]
	--  Экземпляр Ton.
	local ton_1 = lib["Ton"]:new()
	--  setValue("__meralualibtests_ton__ton_1.input")
	ton_1.pt = 3

	-- Ещё экземпляр Ton.
	local ton_2 = lib["Ton"]:new()
	--  setValue("__meralualibtests_ton__ton_2.input")
	ton_2.pt = 6


	-- Главная функция скрипта, вызвается с заданной периодичностью
	function lua_main()
		--  Работа с ton_1.
		ton_1:calc()
		ton_1.input = real_to_bool(getValue("__meralualibtests_ton__ton_1.input"))
		setValue("__meralualibtests_ton__ton_1.q", bool_to_real(ton_1.q))
		setValue("__meralualibtests_ton__ton_1.et", ton_1.et)

		--  Работа с ton_2.
		ton_2:calc()
		ton_2.input = real_to_bool(getValue("__meralualibtests_ton__ton_2.input"))
		setValue("__meralualibtests_ton__ton_2.q", bool_to_real(ton_2.q))
		setValue("__meralualibtests_ton__ton_2.et", ton_2.et)
	end