-- Migration: add created_at columns if missing
-- This version explicitly references the target schema to avoid the "No database selected" error.
-- Set the target schema name below and run the script from any client.

-- Adjust this if your DB name differs
SET @schema = 'getworks_app';

-- Helper: for each table, check INFORMATION_SCHEMA and ALTER only if column absent.
-- Uses prepared statements to run the ALTER only when needed.

-- job_details
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'job_details' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.job_details ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- job_milestones
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'job_milestones' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.job_milestones ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- posts
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'posts' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.posts ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- transactions
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'transactions' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.transactions ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- escrow_payments
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'escrow_payments' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.escrow_payments ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ratings
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'ratings' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.ratings ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- notifications
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'notifications' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.notifications ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admin_logs
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'admin_logs' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.admin_logs ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- users
SELECT COUNT(*) INTO @cnt FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = 'users' AND COLUMN_NAME = 'created_at';
SET @s = IF(@cnt = 0, CONCAT('ALTER TABLE ', @schema, '.users ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP'), 'SELECT 0');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'migration_done' as status;
