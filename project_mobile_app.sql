-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Nov 13, 2026 at 10:21 PM
-- Server version: 8.0.46
-- PHP Version: 8.3.36

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `project_mobile_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` int NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `emoji` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 0xF09F8FB7EFB88F,
  `is_active` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`category_id`, `name`, `emoji`, `is_active`) VALUES
(1, 'Furniture', '🪑', 1),
(2, 'Books', '📚', 1),
(3, 'Technology', '💻', 1),
(4, 'Transport', '🚲', 1),
(5, 'Home & kitchen', '🍳', 1),
(6, 'Clothing', '👕', 1),
(7, 'Appliances', '🔌', 1),
(8, 'Sports', '⚽', 1),
(9, 'Music', '🎵', 1),
(10, 'Stationery', '✏️', 1),
(11, 'Other', '📦', 1);

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

CREATE TABLE `locations` (
  `location_id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zone` enum('on_campus','off_campus') COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `locations`
--

INSERT INTO `locations` (`location_id`, `name`, `zone`, `is_active`) VALUES
(1, 'S-Room Apartment', 'off_campus', 1),
(2, 'Saen Fah Luang Dormitory', 'off_campus', 1),
(3, 'PHUTARA APARTMENT MFU', 'off_campus', 1),
(4, 'PapaMama@MFU', 'off_campus', 1),
(5, 'MFU Home Stay', 'off_campus', 1),
(6, 'SJD Mansion', 'off_campus', 1),
(7, 'Kittiya Dormitory', 'off_campus', 1),
(8, 'Weang Fah Luang \"Bann Goo\"', 'off_campus', 1),
(9, 'Rattana Dormitory', 'off_campus', 1),
(10, 'Tharnn Residence', 'off_campus', 1),
(11, 'Regent Mansion MFU', 'off_campus', 1),
(12, 'Lamduan 1 Dormitory', 'on_campus', 1),
(13, 'Lamduan 2 Dormitory', 'on_campus', 1),
(14, 'Lamduan 7 Dormitory', 'on_campus', 1),
(15, 'Sakthong 2 Dormitory', 'on_campus', 1),
(16, 'Sakthong 3 Dormitory', 'on_campus', 1),
(17, 'F2 Female Dormitory', 'on_campus', 1),
(18, 'F3 Female Dormitory', 'on_campus', 1),
(19, 'F4 Female Dormitory', 'on_campus', 1);

-- --------------------------------------------------------

--
-- Table structure for table `location_requests`
--

CREATE TABLE `location_requests` (
  `request_id` int NOT NULL,
  `requested_by` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zone` enum('on_campus','off_campus') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','reviewing','approved','merged','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `approved_location_id` int DEFAULT NULL,
  `merged_into_location_id` int DEFAULT NULL,
  `handled_by` int DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int NOT NULL,
  `product_id` int NOT NULL,
  `buyer_id` int NOT NULL,
  `seller_id` int NOT NULL,
  `seller_price` decimal(10,2) NOT NULL,
  `commission_rate` decimal(5,2) NOT NULL DEFAULT '0.00',
  `commission_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(10,2) NOT NULL,
  `seller_payout` decimal(10,2) NOT NULL,
  `status` enum('pending_payment','paid','ready_for_meetup','completed','cancelled','expired') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending_payment',
  `meetup_location` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `meetup_datetime` datetime DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `payment_deadline` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int NOT NULL,
  `order_id` int NOT NULL,
  `payment_method` enum('gateway','bank_transfer','cash','free') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'gateway',
  `gateway` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transaction_ref` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_slip_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `gateway_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `payment_status` enum('pending','processing','paid','failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `seller_transfer_ref` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `seller_transfer_status` enum('not_ready','pending','processing','paid','failed','held') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'not_ready',
  `seller_paid_at` datetime DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int NOT NULL,
  `seller_id` int NOT NULL,
  `title` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `item_condition` enum('new','like_new','good','fair') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `urgency_level` enum('normal','urgent','very_urgent') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `zone` enum('on_campus','off_campus') COLLATE utf8mb4_unicode_ci NOT NULL,
  `location_detail` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clearance_deadline` date DEFAULT NULL,
  `status` enum('pending_review','changes_requested','rejected','available','reserved','sold','hidden') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending_review',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `category_id` int DEFAULT NULL,
  `reject_reason` enum('prohibited_item','misleading','poor_photos','duplicate','other') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `review_note` text COLLATE utf8mb4_unicode_ci,
  `reviewed_by` int DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `location_id` int DEFAULT NULL,
  `view_count` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `seller_id`, `title`, `description`, `price`, `item_condition`, `urgency_level`, `zone`, `location_detail`, `clearance_deadline`, `status`, `created_at`, `updated_at`, `category_id`, `reject_reason`, `review_note`, `reviewed_by`, `reviewed_at`, `location_id`, `view_count`) VALUES
(1, 1, 'Oak Study Desk', 'A compact wooden study desk. Good condition, perfect for a dorm room.', 850.00, 'good', 'normal', 'on_campus', 'Near the dorm entrance', '2026-12-15', 'available', '2026-11-12 16:37:17', '2026-11-13 18:40:54', 1, NULL, NULL, NULL, NULL, 12, 1),
(2, 1, 'Acoustic Guitar', 'Acoustic guitar in good condition. Suitable for beginners.', 1200.00, 'good', 'urgent', 'on_campus', 'Lamduan 1 Dormitory', '2026-11-30', 'available', '2026-11-12 16:37:17', '2026-11-13 18:40:56', 9, NULL, NULL, NULL, NULL, 12, 1),
(3, 1, 'Desk Lamp', 'A small desk lamp with adjustable brightness.', 180.00, 'like_new', 'normal', 'off_campus', 'Near the apartment lobby', '2026-12-20', 'available', '2026-11-12 16:37:17', '2026-11-12 16:37:17', 7, NULL, NULL, NULL, NULL, 1, 0),
(4, 1, 'City Bicycle', 'A used city bicycle. Still works well for short-distance travel.', 950.00, 'fair', 'very_urgent', 'off_campus', 'Near S-Room Apartment', '2026-11-25', 'available', '2026-11-12 16:37:17', '2026-11-13 19:47:30', 4, NULL, NULL, NULL, NULL, 1, 1),
(17, 3, 'Japanese Folding Coffee Table', 'Japanese Folding Coffee Table', 150.00, 'like_new', 'normal', 'off_campus', NULL, NULL, 'pending_review', '2026-11-13 21:56:43', '2026-11-13 22:03:08', 1, NULL, NULL, 2, '2026-11-13 21:59:23', 6, 0);

-- --------------------------------------------------------

--
-- Table structure for table `product_images`
--

CREATE TABLE `product_images` (
  `image_id` int NOT NULL,
  `product_id` int NOT NULL,
  `image_url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_order` int NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_images`
--

INSERT INTO `product_images` (`image_id`, `product_id`, `image_url`, `display_order`, `created_at`) VALUES
(1, 1, 'https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExZmY4NWgzZWE5OTJ3d3FmdWZ4bzU0Zm5vajVrYWR1eHhvaTg4YmxyMCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/bNxE7bdyy5RdrfrND1/giphy.gif', 1, '2026-11-12 16:49:48'),
(2, 2, 'https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExcmV6cmQ0YTNmazJ5d2hhZmVxajUxc3BhZWE4OHM4dnk4amVyYm94ZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/sBikoeGRyOrK0/giphy.gif', 1, '2026-11-12 16:49:48'),
(3, 2, 'https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExcmV6cmQ0YTNmazJ5d2hhZmVxajUxc3BhZWE4OHM4dnk4amVyYm94ZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/sBikoeGRyOrK0/giphy.gif', 2, '2026-11-12 16:49:48'),
(4, 3, 'https://i.giphy.com/euGq9pgXoOVJcVhwRF.webp', 1, '2026-11-12 16:49:48'),
(5, 4, 'https://i.giphy.com/xT0GqrJNbZkRcr2Jgc.webp', 1, '2026-11-12 16:49:48'),
(6, 4, 'https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExMGNheW5oeXpiaGV3amhndzJ3aWhhc2x1ZHN5N2dtdDBrZDM0ZTN0dCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/fU2qTPhAKLdxT0ZRyF/giphy.gif', 1, '2026-11-12 16:49:48'),
(7, 17, 'http://localhost:3000/uploads/02d4739d9bd05949cb8f6ffa40fb60b9.jpg', 1, '2026-11-13 21:56:44'),
(8, 17, 'http://localhost:3000/uploads/e2e1fb2902c20b5512be80787bd6adb7.jpg', 2, '2026-11-13 21:56:44');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int NOT NULL,
  `student_id` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(97) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('member','admin') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'member',
  `status` enum('pending','active','suspended','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `verified_by` int DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `residence_location_id` int DEFAULT NULL,
  `residence_zone` enum('on_campus','off_campus') COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `student_id`, `username`, `email`, `password_hash`, `display_name`, `role`, `status`, `verified_by`, `verified_at`, `created_at`, `updated_at`, `residence_location_id`, `residence_zone`) VALUES
(1, '1234567890', 'test_member', 'member@test.local', '$argon2id$v=19$m=19456,t=2,p=1$+QjLPFu1XmByR0Sb1F5gRw$zjtXt6DFNE2a8cYFS1KQGbAqeQPOmqhvx1NjJbFBD24', 'Test Member', 'member', 'active', 2, '2026-11-13 18:58:38', '2026-11-10 18:09:58', '2026-11-13 22:04:33', 12, 'on_campus'),
(2, '1234567891', 'test_admin', 'admin@test.local', '$argon2id$v=19$m=19456,t=2,p=1$2pxeABsftZoGUuyRQhMwyA$c84hTd2vOgipegFlYrkw4nOEMhL8kTcdLx9awCUqSCA', 'Test Admin', 'admin', 'active', NULL, NULL, '2026-11-10 18:09:58', '2026-11-10 18:30:26', NULL, NULL),
(3, '0123456789', 'lethimcook', 'let@him.cook', '$argon2id$v=19$m=19456,t=2,p=1$KAz3Iq70hK5EwQntzRHbCw$Pm5l6aoY8VQPvleSutLCWDIfpNrWZfZVXZmuT4rrhyg', 'Let him cook', 'member', 'active', NULL, NULL, '2026-11-12 17:26:28', '2026-11-12 17:27:55', 6, 'off_campus');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`location_id`);

--
-- Indexes for table `location_requests`
--
ALTER TABLE `location_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `requested_by` (`requested_by`),
  ADD KEY `approved_location_id` (`approved_location_id`),
  ADD KEY `merged_into_location_id` (`merged_into_location_id`),
  ADD KEY `handled_by` (`handled_by`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `idx_orders_buyer` (`buyer_id`),
  ADD KEY `idx_orders_seller` (`seller_id`),
  ADD KEY `idx_orders_product` (`product_id`),
  ADD KEY `idx_orders_status` (`status`),
  ADD KEY `idx_orders_expiry_deadline` (`status`,`payment_deadline`),
  ADD KEY `idx_orders_buyer_product_attempts` (`buyer_id`,`product_id`,`status`,`updated_at`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD UNIQUE KEY `uq_payments_order` (`order_id`),
  ADD UNIQUE KEY `uq_transaction_ref` (`transaction_ref`),
  ADD KEY `idx_payment_status` (`payment_status`),
  ADD KEY `idx_seller_transfer_status` (`seller_transfer_status`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `idx_products_status` (`status`),
  ADD KEY `idx_products_zone` (`zone`),
  ADD KEY `idx_products_seller` (`seller_id`),
  ADD KEY `category_id` (`category_id`),
  ADD KEY `reviewed_by` (`reviewed_by`),
  ADD KEY `location_id` (`location_id`);

--
-- Indexes for table `product_images`
--
ALTER TABLE `product_images`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `idx_images_product` (`product_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_users_username` (`username`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD UNIQUE KEY `uq_users_student_id` (`student_id`),
  ADD KEY `idx_users_status` (`status`),
  ADD KEY `fk_users_verified_by` (`verified_by`),
  ADD KEY `residence_location_id` (`residence_location_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `category_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `locations`
--
ALTER TABLE `locations`
  MODIFY `location_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `location_requests`
--
ALTER TABLE `location_requests`
  MODIFY `request_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `product_images`
--
ALTER TABLE `product_images`
  MODIFY `image_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `location_requests`
--
ALTER TABLE `location_requests`
  ADD CONSTRAINT `location_requests_ibfk_1` FOREIGN KEY (`requested_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `location_requests_ibfk_2` FOREIGN KEY (`approved_location_id`) REFERENCES `locations` (`location_id`),
  ADD CONSTRAINT `location_requests_ibfk_3` FOREIGN KEY (`merged_into_location_id`) REFERENCES `locations` (`location_id`),
  ADD CONSTRAINT `location_requests_ibfk_4` FOREIGN KEY (`handled_by`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `fk_orders_buyer` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orders_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_orders_seller` FOREIGN KEY (`seller_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON UPDATE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `fk_products_seller` FOREIGN KEY (`seller_id`) REFERENCES `users` (`user_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`),
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `products_ibfk_3` FOREIGN KEY (`location_id`) REFERENCES `locations` (`location_id`);

--
-- Constraints for table `product_images`
--
ALTER TABLE `product_images`
  ADD CONSTRAINT `fk_images_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_verified_by` FOREIGN KEY (`verified_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`residence_location_id`) REFERENCES `locations` (`location_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
