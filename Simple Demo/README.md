# Database In-Memory Simple Demo Script

## Requires IM column store to be allocated

  ````
  connect / as sysdba

  alter system set inmemory_size = 500M scope=spfile;
  shutdown immediate;
  startup;
  ````

## Requires a tablespace with at least 1500MB of space

An example create user statement using the USERS tablespace with a user name of IMDEMO:

  ````
  CREATE USER imdemo IDENTIFIED BY <passwd>
    QUOTA UNLIMITED ON users;
  ````

## Requires a user with the following privileges:

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

## ORDERS_TAB populated in the IM column store, default compression

````
                                                                                             BYTES NOT
OWNER                SEGMENT_NAME                    BYTES POP STATUS       INMEMORY_SIZE    POPULATED
-------------------- -------------------- ---------------- ------------- ---------------- ------------
IMDEMO               ORDERS_TAB              1,470,988,288 COMPLETED          411,041,792            0

````

## Sample queries

Two different queries are run with and without inmemory enabled along with execution plans

## Sample Output

See the simple-demo-output.txt file for a sample output from running the dbim_simple_demo.sql script.
