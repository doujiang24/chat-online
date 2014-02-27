/* charset=utf8; */

var api_host = "api.chat.qinxunw.com";
var host = "http://" + api_host;

var console, _log;

(function () {

if (typeof console === 'undefined') {
    _log = function (a, b, c) {
        /*alert('' + a + b + c)*/
    };
} else if (Function.prototype.bind && window.console && typeof console.log.apply === "undefined") {
    _log = function () {
        var log = Function.prototype.bind.call(console.log, console);
        log.apply(console, arguments);
    };
} else {
    _log = function () {
        console && console.log && console.log.apply(console, arguments)
    };
}
})();

var Server = {
    ws: null,
    wb_support: false,
    polling: false,
    connect: function () {
        _log('server connect');
        if (Server.ws !== null || Server.polling) {
            _log('already connected');
            return false;
        }

        if (typeof WebSocket == "undefined") {
            _log('不支持的 websocket, 启动长轮询');
            Server.longpoll();
            Server.contact();
            Server.contact('group');
        } else {
            Server.ws = new WebSocket('ws://' + api_host + '/chat/websocket?uid=' + User.uid + "&client=" + User.client);
            Server.ws.onopen = function () {
                //Server.ws.close();
                Server.wb_support = true;
                //Server.sign();
                Server.contact();
                Server.contact('group');
            };
            Server.ws.onerror = function (error) {
                _log(error);
            };
            Server.ws.onmessage = function (e) {
                Client.recieve(e.data);
            };
            Server.ws.onclose = function () {
                if (Server.wb_support) {
                    _log('server disconnected');
                    Server.ws = null;
                    alert('网络连接断开');
                } else {
                    _log('不支持的 websocket, 启动长轮询');
                    Server.longpoll();
                    Server.contact();
                    Server.contact('group');
                }
            };
        }
        return true;
    },
    longpoll: function () {
        Server.polling = true;
        $.ajax({
            type: 'GET',
            url: host + '/chat/longpoll',
            data: {
                client: User.client
            },
            dataType: 'jsonp',
            success: function (res) {
                if (1 == res.status) {
                    Client.recieve(res.data);
                } else if (-1 == res.status) {
                    return alert(res.errmsg.msg);
                }
                Server.longpoll();
            }
        });
    },
    send: function(text, acceptor) {
        var data = {
            msg: text,
            acceptor: Client.current_contact,
            typ: Database.type(acceptor)
        };
        this._send("msg", data);
    },
    history: function(uid) {
        var data = {
            contactor: uid,
            typ: Database.type(uid)
        };
        this._send('list', data);
    },
    contact: function (typ) {
        var data = {
            typ: typ || 'user'
        };
        this._send("last", data);
    },
    view: function (uid) {
        var data = {
            contact: uid,
            typ: Database.type(uid)
        };
        this._send('view', data);
    },
    join: function (gid) {
        var data = {
            group: gid
        };
        this._send('join', data);
    },
    _send: function(type, data) {
        data._t = type;
        _log(data);
        var str = $.toJSON(data);

        if (this.wb_support) {
            Server.ws.send(str);
        } else {
            this._ajax_send(str);
        }
    },
    _ajax_send: function(str) {
        $.ajax({
            type: 'GET',
            url: host + '/chat/send',
            data: { data: str },
            dataType: 'jsonp',
            success: function (res) {
                if (2 == res.status) {
                    _log('ajax send return:', res.data);
                    Client.recieve(res.data);
                } else if (0 == res.status) {
                    _log(res.errmsg);
                }
            }
        });
    }
};

var Database = {
    contact_users: {},
    contact_groups: {},
    messages: {},

    add_user: function (uid, username, online, unread) {
        if (! this.contact_users[uid]) {
            this.contact_users[uid] = { username: username, online: online || false, unread: unread || 0 };
            this.messages[uid] = null;
            return true;
        }
        return false;
    },
    add_group: function (uid, username, unread) {
        if (! this.contact_groups[uid]) {
            this.contact_groups[uid] = { username: username, unread: unread || 0 };
            this.messages[uid] = null;
            return true;
        }
        return false;
    },
    type: function(uid) {
        if (this.contact_users[uid]) {
            return 'user';

        } else if (this.contact_groups[uid]) {
            return 'group';
        }
        return null;
    },
    username: function(uid) {
        if (this.contact_users[uid]) {
            return this.contact_users[uid].username;
        }
        return this.contact_groups[uid].username;
    },
    unread: function (uid, unread) {
        var arr = this.type(uid) == "user" ? this.contact_users[uid] : this.contact_groups[uid];
        var current = arr['unread'] || 0;
        var num = unread == "incr" ? current + 1 : unread;

        arr['unread'] = num;
        return { num: num, changed: current == num ? false : true };
    },
    online: function (uid, online) {
        var arr = this.type(uid) == "user" ? this.contact_users[uid] : this.contact_groups[uid];
        arr['online'] = online || false;
    },
    add_message: function(data) {
        var uid = data.acceptor === User.uid ? data.sender : data.acceptor;

        if (! Database.messages[uid]) {
            Database.messages[uid] = {};

        } else if (Database.messages[uid][data.id]) {
            return false;
        }

        Database.messages[uid][data.id] = data;
        return uid;
    }
};

var Client = {
    current_contact: null,
    current_group: null,
    current_tab: 'user', // or 'group'
    on: {},
    init: function() {
        _log('client init');
        if (Server.connect()) {
            Client.bind();
        }
    },
    bind: function() {
        $("form.publish").submit(function () {
            var text = $(".publish input").val();
            Server.send(text, Client.current_contact);
            $(".publish input").val('');
            return false;
        });
    },
    unread: function (uid, num) {
        var username = Database.username(uid);
        var res = Database.unread(uid, num);
        //_log('database unread return:', res);
        var typ = Database.type(uid);

        if (res.num > 0) {
            $("." + typ + " li[uid='" + uid + "']").html(username + "(" + res.num + ")");
        } else {
            $("." + typ + " li[uid='" + uid + "']").html(username);
        }
        this.unread_tab();
        return res.changed;
    },
    unread_tab: function() {
        var num = 0;
        $.each(Database.contact_users, function(uid, data) {
            num += (data.unread ? data.unread : 0);
        });
        $(".list_tab li[typ=user]").html("好友聊天" + (num == 0 ? "" : "(" + num + ")"));

        num = 0;
        $.each(Database.contact_groups, function(uid, data) {
            num += (data.unread ? data.unread : 0);
        });
        $(".list_tab li[typ=group]").html("群组聊天" + (num == 0 ? "" : "(" + num + ")"));
    },
    online: function (uid, online) {
        var typ = Database.type(uid);
        if (online) {
            $("." + typ + " li[uid='" + uid + "']").addClass('online');
            Database.online(uid, true);
        } else {
            $("." + typ + " li[uid='" + uid + "']").removeClass('online');
            Database.online(uid, false);
        }
    },
    add_user: function (uid, username, online, unread) {
        if (Database.type(uid) != null) { return; }

        if ("group" == online) {
            if (Database.add_group(uid, username, unread)) {
                $(".group ul").prepend("<li uid='" + uid + "'>" + username + "</li>");
                $(".group li:first").click(function (e) {
                    Client.show($(e.target).attr('uid'));
                });
                this.unread(uid, unread);
                this.online(uid, true);
                return true;
            }
        } else if (Database.add_user(uid, username, online, unread)) {
            $(".user ul").prepend("<li uid='" + uid + "'>" + username + "</li>");
            $(".user li:first").click(function (e) {
                Client.show($(e.target).attr('uid'));
            });
            this.online(uid, online);
            this.unread(uid, unread);
            return true;
        }
    },
    add_message: function (data, is_history) {
        var typ = data.typ == "group" ? data.typ : null;
        if (data.acceptor == User.uid) {
            this.add_user(data.sender, data.sender_username, typ || true, 1);
        } else {
            this.add_user(data.acceptor, data.acceptor_username, typ || undefined, 0);
        }

        var uid = null;
        if ( uid = Database.add_message(data) ) {
            //_log("client add message", data);
            //_log(uid);
            if (data.sender != User.uid && !is_history) {
                this.unread(uid, 'incr');
            }

            if (this.current_contact == uid) {
                this.show(this.current_contact);
            }
        }
    },
    history: function (data) {
        if (data.messages.length > 0) {
            $.each(data.messages, function (_k, m) {
                Client.add_message(m, true);
            });

        } else {
            Database.messages[data.uid] = {};
        }

        if (this.current_contact) {
            this.show(data.uid);
        }
    },
    contact: function (res) {
        _log('contact');
        var typ = res.typ, data = res.data;

        $.each($.isArray(data) ? data.reverse() : [], function(_i, u) {
            Client.add_user(u.uid, u.username, typ == "group" ? typ : u.online, u.unread);
        });

        var uid = $("." + typ + " li:first").attr('uid');
        this.on[typ] = uid;

        //_log(typ, uid);
        if (uid) {
            this.show(uid);
        }
    },
    recieve: function(str) {
        var res = $.evalJSON(str);

        _log(res);
        var data = res.data;
        if (res._t == "msg") {
            this.add_message(data);

        } else if (res._t == "list") {
            this.history(data);

        } else if (res._t == "last") {
            this.contact(data);

        } else if (res._t == "view") {
            //_log("view recv", data);
            if (data.sender == User.uid) {
                this.unread(data.acceptor, 0);
            } else {
                this.unread(data.sender, 0);
            }
        }
    },
    chat: function(uid, username, typ) {
        this.init();
        var newer = this.add_user(uid, username, typ == "group" ? typ : true);

        if (typ == "group" && newer) {
            Server.join(uid);
        }

        this.show(uid);
    },
    change_tab: function(typ) {
        if (typ != this.current_tab) {
            var another = typ == "group" ? "user" : "group";
            $("." + typ).show();
            $("." + another).hide();

            this.current_tab = typ;

            $(".list_tab li").removeClass('on');
            $(".list_tab li[typ='" + typ + "']").addClass('on');
        }
    },
    show: function(uid) {
        var typ = Database.type(uid);
        this.change_tab(typ);

        this.current_tab = typ;

        //_log('show uid:' + uid);

        $("." + typ + " li.on").removeClass('on');
        $("." + typ + " li[uid='" + uid + "']").addClass('on');

        this.on[typ] = uid;
        this.current_contact = uid;

        if (this.unread(uid, 0)) {
            //_log('view', uid);
            Server.view(uid);
        }

        if (Database.messages[uid]) {
            $(".messages").html(this.message_html(uid));
            $(".messages").scrollTop($(".messages")[0].scrollHeight);
        } else {
            Server.history(uid);
        }
    },
    message_html: function (uid) {
        var html = '';
        $.each(Object.keys(Database.messages[uid]), function (i, id) {
            var data = Database.messages[uid][id];
            var time = data.time, msg = data.message,
                myself = 'self', username = '我';

            if (data.sender != User.uid) {
                myself = "";
                username = data.sender_username != undefined ? data.sender_username : Database.contact_users[data.sender].username;
            }

            html += "<div class='" + myself + "'><p><span class='u'>" +
                username + "</span><span class='t'>" +
                time + "</span></p><p>" + msg + "</p></div>";
        });

        return html;
    }
}

var User = {
    uid: '',
    username: '',
    sign: function () {
        _log('sign');
        $.ajax({
            type: 'GET',
            url: host + '/login/sign',
            data: {
                username: $("#username").val()
            },
            dataType: 'jsonp',
            success: function (res) {
                if (1 == res.status) {
                    _log('sign done');
                    User.login();
                }
            }
        });
    },
    login: function () {
        _log('login');
        $.ajax({
            type: 'GET',
            url: host + '/login',
            dataType: 'jsonp',
            success: function (res) {
                _log('callback');
                if (1 == res.status) {
                    _log('login first');
                    User.user(res.data.sid, res.data.username, res.data.client);
                    Client.init();
                } else {
                    User.need_sign();
                }
            }
        });
    },
    need_sign: function () {
        $(".user_info").html("<form id='user_sign'><input name='username' id='username'><input type='submit' value='登录'></form>");
        $("#user_sign").submit(function () {
            User.sign();
            return false;
        });
    },
    user: function (sid, username, client) {
        User.uid = sid;
        User.username = username;
        User.client = client;
        $(".user_info").html("<p>欢迎, " + username + "</p>");
    }
}

$(document).ready(function () {
    // online users
    $.ajax({
        type: 'GET',
        url: host + '/chat/onall',
        dataType: 'jsonp',
        success: function (res) {
            var html = '';
            if (1 == res.status) {
                $.each(res.data, function (uid, username) {
                    html += "<span uid='" + uid + "'>" + username + "</span>";
                });
            }
            $(".onlines div").html(html);

            $(".onlines span").click(function (e) {
                var uid = $(e.target).attr("uid");
                var username = $(e.target).html();

                Client.chat(uid, username);
            });
        }
    });

    // all groups
    $.ajax({
        type: 'GET',
        url: host + '/group/all',
        dataType: 'jsonp',
        success: function (res) {
            var html = '';
            if (1 == res.status) {
                $.each(res.data, function (uid, username) {
                    html += "<span uid='" + uid + "'>" + username + "</span>";
                });
            }
            $(".groups div").html(html);

            $(".groups span").click(function (e) {
                var uid = $(e.target).attr("uid");
                var username = $(e.target).html();

                Client.chat(uid, username, 'group');
            });
        }
    });

    $("#groupadd").submit(function () {
        var name = $("#groupadd input[name=groupname]").val();
        if ( !name || name.length == 0) {
            alert('请输入群组名称');
            return false;
        }
        $.ajax({
            type: 'GET',
            url: host + '/group/add',
            data: {
                name: name
            },
            dataType: 'jsonp',
            success: function (res) {
                if (1 == res.status) {
                    var html = "<span uid='" + res.data.gid + "'>" + res.data.name + "</span>";
                    $(".groups div").append(html);
                }

                $(".groups span:last").click(function (e) {
                    var uid = $(e.target).attr("uid");
                    var username = $(e.target).html();

                    Client.chat(uid, username, 'group');
                });
                $("#groupadd input[name=groupname]").val('');
            }
        });
        return false;
    });
});


$(".list_tab li").click(function () {
    var typ = $(this).attr('typ');
    Client.change_tab(typ);

    if (Client.on[typ]) {
        Client.show(Client.on[typ]);
    }
});

User.login();
