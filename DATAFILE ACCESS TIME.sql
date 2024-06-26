SET LINES 300
SET PAGESIZE 1000
COL NAME FOR A30
SELECT
	TS.NAME||':'||SUBSTR(DF.NAME,INSTR (DF.NAME,'/',-1)+1, LENGTH(DF.NAME)) "NAME",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,1,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI1",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,2,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI2",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,4,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI4",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,8,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI8",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,16,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI16",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,32,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI32",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,64,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI64",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,128,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI128",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,256,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI256",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,512,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI512",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,1024,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI1024",
	ROUND (100 * MAX(DECODE(FH.SINGLEBLKRDTIM_MILLI,2048,FH.SINGLEBLKRDS,0))/(SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY DF.NAME)),1) "MILLI2048",
	ROUND (0 * SUM(FH.SINGLEBLKRDS)/SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY TS.NAME),2) "TOT_BY_TBS",
	ROUND (0 * SUM(FH.SINGLEBLKRDS)/SUM(SUM(FH.SINGLEBLKRDS)) OVER(),2) "TOTAL_BY_SYS"
FROM
	V$FILE_HISTOGRAM FH
JOIN V$DATAFILE DF ON DF.FILE#=FH.FILE# AND DF.ENABLED='READ WRITE'
JOIN V$TABLESPACE TS ON TS.TS#=DF.TS#
GROUP BY  TS.NAME,DF.NAME
ORDER BY TS.NAME, 100 * SUM(FH.SINGLEBLKRDS)/SUM(SUM(FH.SINGLEBLKRDS)) OVER(PARTITION BY TS.NAME) DESC;