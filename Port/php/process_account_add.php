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
    $service_type = $_POST['service_type'];
    $username = $_POST['username'];
    $password = $_POST['password'];

    // 假设账户信息存储在这个文件中
    $accounts_file = '../data/accounts.txt';

    // 简单的输入验证
    if (empty($service_type) || empty($username) || empty($password)) {
        $error = '请填写所有必填字段。';
    } else {
        // 打开文件以追加模式写入
        $file = fopen($accounts_file, 'a');
        if ($file) {
            // 构建要写入的账户信息
            $account_info = "$service_type:$username:$password\n";
            // 写入账户信息
            if (fwrite($file, $account_info) !== false) {
                $success = '账户添加成功！';
            } else {
                $error = '账户添加失败，请检查文件权限。';
            }
            fclose($file);
        } else {
            $error = '无法打开账户文件，请检查文件权限。';
        }
    }
}

// 将消息存储在会话中
if ($error) {
    $_SESSION['account_add_error'] = $error;
}
if ($success) {
    $_SESSION['account_add_success'] = $success;
}

// 重定向回账户管理页面
header('Location: account_management.html');
exit;