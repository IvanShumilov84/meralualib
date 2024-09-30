-- Блок поиска файлов по относительным путям.


function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*[/\\])") or ".\\"
end


pth = script_path()
package.path = pth .."../?.lua;" .. package.path
