#!/bin/bash
#
# Copyright © 2019 ExinPool <robin@exin.one>
#
# Distributed under terms of the MIT license.
#
# Desc: MVMScan process monitor script.
# User: Robin@ExinPool
# Date: 2021-11-28
# Time: 20:43:09

# load the config library functions
source config.shlib

# load configuration
service="$(config_get SERVICE)"
process="$(config_get PROCESS)"
process_num="$(config_get PROCESS_NUM)"
host="$(config_get HOST)"
process_num_var=`sudo netstat -langput | grep LISTEN | grep $process | wc -l`
log_file="$(config_get LOG_FILE)"
webhook_url="$(config_get WEBHOOK_URL)"
access_token="$(config_get ACCESS_TOKEN)"

if [ ${process_num} -eq ${process_num_var} ]
then
    log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO ${service} process is normal."
    echo $log >> $log_file
else
    log="时间: `date '+%Y-%m-%d %H:%M:%S'` UTC \n主机名: `hostname` \n节点: $host \n状态: 进程不存在，已重启节点。"
    echo -e $log >> $log_file
    success=`curl ${webhook_url}=${access_token} -XPOST -H 'Content-Type: application/json' -d '{"category":"PLAIN_TEXT","data":"'"$log"'"}' | awk -F',' '{print $1}' | awk -F':' '{print $2}'`
    if [ "$success" = "true" ]
    then
        log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO send mixin successfully."
        echo $log >> $log_file
    else
        log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO send mixin failed."
        echo $log >> $log_file
    fi
    cd /data/blockscout/blockscout && nohup bash start.sh &
fi
