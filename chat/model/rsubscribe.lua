-- Copyright (C) 2013 MaMa

local redis = require "database.redis"

local setmetatable = setmetatable
local get_instance = get_instance
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
    if data and data ~= ngx_null then
        return data and data[3]
    end

    return nil, err
end

function close(self)
    local red, chs = self.red, self.chs

    if chs then
        red:unsubscribe(unpack(chs))
        get_instance().debug:log_debug('unsubscribe', unpack(chs))
    end

    return red:keepalive()
end
