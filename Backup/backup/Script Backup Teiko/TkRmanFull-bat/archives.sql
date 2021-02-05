show all;
#run {
#allocate channel d2 type disk FORMAT 'G:\backup-full\arch_%d_%s_%p_%t.dbf' maxpiecesize #3000M;
#sql 'alter system archive log current';
#backup as compressed backupset tag 'Backup_Archivelog' archivelog like 'F:\ARCH\%' delete #input ;
#release channel d2;
#} 
exit



