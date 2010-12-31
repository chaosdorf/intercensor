DROP TABLE IF EXISTS solved_challenges;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id serial,
    name character varying(50),
    password char(60),
    PRIMARY KEY (id),
    UNIQUE (name)
);

CREATE TABLE solved_challenges (
    user_id integer,
    challenge_id character varying(50),
    solved_at timestamp with time zone,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

DROP INDEX IF EXISTS solved_challenges_user_id;
CREATE INDEX solved_challenges_user_id ON solved_challenges (user_id);
