#pragma once
#include <Arduino.h>

// ── Cấu trúc 1 bản đọc hoàn chỉnh sau khi tính trung bình ───────
struct SensorReading {
    float co2_ppm;
    float nh3_ppm;
    float benzene_ppm;
    float co_ppm;
    float temperature_c;
    float humidity_pct;
    float pressure_hpa;
    float pm1_ugm3;
    float pm25_ugm3;
    float pm10_ugm3;
    int   aqi;
    bool  valid;  // FALSE nếu chưa có đủ mẫu
};

// ── Buffer tích lũy mẫu trong 60 giây ────────────────────────────
struct SampleBuffer {
    // BME280 + PMS5003 đọc mỗi 10s → tối đa 6 mẫu/phút
    float temp[6], hum[6], press[6];
    float pm1[6],  pm25[6], pm10[6];
    int   fast_count;   // 0–6

    // MQ-135 + MQ-7 đọc mỗi 30s → tối đa 2 mẫu/phút
    float co2[2], nh3[2], benzene[2], co[2];
    int   slow_count;   // 0–2
};

// ── API ──────────────────────────────────────────────────────────
void          sensors_init();
void          read_fast_sensors(SampleBuffer &buf);   // Đọc BME280 + PMS5003 mỗi 10s
void          read_slow_sensors(SampleBuffer &buf);   // Đọc MQ-135 + MQ-7 mỗi 30s
SensorReading average_buffer(SampleBuffer &buf);      // Tổng hợp trung bình 60s
