1. Создаем виртуальную машину и устанавливаем постгрес.
2. скачиваем демонстрационную бд полетов с https://postgrespro.com/docs/postgrespro/15/demodb-bookings-installation или русскую с https://www.postgrespro.ru/education/demodb
3. Копируем архив с демо-базой на виртуальную машину и устанавливаем.
```
bigewg@dz20:/tmp$ unzip demo-small.zip
bigewg@dz20:/tmp$ sudo -i -u postgres
postgres@dz20:~$ psql -f /tmp/demo-small-20170815.sql -U postgres
```
4. Выберем таблицу для секционирования.
```
demo=# \d bookings
                        Table "bookings.bookings"
    Column    |           Type           | Collation | Nullable | Default 
--------------+--------------------------+-----------+----------+---------
 book_ref     | character(6)             |           | not null | 
 book_date    | timestamp with time zone |           | not null | 
 total_amount | numeric(10,2)            |           | not null | 
Indexes:
    "bookings_pkey" PRIMARY KEY, btree (book_ref)
Referenced by:
    TABLE "tickets" CONSTRAINT "tickets_book_ref_fkey" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)
```
5. Секционировать будем по полю book_date. Посмотрим границы диапозона, который нам надо секционировать и кол-во записей по месяцам.
```
demo=#  select count(*),DATE_TRUNC('month',book_date) from bookings group by 2;
 count  |       date_trunc       
--------+------------------------
 167268 | 2017-07-01 00:00:00+00
   7730 | 2017-06-01 00:00:00+00
  87790 | 2017-08-01 00:00:00+00
```
6.  Создадим новую секционированную таблицу.
```
create table bookings_part (
   book_ref character(6) not null, 
   book_date timestamp with time zone not null,
   total_amount numeric(10,2) not null
)
partition by range (book_date);

create table bp_default partition of bookings_part default;
create table bp201706 partition of bookings_part for values from (minvalue) to ('2017-07-01');
create table bp201707 partition of bookings_part for values from ('2017-07-01') to ('2017-08-01');
create table bp201708 partition of bookings_part for values from ('2017-08-01') to (maxvalue);
```
7.  Вставим данные в партицированную таблицу и посчитаем кол-во записей в каждой секции.
```
demo=# insert into bookings_part select * from bookings;
INSERT 0 262788
demo=#  select count(*),DATE_TRUNC('month',book_date) from bookings_part  group by 2;
 count  |       date_trunc       
--------+------------------------
   7730 | 2017-06-01 00:00:00+00
 167268 | 2017-07-01 00:00:00+00
  87790 | 2017-08-01 00:00:00+00
```
8. Наша изначальная таблица имела первичный ключ по полю book_ref и внешний ключ по таблице tickets.
При попытке создать уникальный ключ получаю ошибку:
```
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "bookings_part" lacks column "book_date" which is part of the partition key.
```
 По сути каждая партиция - это отдельная таблица. Поэтому уникальность в границах всех партиций мы можем гарантировать, только если добавим book_date к полям нашего индекса.
```
demo=#  ALTER TABLE bookings_part add PRIMARY KEY (book_ref,book_date);
```
Но в этом случае внешний ключ вообще не получится создать, из-за того, что поле book_ref не имеет уникального индекса.
```
ERROR:  there is no unique constraint matching given keys for referenced table "tickets"
```


