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
