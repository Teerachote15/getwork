-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: getworks_app
-- ------------------------------------------------------
-- Server version	9.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `admin_logs`
--

DROP TABLE IF EXISTS `admin_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_logs` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `admin_id` int NOT NULL,
  `action` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `target_id` int DEFAULT NULL,
  `details` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `admin_id` (`admin_id`),
  CONSTRAINT `admin_logs_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_logs`
--

LOCK TABLES `admin_logs` WRITE;
/*!40000 ALTER TABLE `admin_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `admin_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `comment_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `post_id` int NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `comment_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`comment_id`),
  KEY `user_id` (`user_id`),
  KEY `post_id` (`post_id`),
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `comments_ibfk_2` FOREIGN KEY (`post_id`) REFERENCES `posts` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `escrow_payments`
--

DROP TABLE IF EXISTS `escrow_payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `escrow_payments` (
  `escrow_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employer_id` int NOT NULL,
  `worker_id` int NOT NULL,
  `job_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `status` enum('held','released','refunded') COLLATE utf8mb4_unicode_ci DEFAULT 'held',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `released_at` datetime DEFAULT NULL,
  `refunded_at` datetime DEFAULT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`escrow_id`),
  KEY `employer_id` (`employer_id`),
  KEY `worker_id` (`worker_id`),
  KEY `job_id` (`job_id`),
  CONSTRAINT `escrow_payments_ibfk_1` FOREIGN KEY (`employer_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `escrow_payments_ibfk_2` FOREIGN KEY (`worker_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `escrow_payments_ibfk_3` FOREIGN KEY (`job_id`) REFERENCES `job_details` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `escrow_payments`
--

LOCK TABLES `escrow_payments` WRITE;
/*!40000 ALTER TABLE `escrow_payments` DISABLE KEYS */;
/*!40000 ALTER TABLE `escrow_payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_categories`
--

DROP TABLE IF EXISTS `job_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_categories` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_categories`
--

LOCK TABLES `job_categories` WRITE;
/*!40000 ALTER TABLE `job_categories` DISABLE KEYS */;
INSERT INTO `job_categories` VALUES (1,'เว็บไชต์',''),(2,'ออกแบบกราฟิก',''),(3,'การตลาดโฆษณา',''),(4,'สถาปัตย์และวิศวกรรม','');
/*!40000 ALTER TABLE `job_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_details`
--

DROP TABLE IF EXISTS `job_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_details` (
  `job_id` int NOT NULL AUTO_INCREMENT,
  `post_id` int NOT NULL,
  `detail` text COLLATE utf8mb4_unicode_ci,
  `deadline` date DEFAULT NULL,
  `image` text COLLATE utf8mb4_unicode_ci,
  `contact` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('waiting','in_progress','completed') COLLATE utf8mb4_unicode_ci DEFAULT 'waiting',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_id`),
  KEY `post_id` (`post_id`),
  CONSTRAINT `job_details_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `posts` (`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_details`
--

LOCK TABLES `job_details` WRITE;
/*!40000 ALTER TABLE `job_details` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_details` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_milestones`
--

DROP TABLE IF EXISTS `job_milestones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_milestones` (
  `milestone_id` int NOT NULL AUTO_INCREMENT,
  `job_id` int NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `due_date` date DEFAULT NULL,
  `status` enum('not_started','in_progress','done') COLLATE utf8mb4_unicode_ci DEFAULT 'not_started',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`milestone_id`),
  KEY `job_id` (`job_id`),
  CONSTRAINT `job_milestones_ibfk_1` FOREIGN KEY (`job_id`) REFERENCES `job_details` (`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_milestones`
--

LOCK TABLES `job_milestones` WRITE;
/*!40000 ALTER TABLE `job_milestones` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_milestones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posts`
--

DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posts` (
  `post_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `image_post` text COLLATE utf8mb4_unicode_ci,
  `post_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `post_category` int DEFAULT NULL,
  `wage` decimal(10,2) DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `post_type` enum('employer','worker') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`post_id`),
  KEY `user_id` (`user_id`),
  KEY `post_category` (`post_category`),
  CONSTRAINT `posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `posts_ibfk_2` FOREIGN KEY (`post_category`) REFERENCES `job_categories` (`category_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posts`
--

LOCK TABLES `posts` WRITE;
/*!40000 ALTER TABLE `posts` DISABLE KEYS */;
INSERT INTO `posts` VALUES (1,1,NULL,'กราฟฟิค',2,9210.00,'อออกแบบกแบกฟ','employer','approved','2025-11-01 17:23:23'),(2,1,'/uploads/1761992707109-xx0g5cpj8d8.jpg','รับสร้างรูปปั้น',4,9000.00,'แห่งเสรีภาพ','worker','approved','2025-11-01 17:25:07'),(3,2,'/uploads/1762114197985-wuehg3u6r0g.jpg','ออกแบบกาฟิกผังบ้าน',2,100.00,'ขอฟรีแลนซ์ที่เต็มใจ','worker','approved','2025-11-03 03:09:57');
/*!40000 ALTER TABLE `posts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ratings`
--

DROP TABLE IF EXISTS `ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ratings` (
  `rating_id` int NOT NULL AUTO_INCREMENT,
  `from_user_id` int NOT NULL,
  `to_user_id` int NOT NULL,
  `job_id` int DEFAULT NULL,
  `rate` int DEFAULT NULL,
  `report` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`rating_id`),
  KEY `from_user_id` (`from_user_id`),
  KEY `to_user_id` (`to_user_id`),
  KEY `job_id` (`job_id`),
  CONSTRAINT `ratings_ibfk_1` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `ratings_ibfk_2` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `ratings_ibfk_3` FOREIGN KEY (`job_id`) REFERENCES `job_details` (`job_id`),
  CONSTRAINT `ratings_chk_1` CHECK ((`rate` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ratings`
--

LOCK TABLES `ratings` WRITE;
/*!40000 ALTER TABLE `ratings` DISABLE KEYS */;
/*!40000 ALTER TABLE `ratings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `search_logs`
--

DROP TABLE IF EXISTS `search_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `search_logs` (
  `search_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `search_text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `result_count` int DEFAULT '0',
  `searched_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`search_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `search_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `search_logs`
--

LOCK TABLES `search_logs` WRITE;
/*!40000 ALTER TABLE `search_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `search_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `transaction_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `type` enum('topup','withdraw','payment') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','completed','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `via` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'omise',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `external_ref` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`transaction_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES (1,1,100.00,'topup','pending','omise','2025-11-01 19:23:01',NULL),(2,1,100.00,'topup','pending','omise','2025-11-01 19:24:52',NULL),(3,1,100.00,'topup','pending','omise','2025-11-01 21:35:26',NULL),(4,1,100.00,'topup','pending','omise','2025-11-01 21:35:44',NULL),(5,1,1000.00,'topup','pending','omise','2025-11-01 21:36:39',NULL),(6,1,200.00,'topup','pending','omise','2025-11-01 21:41:41',NULL),(7,1,222.00,'topup','completed','omise','2025-11-01 21:43:14',NULL),(8,1,333.00,'topup','completed','omise','2025-11-01 21:48:04',NULL),(9,1,111.00,'topup','completed','omise','2025-11-01 21:52:14',NULL),(10,1,150.00,'topup','completed','omise','2025-11-01 21:53:14',NULL),(11,1,80.00,'topup','completed','omise','2025-11-02 18:40:00','chrg_test_65kxsnfvy4yvtsj7pwh'),(12,1,78.00,'topup','completed','omise','2025-11-02 19:23:42','chrg_test_65ky815wtlb5pplac6t'),(13,1,200.00,'withdraw','completed','abc','2025-11-02 19:31:39',NULL),(14,1,234.00,'withdraw','completed','abc','2025-11-02 19:37:52',NULL),(15,1,40.00,'withdraw','completed','abc','2025-11-02 20:00:41',NULL),(16,1,100.00,'withdraw','pending','defg','2025-11-02 20:12:42',NULL),(17,1,100.00,'withdraw','pending','defg','2025-11-02 20:12:46',NULL),(18,1,100.00,'withdraw','pending','defg','2025-11-02 20:12:53',NULL),(19,1,100.00,'withdraw','pending','eiou','2025-11-02 20:16:39',NULL),(20,1,100.00,'withdraw','pending','eiou','2025-11-02 20:16:43',NULL),(21,1,100.00,'withdraw','pending','eiou','2025-11-02 20:16:57',NULL),(22,1,100.00,'withdraw','pending','eiou','2025-11-02 20:17:03',NULL),(23,1,100.00,'withdraw','pending','helopo','2025-11-02 20:19:51',NULL),(24,1,100.00,'withdraw','pending','helopo','2025-11-02 20:19:53',NULL),(25,1,100.00,'withdraw','completed','helopo','2025-11-02 20:21:48','trsf_test_65kyshd2cwy3kg9mhfy'),(26,1,20.00,'withdraw','pending','bkasdk','2025-11-02 20:32:43',NULL),(27,1,30.00,'withdraw','pending','hesap','2025-11-02 20:33:20',NULL),(28,1,30.00,'withdraw','pending','hesap','2025-11-02 20:33:23',NULL),(29,1,50.00,'withdraw','completed','sadsa','2025-11-02 20:33:40','trsf_test_65kywnvk9s3hqzdvqhs');
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `displayname` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` text COLLATE utf8mb4_unicode_ci,
  `about_me` text COLLATE utf8mb4_unicode_ci,
  `education_level` enum('มัธยมศึกษาต้น','มัธยมศึกษาปลาย','ปริญญาตรี','ปริญญาโท','ปริญญาเอก') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `education_history` text COLLATE utf8mb4_unicode_ci,
  `work_experience` text COLLATE utf8mb4_unicode_ci,
  `money` decimal(10,2) DEFAULT '0.00',
  `role` enum('user','admin') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `suspended` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'moss001','$2a$10$T6Ve/QF3JMlf7b.rah9WPuD2H254dSmUh95iLFJO7uoMGcEIaldzy','moss001@gmail.com','mossTchote','/uploads/1762108945895-2nfjqpl3xx2.png','',NULL,'','',350.00,'user','2025-11-01 15:39:58',0),(2,'moss002','$2a$10$xLb/RqRyQLwGSwty5jVPduNv07fkyfvBkcs7NLX25tuWzDjIZl1B2','moss002@gmail.com','mossss','/uploads/1762099267130-ilkatirt5ub.png','',NULL,'','',0.00,'user','2025-11-02 20:39:36',0),(3,'adminmos1','$2a$10$RGORrEgKwlRl9fZTQKUWDO2KGH1W1Dyw1JgJ1skBx.1Lk8TZ5KnwS','adminmos1@gmail.com',NULL,NULL,NULL,NULL,NULL,NULL,0.00,'admin','2025-11-03 01:50:14',0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-03  4:25:01
