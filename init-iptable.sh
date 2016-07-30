#!/bin/sh

# Empty current rules
iptables -t filter -F

# Empty custom rules
iptables -t filter -X

# Forbidden all I/O connection
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -P OUTPUT DROP

# ---
# Don't break etablished connection
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow loopback
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT

# ICMP (Ping)
iptables -t filter -A INPUT -p icmp -j ACCEPT
iptables -t filter -A OUTPUT -p icmp -j ACCEPT

# ---
# SSH In
iptables -t filter -A INPUT -p tcp --dport 10022 -j ACCEPT

# SSH Out
iptables -t filter -A OUTPUT -p tcp --dport 10022 -j ACCEPT

# DNS In/Out
iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT

# NTP Out
iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT

# HTTP + HTTPS Out
iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT

# HTTP + HTTPS In
iptables -t filter -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 8443 -j ACCEPT

# FTP Out
iptables -t filter -A OUTPUT -p tcp --dport 20:21 -j ACCEPT

# FTP In
#modprobe ip_conntrack_ftp # ligne facultative avec les serveurs OVH
iptables -t filter -A INPUT -p tcp --dport 20:21 -j ACCEPT
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Mail SMTP:25
iptables -t filter -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 25 -j ACCEPT

# Mail IMAP:143
iptables -t filter -A INPUT -p tcp --dport 465 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 465 -j ACCEPT

# Mail POP3S:995
iptables -t filter -A INPUT -p tcp --dport 993 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 993 -j ACCEPT

# Avoid overload by requesting server
iptables -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT

# Same avoid overload for UDP and ICMP
iptables -A FORWARD -p udp -m limit --limit 1/second -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT

# Avoid scanning port (or use portsentry ;)
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT

# TeamSpeak settings
# Teamspeak Licence
iptables -t filter -A INPUT -p tcp --dport 2008 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 2008 -j ACCEPT

# Teamspeak Voix par défaut
iptables -t filter -A INPUT -p udp --dport 9987 -j ACCEPT 
iptables -t filter -A OUTPUT -p udp --dport 9987 -j ACCEPT 

# Teamspeak ServerQuery
iptables -t filter -A INPUT -p tcp --dport 10011 -j ACCEPT 
iptables -t filter -A OUTPUT -p tcp --dport 10011 -j ACCEPT 

# Teamspeak File Transfer
iptables -t filter -A INPUT -p tcp --dport 30033 -j ACCEPT 
iptables -t filter -A OUTPUT -p tcp --dport 30033 -j ACCEPT

# OpenVPN
iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o venet0 -j MASQUERADE
# allow tcp connection on openvpn port
iptables -A INPUT -i venet0 -m state --state NEW -p udp --dport 1194 -j ACCEPT
# allow tun interface for openvpn
iptables -A INPUT -i tun+ -j ACCEPT
# Allow tun connection to be forwarded through other interface
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -o venet0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i venet0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT
# If your default iptables OUTPUT value is not ACCEPT, you will also need a line like
# iptables -A OUTPUT -o tun+ -j ACCEPT
