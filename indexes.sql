-- СОЗДАНИЕ ИНДЕКСОВ

-- создание уникального индекса
CREATE UNIQUE INDEX account_freq_flyer ON account (frequent_flyer_id);
-- создание индекса
CREATE INDEX flight_arrival_airport ON flight (arrival_airport);
-- функциональный индекс 
CREATE INDEX account_last_name_lower ON account (lower(last_name));
-- составной индекс
CREATE INDEX flight_depart_arr_sched_dep ON flight (departure_airport, arrival_airport, scheduled_departure)
-- покрывающие индексы
CREATE INDEX flight_depart_arr_sched_dep_inc_sched_arr ON flight (departure_airport, arrival_airport, scheduled_departure) INCLUDE (scheduled_arrival);
-- частичные индексы
CREATE INDEX flight_actual_departure_not_null ON flight (actual_departure) WHERE actual_departure is not null
-- удаление индекса
DROP INDEX index_name;

-- ИНФОРМАЦИЯ ПО ИНДЕКСАМ
-- сброс статистики
select pg_stat_reset();
-- информация по индексам
select
    t.schemaname as schema_name,
    t.relname as table_name,
    i.indexrelname as index_name,
    i.idx_scan as index_scans,
    pg_size_pretty(pg_relation_size(t.relname::regclass)) AS table_size,
    pg_size_pretty(pg_relation_size(i.indexrelid::regclass)) AS index_size,
    i.idx_tup_read as tuples_read,
    i.idx_tup_fetch as tuples_fetched,
    x.indexdef as index_definition,
    case 
    	when i.idx_scan > 0 then (100.0 * i.idx_tup_fetch / i.idx_scan)::numeric
        else 0 
    end as fetch_efficiency_percent
from
    pg_stat_user_indexes i
join
    pg_stat_user_tables t ON i.relid = t.relid
join
    pg_indexes x on i.schemaname = x.schemaname 
                and i.relname = x.tablename 
                and i.indexrelname = x.indexname
where
    t.relname = 'your_table_name'  -- Опционально: фильтр по таблице
    and i.indexrelname = 'your_index_name'
order by 
    i.idx_scan desc;
    
-- поиск неиспользуемых индексов
select
    schemaname as schema_name,
    relname as table_name,
    indexrelname as index_name,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size,
    idx_scan as scans_count
from
    pg_stat_user_indexes
where
    idx_scan = 0
    and pg_relation_size(indexrelid::regclass) > 1024*1024  -- Индексы больше 1MB
    and schemaname <> 'pg_toast' and  schemaname <> 'pg_catalog'
order by
    pg_relation_size(indexrelid::regclass) desc;

    
-- индексы которые дублируются    
select
    indrelid::regclass as table_name,
    array_agg(indexrelid) as indexrelid, -- если нужно точно проверить совпадение запроса на create index
    array_agg(indexrelid::regclass) as duplicate_indexes,
    pg_get_indexdef(min(indexrelid)) as index_definition,
    count(*) as duplicate_count
from
    pg_index
group by 
    indrelid,
    indkey -- колонки индекса
having
    count(*) > 1
order by
    table_name,
    duplicate_count desc;
    
--процент использования индекса чем ближе к 100 тем лучше
select relname,   
       100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used,   
       n_live_tup rows_in_table 
from pg_stat_user_tables 
where seq_scan + idx_scan > 0 
order by n_live_tup desc;
    
    
    
    
