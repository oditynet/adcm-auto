# adcm-auto
ADCM automatic API v1

Скрипт поддерживает установку ADH, ADB c автонастройкой сервисов:
 1) ADB:
    - ADB
    - Chrony
    - PXF
    - Monitoring Clients
 3) ADH:
    - HDFS
    - Monitoring
    - YARN
    - Hive
    - HBase
   
Подерживаются операции: 
1) Установка ```bash addv1-grep_srv.sh```
2) Удаление нод ```bash addv1-grep_srv.sh delete``` (Если ноды в Кластере,то удалите его сначала)
3) Установка checker ```bash addv1-grep_srv.sh checker```
4) распределение сервисов по нодам ```bash addv1-grep_srv.sh components```

   Этапы по установке кластера:
   1) Загрузить бандл, создать кластер
   2) Настроить hosts.csv
       - структура файла:
         - список серевров
         - #SRV - обязательный префикс
         - список устанавливаемых служб
   3) ```bash addv1-grep_srv.sh```
   4) ```bash prepare_service.sh```
   5) ```bash addv1-grep_srv.sh components```

ADCM automatic API v2

   Получение токена
```
curl -s -c cooco -b cooco  http://<ipaddress>:<port>/auth/login/ 1>&2 >/dev/null
token=$(cat cooco|grep "csrftoken"|awk '{print $7}')
echo $token
auth=`curl -s -X POST -c cooco -b cooco -d "username=<username>&password=<password>&csrfmiddlewaretoken=$token" http://<ipaddress>:<port>auth/login/`
echo $auth
hosts=`curl -s -X GET  -H 'Content-type: application/json' -c cooco -b cooco  http://<ipaddress>:<port>/api/v2/hosts/`

#hostid=`echo $hosts |jq -r '.[].results'`
hostid=`echo $hosts |jq '.results.[]|"\(.id) \(.name)"'`
echo $hostid       
