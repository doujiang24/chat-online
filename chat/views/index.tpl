<html>

<head>
    <title>即时聊天 - 玩具版</title>
    <meta http-equiv="X-UA-Compatible" content="IE=9"></meta>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
    <link rel="stylesheet" type="text/css" href="css/style.css" />
</head>

<body>

    <div class="notice">
        <p> 支持 IE &gt;= 9; chrome; firefox; safari; <p>
        <p> 随意选择用户名输入即可登录聊天 </p>
        <p> 选择左侧在线用户即可开始聊天 </p>
        <p> 支持群聊，登录后会自动加入默认群 </p>
    </div>

    <div class="left">
        <div class="onlines">
            <h3>在线用户</h3>
            <div></div>
        </div>

        <div class="groups">
            <h3>聊天群组</h3>
            <div></div>

            <form id="groupadd">
                <input type="text" name="groupname">
                <input type="button" value="创建群组">
            </form>
        </div>
    </div>

    <div class="main">
        <div class="header">
            <div class="logo">
                即时聊天
            </div>
            <div class="user_info"></div>
        </div>
        <div class="list_tab">
            <ul>
                <li typ="user">好友聊天</li>
                <li typ="group">群组聊天</li>
            </ul>
            <div style="clear:both"></div>
        </div>

        <div class="last">
            <div class="user">
                <h3>最近联系人</h3>
                <ul></ul>
            </div>
            <div class="group">
                <h3>最近群组</h3>
                <ul></ul>
            </div>
        </div>

        <div class="chat">
            <div class="messages">
            </div>
            <form class="publish">
                <input></input>
                <button>发送</button>
            </form>
        </div>
    </div>


    <script src="js/jquery.js"></script>

    <script src="js/jquery.cookie.js"></script>
    <script src="js/jquery.json-2.4.js"></script>
    <script src="js/chat.js"></script>

</body>

</html>
