col pdb_id format 999
col pdb_name for a8
col file_id format 9999
col tablespace_name for a20
col file_name for a55
select p.pdb_id, p.pdb_name, d.file_id, d.tablespace_name, d.file_name
from dba_pdbs p, cdb_data_files d
where p.pdb_id = d.con_id
order by p.pdb_id