create table if not exists post
(
	id bigserial not null constraint post_pk primary key,
	content text not null
);

-- --------------------
-- DENORMALIZED Method
-- --------------------
create table if not exists post_tag_denormalized
(
	id bigserial not null constraint table_name_pk primary key,
	post_id bigint not null,
	tag text not null
);
create index if not exists post_tag_denormalized_tag_index on post_tag (tag);

-- --------------------
-- NORMALIZED Method
-- --------------------
create table if not exists tag
(
	id bigserial not null constraint tag_pk primary key,
	name text not null
);
create unique index if not exists tag_uindex on tag (name);

create table if not exists post_tag_normalized
(
	id bigserial not null constraint post_tag_pk primary key,
	post_id bigint not null constraint post_tag_normalized_post_id_fk references post,
	tag_id bigint not null constraint post_tag_normalized_tag_id_fk references tag
);
create unique index if not exists post_tag_normalized_post_id_tag_id_uindex on post_tag_normalized (post_id, tag_id);

-- --------------------
-- JSONB Method
-- --------------------
create table if not exists post_tag_josnb
(
	post_id bigint not null constraint post_tag_josnb_pk primary key constraint post_tag_josnb_post_id_fk references post,
	tags jsonb
);

create extension pg_trgm;
create index concurrently post_tag_josnb_tags_gin on post_tag_josnb using gin (tags);

-- --------------------
-- ARRAY Method
-- --------------------
create table if not exists post_tag_array
(
	post_id bigint not null constraint post_tag_array_pk primary key constraint post_tag_array_post_id_fk references post,
	tags text[] default '{}'::text[] not null
);

create extension pg_trgm;
create index concurrently post_tag_array_tags_gin on post_tag using gin (tags);
