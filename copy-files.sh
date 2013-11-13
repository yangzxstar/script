#!/bin/sh


###### 更新线上jsxp

#####author yangzxstar@gmail.com
now=$(date +"%Y%m%d%H%m%s")

echo $now
#local_dir="/data/web/zhan/www_base/backup/views"
local_dir="/data/web/zhan/www_base/views"
remote_dir="/data/web/zhan/www_site/views"

web_host_path="/data/web/zhan/web_hosts.txt"

for host in `cat $web_host_path |grep -v "#"|uniq`
do
        echo "copy views to $host";
        `ssh $host "rm -rf $remote_dir"`
        scp -r $local_dir $host:$remote_dir
done
