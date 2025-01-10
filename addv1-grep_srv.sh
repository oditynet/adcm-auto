#!/bin/bash
#edit 332 line for add host to cluster!?

#bash addv1-grep.sh edit - modify hosts
#bash addv1-grep.sh  - add new hosts
#bash addv1-grep.sh delete - delete hosts #TODO: first delete cluster,then - hosts
#bash addv1-grep.sh checker - install checker# Now:1) run install cluster2) install checker
#bash addv1-grep.sh components - components distribufions on nodes# Now :1) bash addv1-grep.sh 2) bash prepare_service.sh 3) bash addv1-grep.sh components (!!! Now only Pxf,Chrony)
#For ADH services are supporting:

##SRV
#HDFS
#YARN
#Zookeeper
#HBase
#Hive
#Monitoring

#For ADB service are supporting:

##SRV
#ADB
#Monitoring Clients
#PXF
#Chrony

rm -rf prejson
rm -rf postjson

if [ ! -f "hosts.csv" ]
then
    echo "Error ($0) - File hosts.csv not found."
    exit 1
fi

serviceadd="" #NULL!!!
clustername="adb" #завести заранее  Lovely Amur
adcmip="127.0.0.1"  # завести заранее 8000 port

edit=$1
if [[ -z $adcmip ]]; then
    echo "Correct variable hostname"
    exit 0
fi
if [[ -z $clustername ]]; then
    tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
    token=$(echo $tokens|awk -F"\"" '{print $4}')
    clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/ `
    echo "Cluster name:  [list]"
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
    serviceprototypelist=`echo $serviceprototypes |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,/\n/g'| awk -F',' '{print $1":"$10}'|awk -F':' '{print $2":"$4":"}'|tr -d "\""`
    serviceprototype=`echo $serviceprototypes |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,/\n/g'| awk -F',' '{print $1":"$10}'|awk -F':' '{print $2":"$4":"}'|tr -d "\""|awk -F":" '{print $1}'`
    for i in $serviceprototype; do
	namesrv=`echo $serviceprototypes |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,/\n/g'| awk -F',' '{print $1":"$10}'|grep $i|awk -F':' '{print $4}'|tr -d "\""`
	if [[ "$servicename" == "$namesrv" ]];then
	    srvs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"cluster_id":"'$idcluster'","prototype_id":'$i'}' http://$adcmip:8000/api/v1/service/`
	    srv_id=`echo $srvs |grep -Po '"id":\K[^",]*'|head -1`
	    #echo $srvs
	    echo "[%] Service \""$namesrv"\" add $srv_id Id "$i
	    #echo "SRV:"$servicename":"$srv_id >> prejson
	    #get component from service
	    servicecomponents=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/service/$srv_id/component/`
            #servicecomponent=`echo $servicecomponents |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$5}'|awk -F':' '{print $2":"$4":;"}'|tr -d "\""`
            #servicecomponent=`echo -e $servicecomponents |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$5}'|awk -F':' '{print $2":"$4":;"}'`
	    #echo $servicecomponents
	    servicecomponentid=`echo -e $servicecomponents |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$5}'|awk -F':' '{print $2}'`
	    servicecomponentname=`echo -e $servicecomponents |grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$5}'|awk -F':' '{print $4}'`
	    echo "Srv component id:"$servicecomponentid
	    if [[ "$namesrv"  == "Chrony" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #ntp master
	     ch2=`echo $servicecomponentid|awk '{print $2}'` #ntp secondary
	     ch3=`echo $servicecomponentid|awk '{print $3}'` #ntp slave
	    fi
	    if [[ "$namesrv"  == "HDFS" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #HDFS datanode #worker
	     ch2=`echo $servicecomponentid|awk '{print $2}'` #HDFS namenode #1,2 active/standby
	     ch3=`echo $servicecomponentid|awk '{print $3}'` #HDFS journalnode #1-3
	     ch4=`echo $servicecomponentid|awk '{print $4}'` #HDFS zkfc #1,3
	     ch5=`echo $servicecomponentid|awk '{print $5}'` #HDFS httpsfs server# (?) not install!
	     ch6=`echo $servicecomponentid|awk '{print $6}'` #HDFS client #all node
	    fi
	    if [[ "$namesrv"  == "HBase" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #Hbase client #All
	     ch2=`echo $servicecomponentid|awk '{print $2}'` #Hbase master server #1,2 
	     ch3=`echo $servicecomponentid|awk '{print $3}'` #Hbase region server # worker
	     ch4=`echo $servicecomponentid|awk '{print $4}'` #Hbase phoenix query server #2
	     ch5=`echo $servicecomponentid|awk '{print $5}'` #Hbase thrift2 server #3
	     ch6=`echo $servicecomponentid|awk '{print $6}'` #Hbase REST server #3
	    fi
	    if [[ "$namesrv"  == "Monitoring" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #Monitoring diamond #2-...
	     ch2=`echo $servicecomponentid|awk '{print $2}'` #Monitoring jmxtrans #1
	    fi
	    if [[ "$namesrv"  == "YARN" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #YARN mapreduce history server #2 
	     ch2=`echo $servicecomponentid|awk '{print $2}'` #YARN nodemanager #worker
	     ch3=`echo $servicecomponentid|awk '{print $3}'` #YARN resourcemanager #1,2
	     ch4=`echo $servicecomponentid|awk '{print $4}'` #YARN timeline server # 2
	     ch5=`echo $servicecomponentid|awk '{print $5}'` #YARN client #all
	    fi
	    if [[ "$namesrv"  == "Hive" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #hive client #all
	     ch2=`echo $servicecomponentid|awk '{print $2}'` #hiveserver2 #1,3 
	     ch3=`echo $servicecomponentid|awk '{print $3}'` #metastore #1,2
	     ch4=`echo $servicecomponentid|awk '{print $4}'` #tez #4
	     ch5=`echo $servicecomponentid|awk '{print $5}'` #tez ui # 4
	    fi
	    if [[ "$namesrv"  == "Zookeeper" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #Zookeeper 1-3
	    fi
	    if [[ "$namesrv"  == "ADB" ]];then
	     ch1=`echo $servicecomponentid|awk '{print $1}'` #ADB master
	     ch2=`echo $servicecomponentid|awk '{print $3}'` #ADB standBY
	     ch3=`echo $servicecomponentid|awk '{print $2}'` #ADB Segment
	    fi
	    chcount=0
	    adbcount=0
	    hdfscount=0
	    yarncount=0
	    zoocount=0
	    moncount=0
	    hbasecount=0
	    hivecount=0
	    while read -r n
	    do
	    if [[ "$namesrv"  == "Chrony" ]];then
		if [[ "$chcount"  == "0" ]];then
		 echo "$n:$srv_id:$ch1" >>postjson
		fi
		if [[ "$chcount"  == "1" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson
		fi
		if (( "$chcount"  > "1" ));then
		 echo "$n:$srv_id:$ch3" >>postjson
		fi
		chcount=$((chcount=chcount+1))
	    elif [[ "$namesrv"  == "Hive" ]];then
		if [[ "$hivecount"  == "0" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #server1
		 echo "$n:$srv_id:$ch3" >>postjson #metastore1
		fi
		if [[ "$hivecount"  == "1" ]];then
		 echo "$n:$srv_id:$ch3" >>postjson #metastore2
		fi
		if [[ "$hivecount"  == "2" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #server2
		fi
		if [[ "$hivecount"  == "3" ]];then
		 echo "$n:$srv_id:$ch5" >>postjson #tez UI
		 echo "$n:$srv_id:$ch4" >>postjson #tez
		fi
		echo "$n:$srv_id:$ch1" >>postjson  #client
		hivecount=$((hivecount=hivecount+1))
	    elif [[ "$namesrv"  == "HBase" ]];then
		if [[ "$hbasecount"  == "0" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #master1
		fi
		if [[ "$hbasecount"  == "1" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #master2
		 echo "$n:$srv_id:$ch4" >>postjson #phoenix query
		fi
		if [[ "$hbasecount"  == "2" ]];then
		 echo "$n:$srv_id:$ch5" >>postjson # thrift2
		 echo "$n:$srv_id:$ch6" >>postjson # REST
		fi
		if (( "$hbasecount"  > "2" ));then
		 echo "$n:$srv_id:$ch3" >>postjson #worker
		fi
		echo "$n:$srv_id:$ch1" >>postjson #client
		hbasecount=$((hbasecount=hbasecount+1))
	    elif [[ "$namesrv"  == "Zookeeper" ]];then
		if (( "$zoocount"  < "3" ));then #zoo server 1-3
		 echo "$n:$srv_id:$ch1" >>postjson
		fi
		zoocount=$((zoocount=zoocount+1))
	    elif [[ "$namesrv"  == "Monitoring" ]];then
		if [[ "$moncount"  == "0" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #jmxtrans
		fi
		if (( "$moncount"  > "0" ));then #diamon
		 echo "$n:$srv_id:$ch1" >>postjson
		fi
		moncount=$((moncount=moncount+1))
	    elif [[ "$namesrv"  == "ADB" ]];then
		if [[ "$adbcount"  == "0" ]];then
		 echo "$n:$srv_id:$ch1" >>postjson
		fi
		if [[ "$adbcount"  == "1" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson
		fi
		if (( "$adbcount"  > "1" ));then
		 echo "$n:$srv_id:$ch3" >>postjson
		fi
		adbcount=$((adbcount=adbcount+1))
	    elif [[ "$namesrv"  == "YARN" ]];then
		if [[ "$yarncount"  == "0" ]];then
		 echo "$n:$srv_id:$ch3" >>postjson #resurce manager 1
		fi
		if [[ "$yarncount"  == "1" ]];then
		 echo "$n:$srv_id:$ch1" >>postjson #map reduce history
		 echo "$n:$srv_id:$ch3" >>postjson #resurce manager 2
		 echo "$n:$srv_id:$ch4" >>postjson #timeline server
		fi
		if (( "$yarncount"  > "1" ));then
		 echo "$n:$srv_id:$ch2" >>postjson #worker
		fi
		echo "$n:$srv_id:$ch5" >>postjson #client
		yarncount=$((yarncount=yarncount+1))
	    elif [[ "$namesrv"  == "HDFS" ]];then
		if [[ "$hdfscount"  == "0" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #namenode 1
		 echo "$n:$srv_id:$ch3" >>postjson #journalnode 1
		 echo "$n:$srv_id:$ch4" >>postjson #zkfc 1
		fi
		if [[ "$hdfscount"  == "1" ]];then
		 echo "$n:$srv_id:$ch2" >>postjson #namenode 2
		 echo "$n:$srv_id:$ch3" >>postjson #journalnode 2 
		fi
		if [[ "$hdfscount"  == "2" ]];then
		 echo "$n:$srv_id:$ch3" >>postjson #journalnode 3
		 echo "$n:$srv_id:$ch4" >>postjson #zkfc 3
		fi
		if (( "$hdfscount"  > "2" ));then
		 echo "$n:$srv_id:$ch1" >>postjson #worker
		fi
		echo "$n:$srv_id:$ch6" >>postjson #client
		hdfscount=$((hdfscount=hdfscount+1))	
	    else
	         echo "$n:$srv_id:$servicecomponentid" >>postjson
	    fi
	    done < <(cat prejson)
            #echo -e $servicecomponent>> prejson
	fi
    done
fi

if [[ "$t1" == "#SRV" ]];then
    if [[ "$edit" == "" ]];then
	serviceadd="yes"
    else
	exit
    fi
fi

if [[ -z "$serviceadd" ]];then
echo "[*] Get $t1 $t2 $t3 $t4 $t5"
ansible_user=$t1 
ansible_pass=$t2
hostname=$t3 #имя в adcm hostname
ansible_host=$t4   # ip 
ansible_port=$t5

tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
token=$(echo $tokens|awk -F"\"" '{print $4}')
#echo $token
clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/`
idcluster=`echo $clusters|grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$3}'|tr -d '"'|awk -F ':' '{print $2" "$4}'|grep " $clustername$"|awk '{print $1}'`

provids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/provider/`
provid=`echo $provids|grep -Po '"id":\K[^,]*' `

echo "[+] Cluster id: "$idcluster
prototype_ids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/provider/`
prototype_id=`echo $prototype_ids |grep -Po '"prototype_id":\K[^",]*'|head -1`
prototype_id=$((prototype_id+1)) #TODO check algo

echo "[+] Prototype_id: "$prototype_id
echo "[+] Provider: "$provid

if [[ "$edit" == "components" ]];then
    out=$(cat out)
    #echo $out
	editconfigs=`echo $out|curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' --json @- http://$adcmip:8000/api/v1/cluster/$idcluster/hostcomponent/`
	echo "[%]Components are distributions "$editconfigs 
    exit
fi


if [[ "$edit" == "checker" ]];then
    listhost=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
    nodecount=`echo $listhost |grep -Po '"id":\K[^",]*'`
    for i in $nodecount; do
        listactions=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token'' http://$adcmip:8000/api/v1/host/$i/action/`
	checkerid=`echo $listactions|grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/g'| awk -F',' '{print $1":"$3}'|grep "statuschecker"|tr -d '"'|awk -F ':' '{print $2" "$4}'|awk '{print $1}'`
	echo $checkerid
	editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' http://$adcmip:8000/api/v1/host/$i/action/$checkerid/run/`
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
    newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"cluster_id":"'$idcluster'","prototype_id":'$prototype_id',  "provider_id": "'$provid'","fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`
    echo "Add="$newhost
    idnewhost=`echo $newhost |grep -Po '"id":\K[^,]*' `
    
    echo "[+] New host. Id: "$idnewhost
    #echo "HOST:"$hostname":"$idnewhost >> prejson
    echo $idnewhost >> prejson
    #Add host to cluster
    add=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"host_id":"'$idnewhost'"}'  http://$adcmip:8000/api/v1/cluster/$idcluster/host/`
    echo "[+] Host add to cluster."
fi

if [[  "$edit" == "" ]]; then
    echo "[+] Add password"
    editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_ssh_private_key_file":"NULL","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_ssh_common_args":"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null", "ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
    #echo $editconfigs
elif [[ "$edit" == "edit" ]]; then
    listhost=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
    nodecount=`echo $listhost |grep -Po '"id":\K[^",]*'`
    for i in $nodecount; do
	host_names=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/$i/`
	host_name=`echo $host_names |grep -Po '"fqdn":"\K[^",]*'`
	if [[ "$hostname" == "$host_name" ]];then
	    editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_ssh_private_key_file":"NULL","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_ssh_common_args":"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null", "ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$i/config/history/`
	    echo "[%] Edit host id "$i " and name "$host_name
	fi
    done
fi
fi
done < <(cat hosts.csv)