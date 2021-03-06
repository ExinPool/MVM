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
lark_webhook_url="$(config_get LARK_WEBHOOK_URL)"

if [ ${process_num} -eq ${process_num_var} ]
then
    log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO ${service} process is normal."
    echo $log >> $log_file
else
    log="时间: `date '+%Y-%m-%d %H:%M:%S'` UTC \n主机名: `hostname` \n节点: $host \n状态: 进程不存在，请尽快检查。"
    echo -e $log >> $log_file
    curl -X POST -H "Content-Type: application/json" -d '{"msg_type":"text","content":{"text":"'"$log"'"}}' ${lark_webhook_url}
fi
