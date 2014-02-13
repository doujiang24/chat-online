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

    <div class="onlines">
        <h3>在线用户</h3>
        <div></div>
    </div>

    <div class="main">
        <div class="header">
            <div class="logo">
                即时聊天
            </div>
            <div class="user"></div>
        </div>

        <div class="users">
            <h3>最近联系人</h3>
            <ul></ul>
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
