#!/bin/bash

out=""
in=0
while read -r line
do
   start=$(echo "$line"|grep -c "^HOST")
   if [[ "$start" == "1" ]];then
    if [[ "$in" == "1" ]];then
	in=0
	othsrv=""
	srvid=""
    fi
    namenode=`echo $line|grep "^HOST"|awk -F ':' '{print $2}'` #hostname
    hostid=`echo $line|grep "^HOST"|awk -F ':' '{print $3}'`
    #echo $namenode
    #srv=`echo $line|awk -F '- ' '{print $2","}'` #fisrt service
   else
    in=1
    srv=`echo "$line"|awk -F '- ' '{print $2}'|tr -d ','`
    srvid=`cat prejson|grep "SRV"|grep -i "$srv"|awk -F ':' '{print $3}'`
    if [[ ! -z "$srvid" ]];then
    othsrv=`cat prejson|grep "SRV:$srv" -A1|tail -1|awk -F '; ' '{print $3}'|awk -F ':' '{print $1}'`
    if [[ ! -z "$othsrv" ]];then
    echo $hostid":"$srvid":"$othsrv
    else
    othsrv=`cat prejson|grep "SRV:$srv" -A1|tail -1|awk -F ":" '{print $1}'`
    echo $hostid":"$srvid":"$othsrv
    fi
    fi
   fi
done < prejson


str=`cat postjson`
file="out"
rm -rf $file
line=$(echo -n $str|tr ' ' '\n'|grep -c '^')
l=0
echo "{\"hc\": ">>$file
echo "[" >>$file
echo "{" >>$file
for i in $(echo $str);do
l=$((l=l+1))
a1=$(echo $i|awk -F':' '{print $1}')
a2=$(echo $i|awk -F':' '{print $2}')
a3=$(echo $i|awk -F':' '{print $3}')
count=$(echo $a3|tr ',' ' '|wc -w)
c=1
for j in $(echo $a3|tr ',' ' ');do
 echo \"host_id\"":"$a1"," >>$file
 echo \"service_id\"":"$a2"," >>$file
 echo \"component_id\"":"$j >>$file
 c=$((c=c+1))
# echo $c" "$count
# echo $l" " $line
# if [[ "$c" -ge "$count" ]] ;then
#   echo "},{"
# elif  [[ "$l" -eq "$line" ]] && [[ "$c" -gt "$count" ]];then
#   echo "}"
#fi
 if [[ "$l" -ne "$line" ]] ;then
   echo "},{" >>$file
fi
done

done
echo  "}" >>$file
echo "]" >>$file
echo  "}" >>$file