-- Copyright (C) 2013 doujiang24 @ MaMa, Inc.

local server = require "resty.websocket.server"
local cjson = require "cjson"

local get_instance = get_instance
local exit = ngx.exit
local json_encode = cjson.encode

local debug = get_instance().debug

local _M = getfenv()


function init()
    local wb, err = server:new{
        timeout = 1000,
        max_payload_len = 65535,
        send_masked = false,
    }

    if not wb then
        debug:log_error("failed to new websocket: ", err)
        return false
    end
    return setmetatable( { wb = wb }, { __index = _M } )
end

function send(self, txt)
    local bytes, err = self.wb:send_text(txt)

    if not bytes then
        debug:log_error("failed to send text: " .. txt, err)
        return false
    end

    return true
end

function send_err(self, msg)
    local data = {
        _t = 'error',
        data = {
            errmsg = msg,
        },
    }

    return send(self, json_encode(data))
end

function send_data(self, typ, data)
    local data = {
        _t = typ,
        data = data,
    }
    return send(self, json_encode(data))
end

function recv(self)
    local wb = self.wb

    local data, typ, err = wb:recv_frame()

    if wb.fatal then
        debug:log_debug("failed to receive frame: ", err)
        return false
    end

    if typ == "close" then
        wb:send_close()
        debug:log_debug('client send close')
        return false

    elseif typ == "ping" then
        local bytes, err = wb:send_pong()
        if not bytes then
            debug:log_error("failed to send pong: ", err)
            return false
        end

    elseif typ == "text" and data then
        return data
    end

    return nil
end

function close(self)
    local wb = self.wb

    wb:send_close()
end
