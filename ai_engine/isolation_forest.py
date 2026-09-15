"""
Phát hiện spike bất thường trong dữ liệu chất lượng không khí theo giờ.
Dùng Isolation Forest — không cần dữ liệu labeled, phù hợp với dữ liệu cảm biến.
"""
from sklearn.ensemble import IsolationForest
import numpy as np


def detect_anomaly(hourly_rows: list) -> int:
    """
    Phát hiện số giờ có AQI / PM2.5 bất thường trong ngày.

    hourly_rows: list of tuples từ DB —
        (co2_avg, co_avg, pm25_avg, temp_avg, hum_avg, aqi_avg::int, aqi_max::int)

    Returns:
        Số lần bất thường (0 nếu không đủ dữ liệu).
    """
    if len(hourly_rows) < 4:
        return 0

    # Feature: AQI, Nhiệt độ, Độ ẩm (và PM2.5 nếu có)
    X = np.array([[float(r[5] or 0), float(r[3] or 0), float(r[4] or 0), float(r[2] or 0)] for r in hourly_rows])

    # contamination=0.1 → mong đợi 10% outlier trong ngày
    model = IsolationForest(
        contamination=0.1,
        n_estimators=100,
        random_state=42,
    )
    labels = model.fit_predict(X)  # -1 = bất thường, 1 = bình thường
    return int((labels == -1).sum())


def get_anomaly_hours(hourly_rows: list) -> list[int]:
    """
    Trả về danh sách index (giờ) bị phát hiện bất thường.
    Dùng để hiển thị chi tiết trong báo cáo.
    """
    if len(hourly_rows) < 4:
        return []

    X = np.array([[float(r[5] or 0), float(r[3] or 0), float(r[4] or 0), float(r[2] or 0)] for r in hourly_rows])
    model = IsolationForest(contamination=0.1, n_estimators=100, random_state=42)
    labels = model.fit_predict(X)

    return [i for i, label in enumerate(labels) if label == -1]
