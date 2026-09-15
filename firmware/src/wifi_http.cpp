#include "wifi_http.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <WiFiManager.h>
#include <WebServer.h>

static WebServer localServer(80);
static bool localServerStarted = false;

String wifi_scan_json() {
    Serial.println("[WiFi Scan] Đang quét sóng các mạng Wi-Fi ở gần ESP32...");
    int n = WiFi.scanNetworks(false, true); // Quét nhanh
    StaticJsonDocument<1536> doc;
    JsonArray arr = doc.to<JsonArray>();

    for (int i = 0; i < n && i < 15; ++i) {
        String ssid = WiFi.SSID(i);
        if (ssid.length() == 0) continue;
        JsonObject obj = arr.createNestedObject();
        obj["ssid"] = ssid;
        obj["rssi"] = WiFi.RSSI(i);
        obj["secure"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
    }
    WiFi.scanDelete();

    String out;
    serializeJson(doc, out);
    return out;
}

void wifi_server_init() {
    if (localServerStarted) return;

    localServer.on("/wifi-scan", HTTP_GET, []() {
        String json = wifi_scan_json();
        localServer.sendHeader("Access-Control-Allow-Origin", "*");
        localServer.send(200, "application/json", json);
    });

    localServer.on("/wifi-status", HTTP_GET, []() {
        StaticJsonDocument<256> doc;
        doc["ssid"] = WiFi.SSID();
        doc["ip"] = WiFi.localIP().toString();
        doc["rssi"] = WiFi.RSSI();
        doc["connected"] = (WiFi.status() == WL_CONNECTED);
        String out;
        serializeJson(doc, out);
        localServer.sendHeader("Access-Control-Allow-Origin", "*");
        localServer.send(200, "application/json", out);
    });

    auto handle_save = []() {
        String ssid = localServer.arg("s");
        String pass = localServer.arg("p");
        if (ssid.length() == 0) {
            ssid = localServer.arg("ssid");
            pass = localServer.arg("password");
        }
        localServer.sendHeader("Access-Control-Allow-Origin", "*");
        localServer.sendHeader("Access-Control-Allow-Headers", "*");
        if (ssid.length() > 0) {
            Serial.printf("[WiFi] Nhận cấu hình Wi-Fi mới: %s\n", ssid.c_str());
            localServer.send(200, "application/json", "{\"status\":\"ok\",\"msg\":\"Connecting to " + ssid + "\"}");
            delay(400);
            WiFi.disconnect();
            delay(200);
            WiFi.begin(ssid.c_str(), pass.c_str());
        } else {
            localServer.send(400, "application/json", "{\"status\":\"error\",\"msg\":\"Missing SSID\"}");
        }
    };

    localServer.on("/wifi-save", HTTP_POST, handle_save);
    localServer.on("/wifi-save", HTTP_GET, handle_save);

    // Endpoint WiFiManager tương thích
    localServer.on("/wifisave", HTTP_POST, handle_save);
    localServer.on("/wifisave", HTTP_GET, handle_save);

    localServer.begin();
    localServerStarted = true;
    Serial.printf("[LocalServer] Máy chủ quét Wi-Fi nội bộ đã mở tại: http://%s/\n", WiFi.localIP().toString().c_str());
}

void wifi_server_handle() {
    if (localServerStarted) {
        localServer.handleClient();
    }
}

bool wifi_init_smart(const char* ap_name, uint32_t portal_timeout_sec) {
    WiFiManager wm;

    wm.setConfigPortalTimeout(portal_timeout_sec);
    wm.setTitle("SmartAir - Cài Đặt Wi-Fi");

    Serial.println("\n══════════════════════════════════════════════════════");
    Serial.println("[WiFiManager] Đang kiểm tra kết nối Wi-Fi đã lưu...");
    Serial.printf("[WiFiManager] Nếu chưa có hoặc đổi địa điểm, phát AP: [%s]\n", ap_name);
    Serial.println("[WiFiManager] (Kết nối điện thoại vào mạng trên -> trang cài đặt sẽ tự hiện)");
    Serial.println("══════════════════════════════════════════════════════");

    bool res = wm.autoConnect(ap_name);

    if (!res) {
        Serial.println("[WiFiManager] Hết giờ chờ cấu hình! ESP32 tiếp tục đo cảm biến offline.");
        return false;
    }

    Serial.printf("[WiFiManager] Kết nối thành công! IP: %s\n", WiFi.localIP().toString().c_str());
    wifi_server_init();
    return true;
}

void wifi_reset_settings() {
    WiFiManager wm;
    wm.resetSettings();
    Serial.println("[WiFiManager] Đã xóa bộ nhớ Wi-Fi.");
}

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
