WITH search_data AS (
    SELECT 
        'Функция/Процедура' AS object_type,
        p.proname AS object_name,
        n.nspname AS schema_name,
        pg_get_functiondef(p.oid) AS definition
    FROM 
        pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE 
        p.prokind IN ('f', 'p')
    
    UNION ALL
    
    SELECT 
        'Триггер',
        t.tgname,
        n.nspname,
        pg_get_triggerdef(t.oid)
    FROM 
        pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE 
        NOT t.tgisinternal
    
    UNION ALL
    
    SELECT 
        'Представление',
        c.relname,
        n.nspname,
        pg_get_viewdef(c.oid)
    FROM 
        pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE 
        c.relkind = 'v'
    
    UNION ALL
    
    SELECT 
        'Материализованное представление',
        c.relname,
        n.nspname,
        pg_get_viewdef(c.oid)
    FROM 
        pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE 
        c.relkind = 'm'
)

--проверка поля если используется в схеме
SELECT 
    sd.object_type,
    sd.schema_name || '.' || sd.object_name AS full_object_name,
    CASE 
        WHEN sd.object_type IN ('Функция/Процедура', 'Триггер') 
        THEN regexp_replace(substring(sd.definition from 1 for 200), '[\n\r]+', ' ', 'g')
        ELSE substring(sd.definition from 1 for 200)
    END AS object_definition_sample
FROM 
    search_data sd
WHERE 
    sd.definition ILIKE '%smg_radacct%acctsessionid%'
ORDER BY 
    sd.object_type, 
    sd.schema_name, 
    sd.object_name;