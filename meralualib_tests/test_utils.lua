
def_pth = require("_script_path")
pth = def_pth.script_path()
def_pth.lib_path(pth .. "\\..\\meralualib")

uts = require("utils")


local glb_t1 = {
  [0] = 3,
  [1] = 15,--
  [2] = 30,--
  [3] = 500,--
  [10] = "ten",

  "first_2", 
  "second_1", 
  300,

  ["params_1"] = 1000,
  ["params_2"] = 500,
  [print] = 40
}

function test_get_count_keys()

  print("test_count")

end

print(#glb_t1)

print(uts.get_count_keys(glb_t1))
print(uts.get_count_keys(glb_t1, "any"))
print(uts.get_count_keys(glb_t1, "number"))
print(uts.get_count_keys(glb_t1, "string"))
print(uts.get_count_keys(glb_t1, "function"))

print(uts.find_tblvalue(glb_t1, "first_2"))
print(uts.find_tblvalue(glb_t1, "first_2", "val"))

print(uts.find_tblvalue(glb_t1, 300))
print(uts.find_tblvalue(glb_t1, 300, "val"))
print(uts.find_tblvalue(glb_t1, 300, "all"))

print(uts.find_tblvalue(glb_t1, "params_1"))
print(uts.find_tblvalue(glb_t1, "params_1", "key"))
print(uts.find_tblvalue(glb_t1, "params_1", "val"))
print(uts.find_tblvalue(glb_t1, "params_1", "all"))

local tst_findvalues = uts.find_tblvalues(glb_t1, {"first_2", "val"})

print(tst_findvalues[1][1])

print()

local function l_print(...)
  local arg = ...
  print(arg)
  return ...
end

local tbl = uts.tbl_exec(glb_t1, l_print, {combine = "string", plchold = "\t\t"})
print("===========")
print("tbl length = ", #tbl)
print("============")
uts.tbl_exec(tbl, print, {combine = "all"})
for k, v in pairs(tbl) do
  print("key = ", k, "\t\t\t", "val = ", v)
end
print("=== unpack table ===")
print(uts.tbl_unpack(glb_t1, {combine = "string"}))
print("==============")

tbl = uts.extr_tabl_args(glb_t1, {10, "params_1", "params_2"})
uts.tbl_exec(tbl,print, {combine = "all"})
