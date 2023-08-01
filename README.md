# PostgreSQL Hashtags Analysis
A research and development project to determine the optimal and efficient method for storing hashtags in PostgreSQL.

## Abstract
Using a `JSONB` column with a PostgreSQL `Generalized Inverted Index` is the most optimal and efficient method for storing and querying hashtags.

## Introduction
Hashtags are a way to organize content around a specific topic.

The benefits of hashtags include: 

+ `Discoverability`. When you use a hashtag, your content will show up in search results for that hashtag. This means that people interested in that topic can easily find your content.
+ `Connection`. Hashtags can be used to connect with people who are interested in the same things as you.
+ `Engagement`. Hashtags can be used to track trends on social media. This can be helpful for businesses and brands to see what topics are popular and to get involved in conversations.
+ `Promotion`. Hashtags can be used to promote your content and to get more people to see it. When you use relevant hashtags, your content will show up in search results for those hashtags. This can help you to reach a wider audience.

Hashtags are ubiquitous in modern applications and having an optimal and efficient method for storing and querying hashtags is essential.

## Methods

### PostgreSQL storage configurations

**Denormalized Storage**
```mermaid
erDiagram
  post ||--o{ post_tag : has_zero_or_many
  post {
    bigint id PK
    text content
  }
  post_tag
  post_tag {
    bigint id PK
    bigint post_id FK
    text tag
  }
```
+ A `post` has zero or many `post_tag` records
+ A unique index on `(post_id, tag)` within the `post_tag` table
+ An index on `tag` within the `post_tag` table
+ The `tag` value in the `post_tag` table can be redundant

**Normalized Storage**
```mermaid
erDiagram
  post ||--o{ post_tag : has_zero_or_many
  post {
    bigint id PK
    text content
  }
  tag ||--o{ post_tag : has_zero_or_many
  tag {
    bigint id
    text name
  } 
  post_tag
  post_tag {
    bigint post_id PK, FK
    bigint tag_id PK, FK
  }
```
+ A `post` has zero or many `post_tag` records
+ A `tag` has zero or many `post_tag` records
+ A unique index on `(post_id, tag_id)` within the `post_tag`
  

**JSONB Storage**
```mermaid
erDiagram
  post ||--o| post_tag : has_zero_or_one
  post {
    bigint id PK
    text content
  }
  post_tag
  post_tag {
    bigint id PK, FK
    jsonb tags
  } 
```
+ A `post` has zero or one `post_tag` record
+ A GIN (Generalized Inverted Index) on `tags` within the `post_tag` table

**Array Storage**
```mermaid
erDiagram
  post ||--o| post_tag : has_zero_or_one
  post {
    bigint id PK
    text content
  }
  post_tag
  post_tag {
    bigint id PK, FK
    text[] tags
  }
```
+ A `post` has zero or one `post_tag` record

### PostgreSQL testbed
+ Generate 5 million posts
+ Generate 1 million tags
+ for each post, randomly associate _up to_ 10 tags
+ for 5 million posts, randomly associate 3 tags (extremely common tags)
+ for 2,5 million posts, randomly associate 3 tags (very common tags)
+ for 1.25 million posts, randomly associate 3 tags (common tags)
+ A `common` tag is defined as a popular tag
+ A `rare` tag is defined as an unpopular tag

### PostgreSQL queries

**Denormalized Query**
``` sql
    select post_id
    from post_tag
    where tag = '{tag}'
    limit 25 offset 0;
```

**Normalized Query**
``` sql
    select post_id
    from post_tag
    inner join tag on post_tag.tag_id = tag.id
    where tag.name = '{tag}'
    limit 25 offset 0;
```

**JSONB Query**
``` sql
    select post_id
    from post_tag
    where post_tag.tags::jsonb OPERATOR(pg_catalog.@>) '["{tag}"]'::jsonb
    limit 25 offset 0;
```

**Array Query**
``` sql
    select post_id
    from post_tag
    where post_tag.tags::jsonb OPERATOR(pg_catalog.@>) '["{tag}"]'::jsonb
    limit 25 offset 0;
```

## Results

**Number of records**
![Number of database record for each storage method](resources/records.png?raw=true)

**Size of tables**
![Size of database tables for each storage method](resources/size.png?raw=true)

**Query for Most Common Tag (5 million associations)**
![Size of database tables for each storage method](resources/first_common_tag.png?raw=true)

**Query for Second Most Common Tag (2.5 million associations)**
![Size of database tables for each storage method](resources/second_common_tag.png?raw=true)

**Query for Third Most Common Tag (1.25 million associations)**
![Size of database tables for each storage method](resources/third_common_tag.png?raw=true)

**Query for a Random Tag**
![Size of database tables for each storage method](resources/random_tag.png?raw=true)

**Query for the Rarest Tag**
![Size of database tables for each storage method](resources/rare_tag.png?raw=true)

## Discussion
+ The `Denormalized` and `JSONB` methods displayed similar performance
+ The `Array` method displayed degradation with rare tag querying
+ The `Normalized` method displayed inefficient querying throughout
+ Based upon storage size and efficient querying costs, the `JSONB` method is the best choice
