#!/bin/sh
#check running stat args $1 file $2 diff time second
function checkMonitorRunning(){
	retFlag=0;
	if [ -f $1 ];then
		mt=$(stat -c%Y $1)
		now=$(date +%s)
		diff=$(($now-$mt))
		if [ $diff -le $2 ] ; then
			retFlag=1
		else
			#keep running only one process....
			kill -0 `cat $1` >/dev/null 2>&1
			rm -f $1
		fi
	fi	

	return $retFlag;
}

#checkin tomcat running status return 1 ok else 0
function checkServerRunning(){
	retFlag=0;
	hostname=`hostname`;
	result=`curl -s -m $2 http://$hostname:$1/ok.html`;
	if [[ $result == ok* ]]; then
		retFlag=1;
	fi
	return $retFlag;
}


#send sms to admin
function sendSms(){
	for m in ${MOBILES[@]}
	do
		curl -s "http://smscenter.m.***.com/api?cmd=sms&mobile=$m&msg=`hostname`:$1:autorestarted&pdid=100545" 1 > /dev/null &
	done	
}
#set env
#if [ -z "$JAVA_HOME" ] ; then
#export JAVA_HOME=/opt/j2sdk/
#export PATH=$JAVA_HOME/bin:$PATH
#fi

WEB_DIR=/data/web/zhan
XOA_TOMCAT=/opt/apache-tomcat-6.0.32_site
XOA_MONITOR_FILE=$XOA_TOMCAT/monitor.status
MOBILES=("15801594380")
RETRY=3
TIME_OUT=3
#5 second
STAT_TIME=300

#checkin monitor status if status large than 4s then delete it
#if [ -f $XOA_MONITOR_FILE ];then
#	echo "`date +%Y-%m-%d-%H:%M:%S` $XOA_MONITOR_FILE exists, monitor running...";
#	exit;
#fi
echo "`date +%Y-%m-%d-%H:%M:%S` checkin autorestart status..."
$(checkMonitorRunning $XOA_MONITOR_FILE $STAT_TIME);
if [ $? == 1 ]; then
	echo "`date +%Y-%m-%d-%H:%M:%S` $XOA_MONITOR_FILE exists, monitor running...";
	exit;
fi 

echo "`date +%Y-%m-%d-%H:%M:%S` touch $XOA_MONITOR_FILE pid:$$"
touch $XOA_MONITOR_FILE
echo $$ > $XOA_MONITOR_FILE

port=`awk '/<Connector.*HTTP.*/  {print $0}' $XOA_TOMCAT/conf/server.xml|sed '2d'|awk -F '"' '{print $2}'`
#curl http://`hostname`:$port/ok.html
i=1
while(($i <= $RETRY))
do
	echo "`date +%Y-%m-%d-%H:%M:%S` checkServerRunning default port:$port timeout:$TIME_OUT"
	$(checkServerRunning $port $TIME_OUT);
	if [ $? == 1 ]; then
		echo "`date +%Y-%m-%d-%H:%M:%S` tomcat running ok~"
		#echo "`date +%Y-%m-%d-%H:%M:%S` checkin server online info"
		#info=`sh /data/xoa-tomcat/bin/xoa-admin.sh server list this`
		#if [[ "$info" =~ "Disable" ]]; then 
		#	sh /data/xoa-tomcat/bin/xoa-admin.sh server enable this
		#fi
		echo "`date +%Y-%m-%d-%H:%M:%S` server status: $info"
		rm -f $XOA_MONITOR_FILE
		
		exit;
	else
		echo "`date +%Y-%m-%d-%H:%M:%S` tomcat running not ok~ will retry~ $(($RETRY-$i))";
		i=$(($i+1));
	fi
done
echo "`date +%Y-%m-%d-%H:%M:%S` start reboot tomcat...."
#sh $XOA_TOMCAT/bin/xoa-admin.sh server disable this
#$JAVA_HOME/bin/jstack `cat $XOA_TOMCAT/PID` > /data/stack/`date +%Y%m%d%H%M%S`.jvm.log
#sh  $XOA_TOMCAT/bin/shutdown.sh -force
#rm -f $XOA_TOMCAT/PID
#sleep 10
sh $WEB_DIR/restart_site.sh

#delete monitor status
rm -f $XOA_MONITOR_FILE

sleep 100
i=1
while(($i <= $RETRY))
do
        $(checkServerRunning $port $TIME_OUT);
        if [ $? == 1 ]; then
                echo "`date +%Y-%m-%d-%H:%M:%S` tomcat restart running ok~"
		#sh $XOA_TOMCAT/bin/xoa-admin.sh server enable this
		echo "\n`date +%Y-%m-%d-%H:%M:%S` check & restart over ~"
                exit;
        else
                echo "`date +%Y-%m-%d-%H:%M:%S` tomcat restart running not ok~ will retry~ $(($RETRY-$i))";
                i=$(($i+1));
		sleep 100
        fi
done
#send sms to admin to restart....
echo "`date +%Y-%m-%d-%H:%M:%S` call sendSms to admin..."
$(sendSms $port)
