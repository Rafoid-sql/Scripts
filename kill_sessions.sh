#!/usr/bin/env bash
# ==============================================================================
# Script: kill_sessions_rac.sh
# Target: AIX / Oracle Database (Single Instance or RAC)
# Desc  : Interactive script for safe assembly, auditing, and execution of
#         ALTER SYSTEM DISCONNECT SESSION commands.
# ==============================================================================

# Global control variables
FILTER_CLAUSE=""
TMP_SQL_GEN="/tmp/gen_kill_${$}.sql"
TMP_SQL_EXEC="/tmp/exec_kill_${$}.sql"
TMP_OUT_CMD="/tmp/out_kill_${$}.log"

# Automatic cleanup of temporary files on exit (POSIX/AIX trap)
trap 'rm -f "$TMP_SQL_GEN" "$TMP_SQL_EXEC" "$TMP_OUT_CMD"' EXIT HUP INT TERM

clear
echo "================================================================="
echo " DISCONNECT SESSION GENERATOR AND EXECUTOR (ORACLE DATABASE)     "
echo "================================================================="
echo ""
echo "Select the filtering method:"
echo "  1) Filter by SID,SERIAL#"
echo "  2) Filter by SQL_ID"
echo "  3) Other Filters (USERNAME, OSUSER, MACHINE, STATUS)"
echo "  4) Exit"
echo ""
read -r -p "Option [1-4]: " MAIN_OPT

case "$MAIN_OPT" in
    1)
        echo ""
        echo "Enter the SID,SERIAL# pairs separated by space."
        echo "Example: 687,46690 1491,63650"
        read -r -p "Pairs: " INPUT_PAIRS
        
        PAIRS_FORMATTED=""
        for PAIR in $INPUT_PAIRS; do
            # Basic validation to check if it contains a comma separating the two values
            if [[ "$PAIR" == *","* ]]; sid="${PAIR%%,*}"; ser="${PAIR##*,}"; then
                if [ -n "$PAIRS_FORMATTED" ]; then
                    PAIRS_FORMATTED="${PAIRS_FORMATTED}, (${sid}, ${ser})"
                else
                    PAIRS_FORMATTED="(${sid}, ${ser})"
                fi
            else
                echo "[ERROR] Invalid format for pair: '$PAIR'. Use SID,SERIAL#."
                exit 1
            fi
        done
        
        if [ -z "$PAIRS_FORMATTED" ]; then
            echo "[ERROR] No valid pair provided."
            exit 1
        fi
        
        FILTER_CLAUSE="AND (SID, SERIAL#) IN (${PAIRS_FORMATTED})"
        ;;
        
    2)
        echo ""
        echo "Enter the SQL_ID(s) separated by comma."
        echo "Example: 6q352kuy53kcd,abcd1234efgh"
        read -r -p "SQL_ID(s): " INPUT_SQLIDS
        
        # Replace commas with ',' and wrap with single quotes using native expansion
        # Remove whitespace the user might have typed
        CLEAN_SQLIDS=$(echo "$INPUT_SQLIDS" | tr -d ' ')
        SQLIDS_FORMATTED=$(echo "$CLEAN_SQLIDS" | sed "s/,/','/g")
        
        FILTER_CLAUSE="AND SQL_ID IN ('${SQLIDS_FORMATTED}')"
        ;;
        
    3)
        echo ""
        echo "Submenu - Choose the desired filters (separate by comma for multiple):"
        echo "  1) USERNAME"
        echo "  2) OSUSER"
        echo "  3) MACHINE"
        echo "  4) STATUS"
        echo ""
        read -r -p "Options [ex: 1,3,4]: " SUB_OPTS
        
        # Clean whitespace and separate by comma
        SUB_OPTS_CLEAN=$(echo "$SUB_OPTS" | tr -d ' ' | tr ',' ' ')
        
        for OPT in $SUB_OPTS_CLEAN; do
            case "$OPT" in
                1)
                    read -r -p "Enter USERNAME(s) [separated by comma]: " VALS
                    VALS_FMT=$(echo "$VALS" | tr -d ' ' | sed "s/,/','/g")
                    FILTER_CLAUSE="${FILTER_CLAUSE} AND USERNAME IN ('${VALS_FMT}')"
                    ;;
                2)
                    read -r -p "Enter OSUSER(s) [separated by comma]: " VALS
                    VALS_FMT=$(echo "$VALS" | tr -d ' ' | sed "s/,/','/g")
                    FILTER_CLAUSE="${FILTER_CLAUSE} AND OSUSER IN ('${VALS_FMT}')"
                    ;;
                3)
                    read -r -p "Enter MACHINE(s) [separated by comma]: " VALS
                    VALS_FMT=$(echo "$VALS" | tr -d ' ' | sed "s/,/','/g")
                    FILTER_CLAUSE="${FILTER_CLAUSE} AND MACHINE IN ('${VALS_FMT}')"
                    ;;
                4)
                    read -r -p "Enter STATUS [ex: INACTIVE,ACTIVE - separated by comma]: " VALS
                    VALS_FMT=$(echo "$VALS" | tr -d ' ' | sed "s/,/','/g")
                    FILTER_CLAUSE="${FILTER_CLAUSE} AND STATUS IN ('${VALS_FMT}')"
                    ;;
                *)
                    echo "[WARNING] Option ignored in submenu: $OPT"
                    ;;
            esac
        done
        
        if [ -z "$FILTER_CLAUSE" ]; then
            echo "[ERROR] No additional filter was configured."
            exit 1
        fi
        ;;
        
    4)
        echo "Exiting script. No actions taken."
        exit 0
        ;;
        
    *)
        echo "[ERROR] Invalid option '$MAIN_OPT'. Aborting."
        exit 1
        ;;
esac

# ==============================================================================
# PHASE 1: QUERY GENERATION AND DATABASE VALIDATION
# ==============================================================================

echo ""
echo "-----------------------------------------------------------------"
echo "Checking database topology (RAC vs Single Instance)..."
echo "-----------------------------------------------------------------"

# Check cluster_database parameter to determine syntax and view
IS_RAC=$(sqlplus -s / as sysdba << EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT VALUE FROM V\$PARAMETER WHERE NAME = 'cluster_database';
EXIT;
EOF
)
IS_RAC=$(echo "$IS_RAC" | tr -d ' \r\n')

if [ "$IS_RAC" = "TRUE" ] || [ "$IS_RAC" = "true" ]; then
    VIEW_DISPLAY="GV\$SESSION"
    echo "Topology detected: RAC (Using GV\$SESSION and @INST_ID syntax)"
    
    cat << EOF > "$TMP_SQL_GEN"
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET ECHO OFF
SELECT 'ALTER SYSTEM DISCONNECT SESSION '''||SID||','||SERIAL#||',@'||INST_ID||''' IMMEDIATE;'
FROM GV\$SESSION
WHERE PROCESS NOT LIKE ('%BACKGROUND')
${FILTER_CLAUSE}
ORDER BY 1;
EXIT;
EOF
else
    VIEW_DISPLAY="V\$SESSION"
    echo "Topology detected: Single Instance (Using V\$SESSION and standard syntax)"
    
    cat << EOF > "$TMP_SQL_GEN"
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SET ECHO OFF
SELECT 'ALTER SYSTEM DISCONNECT SESSION '''||SID||','||SERIAL#||''' IMMEDIATE;'
FROM V\$SESSION
WHERE PROCESS NOT LIKE ('%BACKGROUND')
${FILTER_CLAUSE}
ORDER BY 1;
EXIT;
EOF
fi

echo ""
echo "-----------------------------------------------------------------"
echo "Querying ${VIEW_DISPLAY} in Oracle to generate commands..."
echo "-----------------------------------------------------------------"

# Execute sqlplus silently capturing only the output of generated commands
sqlplus -s / as sysdba @"$TMP_SQL_GEN" | grep "^ALTER SYSTEM" > "$TMP_OUT_CMD"

# Check if any command was returned
if [ ! -s "$TMP_OUT_CMD" ]; then
    echo "[WARNING] No sessions found in ${VIEW_DISPLAY} for the specified filters:"
    echo "          WHERE PROCESS NOT LIKE ('%BACKGROUND') ${FILTER_CLAUSE}"
    exit 0
fi

# ==============================================================================
# PHASE 2: AUDITING AND ON-SCREEN REVIEW
# ==============================================================================

echo ""
echo "Generated commands ready for execution:"
echo "================================================================="
cat "$TMP_OUT_CMD"
echo "================================================================="
TOTAL_CMDS=$(wc -l < "$TMP_OUT_CMD" | tr -d ' ')
echo "Total impacted sessions: ${TOTAL_CMDS}"
echo ""

read -r -p "Do you want to EXECUTE these commands in the database now? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Operation cancelled by the user. No sessions were terminated."
    exit 0
fi

# ==============================================================================
# PHASE 3: EXECUTION IN SEPARATE SESSION
# ==============================================================================

echo ""
echo "Executing commands in Oracle Database..."

# Assemble the final execution SQL file
cat << EOF > "$TMP_SQL_EXEC"
SET SERVEROUTPUT ON
SET FEEDBACK OFF
SET ECHO OFF
EOF

# Append generated commands to the execution file, adding block exception handling
# To prevent ORA-00030/ORA-00031 from aborting execution or generating noise
while IFS= read -r CMD; do
    # Remove trailing semicolon
    CLEAN_CMD="${CMD%;}"
    # Escape single quotes by doubling them for the EXECUTE IMMEDIATE string literal
    ESCAPED_CMD="${CLEAN_CMD//"'"/"''"}"
    # Extract session identifier (SID,SERIAL#,INST_ID) from within single quotes
    SESS_ID="${CMD#*\'}"
    SESS_ID="${SESS_ID%%\'*}"
    
    echo "BEGIN" >> "$TMP_SQL_EXEC"
    echo "  DBMS_OUTPUT.PUT_LINE('Session: ${SESS_ID}');" >> "$TMP_SQL_EXEC"
    echo "  EXECUTE IMMEDIATE '${ESCAPED_CMD}';" >> "$TMP_SQL_EXEC"
    echo "  DBMS_OUTPUT.PUT_LINE('Result : Session disconnected successfully');" >> "$TMP_SQL_EXEC"
    echo "  DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------');" >> "$TMP_SQL_EXEC"
    echo "EXCEPTION" >> "$TMP_SQL_EXEC"
    echo "  WHEN OTHERS THEN" >> "$TMP_SQL_EXEC"
    echo "    IF SQLCODE = -30 THEN" >> "$TMP_SQL_EXEC"
    echo "      DBMS_OUTPUT.PUT_LINE('Result : Session no longer exists (ORA-00030)');" >> "$TMP_SQL_EXEC"
    echo "    ELSIF SQLCODE = -31 THEN" >> "$TMP_SQL_EXEC"
    echo "      DBMS_OUTPUT.PUT_LINE('Result : Session marked for kill');" >> "$TMP_SQL_EXEC"
    echo "    ELSE" >> "$TMP_SQL_EXEC"
    echo "      DBMS_OUTPUT.PUT_LINE('Result : ERROR - ' || SQLERRM);" >> "$TMP_SQL_EXEC"
    echo "    END IF;" >> "$TMP_SQL_EXEC"
    echo "    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------');" >> "$TMP_SQL_EXEC"
    echo "END;" >> "$TMP_SQL_EXEC"
    echo "/" >> "$TMP_SQL_EXEC"
done < "$TMP_OUT_CMD"

echo "EXIT;" >> "$TMP_SQL_EXEC"

# Execute the final destruction block
sqlplus -s / as sysdba @"$TMP_SQL_EXEC"

echo ""
echo "Process completed successfully."