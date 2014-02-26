-- Copyright (C) 2013 doujiang24, MaMa Inc.


timeout = 3000

host = "127.0.0.1"
port = "6400"

max_keepalive = 100
idle_timeout = 60 * 60 * 1000   -- 1 hour in ms


-- realtime message
channel_pref = "channel:"   -- pub/sub  pref:uid/group

-- unread num
unread_pref = "unread:"     -- hash     pref:uid contact num

-- last contact
contact_pref = "contact:"               -- zsort    pref:uid contact timestamp
group_contact_pref = "contact:group:"   -- zsort    pref:uid contact timestamp

-- online status
online_user_list = "online_user_list"   -- zsort    user timestamp
online_pref =   "online:"               -- hash     pref:uid client timestamp

client_pref =   "client:"   -- string   pref:uid num (incr)
hold_pref   =   "hold:"     -- string   pref:uid:client num (1 or nil)     expire: max network delay
delay_pref  =   "delay:"    -- list     pref:uid:client     expire: max_network_delay

-- users
user_hash_list = "user_lists"

-- groups
group_pref =    "group:"    -- group    pref:uid gid    sets
group_name_count    =   "group_count"   -- group count  string  incr
group_name_hash     =   "group_name"    -- groupname    hash
group_user_pref     =   "gusr:"         -- group user   sets
user_group_pref     =   "ugrp:"         -- user group   sets

-- timeout config
max_network_delay = 10          -- 1 second     max delay hold
longpoll_timeout = 30           -- 30 second
subscribe_timeout = 1000 * 1    -- 1 second
