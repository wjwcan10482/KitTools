#!/bin/bash
if [ `rpm -qa | grep fio | wc -l` == 0 ]; then yum install fio -y ; else echo fio is installed ;fi
fiotime=30 
fiodisk="/dev/sdb"
fioconfs="""
[global]
ioengine=libaio
iodepth=128
time_based
direct=1
thread=1
group_reporting
randrepeat=0
norandommap
#numjobs=32
timeout=6000
runtime=$fiotime
[randread-4k]
rw=randread
bs=4k
filename=$fiodisk
rwmixread=100
stonewall
[randwrite-4k]
rw=randwrite
bs=4k
filename=$fiodisk
stonewall
[read-512k]
rw=read
bs=512k
filename=$fiodisk
stonewall
[write-512k]
rw=write
bs=512k
filename=$fiodisk
stonewall
"""
#1.自定义fio配置文件
echo "$fioconfs" > fio_temp.conf
fio fio_temp.conf > fio_temp_result
iops4kr=`cat fio_temp_result | grep "runt=" | awk -F ', ' '{if(NR==1)print $3}'| awk -F '=' '{print $2}'`
iops4kw=`cat fio_temp_result | grep "runt=" | awk -F ', ' '{if(NR==2)print $3}'| awk -F '=' '{print $2}'`
bw512kr=`cat fio_temp_result | grep "runt=" | awk -F ', ' '{if(NR==3)print $2}'| awk -F '=' '{print $2}'`
bw512kw=`cat fio_temp_result | grep "runt=" | awk -F ', ' '{if(NR==4)print $2}'| awk -F '=' '{print $2}'`
echo -e "测试时间:$fiotime \n测试磁盘: $fiodisk \n4k随机读取:$iops4kr\n4k随机写入:$iops4kw\n512k顺序读取:$bw512kr\n51k顺序写入:$bw512kw"
