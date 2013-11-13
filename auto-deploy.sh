#!/bin/bash
. ./conf/vars.sh

for BACKEND in `cat ${BACKENDHOSTS} |grep -v "#"|sort|uniq`
do
        echo "-->[`date`][${BACKEND}]deploying......"   
        #[1]挂起机器    
        echo "-->[`date`][${BACKEND}]hang up"
        sh hang-up.sh ${BACKEND} 'y'

        #[2]检查connection
        echo "-->[`date`][${BACKEND}]check connections"
        while true
        do
                CONS=`ssh web@${BACKEND} "netstat -a | grep 'ESTABLISHED' | wc -l"`

                #已经没有连接了 
                if [ ${CONS} -lt 1695 ] 
                then
                        break;
                fi

                echo "connections of ${BACKEND}: ${CONS} waiting ...."
                sleep 5;
        done

        #[3]更新代码
        echo "-->[`date`][${BACKEND}]deploy service"
        sh deploy-service.sh ${BACKEND}
        
        sleep 5;

        #[4]等待tomcat启动完毕
        echo "-->[`date`][${BACKEND}]waiting tomcat to start"
        while true
        do
                CODE="`curl -o /dev/null -s -w %{http_code}:%{time_connect}:%{time_starttransfer}:%{time_total} -m ${TIMEOUT} http://${BACKEND}:8061/ok.html`"
                TCODE="`echo ${CODE} | gawk -F: '{ print $1}'| egrep -i '2|3[0-9]+'`"
                #echo ${TCODE}  
                if [ -z "${TCODE}" ]; then        
                        TCODE="`echo ${CODE} | gawk -F: '{ print $1}'`"
                        echo "-->[`date`][${BACKEND}]Http Response Code[${TCODE}],[http_code:time_connect:time_starttransfer:time_total]=[${CODE}] waiting...."
                        sleep 5;
                else
                        break;
                fi
        
        done
        echo "-->[`date`][${BACKEND}]tomcat started"
        #[5]请求一下首页
        echo "wget home explore"
        wget http://${BACKEND}:8061/home
        wget http://${BACKEND}:8061/explore
        echo "-->[`date`]hang back"
        sh hang-back.sh 'y'
        #执行一次，用于test
        #break;
done


echo "-->[`date`]hang back"
sh hang-back.sh 'y'
echo "-->[`date`]deploy over"
