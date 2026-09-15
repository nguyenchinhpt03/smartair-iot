#pragma once
#include <Arduino.h>
#include "sensors.h"

// Khởi tạo WiFi thông minh qua WiFiManager:
// - Tự động kết nối WiFi đã lưu trong bộ nhớ Flash (NVS)
// - Nếu sang chỗ mới / không có mạng cũ -> Tự phát AP "SmartAir-Setup" để điện thoại kết nối và cài đặt
bool wifi_init_smart(const char* ap_name = "SmartAir-Setup", uint32_t portal_timeout_sec = 180);

// Xóa cấu hình WiFi đã lưu để phát lại AP cài đặt
void wifi_reset_settings();

// Gửi JSON lên server qua HTTP POST
int send_reading(const char* server_url, const char* device_id, const SensorReading &r);

