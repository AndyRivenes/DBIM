# Database In-Memory Simple Demo Script

## Requires IM column store to be allocated

  ````
  connect / as sysdba

  alter system set inmemory_size = 500M scope=spfile;
  shutdown immediate;
  startup;
  ````

## Requires a tablespace with at least 1500MB of space

Installation defaults to schema default tablespace

  ````
  CREATE USER imdemo IDENTIFIED BY <passwd>
    QUOTA UNLIMITED ON <tablespace_name>;
  ````

## Schema privileges needed:

  ````
  GRANT CREATE SESSION TO imdemo;
  GRANT CREATE TABLE TO imdemo;
  GRANT CREATE VIEW TO imdemo;
  GRANT CREATE SEQUENCE TO imdemo;
  GRANT EXECUTE ON DBMS_INMEMORY_ADMIN TO imdemo;
  GRANT SELECT ON SYS.V_$IM_SEGMENTS TO imdemo;
  GRANT SELECT_CATALOG_ROLE TO imdemo;
  ````

## Clean up:

  ````
  DROP TABLE orders_tab;
  DROP VIEW  orders_summary_v;
  DROP SEQUENCE order_key_seq;
  ````
  or

  ````
  DROP USER imdemo CASCADE;
  ````

## ORDERS_TAB fully loaded

````
SQL> select segment_name, bytes/1024/1024 from user_segments where segment_name = 'ORDERS_TAB';


SEGMENT_NAME            Size (MB)
-------------------- ------------
ORDERS_TAB                  1,280
````


## ORDERS_TAB populate in the IM column store, default compression

````
                                                                                                 BYTES NOT
SEGMENT_NAME         PARTITION_NAME  EXTERNAL            BYTES POP STATUS       INMEMORY_SIZE    POPULATED
-------------------- --------------- -------- ---------------- ------------- ---------------- ------------
ORDERS_TAB                           FALSE       1,538,031,616 COMPLETED          483,393,536            0

SQL> 
````

## Sample queries

Two different queries are run with and without inmemory enabled along with execution plans

## Sample Output

See the demo.txt file for a sample output from running the dbim_simple_demo.sql script.

