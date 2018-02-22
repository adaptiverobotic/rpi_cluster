CREATE TABLE IF NOT EXISTS devices(
  device_id serial PRIMARY KEY,
  device_name varchar(255) UNIQUE NOT NULL,
  last_record_time timestamp without time zone DEFAULT '1995-10-30 10:30:00'
);

CREATE TABLE IF NOT EXISTS temperature(
  device_id integer NOT NULL,
  temperature decimal NOT NULL,
  record_time timestamp without time zone NOT NULL,
  CONSTRAINT temperature_device_id_fkey FOREIGN KEY (device_id)
    REFERENCES devices (device_id) MATCH SIMPLE
    ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE OR REPLACE FUNCTION update_last_record_time()
	RETURNS trigger AS
$$
BEGIN
	UPDATE devices
    SET last_record_time = NEW.record_time
    WHERE device_id = NEW.device_id;

    RETURN NEW;
END;

$$ LANGUAGE 'plpgsql';

CREATE TRIGGER my_trigger
AFTER INSERT
ON temperature
FOR EACH ROW
EXECUTE PROCEDURE update_last_record_time();
