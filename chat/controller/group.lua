-- Copyright (C) 2013 doujiang24 @ MaMa, Inc.

local cjson = require "cjson"
local output = require "core.output"

local get_instance = get_instance
local json_encode = cjson.encode

local loader = get_instance().loader

function add()
    local dp = get_instance()
    local name = dp.request:get('name')

    local group = dp.loader:model('rgroup')
    local gid = group:add(name)
    group:close()

    local callback = dp.request:get('callback')

    return output.json_callback(callback, 1, { gid = gid, name = name })
end

function all()
    local rgroup = loader:model('rgroup')
    local data = rgroup:all()
    rgroup:close()

    local callback = get_instance().request:get('callback')
    output.json_callback(callback, 1, data)
end
