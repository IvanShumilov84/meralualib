local t = {}


do  --- Функция кусочно-линейной интерполяции для одного аргумента.
    local function piecewise(x, x_arr, y_arr)
        assert(#x_arr >= 2, "The dimension of the array 'x_arr' is less than 2 ")
        assert(#y_arr >= 2, "The dimension of the array 'y_arr' is less than 2 ")
        assert(#x_arr == #y_arr, "The dimensions of the arrays 'x_arr' and 'y_arr' are different ")
        for i = 1, #x_arr do
            assert(type(x_arr[i]) == "number", "A non-numeric value was found in the array 'x_arr'")
            assert(type(y_arr[i]) == "number", "A non-numeric value was found in the array 'y_arr'")
        end

        local i1, i2
        if x <= x_arr[2] then
            i1, i2 = 1, 2
        elseif x > x_arr[#x_arr-1] then
            i1, i2 = #x_arr - 1, #x_arr
        else
            for i = 3, #x_arr - 1 do
                if x <= x_arr[i] then
                    i1, i2 = i - 1, i
                    break
                end
            end
        end

        return (x - x_arr[i1]) / (x_arr[i2] - x_arr[i1]) * (y_arr[i2] - y_arr[i1]) + y_arr[i1]
    end
    t["piecewise"] = piecewise
end


do  --- Функция кусочно-линейной интерполяции для двух аргументов.
    local function piecewise2(x, y, x_arr, y_arr, z_arr)
        local piecewise = t["piecewise"]
        assert(#x_arr >= 2, "The dimension of the array 'x_arr' is less than 2 ")
        assert(#y_arr >= 2, "The dimension of the array 'y_arr' is less than 2 ")
        assert(#y_arr == #z_arr, "The dimensions of the arrays 'y_arr' and 'z_arr' are different ")
        for i = 1, #x_arr do
            assert(type(x_arr[i]) == "number", "A non-numeric value was found in the array 'x_arr'")
        end
        for i = 1, #y_arr do
            assert(type(y_arr[i]) == "number", "A non-numeric value was found in the array 'y_arr'")
        end
        for i = 1, #z_arr do
            assert(#(z_arr[i]) == #x_arr, "The dimensions of the arrays 'x_arr' and 'z_arr' are different ")
            for j = 1, #(z_arr[i]) do
                assert(type(z_arr[i][j]) == "number", "A non-numeric value was found in the array 'z_arr'")
            end
        end

        local i1, i2
        if y <= y_arr[2] then
            i1, i2 = 1, 2
        elseif y > y_arr[#y_arr-1] then
            i1, i2 = #y_arr - 1, #y_arr
        else
            for i = 3, #y_arr - 1 do
                if y <= y_arr[i] then
                    i1, i2 = i - 1, i
                    break
                end
            end
        end

        local z1, z2
        z1 = piecewise(x, x_arr, z_arr[i1])
        z2 = piecewise(x, x_arr, z_arr[i2])

        return (y - y_arr[i1]) / (y_arr[i2] - y_arr[i1]) * (z2 - z1) + z1
    end
    t["piecewise2"] = piecewise2
end

return t
