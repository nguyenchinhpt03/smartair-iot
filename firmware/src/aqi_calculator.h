#pragma once
#include <Arduino.h>

// Tính AQI tiện nghi vi khí hậu (Indoor Comfort Index) từ Nhiệt độ và Độ ẩm BME280
int calculate_comfort_aqi(float temp_c, float hum_pct);

// Tính AQI: Nếu có PM2.5/CO thì tính theo US EPA, nếu chỉ có BME280 thì tính theo Comfort Index
int calculate_aqi(float pm25_ugm3, float co_ppm, float temp_c = 25.0f, float hum_pct = 50.0f);


// Trả về màu LED tương ứng với mức AQI
// r, g, b: 0 hoặc 1 (HIGH/LOW cho LED common cathode)
void aqi_to_rgb(int aqi, bool &r, bool &g, bool &b);

// Trả về chuỗi mô tả mức AQI (để in Serial)
const char* aqi_level_str(int aqi);
