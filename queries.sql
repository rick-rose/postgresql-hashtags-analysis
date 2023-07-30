-- RECORD COUNTS
    SELECT
        (SELECT COUNT(*)FROM post_tag_jsonb),
        (SELECT COUNT(*) FROM post_tag_array),
        (SELECT COUNT(*) FROM post_tag_normalized),
        (SELECT COUNT(*) FROM post_tag_denormalized);

-- STORAGE SIZES
SELECT
    relname,
    pg_size_pretty(pg_total_relation_size(relid))
FROM
    pg_stat_user_tables
ORDER BY
    pg_total_relation_size(relid);

-- TOP 5 RARE TAGS
SELECT tag_id, COUNT(*) FROM post_tag_normalized GROUP BY tag_id ORDER BY COUNT(*) ASC LIMIT 5;

-- TOP 5 COMMON TAGS
SELECT tag_id, COUNT(*) FROM post_tag_normalized GROUP BY tag_id ORDER BY COUNT(*) DESC LIMIT 5;


-- Query DENORMALIZED
select post_id
from post_tag_denormalized
where tag = 'TAG'
imit 25 offset 0;

-- Query NORMALIZED
select post_id
from post_tag_normalized
inner join tag on normalized.tag_id = tag.id
where tag.name = 'TAG'
limit 25 offset 0;

-- Query JSONB
select post_id
from post_tag_json
where tags OPERATOR(pg_catalog.@>) '["TAG"]'::jsonb
limit 25 offset 0;

-- Query ARRAY
select post_id
from post_tag_array
where tags OPERATOR(pg_catalog.@>) ARRAY['TAG']
limit 25 offset 0;
