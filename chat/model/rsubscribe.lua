-- Copyright (C) 2013 MaMa

local redis = require "database.redis"
local cjson = require "cjson"

local setmetatable = setmetatable
local get_instance = get_instance
local json_decode = cjson.decode
local ngx_null = ngx.null
local unpack = unpack


local _M = getfenv()

local config = get_instance().loader:config('redis')
local channel_pref = config.channel_pref
local subscribe_timeout = config.subscribe_timeout

function new(self, uid, groups)
    local red, chs = redis:connect(config), { channel_pref .. uid }

    if groups then
        for i = 1, #groups do
            chs[#chs + 1] = channel_pref .. groups[i]
        end
    end

    get_instance().debug:log_debug('subscribe', unpack(chs))
    red:subscribe(unpack(chs))
    red:set_timeout(subscribe_timeout)

    return setmetatable({
        red = red,
        uid = uid,
        groups = groups,
        chs = chs,
    }, { __index = _M } )
end

function subscribe(self, timeout)
    local red = self.red

    if timeout then
        red:set_timeout(timeout)
    end

    local data, err = red:read_reply()
    if data and data ~= ngx_null and "message" == data[1] then
        local package = json_decode(data[3])
        if package and package._t == "join" then
            join(self, package.group)
            return
        end

        return data[3]
    end

    if err ~= "timeout" then
        return nil, err
    end
end

function join(self, gid)
    local chs, key = self.chs, channel_pref .. gid

    for _i, k in ipairs(chs) do
        if k == key then
            return
        end
    end

    chs[#chs + 1] = key
    self.groups[#self.groups + 1] = gid

    get_instance().debug:log_debug('subscribe', key)
    return self.red:subscribe(key)
end

function close(self)
    local red, chs = self.red, self.chs

    if chs then
        red:unsubscribe(unpack(chs))
        get_instance().debug:log_debug('unsubscribe', unpack(chs))
    end

    return red:keepalive()
end
