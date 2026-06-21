#!/usr/bin/env bash
# This script intelligently detects Single Instance vs. RAC environments to gather
# key system and Oracle Database information.
#
# - For Single Instance, it reports on the local server.
# - For RAC, it attempts to connect to all nodes to gather OS info from each,
#   while gathering cluster-wide database info from just one node.

# --- Spooling Configuration ---
HOSTNAME_VAR=$(hostname)
DATE_VAR=$(date +%Y-%m-%d)
SPOOL_FILE="/home/oracle/chklist_${HOSTNAME_VAR}_${DATE_VAR}.log"

# --- OS Information Gathering Functions ---

# Gathers OS-specific information for AIX systems.
gather_aix_info() {
    local node_hostname=$1
    local output_prefix=""
    # If a hostname is passed, it means we are running this for a specific node in a loop
    if [ -n "$node_hostname" ]; then
        output_prefix="${node_hostname}: "
    else
        node_hostname=$(hostname)
    fi

    echo "============================================="
    echo "    AIX System Information for ${node_hostname}"
    echo "============================================="

    echo ""
    echo "--- Server Uptime ---"
    uptime

    echo ""
    echo "--- Memory Usage ---"
    TOTAL_MEM=$(svmon -G -O unit=GB | grep memory | awk '{print $2}')
    USED_MEM=$(svmon -G -O unit=GB | grep "in use" | awk '{print $3}')
    echo "Total memory: $TOTAL_MEM GB"
    echo "Used memory: $USED_MEM GB"

    echo ""
    echo "--- Memory Installed ---"
    lsattr -El sys0 -a realmem

    echo ""
    echo "--- CPU Information ---"
    prtconf | grep -i "Processor Type"
    prtconf | grep -i "Number Of Processors"

    echo ""
    echo "--- Detailed CPUs Overview ---"
    echo "Processor Devices:"
    lsdev -C | grep Processor
    echo ""

    CPU_DETAILS_FILE="cpu_details_${node_hostname}_${DATE_VAR}.log"
    echo "Detailed CPU attributes for ${node_hostname} are in $CPU_DETAILS_FILE"
    echo ""

    {
        PROCESSOR_LIST=$(lsdev -C | grep Processor | awk '{print $1}')
        if [ -z "$PROCESSOR_LIST" ]; then
            echo "No processors found to detail with lsattr."
        else
            for proc_device in $PROCESSOR_LIST; do
                echo "--- Attributes for $proc_device ---"
                lsattr -El "$proc_device"
                echo ""
            done
        fi
        echo "--- Further CPU Details ---"
        prtconf | grep -i processor
        echo ""
        lscfg -vp | grep WAY
    } > "$CPU_DETAILS_FILE"
    echo ""
}

# Gathers OS-specific information for Linux systems.
gather_linux_info() {
    local node_hostname=$1
    if [ -z "$node_hostname" ]; then
        node_hostname=$(hostname)
    fi

    echo "============================================="
    echo "    Linux System Information for ${node_hostname}"
    echo "============================================="

    echo ""
    echo "--- Server Uptime ---"
    uptime

    echo ""
    echo "--- Memory Usage ---"
    grep -i --color=never ^mem /proc/meminfo

    echo ""
    echo "--- CPU Information ---"
    lscpu | grep -i "Model name"
    echo -n "Number Of Processors: "
    nproc --all
    echo ""
}


# --- Oracle Information Gathering Functions ---

run_memory_health_check() {
    echo ""
    echo "--- Oracle Memory Health Check ---"
    local MEMORY_HEALTH_SCRIPT="/nfs/infra/oracle/DTGTemplates/memory_health_all.sh"
    if [ ! -f "$MEMORY_HEALTH_SCRIPT" ]; then
        echo "Memory health script not found at $MEMORY_HEALTH_SCRIPT. Skipping."
        return
    fi
    MEMORY_HEALTH_OUTPUT=$(SQLFILE=/nfs/infra/oracle/DTGTemplates/conversion_capacity.sql $MEMORY_HEALTH_SCRIPT 2>/dev/null)
    GENERATED_FILE=$(echo "$MEMORY_HEALTH_OUTPUT" | grep "Report saved to:" | awk '{print $4}')
    if [ -n "$GENERATED_FILE" ] && [ -f "$GENERATED_FILE" ]; then
        echo "Appending contents from: $GENERATED_FILE"
        echo ""
        cat "$GENERATED_FILE"
        echo ""
        rm "$GENERATED_FILE"
        echo "Cleaned up temporary file: $GENERATED_FILE"
    else
        echo "Could not find or read the generated memory health report file."
        if [ -z "$GENERATED_FILE" ]; then
            echo "Reason: Failed to parse the filename from the memory script's output."
            echo "--- Raw output from memory_health_all.sh ---"
            if [ -n "$MEMORY_HEALTH_OUTPUT" ]; then echo "$MEMORY_HEALTH_OUTPUT"; else echo "[No output was captured.]"; fi
            echo "---------------------------------------------"
        else
            echo "Reason: The file '$GENERATED_FILE' was reported but not found on the filesystem."
        fi
    fi
    echo "--- End of Oracle Memory Health Check ---"
}

process_opatch_output() {
    local home_path=$1
    local home_type=$2
    if [ -x "$home_path/OPatch/opatch" ]; then
        echo "--- Checking $home_type Home: $home_path ---"
        "$home_path/OPatch/opatch" lsinventory -inactive | awk -v date_var="$DATE_VAR" '
        function print_summary_and_close() {
            if (patch_id != "") {
                print "   Details for this patch are in " detail_file;
                print "";
                close(detail_file);
                patch_id = "";
            }
        }
        /^Patch  / {
            print_summary_and_close();
            patch_id = $2;
            detail_file = "patch_" patch_id "_" date_var ".log";
        }
        patch_id != "" {
            print $0 > detail_file;
            if (/^Patch  / || /^Unique Patch ID:/ || /^Patch description:/ || /^   Created on/) {
                print $0;
            }
        }
        END { print_summary_and_close(); }'
    else
        echo "OPatch utility not found or not executable in $home_path"
    fi
}

check_rac_connectivity() {
    echo ""
    echo "--- RAC Node Connectivity Check ---"
    if [ -n "$GRID_HOME" ] && [ -x "$GRID_HOME/bin/olsnodes" ]; then
        ALL_NODES=$($GRID_HOME/bin/olsnodes)
        CURRENT_NODE=$(hostname)
        if [ $(echo "$ALL_NODES" | wc -l) -gt 1 ]; then
            echo "This is a RAC environment. Cluster nodes: $(echo $ALL_NODES | tr '\n' ' ')"
            echo "Current node: $CURRENT_NODE"
            echo ""
            for node in $ALL_NODES; do
                if [ "$node" != "$CURRENT_NODE" ]; then
                    echo "--- Checking connectivity to remote node: $node ---"
                    REMOTE_OUTPUT=$(ssh -o ConnectTimeout=5 "$node" "ps -ef | grep pmon | grep -v grep")
                    SSH_EXIT_CODE=$?
                    if [ $SSH_EXIT_CODE -eq 0 ]; then
                        echo "Connection successful."
                        if [ -n "$REMOTE_OUTPUT" ]; then
                            echo "Remote pmon process(es) found on $node:"
                            echo "$REMOTE_OUTPUT"
                        else
                            echo "No remote pmon process found on $node."
                        fi
                    else
                        echo "Connection failed to $node (exit code: $SSH_EXIT_CODE). Check SSH configuration and network."
                    fi
                    echo ""
                fi
            done
        else
            echo "This is a single-node cluster or Oracle Restart environment. No remote nodes to check."
        fi
    else
        echo "This is not a RAC environment (olsnodes not found or Grid Home not set). Skipping check."
    fi
}

# Gathers all Oracle-specific information.
gather_oracle_info() {
    ORACLE_SID=$(ps -ef | grep ora_pmon_ | grep -v grep | awk '{print $NF}' | sed 's/ora_pmon_//' | head -1)
    if [ -z "$ORACLE_SID" ]; then
        echo "Could not auto-detect ORACLE_SID. Please enter the ORACLE_SID to check:"
        read -r ORACLE_SID
        if [ -z "$ORACLE_SID" ]; then echo "ORACLE_SID cannot be empty. Exiting Oracle checks."; return; fi
    else
        echo "Auto-detected ORACLE_SID: $ORACLE_SID"
    fi

    export ORAENV_ASK=NO; export ORACLE_SID=$ORACLE_SID; . oraenv >/dev/null 2>&1; ORAENV_ASK=YES
    if [ -z "$ORACLE_HOME" ] || [ ! -d "$ORACLE_HOME" ]; then echo "Could not set environment for SID: $ORACLE_SID. Check /etc/oratab."; return; fi

    echo ""
    echo "============================================="
    echo "    Oracle Database Information"
    echo "============================================="

    echo ""
    echo "Database Uptime (all nodes):"
    sqlplus -s / as sysdba <<EOF
        SET LINES 200 PAGESIZE 200
		COL HOSTNAME FOR A20
		COL STARTUP FOR A20
		COL UPTIME FOR A30
        SELECT '('||inst_id||') '||host_name AS "HOSTNAME", TO_CHAR(startup_time, 'YYYY-MM-DD HH24:MI:SS') AS "STARTUP", FLOOR( (SYSDATE - startup_time) ) || ' days ' || FLOOR( MOD( (SYSDATE - startup_time) * 24, 24) ) || ' hours ' || FLOOR( MOD( (SYSDATE - startup_time) * 24 * 60, 60) ) || ' mins' AS UPTIME FROM gv\$instance ORDER BY host_name;
EOF
    echo ""
    echo "--- Oracle Installation Details ---"
    if [ -f /etc/oraInst.loc ]; then echo "/etc/oraInst.loc exist: Yes"; INVENTORY_LOC=$(grep inventory_loc /etc/oraInst.loc | cut -d= -f2); echo "OraInventory Location: $INVENTORY_LOC"; else echo "/etc/oraInst.loc exist: No"; fi
    GRID_HOME=$(grep -E '^\+ASM' /etc/oratab | head -1 | cut -d: -f2)
    if [ -n "$GRID_HOME" ] && [ -d "$GRID_HOME" ]; then echo "GRID_HOME Location: $GRID_HOME"; else echo "GRID_HOME Location: Not Found/Not Running"; fi
    echo "ORACLE_HOME Location: $ORACLE_HOME"
    echo ""
    echo "--- Oracle Home Free Space ---"
    OH_FREE_SPACE_KB=$(df -P "$ORACLE_HOME" | awk 'NR>1 {print $4}')
    OH_FREE_SPACE_GB=$(echo "scale=2; $OH_FREE_SPACE_KB / 1024 / 1024" | bc)
    echo "Oracle Home Free Space: ${OH_FREE_SPACE_GB} GB"
    IS_LOW_SPACE=$(awk -v free="$OH_FREE_SPACE_GB" 'BEGIN { exit !(free < 100) }')
    if [ $? -eq 0 ]; then SPACE_NEEDED=$(echo "scale=2; 100 - $OH_FREE_SPACE_GB" | bc); echo "Check Additional OracleHome space needed: Yes, needs at least ${SPACE_NEEDED} GB more."; else echo "Check Additional OracleHome space needed: No"; fi
    echo ""
    echo "--- Database Parameters ---"
    sqlplus -s / as sysdba <<EOF
        SET LINES 200 PAGES 200
		COL name FOR A30
		COL value FOR A60
		COL inst_id FOR 9999 HEADING "INST"
        SELECT inst_id, name, value FROM (SELECT p.inst_id, p.name, CASE WHEN p.name = 'sga_max_size' AND TO_NUMBER(p.value) > 0 THEN p.value || ' -- Must be 0' ELSE p.value END AS value FROM gv\$parameter p WHERE p.name IN ('compatible', 'sga_target', 'pga_target', 'db_name', 'db_unique_name', 'db_files', 'processes', 'sessions', 'audit_file_dest', 'audit_trail', 'service_names', 'sga_max_size') OR (p.name LIKE '%pool_size' AND p.name NOT IN ('memoptimize_pool_size', 'olap_page_pool_size')) OR p.name LIKE '%listener' OR p.name LIKE 'db_recovery_file_dest%' OR (p.name LIKE 'log_archive_dest_%' AND p.name NOT LIKE '%_state_%' AND p.value IS NOT NULL) UNION ALL SELECT NULL AS inst_id, 'Database Vault' AS name, CASE WHEN value = 'TRUE' THEN 'Yes' ELSE 'No' END AS value FROM gv\$option WHERE parameter = 'Oracle Database Vault' UNION ALL SELECT inst_id, 'DB version' AS name, version_full AS value FROM gv\$instance) ORDER BY name, inst_id;
EOF
    echo ""
    echo "--- GoldenGate / Streams Parameters ---"
    GG_USER_COUNT=$(sqlplus -s / as sysdba <<< "SET HEADING OFF FEEDBACK OFF; SELECT count(*) FROM dba_users WHERE username = 'GGSUSER';" | tr -d '[:space:]')
    if [[ "$GG_USER_COUNT" =~ ^[0-9]+$ ]] && [ "$GG_USER_COUNT" -gt 0 ]; then echo "GoldenGate user (GGSUSER) found. Checking stream parameters..."; sqlplus -s / as sysdba <<< "SET LINES 200; COL name FOR A30; COL value FOR A60; COL inst_id FOR 9999 HEADING \"INST\"; SELECT inst_id, name, value FROM gv\$parameter WHERE name LIKE '%streams%';"; else echo "No GG found"; fi
    echo ""
    echo "--- SGA_TARGET Check ---"
    BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
    SGA_STATUS=$(sqlplus -s / as sysdba <<EOF
        SET HEADING OFF FEEDBACK OFF SERVEROUTPUT ON
        DECLARE sga_target_val NUMBER; sga_target_mb NUMBER; pool_sum_val NUMBER; pool_sum_mb NUMBER; required_val NUMBER; required_mb NUMBER; increase_mb NUMBER;
        BEGIN SELECT TO_NUMBER(value) INTO sga_target_val FROM v\$parameter WHERE name = 'sga_target'; SELECT SUM(TO_NUMBER(value)) INTO pool_sum_val FROM v\$parameter WHERE name IN ('db_cache_size', 'java_pool_size', 'large_pool_size', 'shared_pool_size', 'streams_pool_size'); pool_sum_val := NVL(pool_sum_val, 0); pool_sum_mb := ROUND(pool_sum_val / 1024 / 1024); sga_target_mb := ROUND(sga_target_val / 1024 / 1024); required_val := pool_sum_val * 1.20; DBMS_OUTPUT.PUT_LINE('Sum of pools (db_cache + java + large + shared + streams): ' || pool_sum_mb || ' MB'); IF sga_target_val >= required_val THEN DBMS_OUTPUT.PUT_LINE('STATUS:SUFFICIENT'); ELSE required_mb := ROUND(required_val / 1024 / 1024); increase_mb := required_mb - sga_target_mb; DBMS_OUTPUT.PUT_LINE('STATUS:INSUFFICIENT:' || sga_target_mb || ':' || required_mb || ':' || increase_mb); END IF; END;
/
EOF
)
    echo "$SGA_STATUS" | grep -v "STATUS:"; STATUS_LINE=$(echo "$SGA_STATUS" | grep "STATUS:")
    if [[ "$STATUS_LINE" == "STATUS:SUFFICIENT" ]]; then echo -e "SGA_TARGET check (pools + 20%): ${BLUE}Size is sufficient${NC}"; elif [[ "$STATUS_LINE" == *"STATUS:INSUFFICIENT"* ]]; then CURRENT_SIZE=$(echo "$STATUS_LINE" | cut -d: -f3); NEEDED_SIZE=$(echo "$STATUS_LINE" | cut -d: -f4); INCREASE_BY=$(echo "$STATUS_LINE" | cut -d: -f5); echo -e "SGA_TARGET check (pools + 20%): ${RED}Size is not sufficient${NC}"; echo "Current size = ${CURRENT_SIZE} MB"; echo "Needed size = ${NEEDED_SIZE} MB"; echo "Needs to increase by ${INCREASE_BY} MB"; fi
    echo ""
    echo "--- Configuration File Locations ---"
    echo "DB password file location: $ORACLE_HOME/dbs/orapw${ORACLE_SID}"; echo "tnsnames.ora location: $ORACLE_HOME/network/admin/tnsnames.ora"; echo ""; echo "sqlnet.ora location: $ORACLE_HOME/network/admin/sqlnet.ora"; echo "--- sqlnet.ora params"; [ -f "$ORACLE_HOME/network/admin/sqlnet.ora" ] && cat "$ORACLE_HOME/network/admin/sqlnet.ora"; echo ""; echo "listener.ora location: $ORACLE_HOME/network/admin/listener.ora"; echo "--- listener.ora params"; [ -f "$ORACLE_HOME/network/admin/listener.ora" ] && cat "$ORACLE_HOME/network/admin/listener.ora"
    
    check_rac_connectivity
    
    echo ""
    echo "--- ASM Specific Checks ---"
    ASM_PMON_PROCESS=$(ps -ef | grep asm_pmon_ | grep -v grep)
    if [ -n "$ASM_PMON_PROCESS" ]; then echo "ASM instance is running on this server."; ASM_PWDFILE=$(srvctl config asm | grep "Password file" | awk '{print $3}'); echo "ASM Password file Location: $ASM_PWDFILE"; if [ -n "$ASM_PWDFILE" ] && [ -f "$ASM_PWDFILE" ]; then strings "$ASM_PWDFILE" | grep -q "CRS__USER_001" && echo "ASMPassword file has CRS__USER_001: Yes" || echo "ASMPassword file has CRS__USER_001: No"; fi; echo "ASM SPFILE: $(srvctl config asm | grep "Spfile" | awk '{print $2}')"; echo "AHF Upgrade: Check for AHF installation in $GRID_HOME/ahf"; [ -d "$GRID_HOME/ahf" ] && echo "AHF appears to be installed." || echo "AHF does not appear to be installed."; else echo "No running ASM instance found on this server. Skipping ASM checks."; fi
    echo ""
    echo "--- TDE (Transparent Data Encryption) Status ---"
    sqlplus -s / as sysdba <<EOF
        SET HEADING OFF FEEDBACK OFF
		SELECT 'Wallet Status: ' || status FROM v\$encryption_wallet; 
		SELECT 'Encrypted Tablespaces: ' || count(*) FROM dba_tablespaces WHERE encrypted = 'YES'; 
		SELECT 'Encrypted Columns: ' || count(*) FROM dba_encrypted_columns;
		SET HEADING ON FEEDBACK ON
EOF
    echo ""
    echo "--- OEM Agent Targets ---"
    ORIGINAL_ORACLE_HOME=$ORACLE_HOME; ORIGINAL_PATH=$PATH
    ORACLE_BASE_PREFIX="/$(echo "$ORACLE_BASE" | cut -d'/' -f2)"
    AGENT_SEARCH_PATH="${ORACLE_BASE_PREFIX}/static/app/oracle/agent13c/"
    LATEST_AGENT_HOME=$(ls -d "${AGENT_SEARCH_PATH}agent_13."* 2>/dev/null | sort -t. -k2,2n | tail -1)
    if [ -n "$LATEST_AGENT_HOME" ] && [ -d "$LATEST_AGENT_HOME" ] && [ -x "$LATEST_AGENT_HOME/bin/emctl" ]; then echo "OEM Agent Home found at: $LATEST_AGENT_HOME"; echo ""; export ORACLE_HOME=$LATEST_AGENT_HOME; export PATH=$ORACLE_HOME/bin:$PATH; "$ORACLE_HOME/bin/emctl" config agent listtargets; else echo "OEM Agent not found or emctl is not executable in the expected path."; fi
    export ORACLE_HOME=$ORIGINAL_ORACLE_HOME; export PATH=$ORIGINAL_PATH
    echo ""
    echo "--- Crontab for oracle user (active jobs only) ---"
    crontab -l 2>/dev/null | grep -Ev '^(#|$)' || echo "No active cron jobs found for oracle."
    echo ""
    echo "--- Oracle Gateway Check ---"
    GATEWAY_INFO=$(grep -i -E 'dg4|gateway' /etc/oratab)
    if [ -n "$GATEWAY_INFO" ]; then echo "Oracle Gateway installation found in /etc/oratab:"; echo "$GATEWAY_INFO"; else echo "No Oracle Gateway installation found in /etc/oratab."; fi
    echo ""
    echo "--- Inactive Oracle Patches ---"
    process_opatch_output "$ORACLE_HOME" "DB"
    if [ -n "$GRID_HOME" ] && [ "$GRID_HOME" != "$ORACLE_HOME" ]; then process_opatch_output "$GRID_HOME" "Grid"; fi
    echo ""
    echo "--- Database Object Counts ---"
    sqlplus -s / as sysdba <<EOF
        SET HEADING OFF FEEDBACK OFF 
		SELECT 'Invalid Objects: ' || count(*) FROM dba_objects WHERE status = 'INVALID';
		SELECT 'Bin$ Objects: ' || count(*) FROM dba_objects WHERE object_name LIKE 'BIN$%';
		SET HEADING ON FEEDBACK ON 
EOF
    run_memory_health_check
}


# --- Main Script Execution ---

# Redirect all subsequent output to the spool file, but tee to console for visibility
exec > >(tee "$SPOOL_FILE") 2>&1

echo "Gathering system information. Output is being saved to: $SPOOL_FILE"
echo ""

# --- Environment Detection ---
IS_RAC="false"
REMOTE_ACCESS="false"
ALL_NODES=""
CURRENT_NODE=$(hostname)
GRID_HOME=$(grep -E '^\+ASM' /etc/oratab | head -1 | cut -d: -f2)

if [ -n "$GRID_HOME" ] && [ -x "$GRID_HOME/bin/olsnodes" ]; then
    ALL_NODES=$($GRID_HOME/bin/olsnodes)
    if [ $(echo "$ALL_NODES" | wc -l) -gt 1 ]; then
        IS_RAC="true"
        # Test connectivity to the first remote node found
        REMOTE_NODE=$(echo "$ALL_NODES" | grep -v "^${CURRENT_NODE}$" | head -1)
        if [ -n "$REMOTE_NODE" ]; then
            ssh -o ConnectTimeout=5 "$REMOTE_NODE" "exit" 2>/dev/null
            if [ $? -eq 0 ]; then
                REMOTE_ACCESS="true"
            fi
        fi
    fi
fi

# --- Execution Logic ---
if [ "$IS_RAC" = "true" ]; then
    if [ "$REMOTE_ACCESS" = "true" ]; then
        echo "RAC Environment Detected with Remote Access. Gathering OS info from all nodes."
        echo "--------------------------------------------------------------------------"
        # Gather OS info from all nodes
        for node in $ALL_NODES; do
            OS_TYPE_REMOTE=$(ssh "$node" "uname")
            if [ "$OS_TYPE_REMOTE" = "AIX" ]; then
                # Export function and call it remotely
                ssh "$node" "$(typeset -f gather_aix_info); gather_aix_info '$node'"
            elif [ "$OS_TYPE_REMOTE" = "Linux" ]; then
                ssh "$node" "$(typeset -f gather_linux_info); gather_linux_info '$node'"
            fi
        done
        # Gather Oracle info once, locally
        gather_oracle_info
    else
        echo "RAC Environment Detected WITHOUT Remote Access. Reporting on local node ONLY."
        echo "--------------------------------------------------------------------------"
        # Run everything locally
        OS_TYPE=$(uname)
        if [ "$OS_TYPE" = "AIX" ]; then gather_aix_info; elif [ "$OS_TYPE" = "Linux" ]; then gather_linux_info; else echo "Unsupported OS: $OS_TYPE"; fi
        gather_oracle_info
    fi
else
    echo "Single Instance Environment Detected. Reporting on local node only."
    echo "--------------------------------------------------------------------------"
    # Run everything locally
    OS_TYPE=$(uname)
    if [ "$OS_TYPE" = "AIX" ]; then gather_aix_info; elif [ "$OS_TYPE" = "Linux" ]; then gather_linux_info; else echo "Unsupported OS: $OS_TYPE"; fi
    gather_oracle_info
fi

echo ""
echo "============================================="
echo "Report generation complete."
echo "============================================="