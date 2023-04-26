1. Откат транзакций. 
2. Длинные транзакции и запросов
3. блокировки.
4. Объем WAL в единицу времени.


1. Объекты привысевшие определенный лимит.
```
demo=# select nspname,relname,pg_size_pretty(pg_relation_size(c.oid))  FROM pg_class c, pg_namespace n where c.relnamespace=n.oid and n.nspname NOT IN ('pg_catalog', 'information_schema') and pg_relation_size(c.oid)>30*1024*1024 order by 3;
 nspname  |       relname       | pg_size_pretty 
----------+---------------------+----------------
 bookings | boarding_passes     | 33 MB
 bookings | ticket_flights_pkey | 41 MB
 bookings | tickets             | 48 MB
 bookings | ticket_flights      | 68 MB
(4 rows)
```
можно также периодически сохранять в отдельную таблицу текущие размеры объектов, чтобы можно было вычислять объекты, которые начали резко расти.

2. Очень долгие запросы.
SELECT pid,now() - pg_stat_activity.query_start AS duration,  query,  state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '30 minutes';
