PROMPT **********************************************
PROMPT Populate ORDERS_TAB table
PROMPT **********************************************
--
SET SERVEROUTPUT ON;
SET TIMING ON;
SET ECHO ON;
--
ALTER TABLE orders_tab INMEMORY PRIORITY HIGH;
--
EXEC DBMS_INMEMORY.POPULATE(USER,'ORDERS_TAB');
--
SET ECHO OFF;
--SET SERVEROUTPUT OFF;
--
--
PROMPT **********************************************
PROMPT Populate ORDERS_TAB table
PROMPT **********************************************
--
SET SERVEROUTPUT ON;
SET TIMING ON;
SET ECHO ON;
--
ALTER TABLE orders_tab INMEMORY PRIORITY HIGH;
--
EXEC DBMS_INMEMORY.POPULATE(USER,'ORDERS_TAB');
--
SET ECHO OFF;
--SET SERVEROUTPUT OFF;
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
  v_rc            NUMBER;
  v_wait          NUMBER := 0;
  v_done          BOOLEAN := FALSE;
  v_debug         BOOLEAN := TRUE;
  --
  POP_ERROR       EXCEPTION;
  PRAGMA EXCEPTION_INIT(POP_ERROR, -20000);
  POP_TIMEOUT     EXCEPTION;
  PRAGMA EXCEPTION_INIT(POP_TIMEOUT, -20010);
BEGIN
  WHILE NOT v_done AND v_wait <= co_wait_timeout LOOP
    select dbms_inmemory_admin.populate_wait(
      priority=>co_priority, percentage=>co_pop_percent, timeout=>co_pop_timeout )
    INTO v_rc
    from dual;
    --
    IF v_debug THEN
      DBMS_OUTPUT.PUT_LINE('POPULATE_WAIT return code: ' || v_rc);
    END IF;
    IF v_rc = 0 THEN
      v_done := TRUE;
    ELSIF v_rc = -1 THEN
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
