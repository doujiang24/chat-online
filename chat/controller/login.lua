-- Copyright (C) 2013 doujiang24 @ MaMa, Inc.

local output = require "core.output"

local get_instance = get_instance
local loader = get_instance().loader

local default_group = "group1"
local default_group_name = "一起来聊天"
local default_mesg = "一起来聊，我也来咯，我是:"

function _remap()
    local sid = get_instance().session:get('sid')
    local callback = get_instance().request:get('callback')

    if sid then
        local user = loader:model('ruser')
        local username = user:get(sid)
        user:close()

        local chat = loader:model('rchat')
        local client = chat:client(sid)
        chat:close()

        output.json_callback(callback, 1, { sid = sid, username = username, client = client })

    else
        output.json_callback(callback, 0)
    end
end

function sign()
    local callback = get_instance().request:get('callback')
    local username = get_instance().request:get("username")

    local user = loader:model('ruser')
    local sid = user:sign(username)
    user:group_join(sid, default_group)
    user:close()

    local chat = loader:model('chat')
    local res, err = chat:send(sid, default_group, default_mesg .. username, username, default_group_name)
    chat:close()

    get_instance().session:set('sid', sid)

    output.set_header('P3P', 'CP=.')
    output.json_callback(callback, 1)
end
