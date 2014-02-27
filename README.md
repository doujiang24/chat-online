Name
====

It is chat online demo base on [durap](https://github.com/doujiang24/durap)

And durap is a framework base on [openresty](http://openresty.org/)



DEMO
====

<http://chat.qinxunw.com>

IE >= 9; chrome; safari supported

just a demo

most 1 second delay now; can be realtime when cosocket support full duplex



Description
====

Multi-client (one user); group chat; online status; unread num supported

messages saved in mysql

messages sent via `websocket` or `longpoll` base on redis pub/sub

in longpoll, lua will start an background thread by 0 delay timer, the thread subscribe channel and push to a list; and longpoll request will blpop from the list


redis datatype
====

last contact:

    sorted set;         user contact timestamp;     user group timestamp

online status:

    (user)          hash        user client timestamp
    (global)        hash        global_key user timestamp

unread number

    hash        user contact num

group relation

    (user-group)    set     user group
    (group-user)    set     group user


realtime

    pub/sub         channel: user or group      group messages sent via group channel


and other ...

License
====

This software is distributed under Apache License Version 2.0, see file LICENSE or <http://www.apache.org/licenses/LICENSE-2.0>
