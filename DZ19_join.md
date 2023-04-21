1. Создаем БД и таблицы, которые будем использовать для демонстрации соединений. Заполняем таблицы данными.
```
create database dz_joins;
create table bus (id serial,route text,id_model int);
create table model_bus (id serial,name text);;
insert into bus values (1,'Москва-Болшево',1),(2,'Москва-Пушкино',1),(3,'Москва-Ярославль',2),(4,'Москва-Кострома',2),(5,'Москва-Волгорад',3),
                       (6,'Москва-Иваново',null),(7,'Москва-Саратов',null),(8,'Москва-Воронеж',null);
insert into model_bus values(1,'ПАЗ'),(2,'ЛИАЗ'),(3,'MAN'),(4,'МАЗ'),(5,'НЕФАЗ'),(6,'ЗиС'),(7,'Икарус');
analyse bus;
analyse model_bus;
select * from bus;
 id |      route       | id_model 
----+------------------+----------
  1 | Москва-Болшево   |        1
  2 | Москва-Пушкино   |        1
  3 | Москва-Ярославль |        2
  4 | Москва-Кострома  |        2
  5 | Москва-Волгорад  |        3
  6 | Москва-Иваново   |         
  7 | Москва-Саратов   |         
  8 | Москва-Воронеж   |         
(8 rows)
select * from model_bus;
 id |  name  
----+--------
  1 | ПАЗ
  2 | ЛИАЗ
  3 | MAN
  4 | МАЗ
  5 | НЕФАЗ
  6 | ЗиС
  7 | Икарус
(7 rows)

```

2. Прямое соединение.
```
dz_joins=# explain
select *
from bus b
join model_bus mb
    on b.id_model=mb.id;
                               QUERY PLAN                                
-------------------------------------------------------------------------
 Hash Join  (cost=1.16..2.32 rows=5 width=49)
   Hash Cond: (b.id_model = mb.id)
   ->  Seq Scan on bus b  (cost=0.00..1.08 rows=8 width=37)
   ->  Hash  (cost=1.07..1.07 rows=7 width=12)
         ->  Seq Scan on model_bus mb  (cost=0.00..1.07 rows=7 width=12)
         
 id |      route       | id_model | id | name 
----+------------------+----------+----+------
  1 | Москва-Болшево   |        1 |  1 | ПАЗ
  2 | Москва-Пушкино   |        1 |  1 | ПАЗ
  3 | Москва-Ярославль |        2 |  2 | ЛИАЗ
  4 | Москва-Кострома  |        2 |  2 | ЛИАЗ
  5 | Москва-Волгорад  |        3 |  3 | MAN
```
3. Левое соединение.
```
explain
select *
from bus b
left join model_bus mb
    on b.id_model=mb.id;
                               QUERY PLAN                                
-------------------------------------------------------------------------
 Hash Left Join  (cost=1.16..2.32 rows=8 width=49)
   Hash Cond: (b.id_model = mb.id)
   ->  Seq Scan on bus b  (cost=0.00..1.08 rows=8 width=37)
   ->  Hash  (cost=1.07..1.07 rows=7 width=12)
         ->  Seq Scan on model_bus mb  (cost=0.00..1.07 rows=7 width=12)

 id |      route       | id_model | id | name 
----+------------------+----------+----+------
  1 | Москва-Болшево   |        1 |  1 | ПАЗ
  2 | Москва-Пушкино   |        1 |  1 | ПАЗ
  3 | Москва-Ярославль |        2 |  2 | ЛИАЗ
  4 | Москва-Кострома  |        2 |  2 | ЛИАЗ
  5 | Москва-Волгорад  |        3 |  3 | MAN
  6 | Москва-Иваново   |          |    | 
  7 | Москва-Саратов   |          |    | 
  8 | Москва-Воронеж   |          |    | 
```
4. Кросссоединение двух таблиц.
``` 
explain
select *
from bus b
cross join model_bus mb;

                               QUERY PLAN                                
-------------------------------------------------------------------------
 Nested Loop  (cost=0.00..2.87 rows=56 width=49)
   ->  Seq Scan on bus b  (cost=0.00..1.08 rows=8 width=37)
   ->  Materialize  (cost=0.00..1.10 rows=7 width=12)
         ->  Seq Scan on model_bus mb  (cost=0.00..1.07 rows=7 width=12)

```
5. Полное соединение таблиц.
```
explain 
select *
from bus b
full join model_bus mb on b.id_model=mb.id;
                               QUERY PLAN                                
-------------------------------------------------------------------------
 Hash Full Join  (cost=1.16..2.32 rows=8 width=49)
   Hash Cond: (b.id_model = mb.id)
   ->  Seq Scan on bus b  (cost=0.00..1.08 rows=8 width=37)
   ->  Hash  (cost=1.07..1.07 rows=7 width=12)
         ->  Seq Scan on model_bus mb  (cost=0.00..1.07 rows=7 width=12)
(5 rows)

select *
from bus b
full join model_bus mb on b.id_model=mb.id;
 id |      route       | id_model | id |  name  
----+------------------+----------+----+--------
  1 | Москва-Болшево   |        1 |  1 | ПАЗ
  2 | Москва-Пушкино   |        1 |  1 | ПАЗ
  3 | Москва-Ярославль |        2 |  2 | ЛИАЗ
  4 | Москва-Кострома  |        2 |  2 | ЛИАЗ
  5 | Москва-Волгорад  |        3 |  3 | MAN
  6 | Москва-Иваново   |          |    | 
  7 | Москва-Саратов   |          |    | 
  8 | Москва-Воронеж   |          |    | 
    |                  |          |  5 | НЕФАЗ
    |                  |          |  6 | ЗиС
    |                  |          |  4 | МАЗ
    |                  |          |  7 | Икарус

```
6.
```
```
7.
```
```
