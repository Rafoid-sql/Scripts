
create or replace package pkg_null_blob  
as 
  function sf_null_blob return blob;   
end;  
/ 

create or replace package body pkg_null_blob   
as 
 function sf_null_blob return blob is  
  begin
    return utl_raw.cast_to_raw('Marcelo'); 
  end sf_null_blob; 
 end pkg_null_blob;
/


create or replace package pkg_null_clob  
as 
  function sf_null_clob (col_clob in clob)
  return clob;   
end;  
/ 

create or replace package body pkg_null_clob   
as 
 function sf_null_clob (col_clob in clob)
   return clob   
 is  
   clob_null clob := '1';   
 begin  
     return clob_null; 
  end; 
end; 
/

