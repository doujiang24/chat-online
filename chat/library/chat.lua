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
-- return ok, data / err
function recv(str)
    local ok, args = pcall(json_decode, str)
    if not ok then
        debug:log_error("invalid input, cannot be json decode", str)
        return nil, "invalid input, cannot be json decode"
    end

    -- need required

    local typ = args._t
    if "msg" == typ then
        return send(args.acceptor, args.msg, args.typ)

    elseif "view" == typ then
        return view(args.contact, args.typ)

    elseif "list" == typ then
        return list(args.contactor, args.typ)

    elseif "last" == typ then
        return last(args.typ)

    elseif "join" == typ then
        return join(args.group)

    else
        return nil, "type not valid in json data"
    end
end

function send(acceptor, msg, typ)
    local chat, user = loader:model('chat'), loader:model('ruser')
    local sender = get_instance().uid

    local res, err
    if typ and typ == "group" then
        local group = loader:model('rgroup')
        local groupname = group:get(acceptor)
        group:close()

        local sender_username = user:get(sender)

        res, err = chat:groupsend(sender, acceptor, msg, sender_username, groupname)
    else
        local users = user:gets({sender, acceptor})
        res, err = chat:send(sender, acceptor, msg, users[sender], users[acceptor])
    end
    user:close()
    chat:close()

    return res, err
end

function view(contact, typ)
    local uid = get_instance().uid
    local chat = loader:model('chat')
    local res, err = chat:view(contact, uid, typ)
    chat:close()

    return res, err
end

function list(user, typ)
    local chat = loader:model('mchat')
    local sid = get_instance().session:get('sid')

    local data, err
    if typ and "group" == typ then
        data, err = chat:grouplist(user)

    else
        data, err = chat:list(user, sid)
    end
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

function last(typ)
    local sid = get_instance().session:get('sid')
    local rnames, get_contact_func

    if "group" == typ then
        get_contact_func = "groupcontact"
        rnames = loader:model('rgroup')

    else
        get_contact_func = "contact"
        rnames = loader:model('ruser')
    end

    local chat = loader:model('rchat')
    local data = chat[get_contact_func](chat, sid, 20)
    chat:close()

    local uids = values(data, 'uid')
    if #uids > 0 then
        local usernames = rnames:gets(uids)

        for i, u in pairs(data) do
            data[i].username = usernames[u.uid]
        end
    end
    rnames:close()

    return "last", { typ = typ or 'user', data = data }
end

function join(gid)
    local uid = get_instance().uid

    local group = loader:model('rgroup')
    local res, err = group:join(uid, gid)
    group:close()

    if res then
        local chat = loader:model('rchat')
        chat:join(uid, gid)
        chat:close()
    end

    return true
end
