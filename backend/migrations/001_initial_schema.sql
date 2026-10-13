CREATE DATABASE IF NOT EXISTS finduo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE finduo;

CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(254) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sessions (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at TIMESTAMP(3) NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_sessions_user_expiry (user_id, expires_at),
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS spaces (
  id CHAR(36) PRIMARY KEY,
  mode ENUM('solo', 'couple') NOT NULL,
  monthly_budget DECIMAL(14, 2) NOT NULL DEFAULT 0,
  invite_code CHAR(6) NULL UNIQUE,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS space_members (
  space_id CHAR(36) NOT NULL,
  user_id CHAR(36) NOT NULL UNIQUE,
  role ENUM('owner', 'member') NOT NULL DEFAULT 'member',
  joined_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (space_id, user_id),
  CONSTRAINT fk_space_members_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_space_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS expenses (
  id CHAR(36) PRIMARY KEY,
  space_id CHAR(36) NOT NULL,
  user_id CHAR(36) NOT NULL,
  amount DECIMAL(14, 2) NOT NULL,
  category VARCHAR(40) NOT NULL,
  payer_name VARCHAR(100) NOT NULL,
  creator_name VARCHAR(100) NOT NULL,
  spent_at DATETIME(3) NOT NULL,
  note VARCHAR(1000) NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  INDEX idx_expenses_space_date (space_id, spent_at),
  CONSTRAINT fk_expenses_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
  CONSTRAINT fk_expenses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_expenses_amount CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS goals (
  id CHAR(36) PRIMARY KEY,
  space_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  target_amount DECIMAL(14, 2) NOT NULL,
  current_amount DECIMAL(14, 2) NOT NULL DEFAULT 0,
  spent_amount DECIMAL(14, 2) NOT NULL DEFAULT 0,
  start_date DATE NULL,
  target_date DATE NULL,
  color_value INT UNSIGNED NOT NULL DEFAULT 7110111,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  status ENUM('planning', 'active', 'paused', 'completed') NOT NULL DEFAULT 'planning',
  goal_type ENUM('planning', 'project') NOT NULL DEFAULT 'planning',
  tasks JSON NOT NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  INDEX idx_goals_space_archived (space_id, is_archived),
  CONSTRAINT fk_goals_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
  CONSTRAINT chk_goals_target CHECK (target_amount >= 0),
  CONSTRAINT chk_goals_current CHECK (current_amount >= 0),
  CONSTRAINT chk_goals_spent CHECK (spent_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS goal_fundings (
  id CHAR(36) PRIMARY KEY,
  goal_id CHAR(36) NOT NULL,
  amount DECIMAL(14, 2) NOT NULL,
  funded_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_goal_fundings_date (goal_id, funded_at),
  CONSTRAINT fk_goal_fundings_goal FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
  CONSTRAINT chk_goal_fundings_amount CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS planned_expenses (
  id CHAR(36) PRIMARY KEY,
  space_id CHAR(36) NOT NULL,
  title VARCHAR(160) NOT NULL,
  amount DECIMAL(14, 2) NOT NULL,
  category VARCHAR(40) NOT NULL,
  planned_at DATE NOT NULL,
  note VARCHAR(1000) NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_planned_expenses_space_date (space_id, planned_at),
  CONSTRAINT fk_planned_expenses_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
  CONSTRAINT chk_planned_expenses_amount CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS licenses (
  id CHAR(36) PRIMARY KEY,
  code_hash CHAR(64) NOT NULL UNIQUE,
  code_hint VARCHAR(5) NOT NULL,
  expires_at DATETIME(3) NULL,
  is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
  activated_space_id CHAR(36) NULL UNIQUE,
  activated_at TIMESTAMP(3) NULL,
  created_by CHAR(36) NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX idx_licenses_expiry (expires_at),
  CONSTRAINT fk_licenses_space FOREIGN KEY (activated_space_id) REFERENCES spaces(id) ON DELETE SET NULL,
  CONSTRAINT fk_licenses_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admin_users (
  user_id CHAR(36) PRIMARY KEY,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_admin_users_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exercises (
  id CHAR(36) PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  category VARCHAR(80) NOT NULL,
  difficulty ENUM('beginner', 'intermediate', 'advanced') NOT NULL DEFAULT 'beginner',
  duration_seconds SMALLINT UNSIGNED NULL,
  repetitions SMALLINT UNSIGNED NULL,
  video_path VARCHAR(512) NOT NULL,
  video_mime_type VARCHAR(100) NOT NULL,
  video_size_bytes BIGINT UNSIGNED NOT NULL,
  cover_image_path VARCHAR(512) NULL,
  status ENUM('draft', 'published', 'archived') NOT NULL DEFAULT 'draft',
  sort_order INT NOT NULL DEFAULT 0,
  created_by CHAR(36) NULL,
  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  published_at TIMESTAMP(3) NULL,
  INDEX idx_exercises_publication (status, sort_order, published_at),
  CONSTRAINT fk_exercises_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_exercises_target CHECK (duration_seconds IS NOT NULL OR repetitions IS NOT NULL)
) ENGINE=InnoDB;
