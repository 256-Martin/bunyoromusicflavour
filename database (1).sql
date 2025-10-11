-- Create Database
CREATE DATABASE IF NOT EXISTS bunyoro_music_flavour;
USE bunyoro_music_flavour;

-- Users Table (for artists and administrators)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    location VARCHAR(100),
    profile_image VARCHAR(255),
    bio TEXT,
    user_type ENUM('artist', 'admin', 'listener') DEFAULT 'artist',
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active'
);

-- Artists Profile Table (extends users table for artist-specific data)
CREATE TABLE artist_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    stage_name VARCHAR(100) NOT NULL,
    genre VARCHAR(100),
    years_active INT,
    social_media_links JSON,
    total_plays INT DEFAULT 0,
    total_downloads INT DEFAULT 0,
    total_followers INT DEFAULT 0,
    verified_artist BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_stage_name (stage_name)
);

-- Categories Table for music classification
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    slug VARCHAR(100) UNIQUE NOT NULL,
    parent_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Audio Tracks Table
CREATE TABLE audio_tracks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL,
    description TEXT,
    audio_file_path VARCHAR(255) NOT NULL,
    thumbnail_path VARCHAR(255),
    duration INT, -- in seconds
    file_size BIGINT, -- in bytes
    file_format VARCHAR(10),
    bitrate INT,
    category_id INT,
    lyrics TEXT,
    release_date DATE,
    plays_count INT DEFAULT 0,
    downloads_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_explicit BOOLEAN DEFAULT FALSE,
    status ENUM('draft', 'published', 'archived') DEFAULT 'published',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (artist_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    FULLTEXT(title, description, lyrics)
);

-- Videos Table
CREATE TABLE videos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL,
    description TEXT,
    video_file_path VARCHAR(255),
    youtube_video_id VARCHAR(50),
    thumbnail_path VARCHAR(255),
    duration INT, -- in seconds
    category_id INT,
    views_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    status ENUM('draft', 'published', 'archived') DEFAULT 'published',
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL,
    FOREIGN KEY (artist_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    FULLTEXT(title, description)
);

-- Albums/Playlists Table
CREATE TABLE albums (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    artist_id INT NOT NULL,
    description TEXT,
    cover_image_path VARCHAR(255),
    release_date DATE,
    total_tracks INT DEFAULT 0,
    total_duration INT DEFAULT 0, -- in seconds
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (artist_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Album Tracks Junction Table
CREATE TABLE album_tracks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    album_id INT NOT NULL,
    audio_track_id INT NOT NULL,
    track_number INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    FOREIGN KEY (audio_track_id) REFERENCES audio_tracks(id) ON DELETE CASCADE,
    UNIQUE KEY unique_album_track (album_id, audio_track_id)
);

-- User Favorites Table
CREATE TABLE user_favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    audio_track_id INT NULL,
    video_id INT NULL,
    album_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (audio_track_id) REFERENCES audio_tracks(id) ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE,
    FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
    CHECK (
        (audio_track_id IS NOT NULL AND video_id IS NULL AND album_id IS NULL) OR
        (audio_track_id IS NULL AND video_id IS NOT NULL AND album_id IS NULL) OR
        (audio_track_id IS NULL AND video_id IS NULL AND album_id IS NOT NULL)
    )
);

-- Play History Table
CREATE TABLE play_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NULL, -- NULL for anonymous plays
    audio_track_id INT NULL,
    video_id INT NULL,
    play_duration INT, -- in seconds
    played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (audio_track_id) REFERENCES audio_tracks(id) ON DELETE SET NULL,
    FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE SET NULL,
    CHECK (
        (audio_track_id IS NOT NULL AND video_id IS NULL) OR
        (audio_track_id IS NULL AND video_id IS NOT NULL)
    )
);

-- Downloads Table
CREATE TABLE downloads (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NULL, -- NULL for anonymous downloads
    audio_track_id INT NOT NULL,
    downloaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (audio_track_id) REFERENCES audio_tracks(id) ON DELETE CASCADE
);

-- Comments Table
CREATE TABLE comments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    audio_track_id INT NULL,
    video_id INT NULL,
    parent_comment_id INT NULL, -- for nested comments
    comment_text TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (audio_track_id) REFERENCES audio_tracks(id) ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    CHECK (
        (audio_track_id IS NOT NULL AND video_id IS NULL) OR
        (audio_track_id IS NULL AND video_id IS NOT NULL)
    )
);

-- Contact Messages Table
CREATE TABLE contact_messages (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    replied_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Newsletter Subscriptions Table
CREATE TABLE newsletter_subscriptions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(100) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unsubscribed_at TIMESTAMP NULL
);

-- Site Settings Table
CREATE TABLE site_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type ENUM('string', 'integer', 'boolean', 'json') DEFAULT 'string',
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Ads Table for advertisement management
CREATE TABLE advertisements (
    id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    ad_type ENUM('banner', 'video', 'audio') NOT NULL,
    ad_content TEXT, -- URL or embed code
    image_path VARCHAR(255),
    target_url VARCHAR(255),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    max_impressions INT,
    current_impressions INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ad Impressions Table
CREATE TABLE ad_impressions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ad_id INT NOT NULL,
    user_id INT NULL,
    impression_date DATE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    FOREIGN KEY (ad_id) REFERENCES advertisements(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create Indexes for Performance
CREATE INDEX idx_audio_tracks_artist_id ON audio_tracks(artist_id);
CREATE INDEX idx_audio_tracks_status ON audio_tracks(status);
CREATE INDEX idx_audio_tracks_featured ON audio_tracks(is_featured);
CREATE INDEX idx_videos_artist_id ON videos(artist_id);
CREATE INDEX idx_videos_status ON videos(status);
CREATE INDEX idx_play_history_user_id ON play_history(user_id);
CREATE INDEX idx_play_history_timestamp ON play_history(played_at);
CREATE INDEX idx_comments_content ON comments(audio_track_id, video_id);
CREATE INDEX idx_user_favorites ON user_favorites(user_id);

-- Insert Default Categories
INSERT INTO categories (name, description, slug) VALUES
('Traditional', 'Traditional Bunyoro music and cultural sounds', 'traditional'),
('Modern', 'Contemporary Bunyoro music with modern influences', 'modern'),
('Fusion', 'Fusion of traditional and modern elements', 'fusion'),
('Gospel', 'Religious and spiritual music', 'gospel'),
('Instrumental', 'Music focusing on traditional instruments', 'instrumental'),
('Dance', 'Music for cultural dances and celebrations', 'dance');

-- Insert Default Admin User
INSERT INTO users (username, email, password_hash, full_name, user_type, is_verified) 
VALUES ('admin', 'martinkissembo@gmail.com', 'hoimacity123', 'martin tech', 'admin', TRUE);

-- Insert Default Site Settings
INSERT INTO site_settings (setting_key, setting_value, setting_type, description) VALUES
('site_name', 'Bunyoro Music Flavour', 'string', 'Website name'),
('site_description', 'Premium Music Platform for Bunyoro Music', 'string', 'Website description'),
('contact_email', 'martinkissembo@gmail.com', 'string', 'Primary contact email'),
('contact_phone', '+256762621780', 'string', 'Primary contact phone'),
('youtube_channel_id', 'UClkK6-wjQGAh4TFtmMI7wgA', 'string', 'YouTube channel ID'),
('developer_whatsapp', '256762621780', 'string', 'Developer WhatsApp number'),
('max_upload_size', '104857600', 'integer', 'Maximum file upload size in bytes (100MB)'),
('allowed_audio_formats', '["mp3", "wav", "ogg", "m4a"]', 'json', 'Allowed audio file formats'),
('allowed_video_formats', '["mp4", "mov", "avi", "mkv"]', 'json', 'Allowed video file formats'),
('maintenance_mode', 'false', 'boolean', 'Website maintenance mode');