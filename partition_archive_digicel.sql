=========================================================================================================================================
SET LINES 280 PAGESIZE 1000
SET SERVEROUTPUT ON
SET HEADING OFF
-- First, define a placeholder for the second parameter &2
DEFINE second_param = '';

-- This block will check if &2 was passed. If not, leave it empty and don't prompt for it.
COLUMN second_param NEW_VALUE second_param
SELECT NVL('&&2', '') AS second_param FROM dual WHERE '&&2' IS NOT NULL;

-- Start PL/SQL block
DECLARE
  V_INIT_DATE DATE;
  V_END_DATE DATE;
  V_CURRENT_DATE DATE;
  V_SQL_STATEMENT VARCHAR2(4000);
BEGIN
  -- Check if the second parameter was provided or not
  FOR REC IN (SELECT TO_CHAR(SCHEMA_NAME) AS SCHEMA_NAME,
                     TO_CHAR(TABLE_NAME) AS TABLE_NAME,
                     PARTITION_FLAG,
                     INIT_DATE,
                     END_DATE
                FROM DBADMIN.DT_ARCHIVE_RETENTION_RULES
               WHERE SCHEMA_ALIAS = '&1'  -- Schema alias is mandatory
                 AND ( '&2' IS NULL OR '&2' = '' OR TABLE_NAME = '&2'))  -- Handle optional table name
  LOOP
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PROCESSING SCHEMA: ' || REC.SCHEMA_NAME || ', TABLE: ' || REC.TABLE_NAME);
    DBMS_OUTPUT.PUT_LINE('');

    IF REC.PARTITION_FLAG = 'D' THEN
      V_INIT_DATE := TO_DATE(REC.INIT_DATE, 'YYYYMMDD');
      V_END_DATE := TO_DATE(REC.END_DATE, 'YYYYMMDD');
    ELSIF REC.PARTITION_FLAG = 'M' THEN
      V_INIT_DATE := TO_DATE(REC.INIT_DATE, 'YYYYMM');
      V_END_DATE := TO_DATE(REC.END_DATE, 'YYYYMM');
    END IF;

    IF V_INIT_DATE IS NOT NULL AND V_END_DATE IS NOT NULL THEN
      V_CURRENT_DATE := V_INIT_DATE;

      WHILE V_CURRENT_DATE <= V_END_DATE
      LOOP
        IF REC.PARTITION_FLAG = 'D' THEN
          V_SQL_STATEMENT := 'ALTER TABLE "' || REC.SCHEMA_NAME || '"."' || REC.TABLE_NAME || '" DROP PARTITION "PART_' || TO_CHAR(V_CURRENT_DATE, 'YYYYMMDD') || '" UPDATE INDEXES;';
        ELSIF REC.PARTITION_FLAG = 'M' THEN
          V_SQL_STATEMENT := 'ALTER TABLE "' || REC.SCHEMA_NAME || '"."' || REC.TABLE_NAME || '" DROP PARTITION "PART_' || TO_CHAR(V_CURRENT_DATE, 'YYYYMM') || '" UPDATE INDEXES;';
        END IF;

        -- OUTPUT THE GENERATED SQL STATEMENT (OR EXECUTE IT IF NEEDED)
        DBMS_OUTPUT.PUT_LINE(V_SQL_STATEMENT);
        --EXECUTE IMMEDIATE V_SQL_STATEMENT;
        V_CURRENT_DATE := V_CURRENT_DATE + 1;
      END LOOP;
    ELSE
      DBMS_OUTPUT.PUT_LINE('INVALID INIT_DATE OR END_DATE FOR TABLE ' || REC.TABLE_NAME);
    END IF;
  END LOOP;
END;
/
=========================================================================================================================================
CREATE OR REPLACE PROCEDURE UPDATE_RETENTION_DATES AS
BEGIN
	UPDATE DBADMIN.DT_ARCHIVE_RETENTION_RULES
	SET INIT_DATE = CASE 
						--WHEN PARTITION_FLAG = 'D' THEN TO_CHAR(ADD_MONTHS(SYSDATE-6, -RETENTION_MONTHS - 1), 'YYYYMMDD')
						WHEN PARTITION_FLAG = 'D' THEN TO_CHAR(TRUNC(ADD_MONTHS(SYSDATE, -RETENTION_MONTHS - 1), 'MM'), 'YYYYMMDD')
						--WHEN PARTITION_FLAG = 'M' THEN TO_CHAR(ADD_MONTHS(SYSDATE-6, -RETENTION_MONTHS - 1), 'YYYYMM')
						WHEN PARTITION_FLAG = 'M' THEN TO_CHAR(TRUNC(ADD_MONTHS(SYSDATE, -RETENTION_MONTHS - 1), 'MM'), 'YYYYMM')
					END,
		 END_DATE = CASE 
						--WHEN PARTITION_FLAG = 'D' THEN TO_CHAR(ADD_MONTHS(SYSDATE-7, -RETENTION_MONTHS), 'YYYYMMDD')
						WHEN PARTITION_FLAG = 'D' THEN TO_CHAR(LAST_DAY(ADD_MONTHS(SYSDATE, -RETENTION_MONTHS-1)), 'YYYYMMDD')
						--WHEN PARTITION_FLAG = 'M' THEN TO_CHAR(ADD_MONTHS(SYSDATE-7, -RETENTION_MONTHS), 'YYYYMM')
						WHEN PARTITION_FLAG = 'M' THEN TO_CHAR(LAST_DAY(ADD_MONTHS(SYSDATE, -RETENTION_MONTHS-1)), 'YYYYMM')
					END
	WHERE PARTITION_FLAG IN ('D', 'M');
	COMMIT;
	--DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' ROWS UPDATED.');
EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
		ROLLBACK;
END UPDATE_RETENTION_DATES;
/
=========================================================================================================================================
EXECUTE UPDATE_RETENTION_DATES;  
=========================================================================================================================================
BEGIN
  DBMS_SCHEDULER.create_job (
    job_name         => 'UPDATE_RETENTION_DATES_JOB',
    job_type         => 'PLSQL_BLOCK',
    job_action       => 'BEGIN UPDATE_RETENTION_DATES; END;',
    start_date       => TRUNC(SYSDATE, 'MM') + INTERVAL '1' DAY + INTERVAL '3' HOUR,
    repeat_interval  => 'FREQ=MONTHLY; BYMONTHDAY=1; BYHOUR=3; BYMINUTE=0; BYSECOND=0;',
    enabled          => TRUE,
    comments         => 'Job to update retention days in DBADMIN.DT_ARCHIVE_RETENTION_RULES on the first day of each month at 3 AM'
  );
END;
/