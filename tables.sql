create table if not exists post
(
	id bigserial not null constraint post_pk primary key,
	content text not null
);

-- --------------------
-- DENORMALIZED Method
-- --------------------
create table if not exists post_tag
(
	id bigserial not null constraint table_name_pk primary key,
	post_id bigint not null,
	tag text not null
);

create index if not exists post_tag_tag_index on post_tag (tag);

-- --------------------
-- NORMALIZED Method
-- --------------------
create table if not exists tag
(
	id bigserial not null constraint tag_pk primary key,
	name text not null
);

create table if not exists post_tag
(
	id bigserial not null constraint post_tag_pk primary key,
	post_id bigint not null constraint post_tag_post_id_fk references post,
	tag_id bigint not null constraint post_tag_tag_id_fk references tag
);

create unique index if not exists post_tag_post_id_tag_id_uindex on post_tag (post_id, tag_id);
create unique index if not exists tag_uindex on tag (name);

-- --------------------
-- JSONB Method
-- --------------------
create table if not exists post_tag
(
	post_id bigint not null constraint post_tag_pk primary key constraint post_tag_json_post_id_fk references post,
	tags jsonb
);

create extensioin pg_trgm;
create index concurrently post_tag_tags_gin on post_tag using gin (tags);

-- --------------------
-- ARRAY Method
-- --------------------
create table if not exists post_tag
(
	post_id bigint not null constraint post_tag_pk primary key constraint post_tag_post_id_fk references post,
	tags text[] default '{}'::text[] not null
);

create extensioin pg_trgm;
create index concurrently post_tag_tags_gin on post_tag using gin (tags);
