<?php
session_start();

// 检查用户是否已登录
if (!isset($_SESSION['username'])) {
    header('Location: login.html');
    exit;
}

$error = '';
$success = '';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $old_password = $_POST['old_password'];
    $new_password = $_POST['new_password'];
    $confirm_password = $_POST['confirm_password'];

    // 从文件中读取用户信息
    $users_file = '../data/users.txt';
    $users = file($users_file, FILE_IGNORE_NEW_LINES);
    $found = false;

    foreach ($users as $key => $user) {
        list($username, $password) = explode(':', $user);
        if ($username === $_SESSION['username'] && $password === $old_password) {
            $found = true;
            if ($new_password === $confirm_password) {
                // 更新用户密码
                $users[$key] = $username . ':' . $new_password;
                file_put_contents($users_file, implode("\n", $users));
                $success = '密码修改成功！';
            } else {
                $error = '新密码和确认密码不匹配，请重试。';
            }
            break;
        }
    }

    if (!$found) {
        $error = '旧密码输入错误，请重试。';
    }
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>修改密码 - 代理服务管理系统</title>
    <link rel="stylesheet" href="/static/lightyear/lightyear.css">
    <style>
        body {
            padding: 20px;
        }

        .ly-card {
            max-width: 400px;
            margin: 0 auto;
        }

        .error-message {
            color: red;
            text-align: center;
            margin-top: 10px;
        }

        .success-message {
            color: green;
            text-align: center;
            margin-top: 10px;
        }
    </style>
</head>

<body>
    <!-- 导航栏 -->
    <nav class="ly-navbar">
        <a href="#" class="ly-logo">代理服务管理系统</a>
        <ul class="ly-nav-links">
            <li><a href="index.html">首页</a></li>
            <li><a href="#">修改密码</a></li>
            <li><a href="logout.php">退出登录</a></li>
        </ul>
    </nav>

    <!-- 卡片展示修改密码表单 -->
    <div class="ly-card">
        <div class="ly-card-header">修改密码</div>
        <div class="ly-card-body">
            <?php if ($error): ?>
                <p class="error-message"><?php echo $error; ?></p>
            <?php endif; ?>
            <?php if ($success): ?>
                <p class="success-message"><?php echo $success; ?></p>
            <?php endif; ?>
            <form id="change-password-form" action="change_password.php" method="post">
                <div class="form-group">
                    <label for="old_password">旧密码</label>
                    <input type="password" class="ly-input" id="old_password" name="old_password" required>
                </div>
                <div class="form-group">
                    <label for="new_password">新密码</label>
                    <input type="password" class="ly-input" id="new_password" name="new_password" required>
                </div>
                <div class="form-group">
                    <label for="confirm_password">确认新密码</label>
                    <input type="password" class="ly-input" id="confirm_password" name="confirm_password" required>
                </div>
                <button type="submit" class="ly-btn ly-btn-primary">修改密码</button>
            </form>
        </div>
    </div>

    <script src="/static/lightyear/lightyear.js"></script>
</body>

</html>