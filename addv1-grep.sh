#!/bin/bash
#version 0.2
#TODO: prototype_id found

#bash addv1-grep.sh edit - modify hosts
#bash addv1-grep.sh  - add new hosts
#bash addv1-grep.sh delete - delete hosts #TODO: first delete cluster,then - hosts
#bash addv1-grep.sh checker - install checker# Now:1) run install cluster2) install checker


serviceadd=""
clustername="ADB" #завести заранее  Lovely Amur
adcmip="10.6.16.120"  # завести заранее 8000 port
edit=$1
if [[ -z $adcmip ]]; then
    echo "Correct variable hostname"
    exit 0
fi
if [[ -z $clustername ]]; then
    tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
    token=$(echo $tokens|awk -F"\"" '{print $4}')
    #echo $token    
    clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/ `
    echo "Cluster name:  [list]"
    #echo $clusters|jq -r '.[].name'
    echo $clusters|grep -Po 'name":"\K[^",]*'
    echo "[!Error] Correct variable clustername in me..."
    exit 0
fi

serviceadd=""
token=""
provid=""
clusters=""
prototype_id=""
idcluster=""

while IFS="," read -r t1 t2 t3 t4 t5
do
if [[ "$serviceadd" == "yes" ]];then
    #echo "[!] Add service "$t1 $t2 $t3 $t4 $t5
    servicename=`echo "$t1 $t2 $t3 $t4 $t5"|sed -r 's/[\ ]{1,5}$//g'`
    #echo $servicename"."

    serviceprototypes=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/$idcluster/serviceprototype/`
    serviceprototypelist=`echo $serviceprototypes |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,/\n/g'| awk -F',' '{print $1":"$10}'|awk -F':' '{print $2":"$4":\n"}'|tr -d "\""`
    serviceprototype=`echo $serviceprototypes |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,/\n/g'| awk -F',' '{print $1":"$10}'|awk -F':' '{print $2":"$4":"}'|tr -d "\""|awk -F":" '{print $1}'`
    for i in $serviceprototype; do
	#echo $i
	#echo $servicename
	#echo $serviceprototypelist
	namesrv=`echo $serviceprototypes |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,/\n/g'| awk -F',' '{print $1":"$10}'|grep $i|awk -F':' '{print $4}'|tr -d "\""`
	#namesrv=`echo $serviceprototypelist|grep $i|awk -F':' '{print $2}'`
	#echo "namesrv="$namesrv
	if [[ "$servicename" == "$namesrv" ]];then
	    srvs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"cluster_id":"'$idcluster'","prototype_id":'$i'}' http://$adcmip:8000/api/v1/service/`
	    #echo $srvs
	    echo "[%] Service \""$namesrv"\" add"
	fi
    done
fi

if [[ "$t1" == "#SRV" ]];then
    #echo "[!] Add service."
    serviceadd="yes"
fi

if [[ -z "$serviceadd" ]];then
echo "[*] Get $t1 $t2 $t3 $t4 $t5"
ansible_user=$t1 
ansible_pass=$t2
hostname=$t3 #имя в adcm hostname
ansible_host=$t4   # ip 
ansible_port=$t5
#jsonadd="{\"description\":\"init\",\"config\":{\"ansible_user\":\"$ansible_user\",\"ansible_ssh_pass\":\"$ansible_pass\",\"ansible_host\":\"$ansible_host\",\"ansible_ssh_port\":\"$ansible_port\",\"ansible_become\":\"$ansible_become\",\"ansible_become_pass\":\"$ansible_pass\" }, \"attr\": {}}"

#echo $jsonadd|jq
tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
token=$(echo $tokens|awk -F"\"" '{print $4}')
#echo $token
clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/`
#echo "Cluster name: "$clusters

idcluster=`echo $clusters|grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$3}'|tr -d '"'|awk -F ':' '{print $2" "$4}'|grep " $clustername$"|awk '{print $1}'`

provids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/provider/`
provid=`echo $provids|grep -Po '"id":\K[^,]*' `

echo "[+] Cluster id: "$idcluster
prototype_ids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/provider/`
prototype_id=`echo $prototype_ids |grep -Po '"prototype_id":\K[^",]*'|head -1`
prototype_id=$((prototype_id+1))

echo "[+] Prototype_id: "$prototype_id
echo "[+] Provider: "$provid

if [[ "$edit" == "checker" ]];then
    listhost=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
    nodecount=`echo $listhost |grep -Po '"id":\K[^",]*'`
    for i in $nodecount; do
        listactions=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token'' http://$adcmip:8000/api/v1/host/$i/action/`
	checkerid=`echo $listactions|grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$3}'|grep "statuschecker"|tr -d '"'|awk -F ':' '{print $2" "$4}'|awk '{print $1}'`
	echo $checkerid
	editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' http://$adcmip:8000/api/v1/host/$i/action/$checkerid/run/`
	#echo $editconfigs
	echo "[%] Checker install on host id "$i
    done
    exit
fi


if [[ "$edit" == "delete" ]];then
    listhost=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
    nodecount=`echo $listhost |grep -Po '"id":\K[^",]*'`
    for i in $nodecount; do
        editconfigs=`curl -s -X DELETE -H 'Content-type: application/json' -H 'Authorization: token '$token'' http://$adcmip:8000/api/v1/host/$i/`
	echo "[%] Delete host id "$i
    done
    exit
fi

if [[ "$edit" == "" ]]; then
    echo "[_]   Add new node."
    #add
    #newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"prototype_id":'$prototype_id', "provider_id": "'$provid'", "cluster_id":"'$idcluster'", "fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`
    newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"cluster_id":"'$idcluster'","prototype_id":'$prototype_id',  "provider_id": "'$provid'","fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`
    
    echo $newhost
    #idnewhost=`echo $newhost | jq  ' .id'`
    idnewhost=`echo $newhost |grep -Po '"id":\K[^,]*' `

    echo "[+] New host id: "$idnewhost
    add=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"host_id":"'$idnewhost'"}'  http://$adcmip:8000/api/v1/cluster/$idcluster/host/`
    echo "[+] Host add to cluster."
fi

#editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '$jsonadd' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
if [[  "$edit" == "" ]]; then
    echo "[+] Add password"
    #editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_ssh_private_key_file":"null","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_ssh_common_args":"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null", "ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
    editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_ssh_private_key_file":"NULL","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_ssh_common_args":"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null", "ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
    #echo $editconfigs
elif [[ "$edit" == "edit" ]]; then
    listhost=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
    nodecount=`echo $listhost |grep -Po '"id":\K[^",]*'`
    for i in $nodecount; do
	host_names=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/$i/`
	host_name=`echo $host_names |grep -Po '"fqdn":"\K[^",]*'`
	if [[ "$hostname" == "$host_name" ]];then
	    #editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$i/config/history/`
	    editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_ssh_private_key_file":"NULL","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_ssh_common_args":"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null", "ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$i/config/history/`
	    echo "[%] Edit host id "$i " and name "$host_name
	fi
    done
fi
fi
done < <(cat hosts.csv)