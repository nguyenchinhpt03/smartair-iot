#include "aqi_calculator.h"

// ── PM2.5 breakpoints (US EPA) ───────────────────────────────────
static const float PM_LO[]  = {0.0f,  12.1f,  35.5f,  55.5f,  150.5f, 250.5f};
static const float PM_HI[]  = {12.0f, 35.4f,  55.4f,  150.4f, 250.4f, 500.4f};
static const int   AQI_LO[] = {0,     51,     101,    151,    201,    301};
static const int   AQI_HI[] = {50,    100,    150,    200,    300,    500};
static const int   N_BREAKS = 6;

static int pm25_to_aqi(float pm25) {
    if (pm25 < 0.0f) return 0;
    for (int i = 0; i < N_BREAKS; i++) {
        if (pm25 <= PM_HI[i]) {
            return (int)(
                (float)(AQI_HI[i] - AQI_LO[i]) / (PM_HI[i] - PM_LO[i])
                * (pm25 - PM_LO[i]) + AQI_LO[i]
            );
        }
    }
    return 500;
}

// CO đơn giản: tuyến tính 0–35 ppm → AQI 0–400
static int co_to_aqi(float co_ppm) {
    if (co_ppm <= 0.0f) return 0;
    return (int)(co_ppm / 35.0f * 400.0f);
}

// Tính chỉ số tiện nghi vi khí hậu từ Nhiệt độ và Độ ẩm BME280
// Thang điểm 0–500 tương đương AQI:
// 0–50: Thoáng mát dễ chịu (22–26°C, 45–60%)
// 51–100: Hơi nóng/lạnh hoặc hơi ẩm (27–31°C hoặc 18–21°C)
// 101–150: Khá ngột ngạt/oi bức (32–35°C hoặc ẩm > 75%)
// >150: Rất oi bức hoặc quá lạnh
int calculate_comfort_aqi(float temp_c, float hum_pct) {
    if (temp_c <= 0.0f && hum_pct <= 0.0f) return 25; // Default an toàn

    float ideal_temp = 24.5f;
    float ideal_hum  = 52.5f;

    float temp_diff = fabsf(temp_c - ideal_temp);
    float hum_diff  = fabsf(hum_pct - ideal_hum);

    // Điểm cơ bản là 20 (môi trường lý tưởng)
    float penalty = (temp_diff * 6.5f) + (hum_diff * 1.5f);
    int comfort_score = 20 + (int)penalty;

    if (comfort_score < 15) comfort_score = 15;
    if (comfort_score > 350) comfort_score = 350;
    return comfort_score;
}

int calculate_aqi(float pm25_ugm3, float co_ppm, float temp_c, float hum_pct) {
    if (pm25_ugm3 > 0.0f || co_ppm > 0.0f) {
        return max(pm25_to_aqi(pm25_ugm3), co_to_aqi(co_ppm));
    }
    // Khi chỉ có cảm biến BME280: tính AQI dựa trên chỉ số tiện nghi vi khí hậu
    return calculate_comfort_aqi(temp_c, hum_pct);
}


void aqi_to_rgb(int aqi, bool &r, bool &g, bool &b) {
    r = false; g = false; b = false;
    if      (aqi <= 50)  { g = true; }              // Xanh lá  — Tốt
    else if (aqi <= 100) { r = true; g = true; }     // Vàng     — Trung bình
    else if (aqi <= 150) { r = true; }               // Cam      — Không tốt
    else if (aqi <= 200) { r = true; }               // Đỏ       — Có hại
    else if (aqi <= 300) { r = true; b = true; }     // Tím      — Rất có hại
    else                 { r = true; g = true; b = true; } // Trắng — Nguy hiểm
}

const char* aqi_level_str(int aqi) {
    if (aqi <= 50)  return "TOT";
    if (aqi <= 100) return "TRUNG_BINH";
    if (aqi <= 150) return "KHONG_TOT";
    if (aqi <= 200) return "CO_HAI";
    if (aqi <= 300) return "RAT_CO_HAI";
    return "NGUY_HIEM";
}
