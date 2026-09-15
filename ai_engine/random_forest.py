"""
Phân loại mức ô nhiễm và xác định khí gây ô nhiễm chính dựa trên dữ liệu theo giờ.
Dùng rule-based thay vì train model (không cần dataset labeled).
"""


# Ngưỡng an toàn tham chiếu (WHO 2021 + QCVN)
SAFE_THRESHOLDS = {
    "PM2.5": 35.0,    # µg/m³ (WHO 24h)
    "CO":    9.0,     # ppm   (WHO 8h)
    "CO₂":  1000.0,  # ppm   (ASHRAE thông gió)
    "NH₃":  25.0,    # ppm   (OSHA PEL 8h)
}

AQI_LEVELS = [
    (50,  "good"),
    (100, "moderate"),
    (150, "unhealthy_sensitive"),
    (200, "unhealthy"),
    (300, "very_unhealthy"),
    (float("inf"), "hazardous"),
]

AQI_LEVEL_VN = {
    "good":                 "Tốt",
    "moderate":             "Trung bình",
    "unhealthy_sensitive":  "Không tốt cho nhóm nhạy cảm",
    "unhealthy":            "Có hại",
    "very_unhealthy":       "Rất có hại",
    "hazardous":            "Nguy hiểm",
}


def classify_pollution(hourly_rows: list) -> tuple[str, str]:
    """
    Phân loại mức ô nhiễm ngày và tìm khí gây ô nhiễm chính.

    hourly_rows: list of tuples —
        (co2_avg, co_avg, pm25_avg, temp_avg, hum_avg, aqi_avg::int, aqi_max::int)

    Returns:
        (pollution_level: str, main_pollutant: str)
    """
    if not hourly_rows:
        return "unknown", "unknown"

    n        = len(hourly_rows)
    aqi_avg  = sum(float(r[5] or 0) for r in hourly_rows) / n
    co2_avg  = sum(float(r[0] or 0) for r in hourly_rows) / n
    co_avg   = sum(float(r[1] or 0) for r in hourly_rows) / n
    pm25_avg = sum(float(r[2] or 0) for r in hourly_rows) / n
    nh3_avg  = 0.0  # hourly_summary chưa có nh3 riêng → bỏ qua

    # Phân loại mức ô nhiễm theo AQI trung bình ngày
    level = "hazardous"
    for threshold, lvl in AQI_LEVELS:
        if aqi_avg <= threshold:
            level = lvl
            break

    temp_avg = sum(float(r[3] or 0) for r in hourly_rows) / n
    hum_avg  = sum(float(r[4] or 0) for r in hourly_rows) / n

    # Xác định yếu tố chính: Nếu có khí/bụi vượt thì tính, nếu chỉ có BME280 thì dựa vào vi khí hậu
    scores = {
        "PM2.5": pm25_avg / SAFE_THRESHOLDS["PM2.5"],
        "CO":    co_avg   / SAFE_THRESHOLDS["CO"],
        "CO₂":  co2_avg  / SAFE_THRESHOLDS["CO₂"],
    }
    if max(scores.values()) > 0.05:
        main_pollutant = max(scores, key=scores.get)
    elif temp_avg > 31.0:
        main_pollutant = "Nhiệt độ cao"
    elif hum_avg > 75.0:
        main_pollutant = "Độ ẩm cao"
    elif hum_avg < 35.0:
        main_pollutant = "Không khí khô"
    else:
        main_pollutant = "Vi khí hậu phòng"

    return level, main_pollutant



def compute_daily_stats(hourly_rows: list) -> dict:
    """
    Tính thống kê ngày từ hourly rows để ghi vào daily_summary.
    """
    if not hourly_rows:
        return {}

    aqi_vals  = [int(r[5] or 0)   for r in hourly_rows]
    pm25_vals = [float(r[2] or 0) for r in hourly_rows]
    co2_vals  = [float(r[0] or 0) for r in hourly_rows]
    co_vals   = [float(r[1] or 0) for r in hourly_rows]

    return {
        "aqi_avg":  round(sum(aqi_vals)  / len(aqi_vals)),
        "aqi_max":  max(aqi_vals),
        "aqi_min":  min(aqi_vals),
        "pm25_avg": round(sum(pm25_vals) / len(pm25_vals), 1),
        "pm25_max": max(pm25_vals),
        "co2_avg":  round(sum(co2_vals)  / len(co2_vals), 1),
        "co2_max":  max(co2_vals),
        "co_avg":   round(sum(co_vals)   / len(co_vals), 2),
    }
