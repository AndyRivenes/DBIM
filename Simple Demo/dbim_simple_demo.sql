REM dbim_simple_demo.sql
REM
REM This script provides an all inclusive script to show Database
REM In-Memory performance. It creates three objects, loads sample 
REM data and then runs some 2 example queries with and without 
REM inmemory enabled.
REM
REM Requirements:
REM
REM   1) inmemory_size >= 600 MB
REM
REM   2) 1.5 GB of tablespace available
REM
REM   3) CREATE USER imdemo IDENTIFIED BY <passwd>
REM        QUOTA UNLIMITED ON users;
REM
REM   4) Privileges: 
REM        GRANT CREATE SESSION TO imdemo;
REM        GRANT CREATE TABLE TO imdemo;
REM        GRANT CREATE VIEW TO imdemo;
REM        GRANT CREATE SEQUENCE TO imdemo;
REM        GRANT EXECUTE ON DBMS_INMEMORY_ADMIN TO imdemo;
REM        GRANT SELECT ON SYS.V_$IM_SEGMENTS TO imdemo;
REM        GRANT SELECT_CATALOG_ROLE TO imdemo;
REM
REM   5) Clean up:
REM      DROP TABLE orders_tab;
REM      DROP VIEW  orders_summary_v;
REM      DROP SEQUENCE order_key_seq;
REM
REM      or
REM
REM      DROP USER imdemo CASCADE;
REM
--
PROMPT **********************************************
PROMPT Database In-Memory Simple Demo - Version 1.0
PROMPT **********************************************
--
--
PROMPT **********************************************
PROMPT Create objects
PROMPT Note: ORA errors for the drop table and 
PROMPT       drop sequence can be ignored 
PROMPT **********************************************
--
drop table orders_tab purge;
create table orders_tab
(
order_key        number,
order_linenum    number,
--
orderdate        date,
--
customer_name    varchar2(100),
customer_city    varchar2(25),
customer_nation  varchar2(15),
customer_region  varchar2(15),
--
line_quantity    number,
line_price       number,
line_supplycost  number,
--
part_key         number,
part_name        varchar2(100),
part_mfgr        varchar2(100),
--
supplier_key     number,
supplier_name    varchar2(100),
supplier_nation  varchar2(15),
supplier_region  varchar2(12),
--
order_discount   number,
order_shipmode   varchar2(15),
order_priority   varchar2(15)
)
NOLOGGING;
--
create or replace view orders_summary_v
as
select 
  orderdate, 
  customer_nation,
  customer_region,
  order_key,
  sum(line_quantity * line_price) order_price,
  sum(line_quantity * line_supplycost) order_cost,
  sum(line_quantity * (line_price - (line_price * order_discount / 100))) order_revenue
from
  orders_tab
group by
  orderdate, 
  customer_nation,
  customer_region,
  order_key;
--
DROP SEQUENCE order_key_seq;
CREATE SEQUENCE order_key_seq;
--
-- Exit on error
--
WHENEVER SQLERROR EXIT;
--
--
PROMPT **********************************************
PROMPT Run Data Load
PROMPT **********************************************
--
SET SERVEROUTPUT ON;
DECLARE
  --
  -- Region - Nation table
  --
  type Nation_Array is table of VARCHAR2(15);
  type Region_Matrix is table of Nation_Array;
  v_region Region_Matrix := Region_Matrix();
  --
  -- Part table
  --
  TYPE Part_Array_Type IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;
  v_part_array Part_Array_Type;
  --
  -- List Type
  --
  TYPE STR_LIST_TYPE IS TABLE OF VARCHAR2(15);
  --
  -- Date list
  --
  v_year_values      STR_LIST_TYPE;
  year_num           NUMBER;
  start_number       NUMBER;
  end_number         NUMBER;
  --
  -- Ship mode list
  --  
  v_ship_values      STR_LIST_TYPE;
  v_ship_mode        VARCHAR2(15);
  --
  -- Order priority list
  --  
  v_priority_values  STR_LIST_TYPE;
  v_order_priority   VARCHAR2(15);
  --
  -- Part Mfgr list
  --  
  v_mfgr_values      STR_LIST_TYPE;
  v_part_mfgr        VARCHAR2(100);  
  --
  -- Table collection
  --
  TYPE orders_tab_type IS TABLE OF orders_tab%ROWTYPE
    INDEX BY PLS_INTEGER;
  --
  v_ord_tab orders_tab_type;
  --
  co_ordtab_limit    CONSTANT NUMBER := 1000;
  co_min_ordnum      CONSTANT NUMBER := 10;
  co_max_ordnum      CONSTANT NUMBER := 100;
  co_min_lnum        CONSTANT NUMBER := 1;
  co_max_lnum        CONSTANT NUMBER := 8;
  --
  v_bulk_idx         PLS_INTEGER;
  v_start_bulk_idx   PLS_INTEGER;
  v_last_bulk_idx    PLS_INTEGER;
  --
  -- Table variables
  --
  orderdate          DATE;
  v_order_key        NUMBER;
  v_order_discount   NUMBER;
  --
  v_cust_num         PLS_INTEGER;
  v_cust_name        VARCHAR2(100);
  v_cust_regidx      NUMBER;	
  v_cust_natidx      NUMBER;
  v_cust_region      VARCHAR2(15);
  v_cust_nation      VARCHAR2(15);
  v_cust_city        VARCHAR2(25);
  --
  v_supplier_regidx  NUMBER;	
  v_supplier_natidx  NUMBER;
  --
  -- Insert orders_tab collection
  --
  PROCEDURE INSERT_DATA(p_order_tab orders_tab_type)
  IS
  BEGIN
    --
    -- DBMS_OUTPUT.PUT_LINE('Bulk load count: ' || TO_CHAR(p_order_tab.count));
    --
    FORALL i IN 1 .. p_order_tab.count
      INSERT /*+ APPEND */ INTO orders_tab ( ORDER_KEY, ORDER_LINENUM, ORDERDATE, CUSTOMER_NAME, CUSTOMER_CITY,
        CUSTOMER_NATION, CUSTOMER_REGION, LINE_QUANTITY, LINE_PRICE, LINE_SUPPLYCOST, PART_KEY, PART_NAME,
        PART_MFGR, SUPPLIER_KEY, SUPPLIER_NAME, SUPPLIER_NATION, SUPPLIER_REGION, ORDER_DISCOUNT,
        ORDER_SHIPMODE, ORDER_PRIORITY  )
      VALUES( 
        p_order_tab(i).order_key, 
        p_order_tab(i).order_linenum,
        p_order_tab(i).orderdate,
        p_order_tab(i).customer_name,
        p_order_tab(i).customer_city,
        p_order_tab(i).customer_nation,
        p_order_tab(i).customer_region,
        p_order_tab(i).line_quantity,
        p_order_tab(i).line_price,
        p_order_tab(i).line_supplycost,
        p_order_tab(i).part_key,
        p_order_tab(i).part_name,
        p_order_tab(i).part_mfgr,
        p_order_tab(i).supplier_key,
        p_order_tab(i).supplier_name,
        p_order_tab(i).supplier_nation,
        p_order_tab(i).supplier_region,
        p_order_tab(i).order_discount,
        p_order_tab(i).order_shipmode,
        p_order_tab(i).order_priority
      );
    --
    COMMIT;
  END;
  --
  -- Load part_name array
  --
  FUNCTION pop_part RETURN Part_Array_Type IS
    p_array Part_Array_Type;
  BEGIN
    p_array(1)  := 'almond';
    p_array(2)  := 'antique';
    p_array(3)  := 'aquamarine';
    p_array(4)  := 'azure';
    p_array(5)  := 'beige';
    p_array(6)  := 'bisque';
    p_array(7)  := 'black';
    p_array(8)  := 'blanched';
    p_array(9)  := 'blue';
    p_array(10) := 'blush';
    p_array(11) := 'brown';
    p_array(12) := 'cornsilk';
    p_array(13) := 'drab';
    p_array(14) := 'firebrick';
    p_array(15) := 'goldenrod';
    p_array(16) := 'khaki';
    p_array(17) := 'orchid';
    p_array(18) := 'peach';
    p_array(19) := 'pink';
    p_array(20) := 'powder';
    p_array(21) := 'salmon';
    p_array(22) := 'seashell';
    p_array(23) := 'white';
    p_array(24) := 'cornflower';
    p_array(25) := 'gainsboro';
    p_array(26) := 'ghost';
    p_array(27) := 'lavender';
    p_array(28) := 'medium';
    p_array(29) := 'midnight';
    p_array(30) := 'misty';
    p_array(31) := 'moccasin';
    p_array(32) := 'red';
    p_array(33) := 'rose';
    p_array(34) := 'spring';
    p_array(35) := 'steel';
    p_array(36) := 'tan';
    --
  RETURN p_array;
END pop_part;
--
BEGIN
  DECLARE
    v_reg_ctr PLS_INTEGER := 0;
    v_nat_ctr PLS_INTEGER;
    --
    PROCEDURE ADD_REGION
    IS
    BEGIN
      v_region.extend;
      v_reg_ctr := v_reg_ctr + 1;
      v_region(v_reg_ctr) := Nation_Array();
      v_nat_ctr := 0;
    END;
    --
    PROCEDURE ADD_NATION(l_value IN VARCHAR2)
    IS
    BEGIN
      v_region(v_reg_ctr).extend;
      v_nat_ctr := v_nat_ctr + 1;
      v_region(v_reg_ctr)(v_nat_ctr) := l_value;
    END;
  BEGIN
    -- Build Africa region
    ADD_REGION;
    ADD_NATION('AFRICA');
    ADD_NATION('ALGERIA');
    ADD_NATION('ETHIOPIA');
    ADD_NATION('KENYA');
    ADD_NATION('MOROCCO');
    ADD_NATION('MOZAMBIQUE');
    -- Add AMERICA region
    ADD_REGION;
    ADD_NATION('AMERICA');
    ADD_NATION('ARGENTINA');
    ADD_NATION('BRAZIL');
    ADD_NATION('CANADA');
    ADD_NATION('PERU');
    ADD_NATION('UNITED STATES');
    -- Add ASIA region
    ADD_REGION;
    ADD_NATION('ASIA');
    ADD_NATION('SINGAPORE');
    ADD_NATION('INDIA');
    ADD_NATION('INDONESIA');
    ADD_NATION('JAPAN');
    ADD_NATION('VIETNAM');
    -- Add EUROPE region
    ADD_REGION;
    ADD_NATION('EUROPE');
    ADD_NATION('FRANCE');
    ADD_NATION('GERMANY');
    ADD_NATION('ROMANIA');
    ADD_NATION('BULGARIA');
    ADD_NATION('UNITED KINGDOM');
    -- Add MIDDLE EAST region
    ADD_REGION;
    ADD_NATION('MIDDLE EAST');
    ADD_NATION('EGYPT');
    ADD_NATION('ISRAEL');
    ADD_NATION('ARMENIA');
    ADD_NATION('JORDAN');
    ADD_NATION('SAUDI ARABIA');
  END;
  --
  -- Populate part_name array
  --
  v_part_array := pop_part;
  --
  -- Load ship mode values
  --
  v_ship_values := STR_LIST_TYPE('AIR','FOB','MAIL','RAIL','REG AIR','SHIP', 'TRUCK');
  --
  -- Load order priority values
  --
  v_priority_values := STR_LIST_TYPE('1-URGENT','2-HIGH','3-MEDIUM','4-NOT SPECIFIED','5-LOW');
  --
  -- Load part mfgr values
  --
  v_mfgr_values := STR_LIST_TYPE('MFGR#1','MFGR#2','MFGR#3','MFGR#4','MFGR#5');
  --
  -- Set up table variables
  --
  v_ord_tab := orders_tab_type();
  v_bulk_idx := 1;
  --
  -- Load four years of data
  --
  v_year_values := STR_LIST_TYPE('2005','2006','2007','2008');
  FOR y IN v_year_values.FIRST..v_year_values.LAST LOOP
    --
    -- Create orders for each day of the year
    --    
    year_num := TO_NUMBER(v_year_values(y)); 
    start_number := TO_NUMBER(TO_CHAR(to_date(TO_CHAR(year_num)||'-01-01', 'YYYY-MM-DD'), 'j'));
    end_number   := TO_NUMBER(TO_CHAR(to_date(TO_CHAR(year_num+1)||'-01-01', 'YYYY-MM-DD') - 1, 'j'));
    --
    FOR d IN start_number .. end_number LOOP
      orderdate := TO_DATE(d, 'j');
      --    
      -- Build order values for each region
      --
      FOR v_cust_regidx IN v_region.FIRST .. v_region.LAST LOOP
        FOR v_cust_natidx IN v_region(v_cust_regidx).FIRST .. v_region(v_cust_regidx).LAST LOOP
          IF v_cust_natidx = v_region(v_cust_regidx).FIRST THEN
            v_cust_region := v_region(v_cust_regidx)(v_cust_natidx);
            CONTINUE; -- Skip to the first nation
          END IF;
          --
          -- Randomize orders by region/nation
          --
          --  Need min and max variables
          --
          FOR v_ordnum_idx IN 1 .. FLOOR(dbms_random.value(co_min_ordnum, co_max_ordnum)) LOOP
	          --
	          -- Add customer info
	          --
            v_cust_nation := v_region(v_cust_regidx)(v_cust_natidx);
            --
	          v_cust_num :=  LPAD( floor(dbms_random.value(1,1000)) , 9, '0');
            v_cust_name := 'Customer#' || TO_CHAR(v_cust_num);
            v_cust_city := v_cust_nation || v_cust_num;
            --
            v_order_key := order_key_seq.nextval;
            v_order_discount := floor(dbms_random.value(0,10));
            v_ship_mode := v_ship_values( FLOOR(dbms_random.value(v_ship_values.FIRST, v_ship_values.LAST)) );
            v_order_priority := v_priority_values( FLOOR(dbms_random.value(v_priority_values.FIRST, v_priority_values.LAST)) );
            --
            -- Capture start v_ord_tab index
            --
            v_start_bulk_idx := v_bulk_idx;
            --
            -- Process order line numbers
            --
            --
            --  Need min and max variables
            --
            FOR i_lnum IN 1 .. floor(dbms_random.value(co_min_lnum, co_max_lnum)) LOOP
              --
              -- Add order values
              --
              v_ord_tab(v_bulk_idx).order_key := v_order_key;
              v_ord_tab(v_bulk_idx).orderdate := orderdate;
              v_ord_tab(v_bulk_idx).customer_name := v_cust_name;
              v_ord_tab(v_bulk_idx).customer_city := v_cust_city;
              v_ord_tab(v_bulk_idx).customer_nation := v_cust_nation;
              v_ord_tab(v_bulk_idx).customer_region := v_cust_region;
              --
              v_ord_tab(v_bulk_idx).order_discount := v_order_discount;
              v_ord_tab(v_bulk_idx).order_shipmode := v_ship_mode;
              v_ord_tab(v_bulk_idx).order_priority := v_order_priority;
              --
              -- Process order line numbers
              --
		          v_ord_tab(v_bulk_idx).order_linenum := i_lnum;
              --
              v_ord_tab(v_bulk_idx).line_quantity := FLOOR(dbms_random.value(1,50));
              v_ord_tab(v_bulk_idx).line_price := FLOOR(dbms_random.value(90098,10494950));
              v_ord_tab(v_bulk_idx).line_supplycost := v_ord_tab(v_bulk_idx).line_price * ( FLOOR(dbms_random.value(3,6))/100 );
              --
              v_ord_tab(v_bulk_idx).part_key := FLOOR(dbms_random.value(1,800000));
              v_ord_tab(v_bulk_idx).part_name := v_part_array( FLOOR(dbms_random.value(v_part_array.FIRST, v_part_array.LAST))) || ' ' ||
                v_part_array( FLOOR(dbms_random.value(v_part_array.FIRST, v_part_array.LAST)));
              v_ord_tab(v_bulk_idx).part_mfgr := v_mfgr_values( FLOOR(dbms_random.value(v_mfgr_values.FIRST, v_mfgr_values.LAST)) );
              --
              v_ord_tab(v_bulk_idx).supplier_key := FLOOR(dbms_random.value(1,20000));
              v_ord_tab(v_bulk_idx).supplier_name := 'Supplier#' || LPAD(v_ord_tab(v_bulk_idx).supplier_key, 9, '0');
              --
              v_supplier_regidx := FLOOR(dbms_random.value(v_region.FIRST, v_region.LAST));	
              v_supplier_natidx := FLOOR(dbms_random.value(v_region(v_cust_regidx).FIRST, v_region(v_cust_regidx).LAST));
              --
              v_ord_tab(v_bulk_idx).supplier_nation := v_region(v_supplier_regidx)(v_region(v_supplier_regidx).FIRST);
              v_ord_tab(v_bulk_idx).supplier_region := v_region(v_supplier_regidx)(v_supplier_natidx);
              --
              -- Capture last v_ord_tab index
              --
              v_last_bulk_idx := v_bulk_idx;
              v_bulk_idx := v_bulk_idx + 1;
            END LOOP;
          END LOOP;
          --
          -- When ord_tab collection exceeds limit flush to the database
          --
          IF v_ord_tab.count >= co_ordtab_limit THEN
            --
            -- Run insert for all rows in the collection
            --
            INSERT_DATA(v_ord_tab);
            --
            -- Reinitialize ord_tab array
            --
            v_ord_tab := orders_tab_type();
            v_bulk_idx := 1;
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP;
  --
  -- Insert any remaining orders
  --
  INSERT_DATA(v_ord_tab);
END;
/
--
--
PROMPT **********************************************
PROMPT Generate Stats and Populate ORDERS_TAB table
PROMPT **********************************************
--
SET ECHO ON;
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'ORDERS_TAB');
--
ALTER TABLE orders_tab INMEMORY PRIORITY HIGH;
--
EXEC DBMS_INMEMORY.POPULATE(USER,'ORDERS_TAB');
--
SET ECHO OFF;
SET SERVEROUTPUT OFF;
--
--
PROMPT **********************************************
PROMPT Wait for IM Population
PROMPT **********************************************
--
DECLARE
  --
  -- populate_wait query
  --
  -- Return code:
  --   -1 = POPULATE_TIMEOUT
  --    0 = POPULATE_SUCCESS
  --    1 = POPULATE_OUT_OF_MEMORY
  --    2 = POPULATE_NO_INMEMORY_OBJECTS
  --    3 = POPULATE_INMEMORY_SIZE_ZERO 
  --
  co_wait_timeout CONSTANT NUMBER := 3; -- Wait up to 3 minutes
  co_priority     CONSTANT VARCHAR2(8) := 'HIGH';
  co_pop_percent  CONSTANT NUMBER := 100;
  co_pop_timeout  CONSTANT NUMBER := 60;
  --
  v_rc            CHAR(2);
  v_wait          NUMBER := 0;
  v_done          BOOLEAN := FALSE;
  --
  POP_ERROR       EXCEPTION;
  PRAGMA EXCEPTION_INIT(POP_ERROR, -20000);
  POP_TIMEOUT     EXCEPTION;
  PRAGMA EXCEPTION_INIT(POP_TIMEOUT, -20010);
BEGIN
  WHILE NOT v_done AND v_wait <= co_wait_timeout LOOP
    select TO_CHAR(dbms_inmemory_admin.populate_wait(
      priority=>co_priority, percentage=>co_pop_percent, timeout=>co_pop_timeout ))
    INTO v_rc
    from dual;
    --
    IF v_rc = '0' THEN
      v_done := TRUE;
    ELSIF v_rc = '-1' THEN
      v_wait := v_wait + 1;
    ELSE
      RAISE_APPLICATION_ERROR(-20000, 'Error populating IM column store');
    END IF;
    --
    IF v_wait >= co_wait_timeout THEN
      RAISE_APPLICATION_ERROR(-20010, 'Timeout populating IM column store');
    END IF;
  END LOOP;
EXCEPTION
  WHEN POP_ERROR THEN
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SQLERRM(-20000)));
    RAISE;
  WHEN POP_TIMEOUT THEN
    DBMS_OUTPUT.PUT_LINE(TO_CHAR(SQLERRM(-20010)));
    RAISE;
END;
/
--
--
PROMPT **********************************************
PROMPT Show space usage
PROMPT **********************************************
--
col segment_name format a20;
col size heading 'Size (MB)' format  999,999,999;
select segment_name, bytes/1024/1024 "size" from user_segments
where segment_name = 'ORDERS_TAB';
--
col owner format a20;
col segment_name format a20;
col bytes format 999,999,999,999;
col inmemory_size format 999,999,999,999;
col bytes_not_populated heading 'BYTES NOT|POPULATED' format 999,999,999;
select
  owner,
  segment_name,
  bytes,
  populate_status as "POP STATUS",
  inmemory_size,
  bytes_not_populated
from
  v$im_segments
where
  segment_name in ('ORDERS_TAB')
order by
  segment_name;
--
--
PROMPT **********************************************
PROMPT Run query 1 with In-Memory enabled
PROMPT **********************************************
--
pause Hit enter ...
--
alter session set statistics_level = all;
--
set timing on
set echo on
alter session set inmemory_query = enable;
--
select 
  customer_region, customer_nation, count(distinct(order_key)) "Total Orders"
from orders_tab group by customer_region, customer_nation;
--
set echo off
set timing off
--
select * from table(dbms_xplan.display_cursor(NULL, NULL, 'TYPICAL IOSTATS LAST'));
--
PROMPT **********************************************
PROMPT Run query 1 with In-Memory disabled
PROMPT **********************************************
--
pause Hit enter ...
set timing on
set echo on
alter session set inmemory_query = disable;
--
select 
  customer_region, customer_nation, count(distinct(order_key)) "Total Orders"
from orders_tab group by customer_region, customer_nation;
--
set echo off
set timing off
--
select * from table(dbms_xplan.display_cursor(NULL, NULL, 'TYPICAL IOSTATS LAST'));
--
--
PROMPT **********************************************
PROMPT Run query 2 with In-Memory enabled
PROMPT **********************************************
--
pause Hit enter ...
set timing on
set echo on
alter session set inmemory_query = enable;
--
select 
  order_key, min(order_revenue)
from   orders_summary_v
where  order_key IN (  select order_key
                          from ORDERS_TAB
                          where line_supplycost = (select max(line_supplycost)
                                                   from  ORDERS_TAB
                                                   where line_quantity > 10
                                                   and order_shipmode LIKE 'SHIP%'
                                                   and order_discount between 5 and 8)
                          and order_shipmode LIKE 'SHIP%'
                          and order_discount between 5 and 8
                        )
group by order_key;
--
set echo off
set timing off
--
select * from table(dbms_xplan.display_cursor(NULL, NULL, 'TYPICAL IOSTATS LAST'));
--
--
PROMPT **********************************************
PROMPT Run query 2 with In-Memory disabled
PROMPT **********************************************
--
pause Hit enter ...
set timing on
set echo on
alter session set inmemory_query = disable;
--
select
  order_key, min(order_revenue)
from   orders_summary_v
where  order_key IN (  select order_key
                          from ORDERS_TAB
                          where line_supplycost = (select max(line_supplycost)
                                                   from  ORDERS_TAB
                                                   where line_quantity > 10
                                                   and order_shipmode LIKE 'SHIP%'
                                                   and order_discount between 5 and 8)
                          and order_shipmode LIKE 'SHIP%'
                          and order_discount between 5 and 8
                        )
group by order_key;
--
set echo off
set timing off
--
select * from table(dbms_xplan.display_cursor(NULL, NULL, 'TYPICAL IOSTATS LAST'));
--
--
PROMPT **********************************************
PROMPT Script complete
PROMPT **********************************************
--
exit;
