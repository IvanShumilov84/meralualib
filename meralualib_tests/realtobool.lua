require("_script_path")

 --  Подгружаем библиотеку.
local lib = require("../meralualib")

-- Фунцкия конвертации реал в бул.
local real_to_bool = lib["real_to_bool"]

-- setValue("__meralualibtests_realtobool__real_value")


-- Главная функция скрипта, вызвается с заданной периодичностью
function lua_main()
	local bool_value = real_to_bool(getValue("__meralualibtests_realtobool__real_value"))
    local bool_is_true = 0
    if bool_value then
        bool_is_true = 1
    end
	setValue("__meralualibtests_realtobool__bool_is_true", bool_is_true)
end
