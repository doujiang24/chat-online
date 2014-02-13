-- Copyright (C) 2013 doujiang24 @ MaMa, Inc.


local get_instance = get_instance

function index()
    ngx.say(get_instance().loader:view('index'))
end
