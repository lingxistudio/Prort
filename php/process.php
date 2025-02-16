<?php
session_start();

// 检查用户是否已登录
if (!isset($_SESSION['username'])) {
    header('Location: login.html');
    exit;
}

// 检查是否通过 POST 方法提交表单
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // 获取表单中的端口号
    $socks_port = $_POST['socks_port'];
    $http_port = $_POST['http_port'];
    $mtproto_port = $_POST['mtproto_port'];
    $pptp_port = $_POST['pptp_port'];
    $l2tp_port = $_POST['l2tp_port'];
    $reverse_proxy_port = $_POST['reverse_proxy_port'];

    // 构建命令来执行 proxy_scripts.sh 脚本
    $script_path = $_SERVER['DOCUMENT_ROOT'] . '/scripts/proxy_scripts.sh';
    $command = "sudo $script_path dummy1 dummy2 $socks_port $http_port $mtproto_port $pptp_port $l2tp_port $reverse_proxy_port";

    // 执行命令并获取输出
    exec($command, $output, $return_var);

    if ($return_var === 0) {
        // 脚本执行成功
        $message = "代理服务部署成功！";
    } else {
        // 脚本执行失败
        $message = "代理服务部署失败，请检查脚本或权限。";
        // 记录错误输出，可用于调试
        error_log("Error in proxy_scripts.sh: " . implode("\n", $output));
    }
} else {
    $message = "无效的请求方法，请使用 POST 方法提交表单。";
}

// 将消息存储在会话中，以便在 index.html 中显示
$_SESSION['deploy_message'] = $message;
header('Location: index.html');
exit;
?>