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
5. Секционировать будем по полю book_date. Посмотрим границы диапозона, который нам надо секционировать.
```
demo=# select min (book_date) from bookings;
          min           
------------------------
 2017-06-21 11:05:00+00
(1 row)

demo=# select max(book_date) from bookings;
          max           
------------------------
 2017-08-15 15:00:00+00
(1 row)
```
