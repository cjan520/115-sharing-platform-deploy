-- 115 影视资源共享平台 - PostgreSQL 初始化脚本

-- 资源主表
CREATE TABLE IF NOT EXISTS resources (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    year SMALLINT,
    tmdb_id INTEGER,
    imdb_id VARCHAR(20),
    media_type VARCHAR(10) NOT NULL CHECK (media_type IN ('movie', 'tv')),
    status VARCHAR(20) NOT NULL DEFAULT 'pushing' CHECK (status IN ('pushing', 'completed', 'failed')),
    pipeline_status VARCHAR(32) NOT NULL DEFAULT 'pending_share',
    category_path VARCHAR(500),
    poster_url VARCHAR(1000),
    poster_local_path VARCHAR(500),
    meta_json JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_resources_tmdb_id ON resources(tmdb_id);
CREATE INDEX idx_resources_status ON resources(status);
CREATE INDEX idx_resources_media_type ON resources(media_type);
CREATE INDEX idx_resources_pipeline_status ON resources(pipeline_status);

-- 资源版本表
CREATE TABLE IF NOT EXISTS resource_versions (
    id BIGSERIAL PRIMARY KEY,
    resource_id BIGINT NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    ed2k_dispatch_id BIGINT,
    source_dir VARCHAR(20) NOT NULL CHECK (source_dir IN ('movie', 'remux', 'bd_disc', 'tv_completed', 'tv_ongoing')),
    quality VARCHAR(50),
    source VARCHAR(50),
    file_size BIGINT,
    episode_range VARCHAR(512),
    share_id VARCHAR(50),
    share_url VARCHAR(500),
    share_code VARCHAR(20),
    share_status VARCHAR(32) NOT NULL DEFAULT 'pending_share',
    share_retry_count INTEGER NOT NULL DEFAULT 0,
    share_last_error TEXT,
    share_last_attempt_at TIMESTAMP,
    share_expire_at TIMESTAMP,
    shared_at TIMESTAMP,
    archive_status VARCHAR(32) NOT NULL DEFAULT 'pending',
    archive_last_error TEXT,
    archived_at TIMESTAMP,
    account_id VARCHAR(100),
    category_task_key VARCHAR(150),
    version_fingerprint VARCHAR(40),
    source_name VARCHAR(255),
    source_pick_code VARCHAR(64),
    source_is_file BOOLEAN,
    "115_folder_id" VARCHAR(50),
    file_count INTEGER,
    media_probe_status VARCHAR(32),
    media_probe_error TEXT,
    media_probe_at TIMESTAMP,
    audio_tracks_json JSONB,
    subtitle_tracks_json JSONB,
    audio_summary VARCHAR(255),
    subtitle_summary VARCHAR(255),
    display_media_type VARCHAR(50),
    source_task_label VARCHAR(120),
    resolution_code VARCHAR(20),
    source_type_code VARCHAR(20),
    dynamic_range_code VARCHAR(30),
    quality_label VARCHAR(100),
    category_code VARCHAR(50),
    category_label_auto VARCHAR(50),
    category_label_manual VARCHAR(50),
    category_label_final VARCHAR(50),
    source_label_auto VARCHAR(50),
    source_label_manual VARCHAR(50),
    source_label_final VARCHAR(50),
    content_form_code VARCHAR(30),
    completion_status VARCHAR(20),
    telegram_push_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    telegram_push_last_error TEXT,
    telegram_push_retry_count INTEGER NOT NULL DEFAULT 0,
    telegram_push_last_attempt_at TIMESTAMP,
    telegram_pushed_at TIMESTAMP,
    instant_transfer_status VARCHAR(32) NOT NULL DEFAULT 'pending',
    instant_transfer_retry_count INTEGER NOT NULL DEFAULT 0,
    instant_transfer_last_error TEXT,
    instant_transfer_last_attempt_at TIMESTAMP,
    instant_transferred_at TIMESTAMP,
    remark_manual VARCHAR(255),
    remark_auto VARCHAR(255),
    remark_final VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_rv_resource_id ON resource_versions(resource_id);
CREATE INDEX idx_rv_share_status ON resource_versions(share_status);
CREATE INDEX IF NOT EXISTS idx_rv_ed2k_dispatch_id ON resource_versions(ed2k_dispatch_id);
CREATE INDEX idx_rv_share_failed_retry ON resource_versions(share_retry_count, share_last_attempt_at, created_at) WHERE share_status = 'share_failed';
CREATE INDEX idx_rv_archive_status ON resource_versions(archive_status);
CREATE INDEX idx_rv_account_id ON resource_versions(account_id);
CREATE INDEX idx_rv_category_task_key ON resource_versions(category_task_key);
CREATE INDEX idx_rv_version_fingerprint ON resource_versions(version_fingerprint);
CREATE INDEX idx_rv_tg_failed_retry ON resource_versions(telegram_push_retry_count, telegram_push_last_attempt_at, shared_at) WHERE telegram_push_status = 'failed';
CREATE INDEX idx_rv_instant_transfer_status ON resource_versions(instant_transfer_status);
CREATE INDEX idx_rv_instant_transfer_retry ON resource_versions(instant_transfer_retry_count, instant_transfer_last_attempt_at, created_at) WHERE instant_transfer_status IN ('failed', 'partial_failed');
CREATE INDEX idx_rv_resolution_code ON resource_versions(resolution_code);
CREATE INDEX idx_rv_source_type_code ON resource_versions(source_type_code);
CREATE INDEX idx_rv_dynamic_range_code ON resource_versions(dynamic_range_code);
CREATE INDEX idx_rv_category_code ON resource_versions(category_code);
CREATE INDEX idx_rv_completion_status ON resource_versions(completion_status);
CREATE INDEX IF NOT EXISTS idx_rv_push_ready ON resource_versions(category_task_key, shared_at, created_at) WHERE share_status = 'shared';
CREATE INDEX IF NOT EXISTS idx_rv_telegram_push_status ON resource_versions(telegram_push_status);
CREATE INDEX IF NOT EXISTS idx_rv_tg_push_ready ON resource_versions(category_task_key, shared_at, created_at) WHERE share_status = 'shared' AND telegram_push_status <> 'sent';

CREATE TABLE IF NOT EXISTS duplicate_resource_queue (
    id BIGSERIAL PRIMARY KEY,
    account_id VARCHAR(100),
    category_task_key VARCHAR(150),
    source_task_label VARCHAR(120),
    source_dir VARCHAR(20),
    entry_id VARCHAR(64),
    entry_name VARCHAR(500),
    is_file BOOLEAN,
    tmdb_id INTEGER,
    title VARCHAR(255),
    year INTEGER,
    episode_range VARCHAR(512),
    file_size BIGINT,
    file_count INTEGER,
    version_fingerprint VARCHAR(40),
    matched_resource_id BIGINT,
    matched_version_id BIGINT,
    matched_share_status VARCHAR(32),
    matched_share_url VARCHAR(500),
    duplicate_reason VARCHAR(50) NOT NULL DEFAULT 'existing_version',
    verify_status VARCHAR(30) NOT NULL DEFAULT 'unverified',
    verify_message TEXT,
    verify_attempts INTEGER NOT NULL DEFAULT 0,
    last_verify_at TIMESTAMP,
    action_status VARCHAR(30) NOT NULL DEFAULT 'pending',
    action_message TEXT,
    action_at TIMESTAMP,
    detail_json JSONB,
    first_seen_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_duplicate_queue_status ON duplicate_resource_queue(action_status, verify_status, last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_duplicate_queue_task ON duplicate_resource_queue(category_task_key, last_seen_at DESC);
CREATE INDEX IF NOT EXISTS idx_duplicate_queue_entry ON duplicate_resource_queue(account_id, entry_id);
CREATE INDEX IF NOT EXISTS idx_duplicate_queue_matched_version ON duplicate_resource_queue(matched_version_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_duplicate_queue_unique_entry ON duplicate_resource_queue(account_id, entry_id) WHERE entry_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_duplicate_queue_unique_fingerprint ON duplicate_resource_queue(account_id, version_fingerprint) WHERE version_fingerprint IS NOT NULL;

-- 会员表
CREATE TABLE IF NOT EXISTS members (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE,
    password_hash TEXT,
    directory_mode VARCHAR(20) NOT NULL DEFAULT 'manual',
    telegram_id VARCHAR(50) UNIQUE,
    telegram_chat_id VARCHAR(50),
    telegram_username VARCHAR(100),
    telegram_first_name VARCHAR(100),
    telegram_bind_code VARCHAR(32) UNIQUE,
    telegram_bound_at TIMESTAMP,
    nickname VARCHAR(100),
    member_type VARCHAR(20) NOT NULL DEFAULT 'monthly' CHECK (member_type IN ('normal', 'premium', 'trial', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'lifetime')),
    expire_at TIMESTAMP,
    cookie_115 TEXT,
    cid_115 VARCHAR(50),
    transfer_dir_115 VARCHAR(50),
    subscription_dir_115 VARCHAR(50),
    ed2k_offline_dir_115 VARCHAR(50),
    ed2k_offline_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    auto_classify_dispatch BOOLEAN NOT NULL DEFAULT FALSE,
    invited_by VARCHAR(32),
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS member_dispatch_preferences (
    member_id BIGINT PRIMARY KEY REFERENCES members(id) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    allow_resolutions_json JSONB,
    allow_source_types_json JSONB,
    allow_dynamic_ranges_json JSONB,
    allow_categories_json JSONB,
    allow_content_forms_json JSONB,
    allow_completion_statuses_json JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS member_login_tokens (
    id BIGSERIAL PRIMARY KEY,
    token_hash VARCHAR(64) UNIQUE NOT NULL,
    member_id BIGINT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    telegram_id VARCHAR(50) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_member_login_tokens_hash ON member_login_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_member_login_tokens_member ON member_login_tokens(member_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_member_login_tokens_expires ON member_login_tokens(expires_at);

-- 会员等级表
CREATE TABLE IF NOT EXISTS member_levels (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    sort_order INTEGER NOT NULL DEFAULT 100,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    can_use_web BOOLEAN NOT NULL DEFAULT TRUE,
    can_search_resources BOOLEAN NOT NULL DEFAULT TRUE,
    search_per_minute INTEGER NOT NULL DEFAULT 3,
    search_per_day INTEGER NOT NULL DEFAULT 30,
    search_per_month INTEGER NOT NULL DEFAULT 300,
    search_max_results INTEGER NOT NULL DEFAULT 5,
    recent_browse_page_limit INTEGER NOT NULL DEFAULT 10,
    recent_browse_page_size INTEGER NOT NULL DEFAULT 12,
    can_view_resource_detail BOOLEAN NOT NULL DEFAULT TRUE,
    can_get_share_link BOOLEAN NOT NULL DEFAULT FALSE,
    can_use_dispatch BOOLEAN NOT NULL DEFAULT TRUE,
    can_use_transfer BOOLEAN NOT NULL DEFAULT TRUE,
    can_use_subscription BOOLEAN NOT NULL DEFAULT TRUE,
    can_use_ed2k_offline BOOLEAN NOT NULL DEFAULT TRUE,
    can_use_auto_classify BOOLEAN NOT NULL DEFAULT TRUE,
    detail_per_day INTEGER NOT NULL DEFAULT 20,
    link_fetch_per_day INTEGER NOT NULL DEFAULT 5,
    search_charge_on_result_only BOOLEAN NOT NULL DEFAULT TRUE,
    detail_charge_only_with_links BOOLEAN NOT NULL DEFAULT TRUE,
    link_charge_on_success_only BOOLEAN NOT NULL DEFAULT TRUE,
    transfer_charge_on_success_only BOOLEAN NOT NULL DEFAULT TRUE,
    admin_actions_exempt BOOLEAN NOT NULL DEFAULT TRUE,
    ongoing_episode_exempt BOOLEAN NOT NULL DEFAULT TRUE,
    duplicate_action_window_minutes INTEGER NOT NULL DEFAULT 30,
    batch_dispatch_once_limit INTEGER NOT NULL DEFAULT 20,
    dispatch_per_day INTEGER NOT NULL DEFAULT 50,
    dispatch_per_year INTEGER NOT NULL DEFAULT 1000,
    batch_transfer_once_limit INTEGER NOT NULL DEFAULT 10,
    transfer_per_day INTEGER NOT NULL DEFAULT 20,
    transfer_per_year INTEGER NOT NULL DEFAULT 500,
    subscription_tv_per_day INTEGER NOT NULL DEFAULT 5,
    subscription_tv_per_month INTEGER NOT NULL DEFAULT 30,
    subscription_movie_per_day INTEGER NOT NULL DEFAULT 3,
    subscription_movie_per_month INTEGER NOT NULL DEFAULT 20,
    subscription_delivery_mode VARCHAR(20) NOT NULL DEFAULT 'episode_update',
    cooldown_seconds_after_limit INTEGER NOT NULL DEFAULT 600,
    risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 邀请码表
CREATE TABLE IF NOT EXISTS invitation_codes (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(32) UNIQUE NOT NULL,
    max_use_count INTEGER DEFAULT 1,
    used_count INTEGER DEFAULT 0,
    member_type VARCHAR(20) NOT NULL DEFAULT 'monthly' CHECK (member_type IN ('normal', 'premium', 'trial', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'lifetime')),
    member_level_id BIGINT,
    duration_days INTEGER DEFAULT 30,
    created_by BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    expire_at TIMESTAMP,
    remark VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_invitation_code ON invitation_codes(code);

-- 派发记录表
CREATE TABLE IF NOT EXISTS dispatch_log (
    id BIGSERIAL PRIMARY KEY,
    resource_version_id BIGINT NOT NULL REFERENCES resource_versions(id),
    member_id BIGINT NOT NULL REFERENCES members(id),
    telegram_chat_id VARCHAR(50),
    target_dir_id VARCHAR(50),
    target_mode VARCHAR(20) NOT NULL DEFAULT 'receive',
    dispatch_source VARCHAR(30) NOT NULL DEFAULT 'auto',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'retrying')),
    error_message TEXT,
    sent_at TIMESTAMP,
    retry_count SMALLINT DEFAULT 0
);
CREATE INDEX idx_dispatch_status ON dispatch_log(status);
CREATE INDEX idx_dispatch_member ON dispatch_log(member_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_member_mode_sent_at ON dispatch_log(member_id, target_mode, sent_at) WHERE status = 'sent';
DROP INDEX IF EXISTS idx_dispatch_unique_version_member;
CREATE UNIQUE INDEX IF NOT EXISTS idx_dispatch_unique_version_member_target ON dispatch_log(resource_version_id, member_id, target_mode, COALESCE(target_dir_id, ''));

-- ED2K 派发记录
CREATE TABLE IF NOT EXISTS ed2k_dispatch_items (
    id BIGSERIAL PRIMARY KEY,
    link TEXT NOT NULL,
    filename VARCHAR(500) NOT NULL,
    file_size BIGINT,
    file_hash VARCHAR(128),
    title VARCHAR(255),
    year INTEGER,
    tmdb_id INTEGER,
    episode VARCHAR(50),
    media_type VARCHAR(30),
    category VARCHAR(80),
    genre_text VARCHAR(500),
    quality VARCHAR(120),
    display_media_type VARCHAR(50),
    resolution_code VARCHAR(20),
    source_type_code VARCHAR(20),
    dynamic_range_code VARCHAR(30),
    quality_label VARCHAR(100),
    category_code VARCHAR(50),
    category_label VARCHAR(50),
    custom_category_label VARCHAR(50),
    source_label VARCHAR(50),
    content_form_code VARCHAR(30),
    completion_status VARCHAR(20),
    audio_summary VARCHAR(255),
    subtitle_summary VARCHAR(255),
    file_count INTEGER NOT NULL DEFAULT 1,
    overview TEXT,
    cast_text TEXT,
    rating VARCHAR(20),
    poster_url TEXT,
    template_key VARCHAR(120),
    target_mode VARCHAR(30) NOT NULL DEFAULT 'all_bound',
    target_member_ids_json JSONB,
    target_chat_ids_json JSONB,
    source_type VARCHAR(30) NOT NULL DEFAULT 'manual',
    source_chat_id VARCHAR(50),
    source_chat_title VARCHAR(255),
    source_user_id VARCHAR(50),
    source_username VARCHAR(100),
    source_message_id VARCHAR(50),
    rendered_message TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'draft',
    sent_count INTEGER NOT NULL DEFAULT 0,
    failed_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    offline_status VARCHAR(30) NOT NULL DEFAULT 'idle',
    master_offline_status VARCHAR(30) NOT NULL DEFAULT 'idle',
    master_offline_task_id VARCHAR(100),
    master_offline_dir_id VARCHAR(50),
    master_offline_message TEXT,
    resource_id BIGINT REFERENCES resources(id) ON DELETE SET NULL,
    resource_version_id BIGINT REFERENCES resource_versions(id) ON DELETE SET NULL,
    offline_sent_count INTEGER NOT NULL DEFAULT 0,
    offline_failed_count INTEGER NOT NULL DEFAULT 0,
    offline_last_error TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    sent_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_ed2k_dispatch_created ON ed2k_dispatch_items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ed2k_dispatch_hash ON ed2k_dispatch_items(file_hash);
CREATE INDEX IF NOT EXISTS idx_ed2k_dispatch_source ON ed2k_dispatch_items(source_type, source_chat_id);
CREATE INDEX IF NOT EXISTS idx_ed2k_dispatch_resource_version ON ed2k_dispatch_items(resource_version_id);

CREATE TABLE IF NOT EXISTS ed2k_offline_dispatch_log (
    id BIGSERIAL PRIMARY KEY,
    ed2k_dispatch_item_id BIGINT NOT NULL REFERENCES ed2k_dispatch_items(id) ON DELETE CASCADE,
    member_id BIGINT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    member_username VARCHAR(100),
    member_display_name VARCHAR(100),
    target_dir_id VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    task_id VARCHAR(100),
    error_message TEXT,
    response_json JSONB,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    last_attempt_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ed2k_offline_dispatch_item ON ed2k_offline_dispatch_log(ed2k_dispatch_item_id);
CREATE INDEX IF NOT EXISTS idx_ed2k_offline_dispatch_member ON ed2k_offline_dispatch_log(member_id);
CREATE INDEX IF NOT EXISTS idx_ed2k_offline_dispatch_status ON ed2k_offline_dispatch_log(status);

-- 系统配置表
CREATE TABLE IF NOT EXISTS configs (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT,
    description VARCHAR(255),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 管理员账号表
CREATE TABLE IF NOT EXISTS admin_accounts (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    display_name VARCHAR(100),
    role VARCHAR(20) NOT NULL DEFAULT 'admin' CHECK (role IN ('super_admin', 'admin')),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_accounts_username_unique ON admin_accounts(LOWER(username));

-- 115 目录名称缓存
CREATE TABLE IF NOT EXISTS directory_cache (
    id BIGSERIAL PRIMARY KEY,
    cookie_hash VARCHAR(64) NOT NULL,
    folder_id VARCHAR(50) NOT NULL,
    name VARCHAR(255),
    path VARCHAR(1000),
    parent_id VARCHAR(50),
    source VARCHAR(50),
    last_seen_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_directory_cache_cookie_folder ON directory_cache(cookie_hash, folder_id);
CREATE INDEX IF NOT EXISTS idx_directory_cache_folder_id ON directory_cache(folder_id);

-- Cookie 检测记录表
CREATE TABLE IF NOT EXISTS cookie_check_log (
    id BIGSERIAL PRIMARY KEY,
    account_type VARCHAR(10) NOT NULL CHECK (account_type IN ('master', 'member')),
    account_id BIGINT NOT NULL,
    is_valid BOOLEAN NOT NULL,
    error_message VARCHAR(255),
    checked_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_cookie_check_account ON cookie_check_log(account_type, account_id);

-- 任务执行日志
CREATE TABLE IF NOT EXISTS task_execution_log (
    id BIGSERIAL PRIMARY KEY,
    task_name VARCHAR(80) NOT NULL,
    action VARCHAR(80) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'success',
    resource_id BIGINT,
    resource_version_id BIGINT,
    target_id VARCHAR(80),
    message TEXT NOT NULL,
    detail_json JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_task_execution_log_created_at ON task_execution_log(created_at DESC);
CREATE INDEX idx_task_execution_log_status ON task_execution_log(status);
CREATE INDEX IF NOT EXISTS idx_task_execution_log_push_success_version ON task_execution_log(resource_version_id) WHERE task_name = 'telegram_push_service' AND status = 'success' AND resource_version_id IS NOT NULL;
