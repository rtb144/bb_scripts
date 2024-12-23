-- Time-series tables for metrics
CREATE SCHEMA metrics;

CREATE TABLE metrics.sql_utilization (
    timestamp TIMESTAMPTZ NOT NULL,
    server_name VARCHAR(100),
    database_name VARCHAR(100),
    metric_name VARCHAR(50),
    metric_value NUMERIC,
    unit VARCHAR(20)
);

-- Create hypertable
SELECT create_hypertable('metrics.sql_utilization', 'timestamp');

-- Create indexes
CREATE INDEX idx_server_time ON metrics.sql_utilization(server_name, timestamp DESC);
CREATE INDEX idx_metric_time ON metrics.sql_utilization(metric_name, timestamp DESC);
