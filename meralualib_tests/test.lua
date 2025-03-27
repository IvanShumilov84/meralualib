-- Auto generated Lua script for MERA Recorder
-- Инициализируйте ваши постоянные переменные здесь
counter = 0

-- Главная функция скрипта, вызвается с заданной периодичностью
setValue("block_button", 0)
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

