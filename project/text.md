Patroni. ETCD. Haproxy.

https://sysad.su/%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0-%D0%B8-%D0%BD%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0-%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0-etcd-ubuntu-18/

1. создаем 3 виртуальные машины.
Имеет смысл разделять ETCD и постгрес, т.к. ETCD чувствителен к нагрузке на диск. Но т.к. это просто тестовая инсталяция, я совмещу. На 2 виртуальные машины установлю Postgresql и ETCD, и еще на одну Haproxy и ETCD.
вопрос: Как именно всю эту конструкцию лучше бекапить.

Установка и создание ETCD кластера.
На все 3 ноды установим ETCD и остановим его.
```
bigewg@node1:~$ sudo -u root -i
root@node1:~# apt -y install etcd
root@node1:~# systemctl stop etcd

Настройки ноды 1:
Дописываем в конец конфигурационного файла параметры для 1-ой ноды и запускаем кластер.
```
cat >> /etc/default/etcd
ETCD_NAME="etcd-node1"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://51.250.30.89:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://51.250.30.89:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_claster"
ETCD_INITIAL_CLUSTER="etcd-node1=http://51.250.30.89:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
root@patroni-node1:~# systemctl start etcd.service
```
Проверяем состояние кластера:
```
root@patroni-node1:~# etcdctl cluster-health
member 22822b8c7bafead5 is healthy: got healthy result from http://51.250.30.89:2379
cluster is healthy
```

Добавление 2-ой ноды.
Добавляем новую ноду: 
```
root@patroni-node1:~# etcdctl member add etcd-node2 http://158.160.18.188:2380
```
Дописываем в конец конфигурационного файла параметры для 2-ой ноды и запускаем ее.
```
cat >> /etc/default/etcd
ETCD_NAME="etcd-node2"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://158.160.18.188:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://158.160.18.188:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_claster"
ETCD_INITIAL_CLUSTER="etcd-node1=http://51.250.30.89:2380,etcd-node2=http://158.160.18.188:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
root@patroni-node2:~# systemctl restart etcd.service
```
Проверяем состояние кластера:
```
root@patroni-node2:~# etcdctl cluster-health
member 111a8236677efc9 is healthy: got healthy result from http://158.160.18.188:2379
member 22822b8c7bafead5 is healthy: got healthy result from http://51.250.30.89:2379
cluster is healthy
```

Добавление 3-ей ноды:
```
root@patroni-node1:~# etcdctl member add etcd-node3 http://84.201.163.89:2380
```
Дописываем в конец конфигурационного файла параметры для 3-ой ноды и запускаем ее.
```
ETCD_NAME="etcd-node3"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://84.201.163.89:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://84.201.163.89:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_claster"
ETCD_INITIAL_CLUSTER="etcd-node1=http://51.250.30.89:2380,etcd-node2=http://158.160.18.188:2380,etcd-node3=http://84.201.163.89:2380"
ETCD_INITIAL_CLUSTER_STATE="existing"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
root@patroni-node3:~# systemctl start etcd.service
```
Проверяем состояние кластера:
```
root@patroni-node3:~# etcdctl cluster-health
member 111a8236677efc9 is healthy: got healthy result from http://158.160.18.188:2379
member 1b6605ca8318e2d0 is healthy: got healthy result from http://84.201.163.89:2379
member 22822b8c7bafead5 is healthy: got healthy result from http://51.250.30.89:2379
cluster is healthy
```

После успешного добавления всех узлов проводим окончательную корректировку конфигурации на всех узлах кластера:
— переменная ETCD_INITIAL_CLUSTER_STATE должна содержать значение «existing»;
— ETCD_INITIAL_CLUSTER должна содержать все узлы кластера: 
etcd-node1=http://51.250.30.89:2380,etcd-node2=http://158.160.18.188:2380,etcd-node3=http://84.201.163.89:2380
Для проверки перезапускаем каждую ноду и проверяем их состояние.

ип сменились
```
root@patroni-node1:~# etcdctl member list
111a8236677efc9: name=etcd-node2 peerURLs=http://158.160.18.188:2380 clientURLs=http://158.160.18.188:2379 isLeader=false
1b6605ca8318e2d0: name=etcd-node3 peerURLs=http://158.160.8.220:2380 clientURLs=http://158.160.8.220:2379 isLeader=false
22822b8c7bafead5: name=etcd-node1 peerURLs=http://158.160.25.27:2380 clientURLs=http://158.160.25.27:2379 isLeader=true
```

Устанавливаем постгрес 15:
```

```
