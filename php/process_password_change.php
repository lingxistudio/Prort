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
        list($username, $stored_password) = explode(':', $user);
        if ($username === $_SESSION['username'] && $stored_password === $old_password) {
            $found = true;
            if ($new_password === $confirm_password) {
                // 更新用户密码
                $users[$key] = $username . ':' . $new_password;
                if (file_put_contents($users_file, implode("\n", $users)) !== false) {
                    $success = '密码修改成功！';
                } else {
                    $error = '密码修改失败，请检查文件权限。';
                }
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

// 将消息存储在会话中
if ($error) {
    $_SESSION['password_change_error'] = $error;
}
if ($success) {
    $_SESSION['password_change_success'] = $success;
}

// 重定向回修改密码页面
header('Location: change_password.php');
exit;
?>