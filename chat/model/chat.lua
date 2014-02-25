-- Copyright (C) 2013 MaMa

local setmetatable = setmetatable


_VERSION = '0.01'


local _M = getfenv()


function new(self)
    return setmetatable({
        rchat = get_instance().loader:model('rchat'),
        mchat = get_instance().loader:model('mchat'),
    }, { __index = _M } )
end

function send(self, sender, acceptor, message, sender_username, acceptor_username)
    local mchat, rchat = self.mchat, self.rchat

    local id, err = mchat:send(sender, acceptor, message)

    if id then
        rchat:send(id, sender, acceptor, message, sender_username, acceptor_username)
        return true
    end
    return nil, err
end

function groupsend(self, sender, acceptor, message, sender_username, groupname)
    local mchat, rchat = self.mchat, self.rchat

    local id, err = mchat:send(sender, acceptor, message)

    if id then
        rchat:groupsend(id, sender, acceptor, message, sender_username, groupname)
        return true
    end
    return nil, err
end

function view(self, sender, acceptor, typ)
    local mchat, rchat = self.mchat, self.rchat

    if "user" == typ then
        mchat:view(sender, acceptor)
    end
    return rchat:view(sender, acceptor)
end

function close(self)
    self.mchat:close()
    return self.rchat:close()
end
