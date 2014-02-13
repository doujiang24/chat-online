-- Copyright (C) 2013 MaMa

local redis = require "database.redis"
local uuid = require "resty.uuid"

local type = type
local unpack = unpack
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

-- sid: string or table
function get(self, sid)
    local red = self.red

    if type(sid) == "string" then
        return red:hget(user_hash_list, sid)
    end

    local ret = {}

    if #sid > 0 then
        local names = red:hmget(user_hash_list, unpack(sid))

        for i = 1, #sid do
            ret[sid[i]] = names[i]
        end
    end
    return ret
end

function groups(self, uid)
    local ret = self.red:smembers(group_pref .. uid)

    return ret ~= ngx_null and ret or {}
end

function group_join(self, uid, gid)
    return self.red:sadd(group_pref .. uid, gid)
end

function close(self)
    return self.red:keepalive()
end
