init('misc', 'Misc')
local obj = load('all')
local slk = save('obj', obj)
compare_string(slk.obj, read 'war3mapmisc.txt')
local obj = load('all')
local slk = save('lni', obj)
compare_string(slk.lni, read 'misc.ini')
