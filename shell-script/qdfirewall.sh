#!/bin/bash

info(){
  echo "usage: $0 [reset|simple|open|list]"
}

reset_firewall(){
  iptables --flush
}

open_port(){
  iptables -A INPUT -p tcp --dport $1 -j ACCEPT
}

list_firewall(){
  iptables -S
}

simple_firewall(){
  iptables -F
  iptables -X
  iptables -Z

  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT

  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -p icmp --icmp-type 3 -j ACCEPT
  iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT       #ping
  iptables -A INPUT -p icmp --icmp-type 11 -j ACCEPT
  iptables -A INPUT -p icmp --icmp-type 12 -j ACCEPT
  iptables -A INPUT -p tcp --syn --dport 113 -j REJECT --reject-with tcp-reset

  ip6tables -F
  ip6tables -X
  ip6tables -Z

  ip6tables -P INPUT DROP
  ip6tables -P FORWARD DROP
  ip6tables -P OUTPUT ACCEPT

  ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  ip6tables -A INPUT -i lo -j ACCEPT
  ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP
  ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
  ip6tables -A INPUT -p udp -m conntrack --ctstate NEW -j REJECT --reject-with icmp6-port-unreachable
  ip6tables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m conntrack --ctstate NEW -j REJECT --reject-with tcp>
}

case $1 in
  "reset") reset_firewall;;
  "simple") simple_firewall;;
  "open") open_port $2 ;;
  "list") list_firewall;;
  *) info;;
esac
