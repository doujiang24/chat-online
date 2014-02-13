-- Copyright (C) 2013 doujiang24 @ MaMa, Inc.

local cjson = require "cjson"
local output = require "core.output"
local log_error = require("helper.core").log_error

local get_instance = get_instance
local json_encode = cjson.encode
local spawn = ngx.thread.spawn
local wait = ngx.thread.wait
local exit = ngx.exit
local timer_at = ngx.timer.at
local on_abort = ngx.on_abort
local ngx = ngx


local loader = get_instance().loader
local wblib = loader:library('websocket')
local chatlib = loader:library('chat')
local debug = get_instance().debug
local hold_dely_subscribe_timeout = loader:config('core').hold_dely_subscribe_timeout


function websocket()
    local dp = get_instance()
    local wb = wblib:init()

    if not wb then return end
    dp.wb = wb

    handle_client_abort()


    local gets = dp.request:get()
    local uid, client = gets.uid, gets.client
    dp.uid, dp.client = uid, client

    local user = loader:model('ruser')
    local groups = user:groups(uid)
    user:close()

    local rchat = loader:model('rchat', uid, groups)

    while true do
        local rcht = loader:model('rchat')
        rcht:client_online(uid, client)
        rcht:close()

        local co = spawn(rchat.subscribe, rchat)

        local recv_data = wb:recv()

        if recv_data then
            local ok, data = chatlib.recv(recv_data)
            if not ok then
                wb:send_err(data)

            elseif data then
                wb:send_data(ok, data)
            end

        elseif false == recv_data then
            wait(co)
            break
        end

        local ok, data = wait(co)
        if not ok then
            log_error("failed to run thread", data)
        end

        if data then
            wb:send(data)
        end
    end

    rchat:close()
    wb:close()
end

function cleanup()
    local dp = get_instance()
    local uid, client, wb = dp.session:get('sid'), dp.client, dp.wb

    local rchat = dp.loader:model('rchat')
    rchat:client_offline(uid, client)
    rchat:close()

    if wb then
        wb:close()
    end
    get_instance().debug:log_debug('client close premature')
end

function handle_client_abort()
    local ok, err = on_abort(cleanup)
    if not ok then
        log_error("failed to register the on_abort callback", err)
        exit(500)
    end
end

function longpoll()
    local dp = get_instance()
    local uid, client = dp.session:get('sid'), dp.request:get('client')
    dp.client = client
    local callback = get_instance().request:get('callback')

    handle_client_abort()

    -- connect
    local rchat = loader:model('rchat')
    local ok, init = rchat:connect(uid, client)

    -- too much delay
    if not ok then
        rchat:close()
        return output.json_callback(callback, -1, nil, err, 607)

    elseif init then
        start_hold(uid, client)
    end

    local data, err = rchat:longpoll(uid, client)
    rchat:hold_delay(uid, client)
    rchat:close()

    output.json_callback(callback, data and 1 or 0, data)
end

function start_hold(uid, client)
    local ok, err = timer_at(0, back_hold, uid, client, get_instance())
    if not ok then
        get_instance().debug:log_error("failed to create timer: ", err)
    end
    get_instance().debug:log_debug('timer')
end

function back_hold(premature, uid, client, dp)
    ngx.ctx.dp = dp
    local loader = get_instance().loader

    local user = loader:model('ruser')
    local groups = user:groups(uid)
    user:close()

    local rchat = loader:model('rchat', uid, groups)
    while true do
        local res, err = rchat:subscribe()

        if res then
            local rcht = loader:model('rchat')
            rcht:delay_message(uid, client, res)
            rcht:close()

        elseif err ~= "timeout" then
            get_instance().debug:log_debug('check_hold, err:', err)
            break
        end

        local rcht = loader:model('rchat')
        local res = rcht:check_hold(uid, client)
        rcht:close()

        if not res then
            get_instance().debug:log_debug('check_hold', res, '.')
            break
        end
    end
    rchat:close()
end


function send()
    local request = get_instance().request

    local get = request:get('data')
    local ok, data = chatlib.recv(get)

    local callback = request:get('callback')
    local status = (ok and data) and 2 or (ok and 1 or 0)

    if not ok then
        return output.json_callback(callback, 0, nil, 602, data)

    elseif data then
        local str = json_encode({ _t = ok, data = data})
        return output.json_callback(callback, 2, str)
    end

    return output.json_callback(callback, 1)
end


function message(contact, id)
    local mchat = loader:model('mchat')

    local sid = get_instance().session:get('sid')
    local data, err = mchat:list(sid, contact, id)

    output.json(1, data)
end

function contact()
    local rchat = loader:model('rchat')

    local sid = get_instance().session:get('sid')
    local data, err = rchat:contact(sid)

    output.json(1, data)
end

function online()
    local users = get_instance().request:post('user')

    local rchat = loader:model('rchat')
    local data, err = rchat:online(users)

    output.json(1, data)
end

function onall()
    local rchat = loader:model('rchat')
    local users, err = rchat:online_all()
    rchat:close()

    local ruser = loader:model('ruser')
    local data, err = ruser:get(users)
    ruser:close()

    local callback = get_instance().request:get('callback')
    output.json_callback(callback, data and 1 or 0, data, nil, err)
end
