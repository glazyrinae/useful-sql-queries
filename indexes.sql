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

-- СТАТИСТИКА ИСПОЛЬЗОВАНИЯ ИНДЕКСОВ
-- сброс статистики
select pg_stat_reset();
-- информация по индексам
select
    t.schemaname AS schema_name,
    t.relname AS table_name,
    i.indexrelname AS index_name,
    i.idx_scan AS index_scans,
    pg_size_pretty(pg_relation_size(i.indexrelid::regclass)) AS index_size,
    i.idx_tup_read AS tuples_read,
    i.idx_tup_fetch AS tuples_fetched,
    x.indexdef AS index_definition,
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
    schemaname AS schema_name,
    relname AS table_name,
    indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size,
    idx_scan AS scans_count
from
    pg_stat_user_indexes
where
    idx_scan = 0
    and pg_relation_size(indexrelid::regclass) > 1024*1024  -- Индексы больше 1MB
order by
    pg_relation_size(indexrelid::regclass) DESC;
