local pairs = pairs

local keydata
local is_remove_same
local w2l
local default
local metadata

local function sortpairs(t)
    local sort = {}
    for k, v in pairs(t) do
        sort[#sort+1] = {k, v}
    end
    table.sort(sort, function (a, b)
        return a[1] < b[1]
    end)
    local n = 1
    return function()
        local v = sort[n]
        if not v then
            return
        end
        n = n + 1
        return v[1], v[2]
    end
end

local function default_value(tp)
    if tp == 0 then
        return 0
    elseif tp == 1 or tp == 2 then
        return 0.0
    elseif tp == 3 then
        return ''
    end
end

local function remove_same_as_slk(meta, key, data, default, obj, ttype)
    local dest = default[key]
    if type(dest) == 'table' then
        local new_data = {}
        for i = 1, #data do
            local default
            if i > #dest then
                default = dest[#dest]
            else
                default = dest[i]
            end
            if data[i] ~= default then
                new_data[i] = data[i]
            end
        end
        if not next(new_data) then
            obj[key] = new_data
            return
        end
        if is_remove_same then
            obj[key] = new_data
        end
    else
        if data == dest then
            obj[key] = nil
        elseif data == nil then
            obj[key] = default_value(meta.type)
        end
    end
end

local function remove_same_as_txt(meta, key, data, default, obj, ttype)
    local dest = default[key]
    if type(dest) == 'table' then
        local new_data = {}
        local last
        for i = 1, #data do
            local default
            if i > #dest then
                default = last
            else
                default = dest[i]
            end
            if data[i] ~= default then
                new_data[i] = data[i]
            end
            last = data[i]
        end
        if not next(new_data) then
            obj[key] = new_data
            return
        end
        if is_remove_same then
            obj[key] = new_data
        end
    else
        if data == dest then
            obj[key] = nil
        elseif data == nil and meta then
            obj[key] = default_value(meta.type)
        end
    end
end

local function clean_obj(name, obj, type, default)
    local parent = obj._parent
    local default = default[parent]
    for key, meta in pairs(metadata[type]) do
        local data = obj[key]
        if meta.profile then
            remove_same_as_txt(meta, key, data, default, obj, type)
        else
            remove_same_as_slk(meta, key, data, default, obj, type)
        end
    end
    if metadata[obj._code] then
        for key, meta in pairs(metadata[obj._code]) do
            local data = obj[key]
            if meta.profile then
                remove_same_as_txt(meta, key, data, default, obj, type)
            else
                remove_same_as_slk(meta, key, data, default, obj, type)
            end
        end
    end
end

local function clean_objs(type, t)
    if not t then
        return
    end
    for id, obj in sortpairs(t) do
        clean_obj(id, obj, type, default[type])
    end
end

local function clean_txt(type, t)
    if not t then
        return
    end
    for id, obj in sortpairs(t) do
        local default = default[type][id]
        if default then
            for key, data in pairs(obj) do
                remove_same_as_txt(nil, key, data, default, obj, type)
            end
        end
    end
end

local function clean_misc(type, t)
    if not t then
        return
    end
    for _, name in ipairs {'FontHeights', 'InfoPanel', 'Misc', 'PingColor', 'QuestIndicatorTimeout', 'SelectionCircle'} do
        clean_obj(id, t[name], type, default[type])
    end
end

return function (w2l_, slk)
    w2l = w2l_
    keydata = w2l:keydata()
    default = w2l:get_default()
    is_remove_same = w2l.config.remove_same
    metadata = w2l:metadata()
    if w2l.config.mode == 'slk' then
        if not w2l.config.slk_doodad then
            local type = 'doodad'
            clean_objs(type, slk[type])
            w2l.progress(0.5)
        end
    else
        for i, type in ipairs {'ability', 'buff', 'unit', 'item', 'upgrade', 'doodad', 'destructable', 'misc'} do
            clean_objs(type, slk[type])
            w2l.progress(i / 8)
        end
        local type = 'txt'
        clean_txt(type, slk[type])
    end
    w2l.progress(1)
end
