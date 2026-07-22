#!/bin/bash
########################################################################################
#
# Name: /nfs/infra/oracle/scripts/tmo_dba/dba_menu.sh
# Function: Oracle DB Scripts menu script for deep dive into oracle database issues.
# Author: Chandan Acharya
# Usage: /nfs/infra/oracle/scripts/tmo_dba/dba_menu.sh
#
# # # # # # # # # # # # # # # # # Change History # # # # # # # # # # # # # # # # # # # #
# 11/10/2021 - Chandan Acharya - Initial version
# 02/09/2022 - Chandan Acharya - get sql_text for sql_id
# 03/05/2022 - Chandan Acharya - get sql_id bind variables
# 03/11/2022 - Chandan Acharya - get logons_hr
# 03/19/2022 - Chandan Acharya - 1.0 removed color from menu, added versioning
# 03/20/2022 - Chandan Acharya - 1.1 added dg,tps,wait_chain,enq:TX rowlock
# 03/27/2022 - Chandan Acharya - 1.2 added oem_menu, check_max_px_sqlid.sql, 
#                               temp_usage_when_ora1652.sql, uniq ORA- err in alert log
# 03/29/2022 - Chandan Acharya - 1.3 added last reboot time in os_menu(1)
#
########################################################################################
#-------------------
### Menu Program ###
#-------------------
clear
ver=1.3
MAGENTA='\033[35m'
STD='\033[0m'
echo -e "${MAGENTA}***********************************************************${STD}"
echo -e "${MAGENTA}******         Oracle DB Scripts Menu($ver)           ******${STD}"
echo -e "${MAGENTA}***********************************************************${STD}"

cd /nfs/infra/oracle/scripts/tmo_dba/

# Colors
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

# Color functions
greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }

# Exit function
fn_bye() { echo ; echo "Exiting $0"; echo ; exit 0; }
fn_fail() { echo "Wrong option." exit 1; }

# sqlplus connection
SQL="sqlplus -S /"
SQLSYS="sqlplus -S / as sysdba"
SQLASM="sqlplus -S / as sysasm"

# ORACLE_SID function
setorasid(){
if [ `ps -ef|grep ora_pmon |grep -v grep | wc -l` -eq 1 ]
then
        ORACLE_SID=`ps -ef|grep ora_pmon |grep -v grep | awk '{print $NF}' | awk -F_ '{print $3}'`
        ORAENV_ASK=NO
        . /usr/local/bin/oraenv > /dev/null 2>&1
elif [ `ps -ef|grep ora_pmon |grep -v grep | wc -l` -gt 1 ]
then
	read -p "Enter ORACLE_SID: " sid
	ORACLE_SID=${sid}
	ORAENV_ASK=NO
	. /usr/local/bin/oraenv > /dev/null 2>&1
else
        echo "DB Instance is not running!!!"
	exit
fi
}

######### Session Information Start #########
sess_menu(){

# Check active session
session_active(){
${SQL} <<EOF
@sess.sql
EOF
}

# Check session count by username
sess_by_user(){
${SQL} <<EOF
@sess_by_username.sql
EOF
}

# Check session count
sess_all(){
${SQL} <<EOF
@sess_all.sql
EOF
}

# Check session count by username,machine
sess_by_user_machine(){
${SQL} <<EOF
@sess_by_username_machine.sql
EOF
}

# Check SID
check_sid(){
yellowprint "NOTE: This is instance specific"
read -p "Enter SID: " sid
${SQL} <<EOF
@sidinfo.sql $sid
EOF
}

# Check transaction details for SID
transaction_info_for_sid(){
read -p "Enter SID: " sid
${SQL} <<EOF
@trans.sql $sid
EOF
}

# Check transaction details for SID rollback
transaction_info_for_sid_rollb(){
read -p "Enter SID: " sid
${SQL} <<EOF
@trans_rollb.sql $sid
EOF
}

# Check PID
check_pid(){
read -p "Enter Server Process ID: " spid
${SQL} <<EOF
@pid.sql $spid
EOF
}

# Check LongOps
check_longops(){
${SQL} <<EOF
@longops.sql
EOF
}

# Check processes history
check_proc_hist(){
read -p "Enter no. of hours to check(sysdate - x/24): " hours
${SQL} <<EOF
@proc_res_hist.sql $hours
EOF
}

# Check px session
check_px_sess(){
${SQL} <<EOF
@px_sess.sql
EOF
}

# Check blocking locks
check_blk_locks(){
${SQL} <<EOF
@locks.sql
EOF
}

# Check logons per hour
check_logons_hr(){
read -p "Enter no. of hours to check(sysdate - x/24): " hours
${SQL} <<EOF
@logons_hr.sql $hours
EOF
}

# Check Wait Chains
check_wait_chains(){
yellowprint "NOTE: This is instance specific"
${SQL} <<EOF
@check_wait_chain.sql
EOF
}

# Check enq:tx row lock contention, get row_id
enq_tx_row_lock(){
${SQL} <<EOF
@enq_tx_row_lock.sql
EOF
}

echo
echo `magentaprint "Database Session Information:"`
echo
echo -e "(1) Check Active Sessions \t (2) Session count by username    \t (3) Total session count           \t (4) Session count by username,machine"
echo -e "(5) Check SID             \t (6) Check v\$transaction for SID \t (7) Check rollback v\$transaction \t (8) Check SPID"
echo -e "(9) Check Longops         \t (10) Check processes usage hist  \t (11) Check parallel sessions      \t (12) Check Blocking Locks"
echo -e "(13) Check Logons per hr  \t (14) Check wait chains           \t (15) Check enq: TX - row lock"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        session_active
        sess_menu
        ;;
    2)
        sess_by_user
        sess_menu
        ;;
    3)
        sess_all
        sess_menu
        ;;
    4)
        sess_by_user_machine
        sess_menu
        ;;
    5)
        check_sid
        sess_menu
        ;;
    6)
        transaction_info_for_sid
        sess_menu
        ;;
    7)
        transaction_info_for_sid_rollb
        sess_menu
        ;;
    8)
        check_pid
        sess_menu
        ;;
    9)
        check_longops
        sess_menu
        ;;
    10)
        check_proc_hist
        sess_menu
        ;;
    11)
        check_px_sess
        sess_menu
        ;;
    12)
        check_blk_locks
        sess_menu
        ;;
    13)
        check_logons_hr
        sess_menu
        ;;
    14) 
        check_wait_chains
	sess_menu
	;;
    15)
        enq_tx_row_lock
        sess_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Session Information End #########

######### SQL_ID Information Start #########

sql_menu(){

# Check sql_id plan
check_sql_id(){
read -p "Enter sql_id: " sql_id
${SQL} <<EOF
@p.sql $sql_id
EOF
}

# Check sql_id details in cache
check_sql_id_cache(){
read -p "Enter sql_id: " sql_id
${SQL} <<EOF
@v_sql.sql $sql_id
EOF
}

# Check sql_id plan in AWR
check_sql_id_awr(){
read -p "Enter sql_id in AWR: " sql_id
${SQL} <<EOF
@pa.sql $sql_id
EOF
}

# Check sql_id plan history for last x hours
check_sql_id_awr_hist(){
read -p "Enter sql_id: " sql_id
read -p "Enter no. of hours to check(sysdate - x/24): " hours
${SQL} <<EOF
@awr_hist.sql $sql_id $hours
EOF
}

# Check sql_id plan change for last x days
check_sql_id_awr_plan_change(){
read -p "Enter sql_id: " sql_id
read -p "Enter no. of days to check(sysdate - x): " days
${SQL} <<EOF
@sql_hist.sql $sql_id $days
EOF
}

# Get sql_id text
get_sql_id_fulltext(){
read -p "Enter sql_id: " sql_id
${SQL} <<EOF
@sql_text.sql $sql_id
EOF
}

# Get sql_id bind value
get_sql_id_binds(){
read -p "Enter sql_id: " sql_id
${SQL} <<EOF
@binds.sql $sql_id
EOF
}

echo
echo `magentaprint "SQL_ID Information:"`
echo
echo -e "(1) Check sql_id plan(cursor cache) \t (2) Check sql_id details(cursor cache)"
echo -e "(3) Check sql_id details(AWR)       \t (4) Check sql_id plan(AWR)                \t (5) Check sql_id plan change history(AWR)"
echo -e "(6) Get sql_id fulltext(AWR)        \t (7) Get sql_id bind values(AWR)"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice
    case $choice in
    1)
        check_sql_id
        sql_menu
        ;;
    2)
        check_sql_id_cache
        sql_menu
        ;;
    3)
        check_sql_id_awr_hist
        sql_menu
        ;;
    4)
        check_sql_id_awr
        sql_menu
        ;;
    5)
	check_sql_id_awr_plan_change
        sql_menu
        ;;
    6)
	get_sql_id_fulltext
        sql_menu
        ;;
    7)
	get_sql_id_binds
        sql_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### SQL_ID Information End #########

######### AWR Information Start ##########

awr_menu(){

check_itl_wait_seg(){
read -p "Enter no. of hours to check(sysdate - x/24): " hours
${SQL} <<EOF
@get_itl_waits.sql $hours
EOF
}

# Check AWR Data for Sys Events
check_sys_event_hist(){
read -p "Enter System Event Name(e.g: log file sync): " event_name
read -p "Enter Start TimeStamp(e.g: 03-NOV-21 12.00.00.001 AM): " start_tstamp
read -p "Enter End   TimeStamp(e.g: 04-NOV-21 12.00.00.001 AM): " end_tstamp
${SQL} <<EOF
@sys_event_awr.sql "$event_name" "$start_tstamp" "$end_tstamp"
EOF
}

# Check sql_id with more than 16 parallels
check_max_px_sqlid(){
read -p "Enter No. of days to check: " num_days
${SQL} <<EOF
@check_max_px_sqlid.sql $num_days
EOF
}

echo
echo -e "(1) Check ITL Waits for Segments \t (2) Check System Event History  \t (3) sql_id with more than 16 parallels"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
	check_itl_wait_seg
        awr_menu
        ;;
    2)
        check_sys_event_hist
        awr_menu
        ;;
    3)
	check_max_px_sqlid
        awr_menu
        ;;
    4)
        awr_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### AWR Information End ##########

######### ASH Information Start ##########

ash_menu(){

# Check ASH top 10 event data for last x mins
ash_timebased(){
read -p "Enter no. of mins to check(sysdate - x/1440): " mins
${SQL} <<EOF
@ash_event_mins.sql $mins
EOF
}

# Check ASH top 10 event data for sql_id in last x mins
ash_for_sql_id(){
read -p "Enter SQL_ID: " sql_id
read -p "Enter no. of mins to check(sysdate - x/1440): " mins
${SQL} <<EOF
@ash_event_sqlid_mins.sql $sql_id $mins
EOF
}

# Check ASH for specific session_id
ash_for_sid(){
read -p "Enter SID: " sess_id
read -p "Enter no. of mins to check(sysdate - x/1440): " mins
${SQL} <<EOF
@ash_session_id.sql $sess_id $mins
EOF
}

# Check ASH for top 10 sql_id
ash_top10_sql_id(){
read -p "Enter no. of mins to check(sysdate - x/1440): " mins
${SQL} <<EOF
@ash_top10_sql_id.sql $mins
EOF
}

echo
echo `magentaprint "Active Session History Information:"`
echo
echo -e "(1) ash event data(time based) \t (2) ash data for sql_id \t (3)  ash data for session_id \t (4) ash data top 10 sql_id"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        ash_timebased
        ash_menu
        ;;
    2)
        ash_for_sql_id
        ash_menu
        ;;
    3)
        ash_for_sid
        ash_menu
        ;;
    4)
        ash_top10_sql_id
        ash_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### ASH Information End ##########

######### Object Information Start #########

obj_menu(){

# Check Object details
obj_dtl(){
read -p "Enter object name: " obj_name
${SQL} <<EOF
@obj.sql $obj_name
EOF
}

# Check Table info
tab_info(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@tab.sql $owner $tab_name
EOF
}

# Check Table Constraints
tab_cons(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@tab_cons.sql $owner $tab_name
EOF
}

# Check Table Ref Constraints
tab_ref_cons(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@tab_ref_c.sql $owner $tab_name
EOF
}

# Check Index details
index_dtl(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@index.sql $owner $tab_name
EOF
}

# Check Index Expression details
ind_exp_dtl(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@ind_exp.sql $owner $tab_name
EOF
}

# Check table partition details
tab_part_def(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@part_def.sql $owner $tab_name
EOF
}

# Check table partition size
tab_part_size(){
read -p "Enter table owner: " owner
read -p "Enter table name: " tab_name
${SQL} <<EOF
@part_size.sql $owner $tab_name
EOF
}

echo
echo `magentaprint "Database Object Information:"`
echo
echo -e "(1) Get Object details \t (2) Get Table info               \t (3) Get Table Constraints          \t (4) Get Ref Constraints"
echo -e "(5) Get index details  \t (6) Get Index expression details \t (7) Get table partition definition \t (8) Get table partition size"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        obj_dtl
        obj_menu
        ;;
    2)
        tab_info
        obj_menu
        ;;
    3)
        tab_cons
        obj_menu
        ;;
    4)
        tab_ref_cons
        obj_menu
        ;;
    5)
        index_dtl
        obj_menu
        ;;
    6)
        ind_exp_dtl
        obj_menu
        ;;
    7) 
	tab_part_def
	obj_menu
	;;
    8)
        tab_part_size
        obj_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Object Information End #########

######### Init parameters Start #########

init_menu(){

# Check UnderScore Init Parameters
underscore_init(){
read -p "Enter init parameter name: " param
${SQLSYS} <<EOF
@init_u.sql $param
EOF
}

# Check Init parameter value
init_param(){
read -p "Enter init parameter name: " param
${SQL} <<EOF
@init.sql $param
EOF
}

# Check Init parameter value history 2 days
init_param_hist(){
read -p "Enter init parameter name: " param
read -p "Enter no. of hours to check(sysdate - x/24): " hours
${SQL} <<EOF
@init_hist.sql $param $hours
EOF
}

echo
echo `magentaprint "Initialization Parameter Information:"`
echo
echo -e "(1) Check underscore parameter \t (2) Check init parameter value \t (3) Check init parameter history"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        underscore_init
        init_menu
        ;;
    2)
        init_param
        init_menu
        ;;
    3)
        init_param_hist
        init_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Init parameters End #########

######### Space Info Start #########

space_menu(){

# Check all tablespace details
check_all_tbsp(){
${SQL} <<EOF
@tbsp.sql
EOF
}

# Check Single tablespace
check_single_tbsp(){
read -p "Enter tablespace Name: " tbsp_name
${SQL} <<EOF
@tbsp_single.sql $tbsp_name
EOF
}

# Check flash recovery area
check_flash_rec_area(){
${SQL} <<EOF
@fra.sql
EOF
}

# Check temp tablespace usage
check_temp_usage(){
${SQL} <<EOF
@temp_usage.sql
EOF
}

# Check temp tablespace free
check_temp_free(){
${SQL} <<EOF
@temp_free.sql
EOF
}

# Check recyclebin space
check_recyclebin(){
${SQL} <<EOF
@recycle.sql
EOF
}

# Check datafile for tablespace
check_datafiles(){
read -p "Enter tablespace Name: " tbsp_name
${SQL} <<EOF
@datafiles.sql $tbsp_name
EOF
}

# Check db space
check_db_space(){
${SQL} <<EOF
@dbspace.sql
EOF
}

# Check which session used temp space when last ORA-1652 error occured
temp_usage_when_ora1652(){
echo
yellowprint "NOTE: ORA-1652 should be in the alert_$ORACLE_SID.log file!"

${SQL} <<EOF
@temp_usage_when_ora1652.sql
EOF
}

echo
echo `magentaprint "Database Space Information:"`
echo
echo -e "(1) Check all tbsp       \t (2) Check single tbsp      \t (3) Check flash recovery area \t (4) Check temp tbsp usage"
echo -e "(5) Check temp tbsp free \t (6) Check recyclebin space \t (7) Datafiles for tbsp        \t (8) Check DB Space"
echo -e "(9) Session causing ORA-1652"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        check_all_tbsp
        space_menu
        ;;
    2)
        check_single_tbsp
        space_menu
        ;;
    3)
        check_flash_rec_area
        space_menu
        ;;
    4)
        check_temp_usage
        space_menu
        ;;
    5)
        check_temp_free
        space_menu
        ;;
    6)
        check_recyclebin
        space_menu
        ;;
    7)
        check_datafiles
        space_menu
        ;;
    8)
        check_db_space
        space_menu
        ;;
    9)
        temp_usage_when_ora1652
        space_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Space Info End #########

######### Privileges Info Start ######### 

user_privs_menu(){

get_user_info(){
read -p "Enter Username: " user
${SQLSYS} <<EOF
@get_user_info.sql $user
EOF
}

get_user_privs(){
read -p "Enter Username: " user
${SQLSYS} <<EOF
@get_user_privs.sql $user
EOF
}

echo
echo `magentaprint "Database User and Privileges:"`
echo
echo -e "(1) Get User Info \t (2) Get User Privs"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        get_user_info
        user_privs_menu
        ;;
    2)
        get_user_privs
        user_privs_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Privileges Info End #########

######### DB Information Start #########

dbinfo_menu(){

get_dbinfo(){
${SQL} <<EOF
@get_dbinfo.sql
EOF
}

check_dbhealth(){
${SQL} <<EOF
@check_dbhealth.sql
@locks.sql
EOF
}

check_invalid_obj(){
${SQL} <<EOF
@check_invalid.sql
EOF
}

check_rman_backup(){
${SQL} <<EOF
@check_latest_bkp.sql
EOF
}

check_resource_limit(){
${SQL} <<EOF
@check_current_res_limit.sql
EOF
}

check_tps(){
${SQL} <<EOF
@tps.sql
EOF
}

echo
echo `magentaprint "Database Information:"`
echo
echo -e "(1) Get DB and Instance Info \t (2) Perform Health Check \t (3) Check Invalid Objects \t (4) Check latest RMAN Backup"
echo -e "(5) Current Resource Limits  \t (6) Check TPS for DB"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        get_dbinfo
        dbinfo_menu
        ;;
    2)
        check_dbhealth
        dbinfo_menu
        ;;
    3)
        check_invalid_obj
        dbinfo_menu
        ;;
    4)
	check_rman_backup
	dbinfo_menu
	;;
    5) 
	check_resource_limit
	dbinfo_menu
	;;
    6)
        check_tps
	dbinfo_menu
	;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### DB Information End #########

######### Troubleshooting Scripts Starts #########

trouble_menu(){

check_arch_gen(){
read -p "Enter No. of days to check: " num_days
${SQL} <<EOF
@check_arch_gen.sql $num_days
EOF
}

find_no_idx_fk(){
read -p "Enter Schema Name to check: " owner
${SQL} <<EOF
@fk_no_idx.sql $owner
EOF
}

find_idx_degree(){
read -p "Enter Schema Name to check: " owner
${SQL} <<EOF
@degree_i.sql $owner
EOF
}

who_locked_user(){
${SQL} <<EOF
prompt Checking for ORA-1017 in last 8 hours...
@who_locked_user.sql
EOF
}

echo
echo `magentaprint "Troubleshooting Scripts:"`
echo
echo -e "(1) Check Archive Log Generation \t (2) Find FK with no indexes           \t (3) Find index with higher degree"
echo -e "(4) Check alert_log(last 30 lines)\t (5) Check alert_log(uniq ORA- error) \t (6) Who Locked User"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        check_arch_gen
        trouble_menu
        ;;
    2)
	find_no_idx_fk
        trouble_menu
        ;;
    3)
        find_idx_degree
        trouble_menu
        ;;
    4)
        check_alert_log.sh 30
        trouble_menu
        ;;
    5)
        check_alert_all_errors.sh
        trouble_menu
        ;;
    6)
	who_locked_user
        trouble_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Troubleshooting Scripts End #########

######### Automatic Storage Management(ASM) Starts #########
asm_menu(){

if [ `ps -ef|grep asm_pmon |grep -v grep | wc -l` -eq 1 ]
then
	ORACLE_SID=`ps -ef|grep asm_pmon |grep -v grep | awk '{print $NF}' | awk -F_ '{print $3}'`
	ORAENV_ASK=NO
	. /usr/local/bin/oraenv > /dev/null 2>&1
else
	echo "ASM Instance is not running!!!"
	main_menu
fi

get_asm_diskgroup(){
${SQLASM} <<EOF
@get_asm_dg.sql
EOF
}

get_asm_disks(){
${SQLASM} <<EOF
@get_asm_disks.sql
EOF
}

check_asm_rebalance(){
${SQLASM} <<EOF
@check_asm_rebalance.sql
EOF
}

echo
echo `magentaprint "Automatic Storage Management(ASM) Information:"`
echo
echo -e "(1) Get diskgroup Info \t (2) Get all disk Info \t (3) Check ASM Rebalance status \t (4) Check interface - oifcfg getif"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        get_asm_diskgroup
        asm_menu
        ;;
    2)
        get_asm_disks
        asm_menu
        ;;
    3)
        check_asm_rebalance
        asm_menu
        ;;
    4)  $ORACLE_HOME/bin/oifcfg getif
        asm_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Automatic Storage Management(ASM) End #########

######### Oracle Clusterware Menu Starts #########
crs_menu(){

if [ `ps -ef|grep crsd.bin |grep -v grep | wc -l` -eq 1 ]
then
        ORACLE_SID=grid
        ORAENV_ASK=NO
        . /usr/local/bin/oraenv > /dev/null 2>&1
else
        echo "Oracle Clusterware is not running!!!"
        main_menu
fi

check_crs_version(){
$ORACLE_HOME/bin/crsctl query crs releaseversion
}

check_crs_status(){
$ORACLE_HOME/bin/crsctl check cluster -all
}

check_crs_res_stat(){
$ORACLE_HOME/bin/crsctl stat res -t 
}

check_crs_res_stat_init(){
$ORACLE_HOME/bin/crsctl stat res -t -init
}


echo
echo `magentaprint "Oracle Clusterware Information:"`
echo
echo -e "(1) Check errors in CRS logs \t (2) Check CRS version \t (3) Check CRS cluster status  \t (4) Check CRS resource status"
echo -e "(5) Check CRS resource status init"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        check_crs_errors.sh
        crs_menu
        ;;
    2)
        check_crs_version
        crs_menu
        ;;
    3)
        check_crs_status
        crs_menu
        ;;
    4)
        check_crs_res_stat
        crs_menu
        ;;
    5)
        check_crs_res_stat_init
        crs_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### Oracle Clusterware Menu Ends #########

######### OS Menu Starts #########

os_menu()
{

check_os_details(){
if [ `uname` = 'AIX' ]
then
 echo
 echo "OS Version                                 :" `oslevel -s`
 lparstat -i |egrep 'Type|Mode|Entitled Capacity|Online Virtual CPUs|Maximum Virtual CPUs|Online Memory|Maximum Memory|Target Memory Expansion Factor|Target Memory Expansion Size'
 echo "Swap Space                                 :" `lsps -a | grep -v Page | awk '{print $4}'`
 echo "Available Memory(MB)                       :" `svmon  -O summary=basic,unit=auto |grep ^memory | awk '{print $(NF-1)}'`
 echo "Swap Utilization(%)                        :" `lsps -s | grep -v Total| awk '{print $NF}'`
 echo "Last Reboot Time			   :" `who -b`
fi

if [ `uname` = 'Linux' ]
then
 echo
 echo "OS Release		:" `cat /etc/redhat-release`
 echo "Allocated CPUs		:" `lscpu | grep ^CPU\(s\) | awk '{print $NF}'`
 echo "Allocated Memory(MB)	:" `free -m | grep ^Mem | awk '{print $2}'`
 echo "Available Memory(MB)	:" `free -m | grep ^Mem | awk '{print $NF}'`
 echo "Allocated Swap Space(MB) :" `free -m |grep ^Swap | awk '{print $2}'`
 echo "Available Swap Space(MB) :" `free -m |grep ^Swap | awk '{print $NF}'`
 echo "Last Reboot Time	 :" `who -b`
 echo "CPU Utilization		:"
 echo
 sar -u 1 2 |egrep 'CPU|Average'
fi
}

check_hosts_file(){
echo "Uncommented lines in /etc/hosts file..."
cat /etc/hosts | grep -v ^#
}

check_oratab_file(){
echo "Uncommented lines in /etc/oratab file..."
cat /etc/oratab | grep -v ^#
}

echo
echo `magentaprint "OS Information:"`
echo
echo -e "(1) Check OS details \t (2) Check /etc/hosts file \t (3) Check /etc/oratab file \t (4) AIX topas"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        check_os_details
        os_menu
        ;;
    2)
        check_hosts_file
        os_menu
        ;;
    3)
        check_oratab_file
        os_menu
        ;;
    4)
        topas
        os_menu
        ;;
    5)
        os_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}


######### OS Menu Ends #########

######### DataGuard Information Start #########

dg_menu(){

get_dgconfig_primary(){
${SQL} <<EOF
@get_dgconfig_primary.sql
EOF
}

get_dgconfig_standby(){
${SQL} <<EOF
@get_dgconfig_standby.sql
EOF
}

check_dg_lag(){
${SQL} <<EOF
@check_dg_lag.sql
EOF
}

echo
echo `magentaprint "Database Information:"`
echo
echo -e "(1) Get DG Config Primary \t (2) Get DG Config Standby \t (3) Check DG Lag"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        get_dgconfig_primary
        dg_menu
        ;;
    2)
        get_dgconfig_standby
        dg_menu
        ;;
    3)
        check_dg_lag
        dg_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### DataGuard Information End #########

######### OEM Repository Info Start #########

oem_menu(){

echo
yellowprint "NOTE: This option should be executed on OEM Repository Database Server ONLY!!"

oem_target_avail(){
${SQLSYS} <<EOF
@oem_target_avail.sql
EOF
}

oem_target_blackout(){
${SQLSYS} <<EOF
@oem_blackout_status.sql
EOF
}

echo
echo `magentaprint "OEM Repository Info:"`
echo
echo -e "(1) Target Avaibility Report \t (2) Targets in Blackout Mode Report"
echo
echo -e `cyanprint "(b) Back to Main Menu \t (x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
    1)
        oem_target_avail
        oem_menu
        ;;
    2)
        oem_target_blackout
        oem_menu
        ;;
    b)
        main_menu
        ;;
    x)
        fn_bye
        ;;
    *)
        fn_fail
        ;;
    esac
}

######### OEM Repository Info End #########

#-------------------
### Main Program ###
#-------------------
email=TEQDatabaseEngineering-Oracle-Prod@T-Mobile.com

main_menu(){
while :
do
echo
echo `magentaprint "Main Menu: "`
echo
echo -e "(0) DB Info \t (1) Session Info \t (2) Object Info \t (3) SQL Info            \t (4) Init Parameter Info"
echo -e "(5) AWR Info \t (6) ASH Info    \t (7) Space Info  \t (8) User and Privs Info \t (9) Troubleshooting"
echo -e "(10) ASM Info \t (11) CRS Info  \t (12) OS Info    \t (13) DataGuard Info     \t (14) OEM Info"
echo
echo -e `cyanprint "(x) Exit"`
echo
echo -n "Choose an option: "
read choice

case $choice in
	0) 
		setorasid
		dbinfo_menu ;;
        1)
		setorasid
                sess_menu ;;
        2)
		setorasid
                obj_menu ;;
        3)
		setorasid
                sql_menu ;;
        4)
		setorasid
                init_menu ;;
        5)
		setorasid
                awr_menu ;;
        6)
		setorasid
                ash_menu ;;
	7) 
		setorasid
		space_menu ;;
	8)
		setorasid
		user_privs_menu ;;
        9)
		setorasid
                trouble_menu ;;
	10)	
		asm_menu ;;
        11)
                crs_menu ;;
        12) 
                os_menu ;;
	13)
		setorasid
		dg_menu ;;
	14) 
		setorasid
		oem_menu ;;
        x)
                fn_bye ;;
        *)
                echo "Invalid Choice, Please try again..." ;;
esac
done
}

main_menu
