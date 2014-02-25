-- Copyright (C) 2013 MaMa

local mysql = require "database.mysql"

local setmetatable = setmetatable
local localtime = ngx.localtime
local str_sub = string.sub


local _M = getfenv()

_VERSION = '0.01'


-- constants
local config = get_instance().loader:config('mysql')
local db_table = config.chat_message


function new(self)
    return setmetatable( {
        db = mysql:connect(config)
    }, { __index = _M } )
end

function send(self, sender, acceptor, msg)
    local db = self.db

    local setarr = {
        sender = sender,
        acceptor = acceptor,
        message = msg,
        time = localtime()
    }
    return db:add(db_table, setarr)
end

function view(self, sender, acceptor)
    local db = self.db

    db:where('sender', sender):where('acceptor', acceptor)
    return db:set('status', 0):update(db_table)
end

function list(self, id, another, limit, max_id)
    local db = self.db

    local s1 = db:where('sender', id):where('acceptor', another):where_export()
    local s2 = db:where('acceptor', id):where('sender', another):where_export()
    db:where("((" .. s1 .. ") OR (" .. s2 .. "))", '', false)

    if max_id then
        db:where('`id` <', max_id)
    end

    return db:limit(limit or 10):order_by('id', 'DESC'):get(db_table)
end

function grouplist(self, group, limit, max_id)
    local db = self.db
    db:where('acceptor', group)

    if max_id then
        db:where('`id` <', max_id)
    end

    return db:limit(limit or 10):order_by('id', 'DESC'):get(db_table)
end

function close(self)
    return self.db:keepalive()
end
