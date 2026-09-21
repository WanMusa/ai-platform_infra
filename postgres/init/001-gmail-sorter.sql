CREATE DATABASE gmail_sorter;

CREATE USER gmail_sorter_user
WITH PASSWORD 'gmailsorter1234';

GRANT CONNECT ON DATABASE gmail_sorter TO gmail_sorter_user;

ALTER DATABASE gmail_sorter
OWNER TO gmail_sorter_user;