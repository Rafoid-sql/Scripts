select NAME,TO_CHAR(LAST_CAPTURED,'DD/MM/YYYY HH24:MI:SS'),VALUE_STRING from v$sql_bind_capture
where sql_id = '8kw6z2g0uwp5s'