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
        } else {
            Server.ws = new WebSocket('ws://' + api_host + '/chat/websocket?uid=' + User.uid + "&client=" + User.client);
            Server.ws.onopen = function () {
                //Server.ws.close();
                Server.wb_support = true;
                //Server.sign();
                Server.contact();
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
                client: User.client,
                _t: (new Date()).valueOf()
            },
            dataType: 'jsonp',
            success: function (res) {
                _log(res);
                if (1 == res.status) {
                    Client.recieve(res.data);
                } else if (-1 == res.status) {
                    return alert(res.errmsg.msg);
                }
                Server.longpoll();
            }
        });
    },
    sign: function() {
        var data = {
            uid: User.uid,
            client: User.client
        };
        this._send("sign", data);
    },
    send: function(text) {
        var data = {
            acceptor: Client.current_uid,
            msg: text
        };
        this._send("msg", data);
    },
    history: function(uid) {
        var data = {
            contactor: uid
        };
        this._send('list', data);
    },
    contact: function () {
        this._send("last", {});
    },
    view: function (uid) {
        var data = {
            contact: uid
        };
        this._send('view', data);
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
    messages: {},

    add_user: function (uid, username, online, unread) {
        if (! this.contact_users[uid]) {
            this.contact_users[uid] = { username: username, online: online || false, unread: unread || 0 };
            this.messages[uid] = null;
            return true;
        }
        return false;
    },
    unread: function (uid, unread) {
        var current = this.contact_users[uid]['unread'] || 0;
        var num = unread == "incr" ? current + 1 : unread;

        this.contact_users[uid]['unread'] = num;
        return { num: num, changed: current == num ? false : true };
    },
    online: function (uid, online) {
        this.contact_users[uid]['online'] = online || false;
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
    init: function() {
        _log('client init');
        if (Server.connect()) {
            Client.bind();
        }
    },
    bind: function() {
        $("form.publish").submit(function () {
            var text = $(".publish input").val();
            Server.send(text);
            $(".publish input").val('');
            return false;
        });
    },
    unread: function (uid, num) {
        var username = Database.contact_users[uid].username;
        var res = Database.unread(uid, num);
        _log('database unread return:', res);

        if (res.num > 0) {
            $(".users li[uid=" + uid + "]").html(username + "(" + res.num + ")");
        } else {
            $(".users li[uid=" + uid + "]").html(username);
        }
        return res.changed;
    },
    online: function (uid, online) {
        if (online) {
            $(".users li[uid=" + uid + "]").addClass('online');
            Database.online(uid, true);
        } else {
            $(".users li[uid=" + uid + "]").removeClass('online');
            Database.online(uid, false);
        }
    },
    add_user: function (uid, username, online, unread) {
        if (Database.add_user(uid, username, online, unread)) {
            $(".users ul").prepend("<li uid='" + uid + "'>" + username + "</li>");
            $(".users li:first").click(function (e) {
                Client.show($(e.target).attr('uid'));
            });
            this.online(uid, online);
            this.unread(uid, unread);
        }
    },
    add_message: function (data) {
        if (data.acceptor == User.uid) {
            this.add_user(data.sender, data.sender_username, true, 1);
        } else {
            this.add_user(data.acceptor, data.acceptor_username, undefined, 0);
        }

        var uid = null;
        if ( uid = Database.add_message(data) ) {
            //_log("client add message", data);
            _log(uid);
            if (this.current_uid == uid) {
                this.show(this.current_uid);

            } else if (data.sender != User.uid) {
                this.unread(uid, 'incr');
            }
        }
    },
    history: function (data) {
        if (data.messages.length > 0) {
            $.each(data.messages, function (_k, m) {
                Client.add_message(m);
            });

        } else {
            Database.messages[data.uid] = {};
        }

        if (this.current_uid) {
            this.show(data.uid);
        }
    },
    contact: function (data) {
        _log('contact');
        $.each($.isArray(data) ? data.reverse() : [], function(_i, u) {
            Client.add_user(u.uid, u.username, u.online, u.unread);
        });
        _log(data);

        var uid = $(".users li:first").attr('uid');
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
            _log("view recv", data);
            if (data.sender == User.uid) {
                this.unread(data.acceptor, 0);
            } else {
                this.unread(data.sender, 0);
            }
        }
    },
    chat: function(uid, username) {
        this.init();
        this.add_user(uid, username, true);

        if (Database.add_user(uid, username, true)) {
            $(".users ul").prepend("<li uid='" + uid + "'>" + username + "</li>");
            $(".users li:first").click(function (e) {
                this.show($(e.target).attr('uid'));
            });
        }

        this.show(uid);
    },
    show: function(uid) {
        if (this.current_uid != uid) {
            _log('show uid:' + uid);

            $(".users li.on").removeClass('on');
            $(".users li[uid=" + uid + "]").addClass('on');

            this.current_uid = uid;

            if (this.unread(uid, 0)) {
                _log('view', uid);
                Server.view(uid);
            }
        }

        if (Database.messages[uid]) {
            $(".messages").html(this.message_html(uid));
        } else {
            Server.history(uid);
        }
    },
    message_html: function (uid) {
        var html = '';
        $.each(Object.keys(Database.messages[uid]).sort(), function (i, id) {
            var data = Database.messages[uid][id];
            var time = data.time, msg = data.message,
                myself = 'self', username = '我';

            if (data.sender != User.uid) {
                myself = "";
                username = data.sender_username || Database.contact_users[data.sender].username;
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
        $(".user").html("<form id='user_sign'><input name='username' id='username'><input type='submit' value='登录'></form>");
        $("#user_sign").submit(function () {
            User.sign();
            return false;
        });
    },
    user: function (sid, username, client) {
        User.uid = sid;
        User.username = username;
        User.client = client;
        $(".user").html("<p>欢迎, " + username + "</p>");
    }
}

$(document).ready(function () {
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
});



User.login();
