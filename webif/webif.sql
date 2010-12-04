CREATE TABLE users (id INTEGER PRIMARY KEY, username, password, salt);
CREATE TABLE solved_challenges (challenge, user_id);
