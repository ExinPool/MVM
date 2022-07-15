#!/bin/bash
#
# Copyright © 2019 ExinPool <robin@exin.one>
#
# Distributed under terms of the MIT license.
#
# Desc: Mixin process monitor script.
# User: Robin@ExinPool
# Date: 2022-06-30
# Time: 15:34:02

# load the config library functions
source config.shlib

# load configuration
service="$(config_get SERVICE)"
local_host="$(config_get LOCAL_HOST)"
remote_host_first="$(config_get REMOTE_HOST_FIRST)"
remote_host_second="$(config_get REMOTE_HOST_SECOND)"
abs_num="$(config_get ABS_NUM)"
node_id="$(config_get NODE_ID)"
log_file="$(config_get LOG_FILE)"
lark_webhook_url="$(config_get LARK_WEBHOOK_URL)"

local_blocks_hex=`curl --max-time 10 -X POST ${local_host} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
local_blocks=`echo $((16#${local_blocks_hex}))`
remote_first_blocks_hex=`curl --max-time 10 -X POST ${remote_host_first} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
remote_first_blocks=`echo $((16#${remote_first_blocks_hex}))`
remote_second_blocks_hex=`curl --max-time 10 -X POST ${remote_host_second} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
remote_second_blocks=`echo $((16#${remote_second_blocks_hex}))`
log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO local_blocks: ${local_blocks}, remote_first_blocks: ${remote_first_blocks}, remote_second_blocks: ${remote_second_blocks}"
echo $log >> $log_file

if [[ ${local_blocks} == ?(-)+([[:digit:]]) ]] && [ ${local_blocks} -gt 0 ] && [[ ${remote_first_blocks} == ?(-)+([[:digit:]]) ]] && [ ${remote_first_blocks} -gt 0 ] && [[ ${remote_second_blocks} == ?(-)+([[:digit:]]) ]] && [ ${remote_second_blocks} -gt 0 ]
then
    local_first=$((local_blocks - remote_first_blocks))
    local_second=$((local_blocks - remote_second_blocks))
    if [ ${local_first#-} -gt ${abs_num} ] && [ ${local_second#-} -gt ${abs_num} ]
    then
        log="时间: `date '+%Y-%m-%d %H:%M:%S'` UTC \n主机名: `hostname` \n节点: ${local_host}, ${local_blocks} \n远端节点 1: ${remote_host_first}, ${remote_first_blocks} \n远端节点 2: ${remote_host_second}, ${remote_second_blocks} \n状态: 区块数据不同步。"
        echo -e $log >> $log_file
        curl -X POST -H "Content-Type: application/json" -d '{"msg_type":"text","content":{"text":"'"$log"'"}}' ${lark_webhook_url}
    else
        log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO ${service} ${local_host} status is normal."
        echo $log >> $log_file
    fi
else
    log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO ${service} check point is abnormal."
    echo $log >> $log_file
fi