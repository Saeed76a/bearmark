CREATE TABLE bookmarks (
  id SERIAL PRIMARY KEY,
  title VARCHAR NOT NULL,
  url VARCHAR NOT NULL,
  created_at TIMESTAMP(6) WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
