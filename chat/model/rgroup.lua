-- Copyright (C) 2013 MaMa

local redis = require "database.redis"
local uuid = require "resty.uuid"

local type = type
local unpack = unpack
local setmetatable = setmetatable


local _M = getfenv()

local config = get_instance().loader:config('redis')
local group_pref = config.group_pref
local group_name_hash = config.group_name_hash
local group_user_pref = config.group_user_pref
local user_group_pref = config.user_group_pref

function new(self)
    return setmetatable({
        red = redis:connect(config),
    }, { __index = _M } )
end

function add(self, name)
    local red = self.red

    local id = red:hincrby(group_name_hash, 'count', 1)
    local key = group_pref .. id
    red:hset(group_name_hash, key, name)

    return key
end

function get(self, group)
    local res, err = self.red:hget(group_name_hash, group)

    return res ~= ngx_null and res or ''
end

function gets(self, groups)
    local red, ret = self.red, {}

    local names = red:hmget(group_name_hash, unpack(groups))

    for i = 1, #groups do
        ret[groups[i]] = names and names[i] or ''
    end

    return ret
end

function all(self)
    local red = self.red

    local res, err = red:hgetall(group_name_hash)

    if res and res ~= ngx_null then
        return red:array_to_hash(res)
    end

    return {}, err
end

function users(self, group)
    local ret = self.red:smembers(group_user_pref .. group)

    return ret ~= ngx_null and ret or {}
end

function groups(self, uid)
    local ret = self.red:smembers(user_group_pref .. uid)

    return ret ~= ngx_null and ret or nil
end

function join(self, uid, group)
    local red = self.red

    red:multi()
    red:sadd(group_user_pref .. group, uid)
    red:sadd(user_group_pref .. uid, group)
    local results, err = red:exec()

    return results and 1 == results[1] or nil
end

function close(self)
    return self.red:keepalive()
end
