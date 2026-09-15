#include "wifi_http.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

#include <WiFiManager.h>

bool wifi_init_smart(const char* ap_name, uint32_t portal_timeout_sec) {
    WiFiManager wm;

    // Giới hạn thời gian chờ cấu hình (mặc định 180 giây)
    // Nếu hết giờ mà không có ai kết nối cấu hình, ESP32 vẫn tiếp tục chạy offline
    wm.setConfigPortalTimeout(portal_timeout_sec);
    wm.setTitle("SmartAir - Cài Đặt Wi-Fi");

    Serial.println("\n══════════════════════════════════════════════════════");
    Serial.println("[WiFiManager] Đang kiểm tra kết nối Wi-Fi đã lưu...");
    Serial.printf("[WiFiManager] Nếu chưa có hoặc đổi địa điểm, phát AP: [%s]\n", ap_name);
    Serial.println("[WiFiManager] (Kết nối điện thoại vào mạng trên -> trang cài đặt sẽ tự hiện)");
    Serial.println("══════════════════════════════════════════════════════");

    // Tự kết nối WiFi đã lưu. Nếu thất bại, tự mở AP cấu hình Captive Portal
    bool res = wm.autoConnect(ap_name);

    if (!res) {
        Serial.println("[WiFiManager] Hết giờ chờ cấu hình! ESP32 tiếp tục đo cảm biến offline.");
        return false;
    }

    Serial.printf("[WiFiManager] Kết nối thành công! IP: %s\n", WiFi.localIP().toString().c_str());
    return true;
}

void wifi_reset_settings() {
    WiFiManager wm;
    wm.resetSettings();
    Serial.println("[WiFiManager] Đã xóa bộ nhớ Wi-Fi.");
}

#include <WiFiClientSecure.h>

int send_reading(const char* server_url, const char* device_id, const SensorReading &r) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[HTTP] Mất WiFi — bỏ qua lần gửi này");
        return -1;
    }

    // Làm tròn để giảm kích thước payload
    StaticJsonDocument<512> doc;
    doc["device_id"]     = device_id;
    doc["wifi_ssid"]     = WiFi.SSID();
    doc["ip_address"]    = WiFi.localIP().toString();
    doc["aqi"]           = r.aqi;
    doc["co2_ppm"]       = round(r.co2_ppm     * 10.0f)   / 10.0f;
    doc["nh3_ppm"]       = round(r.nh3_ppm     * 100.0f)  / 100.0f;
    doc["benzene_ppm"]   = round(r.benzene_ppm * 1000.0f) / 1000.0f;
    doc["co_ppm"]        = round(r.co_ppm      * 100.0f)  / 100.0f;
    doc["pm1_ugm3"]      = round(r.pm1_ugm3    * 10.0f)   / 10.0f;
    doc["pm25_ugm3"]     = round(r.pm25_ugm3   * 10.0f)   / 10.0f;
    doc["pm10_ugm3"]     = round(r.pm10_ugm3   * 10.0f)   / 10.0f;
    doc["temperature_c"] = round(r.temperature_c * 10.0f) / 10.0f;
    doc["humidity_pct"]  = round(r.humidity_pct  * 10.0f) / 10.0f;
    doc["pressure_hpa"]  = round(r.pressure_hpa  * 10.0f) / 10.0f;

    String body;
    serializeJson(doc, body);

    HTTPClient http;
    int code = -1;

    if (strncmp(server_url, "https://", 8) == 0) {
        WiFiClientSecure client;
        client.setInsecure(); // Bỏ qua verify cert CA để kết nối Cloud HTTPS dễ dàng
        http.begin(client, server_url);
        http.addHeader("Content-Type", "application/json");
        http.setTimeout(10000); // 10s cho HTTPS
        code = http.POST(body);
        http.end();
    } else {
        http.begin(server_url);
        http.addHeader("Content-Type", "application/json");
        http.setTimeout(5000);
        code = http.POST(body);
        http.end();
    }

    if (code == 200) {
        Serial.printf("[HTTP] OK — AQI=%d PM2.5=%.1f\n", r.aqi, r.pm25_ugm3);
    } else if (code < 0) {
        Serial.printf("[HTTP] Lỗi kết nối: %s\n", http.errorToString(code).c_str());
    } else {
        Serial.printf("[HTTP] Server trả lỗi: %d\n", code);
    }

    return code;
}
