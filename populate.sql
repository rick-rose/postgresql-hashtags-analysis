CREATE EXTENSION tsm_system_rows;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION pg_trgm;
CREATE EXTENSION pgcrypto;

TRUNCATE post RESTART IDENTITY CASCADE;
TRUNCATE tag RESTART IDENTITY CASCADE;
TRUNCATE post_tag_normalized RESTART IDENTITY CASCADE;
TRUNCATE post_tag_denormalized RESTART IDENTITY CASCADE;
TRUNCATE post_tag_array RESTART IDENTITY CASCADE;
TRUNCATE post_tag_json RESTART IDENTITY CASCADE;

-- POPULATE POSTS
INSERT INTO post(content)
  SELECT
    md5('post' || seq::text) AS content
  FROM
    GENERATE_SERIES(1, 5000000) seq;

-- POPULATE TAGS
INSERT INTO tag(name)
  SELECT
    md5('tag' || seq::text) AS name
  FROM
    GENERATE_SERIES(1, 1000000) seq;

-- POPULATE POST TAGS
DO
$$
    DECLARE
        p record;
        t record;
        common_tag_all record;
        common_tag_half record;
        common_tag_quarter record;
        max_tags integer := 10;
        tag_array text[];
        counter integer := 0 ;
    BEGIN
        -- select common tags
        SELECT id AS tag_id, name AS tag_name INTO common_tag_all FROM tag TABLESAMPLE SYSTEM_ROWS(1);
        SELECT id AS tag_id, name AS tag_name INTO common_tag_half FROM tag TABLESAMPLE SYSTEM_ROWS(1) WHERE id != common_tag_all.tag_id;
        SELECT id AS tag_id, name AS tag_name INTO common_tag_quarter FROM tag TABLESAMPLE SYSTEM_ROWS(1) WHERE id != common_tag_all.tag_id AND id != common_tag_half.tag_id;

        FOR p IN SELECT id AS post_id FROM post ORDER BY id LOOP
            -- prepare tag array; pre-populate with popular tag
            tag_array := '{}'::text[];

            -- insert a common tag ALL of the time
            tag_array := ARRAY_APPEND(tag_array, common_tag_all.tag_name);
            INSERT INTO post_tag_normalized(post_id, tag_id) VALUES (p.post_id, common_tag_all.tag_id);
            INSERT INTO post_tag_denormalized(post_id, tag) VALUES (p.post_id, common_tag_all.tag_name);

            -- insert a common tag HALF of the time
            IF MOD(counter, 2) = 0 THEN
                tag_array := ARRAY_APPEND(tag_array, common_tag_half.tag_name);
                INSERT INTO post_tag_normalized(post_id, tag_id) VALUES (p.post_id, common_tag_half.tag_id);
                INSERT INTO post_tag_denormalized(post_id, tag) VALUES (p.post_id, common_tag_half.tag_name);
            END IF;

            -- insert a common tag QUARTER of the time
            IF MOD(counter, 4) = 0 THEN
                tag_array := ARRAY_APPEND(tag_array, common_tag_quarter.tag_name);
                INSERT INTO post_tag_normalized(post_id, tag_id) VALUES (p.post_id, common_tag_quarter.tag_id);
                INSERT INTO post_tag_denormalized(post_id, tag) VALUES (p.post_id, common_tag_quarter.tag_name);
            END IF;

            -- insert random tags
            FOR t IN SELECT id AS tag_id, name AS tag_name FROM tag TABLESAMPLE SYSTEM_ROWS(floor(random() * (max_tags-1+1) + 1)::int) WHERE id NOT IN (common_tag_all.tag_id, common_tag_half.tag_id, common_tag_quarter.tag_id) LOOP
                tag_array := ARRAY_APPEND(tag_array, t.tag_name);
                INSERT INTO post_tag_normalized(post_id, tag_id) VALUES (p.post_id, t.tag_id);
                INSERT INTO post_tag_denormalized(post_id, tag) VALUES (p.post_id, t.tag_name);
            END LOOP;
            INSERT INTO post_tag_array(post_id, tags) VALUES (p.post_id, tag_array);
            INSERT INTO post_tag_json(post_id, tags) VALUES (p.post_id, array_to_json(tag_array));

            counter := counter + 1;
        END LOOP;
    END; $$;
