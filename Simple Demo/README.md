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

## Requires a user with the following privileges:

  ````
  GRANT CREATE SESSION
  GRANT CREATE TABLE
  GRANT CREATE VIEW
  GRANT CREATE SEQUENCE
  GRANT EXECUTE ON DBMS_INMEMORY_ADMIN
  GRANT SELECT ON SYS.V_$IM_SEGMENTS
  GRANT SELECT_CATALOG_ROLE
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

## ORDERS_TAB populate in the IM column store, default compression

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
