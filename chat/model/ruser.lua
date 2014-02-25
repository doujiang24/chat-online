-- Copyright (C) 2013 MaMa

local redis = require "database.redis"
local uuid = require "resty.uuid"

local type = type
local unpack = unpack
local str_sub = string.sub
local setmetatable = setmetatable


local _M = getfenv()

local config = get_instance().loader:config('redis')
local user_hash_list = config.user_hash_list
local group_pref = config.group_pref

function new(self)
    return setmetatable({
        red = redis:connect(config),
    }, { __index = _M } )
end

function sign(self, username)
    local red = self.red

    local sid = uuid:generate()
    red:hset(user_hash_list, sid, username)

    return sid
end

-- uid: string or table
function get(self, uid)
    local red = self.red

    if type(uid) == "string" then
        local res = red:hget(user_hash_list, uid)
        return res ~= ngx_null and res or ''
    end

    local ret = {}

    if #uid > 0 then
        local uids, groups = {}, {}

        for i = 1, #uid do
            if str_sub(uid[i], 1, #group_pref) ~= group_pref then
                uids[#uids + 1] = uid[i]
            else
                groups[#groups + 1] = uid[i]
            end
        end

        if #uids > 0 then
            ret = gets(self, uids)
        end

        if #groups > 0 then
            local group = get_instance().loader:model('rgroup')
            groupnames = group:gets(groups)
            group:close()

            for k, v in pairs(groupnames) do
                ret[k] = v
            end
        end
    end
    return ret
end

function gets(self, uids)
    local red, ret = self.red, {}

    local names = red:hmget(user_hash_list, unpack(uids))

    for i = 1, #uids do
        ret[uids[i]] = names and names[i] or ''
    end

    return ret
end

function close(self)
    return self.red:keepalive()
end
