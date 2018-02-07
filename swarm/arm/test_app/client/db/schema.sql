CREATE TABLE IF NOT EXISTS temperature(
record_time timestamp without time zone NOT NULL,
temperature decimal NOT NULL);

CREATE TABLE IF NOT EXISTS last_backup(
record_time timestamp without time zone NOT NULL);

CREATE UNIQUE INDEX IF NOT EXISTS last_backup_one_row
ON last_backup(record_time IS NOT NULL);
