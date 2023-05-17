Patroni. ETCD. Haproxy.

1. создаем 3 виртуальные машины с ETCD. На 2 из них ставим постгрес.
вопрос: имеет ли смысл разделять ETCD и постгрес, или можно их ставить на одну машину.
вопрос: Как именно всю эту конструкцию лучше бекапить.

```
bigewg@node1:~$ sudo -u root -i
root@node1:~# apt -y install etcd



Настройки ноды 1
ETCD_NAME="etcd-node1"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://51.250.30.89:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://51.250.30.89:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_claster"
ETCD_INITIAL_CLUSTER="etcd-node1=http://51.250.30.89:2380, etcd-node2=http://158.160.18.188:2380, etcd-node3=http://84.201.163.89:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"

Настройки ноды 2
ETCD_NAME="etcd-node2"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://158.160.18.188:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://158.160.18.188:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_claster"
ETCD_INITIAL_CLUSTER="etcd-node1=http://51.250.30.89:2380, etcd-node2=http://158.160.18.188:2380, etcd-node3=http://84.201.163.89:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"

Настройки ноды 3
ETCD_NAME="etcd-node3"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://84.201.163.89:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://84.201.163.89:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_claster"
ETCD_INITIAL_CLUSTER="etcd-node1=http://51.250.30.89:2380, etcd-node2=http://158.160.18.188:2380, etcd-node3=http://84.201.163.89:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_ELECTION_TIMEOUT="5000"
ETCD_HEARTBEAT_INTERVAL="1000"
