DECLARE
    v_tablespace_name        VARCHAR2(50) := '&1'; -- First parameter: Tablespace name
    v_total_space            NUMBER;
    v_used_space             NUMBER;
    v_free_space             NUMBER;
    v_new_tablespace_name    VARCHAR2(50);
    v_size_to_allocate       NUMBER;
    v_size_with_extra        NUMBER;
    v_empty_tablespace       NUMBER;
    v_diskgroup_destination  VARCHAR2(20) := '&2'; -- Second parameter: Diskgroup destination
    v_available_space        NUMBER;
    v_table_migration_count  NUMBER;
    v_view_migration_count   NUMBER;
    v_mview_migration_count  NUMBER;
    v_object_type            VARCHAR2(50);
    v_object_name            VARCHAR2(50);
    v_owner                  VARCHAR2(50);
    v_aborted                VARCHAR2(3);
    v_old_table_count        NUMBER;
    v_old_view_count         NUMBER;
    v_old_mview_count        NUMBER;
    v_old_other_object_count NUMBER; -- Old count of other objects
    v_new_other_object_count NUMBER; -- New count of other objects
    v_new_table_count        NUMBER;
    v_new_view_count         NUMBER;
    v_new_mview_count        NUMBER;
BEGIN
    -- Step 0: Check if the new tablespace already exists
    SELECT COUNT(*)
    INTO v_empty_tablespace
    FROM dba_tablespaces
    WHERE tablespace_name = v_tablespace_name || '_01';

    IF v_empty_tablespace = 0 THEN
        -- Step 1 to 5: Get space information and create new tablespace
        DBMS_OUTPUT.PUT_LINE('New tablespace does not exist. Proceeding with space validation and creation of new tablespace ' || v_new_tablespace_name);
        
        -- Step 1: Get total, used, and free space of the tablespace
        DBMS_OUTPUT.PUT_LINE('Getting total, used, and free space for tablespace ' || v_tablespace_name);
        SELECT
            tablespace_name,
            total_space_mb,
            used_space_mb,
            free_space_mb
        INTO
            v_tablespace_name,
            v_total_space,
            v_used_space,
            v_free_space
        FROM (
            SELECT
                df.tablespace_name,
                ROUND(SUM(df.bytes) / 1024 / 1024, 2) AS total_space_mb,
                ROUND(SUM(df.bytes - NVL(fs.bytes, 0)) / 1024 / 1024, 2) AS used_space_mb,
                ROUND(SUM(NVL(fs.bytes, 0)) / 1024 / 1024, 2) AS free_space_mb
            FROM
                dba_data_files df
            LEFT JOIN (
                SELECT
                    tablespace_name,
                    file_id,
                    SUM(bytes) AS bytes
                FROM
                    dba_free_space
                GROUP BY
                    tablespace_name, file_id
            ) fs ON df.tablespace_name = fs.tablespace_name AND df.file_id = fs.file_id
            GROUP BY
                df.tablespace_name
        ) WHERE tablespace_name = v_tablespace_name;

        DBMS_OUTPUT.PUT_LINE('Total Space (MB): ' || v_total_space);
        DBMS_OUTPUT.PUT_LINE('Used Space (MB): ' || v_used_space);
        DBMS_OUTPUT.PUT_LINE('Free Space (MB): ' || v_free_space);

        -- Step 2: Calculate the size to allocate + 5%
        v_size_to_allocate := v_used_space * 1.2; -- Used space + 20%
        v_size_with_extra := v_size_to_allocate * 1.05; -- Additional 5% of the size to allocate
        DBMS_OUTPUT.PUT_LINE('Calculated size to allocate (MB): ' || v_size_to_allocate);
        DBMS_OUTPUT.PUT_LINE('Calculated size with extra 5% (MB): ' || v_size_with_extra);

        -- Step 3: Check the available space in the diskgroup
        DBMS_OUTPUT.PUT_LINE('Checking available space in the diskgroup: ' || v_diskgroup_destination);
        SELECT ROUND(SUM(free_mb), 2)
        INTO v_available_space
        FROM v$asm_diskgroup
        WHERE name = v_diskgroup_destination;

        DBMS_OUTPUT.PUT_LINE('Available space in diskgroup: ' || v_available_space);

        -- Step 4: Check if the available space is sufficient
        IF v_available_space >= v_size_with_extra THEN
            DBMS_OUTPUT.PUT_LINE('Sufficient space found, proceeding with creation of new bigfile tablespace.');

            -- Step 5: Create a new bigfile tablespace
            v_new_tablespace_name := v_tablespace_name || '_01';
            DBMS_OUTPUT.PUT_LINE('Creating new bigfile tablespace ' || v_new_tablespace_name);
            EXECUTE IMMEDIATE 'CREATE BIGFILE TABLESPACE ' || v_new_tablespace_name || ' DATAFILE ''+' || v_diskgroup_destination || ''' SIZE ' || v_size_to_allocate || 'M';
        ELSE
            DBMS_OUTPUT.PUT_LINE('Not enough space in the diskgroup: ' || v_diskgroup_destination);
            RAISE_APPLICATION_ERROR(-20003, 'Not enough space in the diskgroup. Migration failed.');
        END IF;
    ELSE
        -- Step 6: Skip creation and proceed with migration
        DBMS_OUTPUT.PUT_LINE('New tablespace '|| v_new_tablespace_name || ' already exists. Skipping creation and proceeding with migration.');
    END IF;

	-- Step 7: Count tables, views, and materialized views in the old tablespace
	DBMS_OUTPUT.PUT_LINE('Counting tables, views, and materialized views in the old tablespace:');
	SELECT COUNT(*) INTO v_old_table_count
	FROM dba_tables
	WHERE tablespace_name = v_tablespace_name;

	SELECT COUNT(*) INTO v_old_view_count
	FROM dba_views
	WHERE tablespace_name = v_tablespace_name;

	SELECT COUNT(*) INTO v_old_mview_count
	FROM dba_mviews
	WHERE tablespace_name = v_tablespace_name;

	DBMS_OUTPUT.PUT_LINE('Old Tables count: ' || v_old_table_count);
	DBMS_OUTPUT.PUT_LINE('Old Views count: ' || v_old_view_count);
	DBMS_OUTPUT.PUT_LINE('Old Materialized Views count: ' || v_old_mview_count);

	-- Step 8: Migrate all tables, views, and materialized views to the new tablespace
	DBMS_OUTPUT.PUT_LINE('Migrating tables, views, and materialized views to the new tablespace:');
	
	-- Migrate tables
	FOR rec IN (
		SELECT owner, table_name
		FROM dba_tables
		WHERE tablespace_name = v_tablespace_name
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE ' || rec.owner || '.' || rec.table_name || ' MOVE TABLESPACE ' || v_new_tablespace_name;
		DBMS_OUTPUT.PUT_LINE('Moved table ' || rec.owner || '.' || rec.table_name);
	END LOOP;

	-- Migrate views
	FOR view_rec IN (
		SELECT owner, view_name
		FROM dba_views
		WHERE tablespace_name = v_tablespace_name
	) LOOP
		EXECUTE IMMEDIATE 'ALTER VIEW ' || view_rec.owner || '.' || view_rec.view_name || ' MOVE TABLESPACE ' || v_new_tablespace_name;
		DBMS_OUTPUT.PUT_LINE('Moved view ' || view_rec.owner || '.' || view_rec.view_name);
	END LOOP;

	-- Migrate materialized views
	FOR mv_rec IN (
		SELECT owner, mview_name
		FROM dba_mviews
		WHERE tablespace_name = v_tablespace_name
	) LOOP
		EXECUTE IMMEDIATE 'ALTER MATERIALIZED VIEW ' || mv_rec.owner || '.' || mv_rec.mview_name || ' MOVE TABLESPACE ' || v_new_tablespace_name;
		DBMS_OUTPUT.PUT_LINE('Moved materialized view ' || mv_rec.owner || '.' || mv_rec.mview_name);
	END LOOP;

	-- Step 9: Count tables, views, and materialized views in the new tablespace
	DBMS_OUTPUT.PUT_LINE('Counting tables, views, and materialized views in the new tablespace:');
	SELECT COUNT(*) INTO v_new_table_count
	FROM dba_tables
	WHERE tablespace_name = v_new_tablespace_name;

	SELECT COUNT(*) INTO v_new_view_count
	FROM dba_views
	WHERE tablespace_name = v_new_tablespace_name;

	SELECT COUNT(*) INTO v_new_mview_count
	FROM dba_mviews
	WHERE tablespace_name = v_new_tablespace_name;

	DBMS_OUTPUT.PUT_LINE('New Tables count: ' || v_new_table_count);
	DBMS_OUTPUT.PUT_LINE('New Views count: ' || v_new_view_count);
	DBMS_OUTPUT.PUT_LINE('New Materialized Views count: ' || v_new_mview_count);

	-- Compare the counts of objects in the old and new tablespace
	IF v_old_table_count = v_new_table_count AND v_old_view_count = v_new_view_count AND v_old_mview_count = v_new_mview_count THEN
		DBMS_OUTPUT.PUT_LINE('Migration verification successful: All objects were migrated to the new tablespace.');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Warning: Some objects were not migrated properly.');
		DBMS_OUTPUT.PUT_LINE('Old Tables count: ' || v_old_table_count || ', New Tables count: ' || v_new_table_count);
		DBMS_OUTPUT.PUT_LINE('Old Views count: ' || v_old_view_count || ', New Views count: ' || v_new_view_count);
		DBMS_OUTPUT.PUT_LINE('Old Materialized Views count: ' || v_old_mview_count || ', New Materialized Views count: ' || v_new_mview_count);
	END IF;

		-- List the objects still in the old tablespace
		FOR obj IN (
			SELECT owner, object_name, object_type
			FROM dba_objects
			WHERE tablespace_name = v_tablespace_name
		) LOOP
			DBMS_OUTPUT.PUT_LINE('Owner: ' || obj.owner || ', Object: ' || obj.object_name || ', Type: ' || obj.object_type);
		END LOOP;

		-- Ask user to continue or abort
		DBMS_OUTPUT.PUT_LINE('Do you want to continue or abort? Type "c" to continue or "a" to abort:');
		v_aborted := 'c';  -- Change this value to simulate user input

		IF v_aborted = 'a' THEN
			DBMS_OUTPUT.PUT_LINE('Migration aborted. Exiting script.');
			RAISE_APPLICATION_ERROR(-20001, 'Migration aborted by user.');
		END IF;
	END IF;

	-- Step 10: Count and list other objects (indexes, LOBs, etc.)
	DBMS_OUTPUT.PUT_LINE('Counting other objects (indexes, LOBs, etc.) in the old tablespace...');
	SELECT COUNT(*) INTO v_old_other_object_count
	FROM dba_objects
	WHERE tablespace_name = v_tablespace_name
	AND object_type NOT IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW');

	DBMS_OUTPUT.PUT_LINE('Old Other Objects count: ' || v_old_other_object_count);

	-- Step 11: Check and migrate other objects in the tablespace
	DBMS_OUTPUT.PUT_LINE('Migrating other objects (indexes, LOBs, etc.) to the new tablespace:');
	FOR obj IN (
		SELECT owner, object_name, object_type
		FROM dba_objects
		WHERE tablespace_name = v_tablespace_name
	) LOOP
		IF obj.object_type = 'INDEX' THEN
			EXECUTE IMMEDIATE 'ALTER INDEX ' || obj.owner || '.' || obj.object_name || ' REBUILD TABLESPACE ' || v_new_tablespace_name;
			DBMS_OUTPUT.PUT_LINE('Rebuilt index ' || obj.owner || '.' || obj.object_name);
		ELSIF obj.object_type = 'LOB' THEN
			EXECUTE IMMEDIATE 'ALTER TABLE ' || obj.owner || '.' || obj.object_name || ' MOVE LOB (' || obj.object_name || ') STORE AS (TABLESPACE ' || v_new_tablespace_name || ')';
			DBMS_OUTPUT.PUT_LINE('Moved LOB ' || obj.owner || '.' || obj.object_name);
		ELSE
			DBMS_OUTPUT.PUT_LINE('Object ' || obj.owner || '.' || obj.object_name || ' type ' || obj.object_type || ' migration not handled explicitly.');
		END IF;
	END LOOP;

	-- Step 12: Count and list other objects (indexes, LOBs, etc.) in the new tablespace after migration
	DBMS_OUTPUT.PUT_LINE('Counting other objects (indexes, LOBs, etc.) in the new tablespace...');
	SELECT COUNT(*) INTO v_new_other_object_count
	FROM dba_objects
	WHERE tablespace_name = v_new_tablespace_name
	AND object_type NOT IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW');

	DBMS_OUTPUT.PUT_LINE('New Other Objects count: ' || v_new_other_object_count);

	IF v_old_other_object_count = v_new_other_object_count THEN
		DBMS_OUTPUT.PUT_LINE('Migration verification successful: All other objects were migrated to the new tablespace.');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Warning: Some other objects were not migrated properly.');
		DBMS_OUTPUT.PUT_LINE('Old Other Objects count: ' || v_old_other_object_count || ', New Other Objects count: ' || v_new_other_object_count);
	END IF;

	-- List the objects still in the old tablespace by type
	IF v_old_other_object_count > 0 THEN
		DBMS_OUTPUT.PUT_LINE('Listing remaining other objects (indexes, LOBs, etc.) in the old tablespace...');
		FOR obj IN (
			SELECT owner, object_name, object_type
			FROM dba_objects
			WHERE tablespace_name = v_tablespace_name
			AND object_type NOT IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
		) LOOP
			DBMS_OUTPUT.PUT_LINE('Owner: ' || obj.owner || ', Object: ' || obj.object_name || ', Type: ' || obj.object_type);
		END LOOP;
	END IF;

		-- Ask user to continue or abort
		DBMS_OUTPUT.PUT_LINE('Do you want to continue or abort? Type "c" to continue or "a" to abort:');
		v_aborted := 'c';  -- Change this value to simulate user input

		IF v_aborted = 'a' THEN
			DBMS_OUTPUT.PUT_LINE('Migration aborted. Exiting script.');
			RAISE_APPLICATION_ERROR(-20001, 'Migration aborted by user.');
		END IF;

	-- Step 13: Rebuild indexes online
	DBMS_OUTPUT.PUT_LINE('Rebuilding indexes online:');
	FOR idx IN (
		SELECT owner, index_name
		FROM dba_indexes
		WHERE tablespace_name = v_tablespace_name
	) LOOP
		-- Rebuild the index online in the new tablespace
		EXECUTE IMMEDIATE 'ALTER INDEX ' || idx.owner || '.' || idx.index_name || ' REBUILD ONLINE TABLESPACE ' || v_new_tablespace_name;
		DBMS_OUTPUT.PUT_LINE('Rebuilt index online ' || idx.owner || '.' || idx.index_name);
	END LOOP;

	-- Step 14: Check if all indexes were rebuilt in the new tablespace
	DBMS_OUTPUT.PUT_LINE('Verifying if all indexes were rebuilt:');
	DECLARE
		v_failed_index_count NUMBER := 0;
	BEGIN
		-- Loop through all indexes related to tables in the given tablespace
		FOR idx IN (
			SELECT i.owner, i.index_name
			FROM dba_indexes i
			JOIN dba_tables t
				ON i.table_owner = t.owner
				AND i.table_name = t.table_name
			WHERE t.tablespace_name = v_tablespace_name
		) LOOP
			BEGIN
				-- Rebuild index in the new tablespace, even if the index is in another tablespace
				EXECUTE IMMEDIATE 'ALTER INDEX ' || idx.owner || '.' || idx.index_name || ' REBUILD ONLINE;'
				DBMS_OUTPUT.PUT_LINE('Rebuilt index ' || idx.owner || '.' || idx.index_name || '.');
			EXCEPTION
				WHEN OTHERS THEN
					-- In case of failure, log the failed index
					DBMS_OUTPUT.PUT_LINE('Failed to rebuild index ' || idx.owner || '.' || idx.index_name || '.');
					v_failed_index_count := v_failed_index_count + 1;
			END;
		END LOOP;

		-- If any index failed to rebuild, abort the operation and list failed indexes
		IF v_failed_index_count > 0 THEN
			DBMS_OUTPUT.PUT_LINE('ERROR: Some indexes were not rebuilt properly.');
			RAISE_APPLICATION_ERROR(-20004, 'Some indexes were not rebuilt successfully.');
		ELSE
			DBMS_OUTPUT.PUT_LINE('All indexes were rebuilt successfully.');
		END IF;
	END;

	-- Step 15: Verify the old tablespace is empty
	DBMS_OUTPUT.PUT_LINE('Verifying if old tablespace is empty.');
	SELECT COUNT(*)
	INTO v_empty_tablespace
	FROM dba_segments
	WHERE tablespace_name = v_tablespace_name;

	IF v_empty_tablespace = 0 THEN
		-- Step 16: Drop the old tablespace
		DBMS_OUTPUT.PUT_LINE('Dropping old tablespace ' || v_tablespace_name);
		EXECUTE IMMEDIATE 'DROP TABLESPACE ' || v_tablespace_name || ' INCLUDING CONTENTS AND DATAFILES';

		 -- Step 17: Rename the new tablespace
		DBMS_OUTPUT.PUT_LINE('Renaming new tablespace to ' || v_tablespace_name);
		EXECUTE IMMEDIATE 'ALTER TABLESPACE ' || v_new_tablespace_name || ' RENAME TO ' || v_tablespace_name;
	ELSE
		DBMS_OUTPUT.PUT_LINE('Old tablespace is not empty. Migration failed.');
		RAISE_APPLICATION_ERROR(-20002, 'Old tablespace is not empty. Migration failed.');
	END IF;
END;
/