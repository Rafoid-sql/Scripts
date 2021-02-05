show all;
#run{
#configure retention policy to redundancy 1;
#allocate channel d1 type disk FORMAT 'G:\backup-full\full_%d_%s_%p_%t.dbf' maxpiecesize 5000M;
#backup as compressed backupset tag 'Backup_DatabaseFull' database;
#release channel d1;
#sql 'alter system archive log current';
#allocate channel d2 type disk FORMAT 'G:\backup-full\arch_%d_%s_%p_%t.dbf' maxpiecesize 5000M;
#backup as compressed backupset tag 'Backup_Archivelog' archivelog like 'F:\ARCH\%' delete input;
#release channel d2;
#allocate channel d3 type disk FORMAT 'G:\backup-full\/cf_%d_%s_%p_%t.ctl' maxpiecesize 1000M;
#backup as compressed backupset tag 'BackupCurrentControlfile' current controlfile;
#release channel d3;
#change archivelog like 'F:\ARCH_STDY\%' uncatalog;
#delete noprompt obsolete device type disk;
#}
exit