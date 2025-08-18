-- Admin Dashboard Database Schema
-- PostgreSQL initialization script

-- Create database if not exists (run this as superuser)
-- CREATE DATABASE admin_dashboard;

-- Connect to the database
-- \c admin_dashboard;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'user')),
    active BOOLEAN NOT NULL DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Push notification subscriptions
CREATE TABLE IF NOT EXISTS push_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    p256dh TEXT NOT NULL,
    auth TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Backup history
CREATE TABLE IF NOT EXISTS backup_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    filename VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    size BIGINT,
    duration INTEGER,
    status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failed')),
    error TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Service health history
CREATE TABLE IF NOT EXISTS service_health_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'unhealthy', 'warning')),
    response_time INTEGER,
    error_message TEXT,
    metrics JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alert history
CREATE TABLE IF NOT EXISTS alert_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    level VARCHAR(20) NOT NULL CHECK (level IN ('info', 'warning', 'critical')),
    message TEXT NOT NULL,
    service_name VARCHAR(100),
    context JSONB,
    sent_via_email BOOLEAN DEFAULT false,
    sent_via_push BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System metrics history
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cpu_usage_percent DECIMAL(5,2),
    memory_usage_percent DECIMAL(5,2),
    disk_usage_percent DECIMAL(5,2),
    network_rx_bytes BIGINT,
    network_tx_bytes BIGINT,
    active_connections INTEGER,
    uptime_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Configuration settings
CREATE TABLE IF NOT EXISTS config_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit log
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(100),
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(active);

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id ON push_subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_backup_history_created_at ON backup_history(created_at);
CREATE INDEX IF NOT EXISTS idx_backup_history_status ON backup_history(status);
CREATE INDEX IF NOT EXISTS idx_backup_history_type ON backup_history(type);

CREATE INDEX IF NOT EXISTS idx_service_health_service_name ON service_health_history(service_name);
CREATE INDEX IF NOT EXISTS idx_service_health_created_at ON service_health_history(created_at);
CREATE INDEX IF NOT EXISTS idx_service_health_status ON service_health_history(status);

CREATE INDEX IF NOT EXISTS idx_alert_history_level ON alert_history(level);
CREATE INDEX IF NOT EXISTS idx_alert_history_created_at ON alert_history(created_at);
CREATE INDEX IF NOT EXISTS idx_alert_history_service_name ON alert_history(service_name);

CREATE INDEX IF NOT EXISTS idx_system_metrics_created_at ON system_metrics(created_at);

CREATE INDEX IF NOT EXISTS idx_config_settings_key ON config_settings(key);
CREATE INDEX IF NOT EXISTS idx_config_settings_category ON config_settings(category);

CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_resource_type ON audit_log(resource_type);

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_push_subscriptions_updated_at BEFORE UPDATE ON push_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_config_settings_updated_at BEFORE UPDATE ON config_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user (password: admin123 - change this in production!)
INSERT INTO users (username, email, password_hash, role, active) 
VALUES (
    'admin',
    'admin@defimon.highfunk.uk',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5u.Ge', -- bcrypt hash of 'admin123'
    'admin',
    true
) ON CONFLICT (username) DO NOTHING;

-- Insert default configuration settings
INSERT INTO config_settings (key, value, description, category) VALUES
('backup_enabled', 'true', 'Enable automatic database backups', 'backup'),
('backup_schedule', '0 2 * * *', 'Cron schedule for backups (UTC)', 'backup'),
('backup_retention_days', '30', 'Number of days to keep backups', 'backup'),
('alert_email_enabled', 'true', 'Enable email alerts', 'alerts'),
('alert_push_enabled', 'true', 'Enable push notifications', 'alerts'),
('health_check_interval', '30000', 'Health check interval in milliseconds', 'monitoring'),
('log_level', 'info', 'Application log level', 'logging'),
('ssl_certificate_check', 'true', 'Enable SSL certificate expiry monitoring', 'security'),
('rate_limit_enabled', 'true', 'Enable rate limiting', 'security'),
('rate_limit_max_requests', '100', 'Maximum requests per window', 'security'),
('rate_limit_window_ms', '900000', 'Rate limit window in milliseconds', 'security')
ON CONFLICT (key) DO NOTHING;

-- Create views for common queries
CREATE OR REPLACE VIEW service_health_summary AS
SELECT 
    service_name,
    status,
    COUNT(*) as count,
    AVG(response_time) as avg_response_time,
    MAX(created_at) as last_check
FROM service_health_history
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY service_name, status;

CREATE OR REPLACE VIEW alert_summary AS
SELECT 
    level,
    COUNT(*) as count,
    MAX(created_at) as last_alert
FROM alert_history
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY level;

CREATE OR REPLACE VIEW system_health_summary AS
SELECT 
    AVG(cpu_usage_percent) as avg_cpu_usage,
    AVG(memory_usage_percent) as avg_memory_usage,
    AVG(disk_usage_percent) as avg_disk_usage,
    MAX(active_connections) as max_connections,
    MAX(created_at) as last_metric
FROM system_metrics
WHERE created_at >= NOW() - INTERVAL '1 hour';

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_user;

-- Create a function to clean up old data
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Clean up old service health records (keep 30 days)
    DELETE FROM service_health_history 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Clean up old system metrics (keep 7 days)
    DELETE FROM system_metrics 
    WHERE created_at < NOW() - INTERVAL '7 days';
    
    -- Clean up old audit logs (keep 90 days)
    DELETE FROM audit_log 
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    -- Clean up old alert history (keep 30 days)
    DELETE FROM alert_history 
    WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Create a function to get system statistics
CREATE OR REPLACE FUNCTION get_system_stats()
RETURNS TABLE(
    total_users INTEGER,
    active_users INTEGER,
    total_backups INTEGER,
    successful_backups INTEGER,
    failed_backups INTEGER,
    total_alerts_24h INTEGER,
    critical_alerts_24h INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users)::INTEGER as total_users,
        (SELECT COUNT(*) FROM users WHERE active = true)::INTEGER as active_users,
        (SELECT COUNT(*) FROM backup_history)::INTEGER as total_backups,
        (SELECT COUNT(*) FROM backup_history WHERE status = 'success')::INTEGER as successful_backups,
        (SELECT COUNT(*) FROM backup_history WHERE status = 'failed')::INTEGER as failed_backups,
        (SELECT COUNT(*) FROM alert_history WHERE created_at >= NOW() - INTERVAL '24 hours')::INTEGER as total_alerts_24h,
        (SELECT COUNT(*) FROM alert_history WHERE level = 'critical' AND created_at >= NOW() - INTERVAL '24 hours')::INTEGER as critical_alerts_24h;
END;
$$ LANGUAGE plpgsql;
