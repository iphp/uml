#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6                                    #
#   Description: One click Install UML for bbr+ssr                #
#   Author: 91yun <https://twitter.com/91yun>                     #
#   Thanks: @allient                                              #
#   Intro:  https://www.91yun.org                                 #
#=================================================================#




yum install -y tunctl uml-utilities screen


wget http://soft.91yun.org/uml/91yun/uml-ssr-64.tar.gz
tar zfvx uml-ssr-64.tar.gz
cd uml-ssr-64
cur_dir=`pwd`
cat > run.sh<<-EOF
#!/bin/sh
export HOME=/root
tunctl -t tap1
ifconfig tap1 10.0.0.1
ifconfig tap1 up
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -P FORWARD ACCEPT 
iptables -t nat -A POSTROUTING -o venet0 -j MASQUERADE
iptables -I FORWARD -i tap1 -j ACCEPT
iptables -I FORWARD -o tap1 -j ACCEPT
iptables -t nat -A PREROUTING -i venet0 -p tcp --dport 9191 -j DNAT --to-destination 10.0.0.2
iptables -t nat -A PREROUTING -i venet0 -p udp --dport 9191 -j DNAT --to-destination 10.0.0.2
screen -dmS uml ${cur_dir}/vmlinux ubda=${cur_dir}/alpine-x64 eth0=tuntap,tap1 mem=64m
sleep 1
ps aux | grep "vmlinux"
if [ $? -eq 0 ]; then
	echo "all things done!"
	echo "you can use command to login uml:"
	echo "/etc/init.d/uml status"
	echo "user:root password:root"
else
	echo "some things error"
fi	

EOF
chmod +x run.sh



# Add run on system start up
cat > /etc/init.d/uml<<-EOF
start(){
	bash ${cur_dir}/run.sh
}

stop(){
    kill \$( ps aux | grep vmlinux )
	ifconfig tap1 down
}

status(){
pid=\$(screen -list | grep pts | awk '{print \$1}')
if [ "\$pid" == "" ]; then
	screen /dev/pts/1
else
	screen -r \$(screen -list | grep pts | awk 'NR==1{print \$1}')
fi	
}

case "\$1" in
'start')
    start
    ;;
'stop')
    stop
    ;;
'status')
    status
    ;;
'restart')
    stop
    start
    ;;
*)
    echo "Usage: \$0 { start | stop | restart | status }"
    ;;
esac
exit
EOF


chmod +x /etc/init.d/uml
chkconfig --add uml
chkconfig uml on

/etc/init.d/uml start
