CREATE KEYSPACE IF NOT EXISTS events WITH replication = {'class': 'SimpleStrategy', 'replication_factor': '1'};

USE events;

CREATE TABLE IF NOT EXISTS EventsById (
    id          UUID PRIMARY KEY,
    event_time  TIMESTAMP,
    event_type  TEXT,
    details     TEXT, -- Different structs for different types
);

CREATE TABLE IF NOT EXISTS EventsByTimestamp (
    event_hour  INT,
    event_time  TIMESTAMP,
    id          UUID,
    event_type  TEXT,
    details     TEXT,
    PRIMARY KEY(event_hour, event_time)
);

CREATE TABLE IF NOT EXISTS WindowsById (
    id              UUID PRIMARY KEY,
    entity_id       TEXT, -- Entity ID is deploymentName.deploymentNamespace
    entity_type     TEXT,
    details         TEXT, -- See JSON definition below
    creation_time   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS WindowsByEntityId (
    entity_id       TEXT,
    entity_type     TEXT,
    creation_time   TIMESTAMP,
    window_id       UUID,
    details         TEXT,
    PRIMARY KEY(entity_id, creation_time)
) WITH CLUSTERING ORDER BY(creation_time DESC);

CREATE TABLE IF NOT EXISTS AlertedWindowsByEntityId (
    entity_id       TEXT,
    entity_type     TEXT,
    creation_time   TIMESTAMP,
    window_id       UUID,
    PRIMARY KEY(entity_id, creation_time)
) WITH CLUSTERING ORDER BY(creation_time DESC);
