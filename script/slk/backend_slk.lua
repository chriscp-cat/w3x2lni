local w3xparser = require 'w3xparser'

local table_concat = table.concat
local ipairs = ipairs
local string_char = string.char
local pairs = pairs
local type = type
local table_sort = table.sort
local table_insert = table.insert
local math_floor = math.floor
local wtonumber = w3xparser.tonumber
local math_type = math.type

local slk
local w2l
local metadata
local keydata
local keys
local lines
local cx
local cy

local slk_keys = {
    ['units\\abilitydata.slk']      = {
        'alias','code','Area1','Area2','Area3','Area4','BuffID1','BuffID2','BuffID3','BuffID4','Cast1','Cast2','Cast3','Cast4','Cool1','Cool2','Cool3','Cool4','Cost1','Cost2','Cost3','Cost4','DataA1','DataA2','DataA3','DataA4','DataB1','DataB2','DataB3','DataB4','DataC1','DataC2','DataC3','DataC4','DataD1','DataD2','DataD3','DataD4','DataE1','DataE2','DataE3','DataE4','DataF1','DataF2','DataF3','DataF4','DataG1','DataG2','DataG3','DataG4','DataH1','DataH2','DataH3','DataH4','DataI1','DataI2','DataI3','DataI4','Dur1','Dur2','Dur3','Dur4','EfctID1','EfctID2','EfctID3','EfctID4','HeroDur1','HeroDur2','HeroDur3','HeroDur4','Rng1','Rng2','Rng3','Rng4','UnitID1','UnitID2','UnitID3','UnitID4','checkDep','levelSkip','levels','priority','reqLevel','targs1','targs2','targs3','targs4',
    },
    ['units\\abilitybuffdata.slk']  = {
        'alias',
    },
    ['units\\destructabledata.slk'] = {
        'DestructableID','HP','MMBlue','MMGreen','MMRed','Name','armor','cliffHeight','colorB','colorG','colorR','deathSnd','fatLOS','file','fixedRot','flyH','fogRadius','fogVis','lightweight','maxPitch','maxRoll','maxScale','minScale','numVar','occH','pathTex','pathTexDeath','portraitmodel','radius','selcircsize','selectable','shadow','showInMM','targType','texFile','texID','tilesetSpecific','useMMColor','walkable',
    },
    ['units\\itemdata.slk']         = {
        'itemID','HP','Level','abilList','armor','class','colorB','colorG','colorR','cooldownID','drop','droppable','file','goldcost','ignoreCD','lumbercost','morph','oldLevel','pawnable','perishable','pickRandom','powerup','prio','scale','sellable','stockMax','stockRegen','stockStart','usable','uses',
    },
    ['units\\upgradedata.slk']      = {
        'upgradeid','base1','base2','base3','base4','class','code1','code2','code3','code4','effect1','effect2','effect3','effect4','global','goldbase','goldmod','inherit','lumberbase','lumbermod','maxlevel','mod1','mod2','mod3','mod4','timebase','timemod',
    },
    ['units\\unitabilities.slk']    = {
        'unitAbilID','abilList','auto','heroAbilList',
    },
    ['units\\unitbalance.slk']      = {
        'unitBalanceID','AGI','AGIplus','HP','INT','INTplus','Primary','STR','STRplus','bldtm','bountydice','bountyplus','bountysides','collision','def','defType','defUp','fmade','fused','goldRep','goldcost','isbldg','level','lumberRep','lumberbountydice','lumberbountyplus','lumberbountysides','lumbercost','mana0','manaN','maxSpd','minSpd','nbrandom','nsight','preventPlace','regenHP','regenMana','regenType','reptm','repulse','repulseGroup','repulseParam','repulsePrio','requirePlace','sight','spd','stockMax','stockRegen','stockStart','tilesets','type','upgrades',
    },
    ['units\\unitdata.slk']         = {
        'unitID','buffRadius','buffType','canBuildOn','canFlee','canSleep','cargoSize','death','deathType','fatLOS','formation','isBuildOn','moveFloor','moveHeight','movetp','nameCount','orientInterp','pathTex','points','prio','propWin','race','requireWaterRadius','targType','turnRate',
    },
    ['units\\unitui.slk']           = {
        'unitUIID','name','armor','blend','blue','buildingShadow','customTeamColor','elevPts','elevRad','file','fileVerFlags','fogRad','green','hideHeroBar','hideHeroDeathMsg','hideHeroMinimap','hideOnMinimap','maxPitch','maxRoll','modelScale','nbmmIcon','occH','red','run','scale','scaleBull','selCircOnWater','selZ','shadowH','shadowOnWater','shadowW','shadowX','shadowY','teamColor','tilesetSpecific','uberSplat','unitShadow','unitSound','walk',
    },
    ['units\\unitweapons.slk']      = {
        'unitWeapID','Farea1','Farea2','Harea1','Harea2','Hfact1','Hfact2','Qarea1','Qarea2','Qfact1','Qfact2','RngBuff1','RngBuff2','acquire','atkType1','atkType2','backSw1','backSw2','castbsw','castpt','cool1','cool2','damageLoss1','damageLoss2','dice1','dice2','dmgUp1','dmgUp2','dmgplus1','dmgplus2','dmgpt1','dmgpt2','impactSwimZ','impactZ','launchSwimZ','launchX','launchY','launchZ','minRange','rangeN1','rangeN2','showUI1','showUI2','sides1','sides2','spillDist1','spillDist2','spillRadius1','spillRadius2','splashTargs1','splashTargs2','targCount1','targCount2','targs1','targs2','weapTp1','weapTp2','weapType1','weapType2','weapsOn',
    },
    --['doodads\\doodads.slk']        = 'doodID',
}

local function add_end()
    lines[#lines+1] = 'E'
end

local function add(x, y, k)
    local strs = {}
    strs[#strs+1] = 'C'
    if x ~= cx then
        cx = x
        strs[#strs+1] = 'X' .. x
    end
    if y ~= cy then
        cy = y
        strs[#strs+1] = 'Y' .. y
    end
    if type(k) == 'string' then
        k = '"' .. k .. '"'
    elseif math_type(k) == 'float' then
        k = ('%.4f'):format(k):gsub('[0]+$', ''):gsub('%.$', '.0')
    end
    strs[#strs+1] = 'K' .. k
    lines[#lines+1] = table_concat(strs, ';')
end

local function add_values(names, skeys)
    for y, name in ipairs(names) do
        local obj = slk[name]
        for x, key in ipairs(skeys) do
            local value = obj[key]
            if value then
                add(x, y+1, value)
            end
        end
    end
end

local function add_title(names)
    for x, name in ipairs(names) do
        add(x, 1, name)
    end
end

local function add_head(names, skeys)
    lines[#lines+1] = 'ID;PWXL;N;E'
    lines[#lines+1] = ('B;X%d;Y%d;D0'):format(#skeys, #names+1)
end

local function get_key(id)
	local meta  = metadata[id]
	if not meta then
		return
	end
	local key = meta.field
	local num = meta.data
	if num and num ~= 0 then
		key = key .. string_char(('A'):byte() + num - 1)
	end
	if meta._has_index then
		key = key .. ':' .. (meta.index + 1)
	end
	return key
end

local function get_names()
    local names = {}
    for name in pairs(slk) do
        names[#names+1] = name
    end
    table_sort(names, function(a, b)
        return slk[a]['_id'] < slk[b]['_id']
    end)
    return names
end

local function convert_slk(slk_name)
    if not next(slk) then
        return
    end
    local names = get_names()
    local skeys = slk_keys[slk_name]
    add_head(names, skeys)
    add_title(skeys)
    add_values(names, skeys)
    add_end()
end

local function key2id(name, para, key)
    name = name:lower()
    para = para:lower()
    key = key:lower()
    local id = para and keydata[para] and keydata[para][key] or keydata[name] and keydata[name][key] or keydata['common'][key]
    if id then
        return id
    end
    return nil
end

local function to_type(tp, value)
    if tp == 0 then
        if not value or value == 0 then
            return nil
        end
        return math_floor(wtonumber(value))
    elseif tp == 1 or tp == 2 then
        if not value or value == 0 then
            return nil
        end
        return wtonumber(value) + 0.0
    elseif tp == 3 then
        if not value then
            return nil
        end
        if value == '' then
            return nil
        end
        value = tostring(value)
        if not value:match '[^ %-%_]' then
            return nil
        end
        if value:match '^%.[mM][dD][lLxX]$' then
            return nil
        end
        return value
    end
end

local function load_data(name, para, obj, key, id, slk_data)
    if not obj[key] then
        return
    end
    local tp = w2l:get_id_type(metadata[id].type)
    local skey = get_key(key2id(name, para, key))
    if type(obj[key]) == 'table' then
        for i = 1, 4 do
            slk_data[skey..i] = to_type(tp, obj[key][i])
            obj[key][i] = nil
        end
        if not next(obj[key]) then
            obj[key] = nil
        end
    else
        slk_data[skey] = to_type(tp, obj[key])
        obj[key] = nil
    end
end

local function load_obj(name, obj, slk_name)
    local para = obj._lower_para
    local slk_data = {}
    slk_data[slk_keys[slk_name][1]] = obj['_id']
    slk_data['code'] = obj._code
    slk_data['name'] = obj._name
    slk_data['_id'] = obj._id
    obj._slk = true
    for key, id in pairs(keys) do
        load_data(name, para, obj, key, id, slk_data)
    end
    if keydata[para] then
        for key, id in pairs(keydata[para]) do
            load_data(name, para, obj, key, id, slk_data)
        end
    end
    return slk_data
end

local function load_chunk(chunk, slk_name)
    for name, obj in pairs(chunk) do
        slk[name] = load_obj(name, obj, slk_name)
    end
end

return function(w2l_, type, slk_name, chunk)
    slk = {}
    w2l = w2l_
    cx = nil
    cy = nil
    lines = {}
    metadata = w2l:read_metadata(type)
    keydata = w2l:keyconvert(type)
    keys = keydata[slk_name]

    load_chunk(chunk, slk_name)
    convert_slk(slk_name)
    return table_concat(lines, '\r\n')
end
