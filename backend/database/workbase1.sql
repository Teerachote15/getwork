-- สร้างฐานข้อมูล
CREATE DATABASE getworks_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE getworks_app;

-- ตารางผู้ใช้งาน
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    displayname VARCHAR(100),
    image TEXT,
    about_me TEXT,
    education_level ENUM('มัธยมศึกษาต้น','มัธยมศึกษาปลาย','ปริญญาตรี','ปริญญาโท','ปริญญาเอก'),
    education_history TEXT,
    work_experience TEXT,
    money DECIMAL(10,2) DEFAULT 0.00,
    role ENUM('user', 'admin') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- หมวดหมู่งาน
CREATE TABLE job_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

-- โพสต์งาน (โดย freelancer)
CREATE TABLE posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    image_post TEXT,
    post_name VARCHAR(255) NOT NULL,
    post_category INT,
    wage DECIMAL(10,2),
    description TEXT,
    post_type ENUM('employer','worker') NOT NULL, -- เพิ่มบรรทัดนี้
    status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (post_category) REFERENCES job_categories(category_id)
);

-- รายละเอียดของงาน
CREATE TABLE job_details (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    detail TEXT,
    deadline DATE,
    image TEXT,
    contact VARCHAR(255),
    status ENUM('waiting', 'in_progress', 'completed') DEFAULT 'waiting',
    FOREIGN KEY (post_id) REFERENCES posts(post_id)
);

-- ความคิดเห็น    
CREATE TABLE comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    post_id INT NOT NULL,
    message TEXT NOT NULL,
    comment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (post_id) REFERENCES posts(post_id)
);

-- การให้คะแนน/รีวิว
CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    from_user_id INT NOT NULL,
    to_user_id INT NOT NULL,
    job_id INT,
    rate INT CHECK (rate BETWEEN 1 AND 5),
    report TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_user_id) REFERENCES users(user_id),
    FOREIGN KEY (to_user_id) REFERENCES users(user_id),
    FOREIGN KEY (job_id) REFERENCES job_details(job_id)
);

-- ธุรกรรม (เติมเงิน, จ่ายเงิน, ถอนเงิน)
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    type ENUM('topup', 'withdraw', 'payment') NOT NULL,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    via VARCHAR(50) DEFAULT 'omise',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- บันทึกการค้นหา (AI Search Log)
CREATE TABLE search_logs (
    search_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    search_text TEXT NOT NULL,
    result_count INT DEFAULT 0,
    searched_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE admin_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT NOT NULL,
    action VARCHAR(100),
    target_type VARCHAR(50),
    target_id INT,
    details TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(user_id)
);

CREATE TABLE job_milestones (
    milestone_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT NOT NULL,
    title VARCHAR(255),
    description TEXT,
    due_date DATE,
    status ENUM('not_started', 'in_progress', 'done') DEFAULT 'not_started',
    FOREIGN KEY (job_id) REFERENCES job_details(job_id)
);

-- Escrow payments (เงินที่ถูก hold ไว้)
CREATE TABLE escrow_payments (
    escrow_id VARCHAR(100) PRIMARY KEY,
    employer_id INT NOT NULL,
    worker_id INT NOT NULL,
    job_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    status ENUM('held', 'released', 'refunded') DEFAULT 'held',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    released_at DATETIME NULL,
    refunded_at DATETIME NULL,
    reason TEXT,
    FOREIGN KEY (employer_id) REFERENCES users(user_id),
    FOREIGN KEY (worker_id) REFERENCES users(user_id),
    FOREIGN KEY (job_id) REFERENCES job_details(job_id)
);