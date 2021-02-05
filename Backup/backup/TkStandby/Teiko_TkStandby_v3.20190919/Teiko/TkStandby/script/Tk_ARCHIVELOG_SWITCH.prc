CREATE OR REPLACE PROCEDURE TK_ARCHIVELOG_SWITCH  as
begin
      /* Executa log switch */
         execute immediate ('alter system switch logfile');
         dbms_output.put_line('Log switch OK');
      EXCEPTION
          WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001, 'ERRO TK_ARCHIVELOG_SWITCH='||sqlerrm);
end;
/

