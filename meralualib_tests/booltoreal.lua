require("_script_path")

 --  Подгружаем библиотеку.
local lib = require("../meralualib")

-- Функция конвертации бул в реал.
local bool_to_real = lib["bool_to_real"]

-- setValue("__meralualibtests_booltoreal__set_bool_true")

-- Главная функция скрипта, вызвается с заданной периодичностью
function lua_main()
    local set_bool_true = getValue("__meralualibtests_booltoreal__set_bool_true")
    local bool_value = false
    if set_bool_true > 0 then
        bool_value = true
    end
    local real_value = 0
    if bool_value then
        real_value = 1
    end
    setValue("__meralualibtests_booltoreal__real_value", real_value)
end
