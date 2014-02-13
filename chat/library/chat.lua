-- Copyright (C) 2013 doujiang24 @ MaMa, Inc.

local cjson = require "cjson"
local values = require("helper.table").values


local pcall = pcall
local pairs = pairs
local json_decode = cjson.decode
local json_encode = cjson.encode


local _M = getfenv()
local debug = get_instance().debug
local loader = get_instance().loader


-- str: json
function recv(str)
    local ok, args = pcall(json_decode, str)
    if not ok then
        debug:log_error("invalid input, cannot be json decode", str)
        return nil, "invalid input, cannot be json decode"
    end

    -- need required

    local typ = args._t
    if "msg" == typ then
        return send(args.acceptor, args.msg)

    elseif "view" == typ then
        return view(args.contact)

    elseif "sign" == typ then
        return sign(args.uid, args.client)

    elseif "list" == typ then
        return list(args.contactor)

    elseif "last" == typ then
        return last()

    else
        return nil, "type not valid in json data"
    end
end

function send(acceptor, msg)
    local chat, user = loader:model('chat'), loader:model('ruser')
    local sender = get_instance().session:get('sid')
    local users = user:get({sender, acceptor})
    local res, err = chat:send(sender, acceptor, msg, users[sender], users[acceptor])
    chat:close()

    return res, err
end

function view(contact)
    local chat = loader:model('chat')
    local self = get_instance().session:get('sid')
    local res, err = chat:view(contact, self)
    chat:close()

    return res, err
end

function sign(uid, client)
    local dp = get_instance()

    if not uid or not client then
        return nil, "not login"
    end

    dp.client = client
    dp.uid = uid
    return true
end

function list(user)
    local chat = loader:model('mchat')
    local sid = get_instance().session:get('sid')

    local data, err = chat:list(user, sid)
    chat:close()

    if data then
        local uids = {}
        for _i, r in ipairs(data) do
            uids[#uids + 1] = r.sender
        end

        local user = loader:model('ruser')
        local usernames = user:get(uids)
        user:close()

        for i, r in pairs(data) do
            r.sender_username = usernames[r.sender]
        end
    end

    return "list", { uid = user, messages = data }
end

function last()
    local chat = loader:model('rchat')
    local sid = get_instance().session:get('sid')

    local data = chat:contact(sid, 20)
    chat:close()

    local uids = values(data, 'uid')

    if #uids > 0 then
        local user = loader:model('ruser')
        local usernames = user:get(uids)
        user:close()

        for i, u in pairs(data) do
            get_instance().debug:log_debug(i, u, usernames, u.uid)
            data[i].username = usernames[u.uid]
        end
    end

    return "last", data
end
