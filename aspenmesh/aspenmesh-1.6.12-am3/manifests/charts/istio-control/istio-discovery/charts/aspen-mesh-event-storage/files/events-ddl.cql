CREATE KEYSPACE IF NOT EXISTS events WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'};

USE events;

CREATE TABLE IF NOT EXISTS EventsById (
    event_id    TEXT PRIMARY KEY,
    event_time  TIMESTAMP,
    event_type  INT,
    details     TEXT, -- Different structs for different types
) WITH default_time_to_live = 691200; -- 8 days

CREATE TABLE IF NOT EXISTS EventsByTimestamp (
    event_hour  INT,
    event_time  TIMESTAMP,
    event_id    TEXT,
    event_type  INT,
    details     TEXT,
    PRIMARY KEY(event_hour, event_time)
) WITH default_time_to_live = 691200; -- 8 days

CREATE TABLE IF NOT EXISTS AlertsById (
    alert_id TEXT PRIMARY KEY,
    details  TEXT,
) WITH default_time_to_live = 691200; -- 8 days

CREATE TABLE IF NOT EXISTS AlertsByEntityId (
    entity_id   TEXT,
    entity_type TEXT,
    alerted_at  TIMESTAMP, -- for sorting
    details     TEXT,
    PRIMARY KEY(entity_id, alerted_at)
) WITH default_time_to_live = 691200; -- 8 days

CREATE TABLE IF NOT EXISTS AlertFingerprints (
    fingerprint       TEXT PRIMARY KEY,
    alert_id          TEXT,
    alerted_event_id  TEXT
) WITH default_time_to_live = 691200; -- 8 days

CREATE TABLE IF NOT EXISTS ItemNumbers (
    name              TEXT PRIMARY KEY,
    next_item_number  COUNTER
); -- This table is used for generating the next item number (for alerts, events and etc)
