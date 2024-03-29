CREATE SCHEMA book_store AUTHORIZATION student;

CREATE TABLE book_store.genre
(
	genre_id 	integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	parent 	 	integer NOT NULL DEFAULT currval('book_store.genre_genre_id_seq'::regclass)
						 REFERENCES book_store.genre(genre_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	genre_code	text,
	genre_name 	varchar(511) NOT NULL
);
CREATE INDEX i1_genre ON book_store.genre USING btree (parent);

INSERT INTO book_store.genre (parent,genre_code,genre_name) VALUES
	 (1,'3','������������ ����������'),
	 (1,'3.1','������� � ���������'),
	 (1,'3.2','������������ ������'),
	 (3,'3.2.1','������ �� �������� �������'),
	 (3,'3.2.2','������ � �������������'),
	 (3,'3.2.3','������ �� ������� ����� �����������'),
	 (3,'3.2.4','������ � �������� �������'),
	 (1,'3.3','������������ ������'),
	 (1,'3.4','������������ ����������'),
	 (2,'3.1.1','��������� ���������� � ����������');
INSERT INTO book_store.genre (parent,genre_code,genre_name) VALUES
	 (2,'3.1.3','��������� ����������������'),
	 (2,'3.1.2','��������� ��������� � ������'),
	 (12,'3.1.2.1','��������� ����������������'),
	 (14,'4','�������������� ����������'),
	 (14,'4.1','������'),
	 (14,'4.2','�����'),
	 (17,'5','����������� ����������'),
	 (17,'5.1','���������� � ����������������'),
	 (18,'5.1.1','����� ����������������'),
	 (18,'5.1.2','���� ������');
	
CREATE TABLE book_store.author
(
	author_id  	integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	author_name varchar(127) NOT NULL UNIQUE,
	biography 	text NULL
);	

INSERT INTO book_store.author (author_name,biography) VALUES
	 ('������ �������',NULL),
	 ('����� �����',NULL),
	 ('����� ������� ���������',NULL),
	 ('������ ���',NULL),
	 ('������� ������',NULL),
	 ('��������� ��. ����',NULL),
	 ('����� ����������',NULL),
	 ('�.�.������',NULL),
	 ('�.�.�������',NULL),
	 ('������ ����',NULL);
INSERT INTO book_store.author (author_name,biography) VALUES
	 ('�.�.���������',NULL),
	 ('������ ����������',NULL),
	 ('������ ������',NULL);

	
CREATE TABLE book_store.book
(
	book_id 	integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	book_name 	varchar(255) NOT NULL,
	isbn 		varchar(18) NULL UNIQUE,
	published 	smallint NULL,
	genre_id 	integer NOT NULL REFERENCES book_store.genre(genre_id) ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX i1_book ON book_store.book USING btree (genre_id);

INSERT INTO book_store.book (book_name,isbn,published,genre_id) VALUES
	 ('SQL Server 2008. ���������� ���� ��� ��������������','978-5-8459-1481-1',NULL,19),
	 ('�������� � ������� ��� ������','5-8459-0788-8',NULL,19),
	 ('���� ���������������� �++. ����������� �������','978-5-7989-0226-2',NULL,19),
	 ('���������','5-7325-0564-4',NULL,13),
	 ('�������','978-5-235-03285-9',NULL,13),
	 ('����������� �.�.�������','5-203-00139-1',NULL,13),
	 ('����������� ��������','978-5-699-49800-0',NULL,13),
	 ('����������� ������','978-5-699-58507-6',NULL,13),
	 ('�����������. ��������� ������������� ����','5-93286-045-6',NULL,18);


	
CREATE TABLE book_store.book_author
( 
	book_id 	integer REFERENCES book_store.book(book_id) ON DELETE CASCADE ON UPDATE CASCADE,
	author_id 	integer REFERENCES book_store.author(author_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT pk_book_author PRIMARY KEY (book_id, author_id)
);

INSERT INTO book_store.book_author (book_id,author_id) VALUES
	 (1,1),
	 (1,2),
	 (1,3),
	 (1,4),
	 (1,5),
	 (2,6),
	 (3,7),
	 (4,8),
	 (4,9),
	 (5,10);
INSERT INTO book_store.book_author (book_id,author_id) VALUES
	 (6,11),
	 (7,12),
	 (8,12),
	 (9,13);


	 
SELECT B.book_name, string_agg (author_name, ', ')
FROM  book_store.book B
INNER JOIN  book_store.book_author BA ON BA.book_id = B.book_id
INNER JOIN  book_store.author A ON A.author_id = BA.author_id
GROUP BY B.book_name;
	
CREATE TABLE book_store.price_category (
	price_category_no	integer PRIMARY KEY,
	category_name 		varchar(63) NOT NULL UNIQUE
);

INSERT INTO book_store.price_category (price_category_no,category_name) VALUES
	 (1,'������� ����'),
	 (2,'���� VIP �������'),
	 (3,'���� �� �����');


CREATE TABLE book_store.price
(
	price_id			integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	book_id 			integer NOT NULL REFERENCES book_store.book(book_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	price_category_no 	integer NOT NULL REFERENCES book_store.price_category(price_category_no) ON DELETE RESTRICT ON UPDATE CASCADE,
	price_value 		numeric(8, 2) NOT NULL CHECK ((price_value > (0)::numeric)),
	price_expired 		date
);

CREATE INDEX i1_price ON book_store.price USING btree (book_id);
CREATE INDEX i2_price ON book_store.price USING btree (price_category_no);
CREATE UNIQUE INDEX uqix_price ON book_store.price USING btree (book_id, price_category_no, COALESCE(price_expired, '2221-01-01'::date));


INSERT INTO book_store.price (book_id,price_category_no,price_value,price_expired) VALUES
	 (1,2,1670.00,NULL),
	 (1,3,1499.99,NULL),
	 (1,1,1610.00,NULL),
	 (2,1,1840.50,NULL),
	 (2,2,1800.00,NULL),
	 (2,3,1800.00,NULL),
	 (3,3,10400.00,NULL),
	 (3,2,1450.50,NULL),
	 (3,1,1600.00,NULL),
	 (4,2,900.00,NULL);
INSERT INTO book_store.price (book_id,price_category_no,price_value,price_expired) VALUES
	 (4,3,850.00,NULL),
	 (4,1,960.50,NULL),
	 (5,1,450.50,NULL),
	 (5,2,400.00,NULL),
	 (5,3,350.00,NULL),
	 (6,3,400.00,NULL),
	 (6,2,430.00,NULL),
	 (6,1,475.00,NULL),
	 (7,1,465.00,NULL),
	 (8,3,410.00,NULL);
INSERT INTO book_store.price (book_id,price_category_no,price_value,price_expired) VALUES
	 (8,2,440.00,NULL),
	 (7,3,410.00,NULL),
	 (7,2,440.00,NULL),
	 (8,1,465.00,NULL),
	 (9,1,590.00,NULL),
	 (9,3,520.50,NULL);


UPDATE book_store.book SET genre_id = 13 WHERE book_id = 5;



