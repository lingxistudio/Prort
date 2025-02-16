document.addEventListener('DOMContentLoaded', function () {
    // 按钮点击缩放效果
    const buttons = document.querySelectorAll('.ly-btn');
    buttons.forEach(function (button) {
        button.addEventListener('mousedown', function () {
            this.style.transform = 'scale(0.98)';
        });
        button.addEventListener('mouseup', function () {
            this.style.transform = 'scale(1)';
        });
    });

    // 模态框交互
    const openModalBtns = document.querySelectorAll('.ly-open-modal');
    openModalBtns.forEach(function (btn) {
        const modalId = btn.getAttribute('data-modal');
        const modal = document.getElementById(modalId);
        const closeBtn = modal.querySelector('.ly-modal-close');

        btn.addEventListener('click', function () {
            modal.style.display = 'block';
        });

        closeBtn.addEventListener('click', function () {
            modal.style.display = 'none';
        });

        window.addEventListener('click', function (e) {
            if (e.target === modal) {
                modal.style.display = 'none';
            }
        });
    });

    // 表单验证示例（修改密码表单）
    const changePasswordForm = document.getElementById('change-password-form');
    if (changePasswordForm) {
        changePasswordForm.addEventListener('submit', function (e) {
            const oldPassword = document.getElementById('old_password').value;
            const newPassword = document.getElementById('new_password').value;
            if (newPassword.length < 6) {
                alert('新密码长度不能少于 6 位');
                e.preventDefault();
            }
        });
    }

    // 部署表单验证
    const deployForm = document.getElementById('deploy-form');
    if (deployForm) {
        deployForm.addEventListener('submit', function (e) {
            const ports = ['socks_port', 'http_port', 'mtproto_port', 'pptp_port', 'l2tp_port', 'reverse_proxy_port'];
            let hasError = false;
            ports.forEach(function (portId) {
                const portInput = document.getElementById(portId);
                const portValue = parseInt(portInput.value);
                if (isNaN(portValue) || portValue < 1 || portValue > 65535) {
                    alert(`请输入有效的 ${portId.replace('_port', '')} 端口号（1 - 65535）`);
                    hasError = true;
                    e.preventDefault();
                }
            });
        });
    }

    // 更新系统信息（模拟）
    function updateInfo() {
        const loadingElement = document.createElement('p');
        loadingElement.textContent = '正在加载信息...';
        const infoDiv = document.getElementById('current_info');
        infoDiv.appendChild(loadingElement);

        fetch('/get_info')
           .then(response => {
                if (!response.ok) {
                    throw new Error('网络请求失败');
                }
                return response.json();
            })
           .then(data => {
                infoDiv.removeChild(loadingElement);
                document.getElementById('socks_info').textContent = `SOCKS5 端口：${data.socks_port}，连接状态：${data.socks_status}`;
                document.getElementById('http_info').textContent = `HTTP 端口：${data.http_port}，连接状态：${data.http_status}`;
                document.getElementById('mtproto_info').textContent = `MTProto 端口：${data.mtproto_port}，连接状态：${data.mtproto_status}`;
                document.getElementById('pptp_info').textContent = `PPTP 端口：${data.pptp_port}，连接状态：${data.pptp_status}`;
                document.getElementById('l2tp_info').textContent = `L2TP 端口：${data.l2tp_port}，连接状态：${data.l2tp_status}`;
                document.getElementById('reverse_proxy_info').textContent = `反代端口：${data.reverse_proxy_port}，连接状态：${data.reverse_proxy_status}`;
                document.getElementById('cpu_info').textContent = `CPU 占用率：${data.cpu_usage}%`;
                document.getElementById('memory_info').textContent = `内存占用率：${data.memory_usage}%`;
            })
           .catch(error => {
                infoDiv.removeChild(loadingElement);
                infoDiv.innerHTML = `<p style="color: red;">加载信息失败：${error.message}</p>`;
            });
    }

    // 页面加载完成后立即更新信息
    if (document.getElementById('current_info')) {
        updateInfo();
        // 每隔一段时间（例如 5 分钟）自动更新信息
        setInterval(updateInfo, 5 * 60 * 1000);
    }
});