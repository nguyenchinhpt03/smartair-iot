#include <Arduino.h>
#include <WiFi.h>
#include "sensors.h"
#include "aqi_calculator.h"
#include "wifi_http.h"

// ═══════════════════════════════════════════════════════════════════
//  CẤU HÌNH HỆ THỐNG
// ═══════════════════════════════════════════════════════════════════
// URL Server Backend Online Render:
static const char* SERVER_URL    = "https://smartair-backend.onrender.com/api/reading";
static const char* DEVICE_ID     = "SA-001";

// ── Pin Còi Buzzer & Đèn LED RGB ──────────────────────────────────
// Đèn LED RGB Dương chung (Common Anode):
// Chân dài nhất nối 3.3V. Kích LOW = SÁNG, HIGH = TẮT.
#if CONFIG_IDF_TARGET_ESP32S3
  #define BUZZER   10
  #define LED_R    11
  #define LED_G    12
  #define LED_B    13
#else
  #define LED_R    4
  #define LED_G    5
  #define LED_B    18
  #define BUZZER   19
#endif

// ── Khoảng thời gian đọc ──────────────────────────────────────────
#define FAST_INTERVAL_MS   10000UL   // BME280 + PMS5003: 10 giây
#define SLOW_INTERVAL_MS   30000UL   // MQ-135 + MQ-7:   30 giây
#define SEND_INTERVAL_MS   60000UL   // Gửi lên server:  60 giây

// ── Trạng thái toàn cục ───────────────────────────────────────────
static SampleBuffer  buf       = {};
static unsigned long last_fast = 0;
static unsigned long last_slow = 0;
static unsigned long last_send = 0;

// ═══════════════════════════════════════════════════════════════════
//  HÀM TIỆN ÍCH
// ═══════════════════════════════════════════════════════════════════

// Cập nhật LED RGB (Dương chung - Common Anode: LOW là sáng)
static void update_led_buzzer(int aqi) {
    bool r, g, b;
    aqi_to_rgb(aqi, r, g, b);

    // Common Anode: r=true -> LOW (sáng), r=false -> HIGH (tắt)
    digitalWrite(LED_R, r ? LOW : HIGH);
    digitalWrite(LED_G, g ? LOW : HIGH);
    digitalWrite(LED_B, b ? LOW : HIGH);

    if (aqi > 150) {
        tone(BUZZER, 1000, 3000);  // 1kHz trong 3 giây
    } else {
        noTone(BUZZER);
    }
}

static void print_reading(const SensorReading &r) {
    Serial.println("─────────────────────────────────────");
    Serial.printf("AQI:             %d  [%s]\n", r.aqi, aqi_level_str(r.aqi));
    Serial.printf("Bụi mịn PM2.5:   %.1f µg/m³\n", r.pm25_ugm3);
    Serial.printf("Bụi PM10:        %.1f µg/m³\n", r.pm10_ugm3);
    Serial.printf("Khí CO₂:         %.0f ppm\n",   r.co2_ppm);
    Serial.printf("Khí CO:          %.1f ppm\n",   r.co_ppm);
    Serial.printf("Khí NH₃:         %.1f ppm\n",   r.nh3_ppm);
    Serial.printf("Nhiệt độ:        %.1f °C\n",    r.temperature_c);
    Serial.printf("Độ ẩm:           %.1f %%\n",    r.humidity_pct);
    Serial.printf("Áp suất:         %.1f hPa\n",   r.pressure_hpa);
    Serial.println("─────────────────────────────────────");
}

// ═══════════════════════════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════════════════════════
void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n[SmartAir] Khởi động hệ thống đầy đủ cảm biến (ESP32-S3 N16R8)...");

    // LED RGB Dương chung (ban đầu xuất HIGH để tắt đèn) & Buzzer
    pinMode(LED_R,  OUTPUT); pinMode(LED_G,  OUTPUT);
    pinMode(LED_B,  OUTPUT); pinMode(BUZZER, OUTPUT);
    digitalWrite(LED_R, HIGH); 
    digitalWrite(LED_G, HIGH); 
    digitalWrite(LED_B, HIGH); 
    digitalWrite(BUZZER, LOW);

    // Khởi tạo toàn bộ cảm biến (BME280, PMS5003, MQ-135, MQ-7)
    sensors_init();

    // Wi-Fi thông minh (WiFiManager):
    // Tự kết nối mạng đã lưu trong Flash NVS.
    // Nếu sang chỗ mới hoặc chưa lưu, tự phát AP "SmartAir-Setup" để điện thoại kết nối cấu hình.
    wifi_init_smart("SmartAir-Setup", 180);

    Serial.println("[SmartAir] Setup xong — bắt đầu thu thập dữ liệu chu kỳ");
}

// ═══════════════════════════════════════════════════════════════════
//  LOOP
// ═══════════════════════════════════════════════════════════════════
void loop() {
    wifi_server_handle();
    unsigned long now = millis();

    // ── Đọc BME280 + PMS5003 mỗi 10 giây ────────────────────────
    if (now - last_fast >= FAST_INTERVAL_MS) {
        read_fast_sensors(buf);
        last_fast = now;
    }

    // ── Đọc MQ-135 + MQ-7 mỗi 30 giây ───────────────────────────
    if (now - last_slow >= SLOW_INTERVAL_MS) {
        read_slow_sensors(buf);
        last_slow = now;
    }

    // ── Sau 60 giây: tính trung bình → AQI → cập nhật LED → gửi Server ──
    if (now - last_send >= SEND_INTERVAL_MS) {
        SensorReading r = average_buffer(buf);

        if (!r.valid) {
            Serial.println("[Main] Buffer chưa đủ mẫu — bỏ qua chu kỳ này");
            last_send = now;
            return;
        }

        // Tính AQI tổng hợp từ Bụi PM2.5, Khí CO và Nhiệt ẩm
        r.aqi = calculate_aqi(r.pm25_ugm3, r.co_ppm, r.temperature_c, r.humidity_pct);
        update_led_buzzer(r.aqi);

        // In dữ liệu ra Serial Monitor
        print_reading(r);

        // Gửi gói JSON lên Server
        send_reading(SERVER_URL, DEVICE_ID, r);

        last_send = now;
    }

    // ── Tự reconnect WiFi nếu mất kết nối hoặc tự phát lại AP khi đổi vị trí ──
    if (WiFi.status() != WL_CONNECTED) {
        static unsigned long last_reconnect = 0;
        static int disconnect_count = 0;

        if (now - last_reconnect > 20000UL) {  // Kiểm tra mỗi 20s
            Serial.println("[WiFi] Đang thử kết nối lại mạng cũ...");
            WiFi.reconnect();
            last_reconnect = now;
            disconnect_count++;

            // Nếu thử 5 lần (khoảng gần 2 phút) không thấy mạng cũ (do đã chuyển sang chỗ mới)
            // -> Tự động kích hoạt lại AP "SmartAir-Setup" để người dùng mở App cài Wi-Fi mới!
            if (disconnect_count >= 5) {
                Serial.println("[WiFi] Không tìm thấy mạng cũ -> Mở lại AP 'SmartAir-Setup' để cấu hình mạng mới!");
                wifi_init_smart("SmartAir-Setup", 180);
                disconnect_count = 0;
            }
        }
    }
}
