Patroni. ETCD. Haproxy.

1. создаем 3 виртуальные машины с ETCD. На 2 из них ставим постгрес.
вопрос: имеет ли смысл разделять ETCD и постгрес, или можно их ставить на одну машину.
вопрос: Как именно всю эту конструкцию лучше бекапить.

```
bigewg@node1:~$ sudo -u root -i
root@node1:~# apt -y install etcd

сделанные настройки 3
ETCD_NAME="etcd-node3"
ETCD_LISTEN_CLIENT_URLS="http://158.160.66.23:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://158.160.66.23:2379"
ETCD_LISTEN_PEER_URLS="http://158.160.66.23:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://158.160.66.23:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_Claster"
ETCD_INITIAL_CLUSTER="etcd-node3=http://158.160.66.23:2380, etcd-node2=http://158.160.9.164:2380, etcd-node1=http://130.193.53.110:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"

сделанные настройки 2
ETCD_NAME="etcd-node2"
ETCD_LISTEN_CLIENT_URLS="http://158.160.9.164:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://158.160.9.164:2379"
ETCD_LISTEN_PEER_URLS="http://158.160.9.164:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://158.160.9.164:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_Claster"
ETCD_INITIAL_CLUSTER="etcd-node3=http://158.160.66.23:2380, etcd-node2=http://158.160.9.164:2380, etcd-node1=http://130.193.53.110:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"

сделанные настройки 1
ETCD_NAME="etcd-node1"
ETCD_LISTEN_CLIENT_URLS="http://130.193.53.110:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://130.193.53.110:2379"
ETCD_LISTEN_PEER_URLS="http://130.193.53.110:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://130.193.53.110:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd_patroni_haproxy_Claster"
ETCD_INITIAL_CLUSTER="etcd-node3=http://158.160.66.23:2380, etcd-node2=http://158.160.9.164:2380, etcd-node1=http://130.193.53.110:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_DATA_DIR="/var/lib/etcd"
