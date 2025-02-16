<?php
session_start();

// 检查是否通过 POST 方法提交表单
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // 获取表单中的用户名和密码
    $username = $_POST['username'];
    $password = $_POST['password'];

    // 从文件中读取用户信息
    $users_file = '../data/users.txt';
    $users = file($users_file, FILE_IGNORE_NEW_LINES);
    $authenticated = false;

    foreach ($users as $user) {
        list($stored_username, $stored_password) = explode(':', $user);
        if ($stored_username === $username && $stored_password === $password) {
            $authenticated = true;
            break;
        }
    }

    if ($authenticated) {
        // 验证成功，设置会话变量并跳转到首页
        $_SESSION['username'] = $username;
        header('Location: index.html');
        exit;
    } else {
        // 验证失败，重定向到登录页面并携带错误参数
        header('Location: login.html?error=1');
        exit;
    }
} else {
    // 非 POST 请求，重定向到登录页面
    header('Location: login.html');
    exit;
}
?>