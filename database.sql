-- ============================================================
--  CHIT-CHAT  —  Full Database Schema
--  Matches app.py exactly (init_db + all route queries)
-- ============================================================

CREATE DATABASE IF NOT EXISTS chitchat
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE chitchat;

-- ============================================================
--  USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username     VARCHAR(50)  NOT NULL,
    phone_number VARCHAR(20)  NOT NULL,
    email        VARCHAR(100) NOT NULL,
    password     VARCHAR(255) NOT NULL,
    profile_pic  VARCHAR(255) DEFAULT NULL,
    bio          TEXT         DEFAULT NULL,
    verified     TINYINT(1)   DEFAULT 0,
    created_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_phone (phone_number),
    UNIQUE KEY uq_email (email),
    INDEX idx_username (username)
) ENGINE=InnoDB;

-- ============================================================
--  MESSAGES
--  type includes 'call' — recorded when a call ends
--  deleted_for_everyone — set to 1 instead of deleting the row
-- ============================================================
CREATE TABLE IF NOT EXISTS messages (
    id                   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_id            INT UNSIGNED NOT NULL,
    receiver_id          INT UNSIGNED NOT NULL,
    message              TEXT         NOT NULL,
    type                 ENUM('text','voice','image','video','call') DEFAULT 'text',
    is_seen              TINYINT(1)   DEFAULT 0,
    deleted_for_everyone TINYINT(1)   DEFAULT 0,
    timestamp            TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_msg_sender   FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_msg_receiver FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_sender    (sender_id),
    INDEX idx_receiver  (receiver_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB;

-- ============================================================
--  MESSAGE REACTIONS
--  emoji is VARCHAR(10) — matches app.py validation (len > 10 rejected)
-- ============================================================
CREATE TABLE IF NOT EXISTS message_reactions (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    message_id INT NOT NULL,
    user_id    INT NOT NULL,
    emoji      VARCHAR(10) NOT NULL,
    created_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_react (message_id, user_id, emoji)
) ENGINE=InnoDB;

-- ============================================================
--  MESSAGE DELETIONS  ("delete for me")
--  No delete_type column — app only uses this table for "for me"
--  "delete for everyone" is handled by deleted_for_everyone on messages
-- ============================================================
CREATE TABLE IF NOT EXISTS message_deletions (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    message_id INT NOT NULL,
    user_id    INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_del (message_id, user_id)
) ENGINE=InnoDB;

-- ============================================================
--  NOTIFICATIONS
--  from_user_id — matches JOIN in get_notifications query
--  reference_id — matches insert in react_message handler
--  content      — matches SELECT n.* … n.content in get_notifications
--  type         — VARCHAR(20), not ENUM, so new types can be added freely
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT         NOT NULL,
    type         VARCHAR(20) NOT NULL,
    from_user_id INT         DEFAULT NULL,
    reference_id INT         DEFAULT NULL,
    content      TEXT,
    is_read      TINYINT(1)  DEFAULT 0,
    created_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_user   (user_id),
    INDEX idx_notif_unread (user_id, is_read)
) ENGINE=InnoDB;

-- ============================================================
--  STATUSES  (24-hour stories)
--  expires_at is DATETIME — app inserts via DATE_ADD(NOW(), INTERVAL 24 HOUR)
--  media_type is VARCHAR(10) — not ENUM, matches init_db
-- ============================================================
CREATE TABLE IF NOT EXISTS statuses (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT         NOT NULL,
    media_url  TEXT        NOT NULL,
    media_type VARCHAR(10) NOT NULL,
    caption    TEXT,
    created_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    INDEX idx_status_user    (user_id),
    INDEX idx_status_expires (expires_at)
) ENGINE=InnoDB;

-- ============================================================
--  STATUS VIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS status_views (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    status_id INT NOT NULL,
    user_id   INT NOT NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_status_view (status_id, user_id)
) ENGINE=InnoDB;

-- ============================================================
--  REELS
--  video_url is TEXT — matches init_db and upload_reel route
-- ============================================================
CREATE TABLE IF NOT EXISTS reels (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT  NOT NULL,
    video_url  TEXT NOT NULL,
    caption    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_reel_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
--  REEL LIKES
-- ============================================================
CREATE TABLE IF NOT EXISTS reel_likes (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    reel_id    INT NOT NULL,
    user_id    INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_reel_like (reel_id, user_id)
) ENGINE=InnoDB;

-- ============================================================
--  REEL COMMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS reel_comments (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    reel_id    INT  NOT NULL,
    user_id    INT  NOT NULL,
    comment    TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rc_reel (reel_id)
) ENGINE=InnoDB;

-- ============================================================
--  SONGS
--  audio_url / cover_url are TEXT — matches init_db and upload_song route
-- ============================================================
CREATE TABLE IF NOT EXISTS songs (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT          NOT NULL,
    audio_url  TEXT         NOT NULL,
    title      VARCHAR(200),
    artist     VARCHAR(200),
    cover_url  TEXT,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_song_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
--  SONG LIKES
-- ============================================================
CREATE TABLE IF NOT EXISTS song_likes (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    song_id    INT NOT NULL,
    user_id    INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_song_like (song_id, user_id)
) ENGINE=InnoDB;

-- ============================================================
--  FOLLOWS
-- ============================================================
CREATE TABLE IF NOT EXISTS follows (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    follower_id  INT UNSIGNED NOT NULL,
    following_id INT UNSIGNED NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_follow (follower_id, following_id),
    INDEX idx_follower (follower_id),
    INDEX idx_following (following_id)
) ENGINE=InnoDB;

-- ============================================================
--  BLOCKS
-- ============================================================
CREATE TABLE IF NOT EXISTS blocks (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    blocker_id INT UNSIGNED NOT NULL,
    blocked_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_block (blocker_id, blocked_id),
    INDEX idx_blocker (blocker_id),
    INDEX idx_blocked (blocked_id)
) ENGINE=InnoDB;

-- ============================================================
--  POSTS  (permanent image / video uploads)
-- ============================================================
CREATE TABLE IF NOT EXISTS posts (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT          NOT NULL,
    media_url  TEXT         NOT NULL,
    media_type VARCHAR(10)  NOT NULL,
    caption    TEXT,
    created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_post_user (user_id)
) ENGINE=InnoDB;
