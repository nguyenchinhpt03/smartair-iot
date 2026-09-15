-- ================================================================
-- SMARTAIR — DATABASE SCHEMA
-- PostgreSQL 15+
-- Chạy lần đầu: psql -U smartair_user -d smartair -f schema.sql
-- ================================================================

-- Xóa toàn bộ nếu cần reset (bỏ comment khi muốn reset sạch)
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- ================================================================
-- PHẦN 1: BẢNG CỐ ĐỊNH (8 bảng)
-- ================================================================

-- ── 1.1 Thiết bị IoT ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS devices (
    device_id       VARCHAR(20)  PRIMARY KEY,
    name            VARCHAR(100) NOT NULL DEFAULT 'SmartAir Device',
    location        VARCHAR(20)  NOT NULL DEFAULT 'indoor'
                                 CHECK (location IN ('indoor', 'outdoor')),
    qr_code         TEXT         UNIQUE,
    is_online       BOOLEAN      NOT NULL DEFAULT FALSE,
    last_seen       TIMESTAMPTZ,
    ip_address      VARCHAR(100),
    temp_password   VARCHAR(50),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  devices            IS 'Danh sách thiết bị IoT ESP32';
COMMENT ON COLUMN devices.device_id  IS 'Mã thiết bị, ví dụ: SA-001';
COMMENT ON COLUMN devices.location   IS 'indoor = trong nhà, outdoor = ngoài trời';
COMMENT ON COLUMN devices.qr_code    IS 'Mã QR in lên thiết bị để app quét đăng nhập';
COMMENT ON COLUMN devices.is_online  IS 'TRUE nếu gửi dữ liệu trong 5 phút gần nhất';

-- ── 1.2 Người dùng ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    user_id         SERIAL       PRIMARY KEY,
    email           VARCHAR(200) UNIQUE NOT NULL,
    username        VARCHAR(100) UNIQUE,
    password_hash   TEXT,
    fcm_token       TEXT,
    fcm_enabled     BOOLEAN      NOT NULL DEFAULT TRUE,
    phone           VARCHAR(20)  UNIQUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  users           IS 'Người dùng ứng dụng Flutter';
COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging token để gửi push notification';


-- ── 1.3 Liên kết user ↔ thiết bị ────────────────────────────────
CREATE TABLE IF NOT EXISTS user_devices (
    user_id   INTEGER      NOT NULL REFERENCES users(user_id)   ON DELETE CASCADE,
    device_id VARCHAR(20)  NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    linked_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, device_id)
);

COMMENT ON TABLE user_devices IS 'Một user có thể theo dõi nhiều thiết bị (và ngược lại)';

-- ── 1.4 Cài đặt ngưỡng cảnh báo ──────────────────────────────────
CREATE TABLE IF NOT EXISTS alert_settings (
    id          SERIAL       PRIMARY KEY,
    device_id   VARCHAR(20)  NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    user_id     INTEGER      NOT NULL REFERENCES users(user_id)     ON DELETE CASCADE,
    metric      VARCHAR(30)  NOT NULL
                             CHECK (metric IN ('aqi', 'co2_ppm', 'co_ppm', 'pm25_ugm3',
                                               'nh3_ppm', 'benzene_ppm', 'pm10_ugm3',
                                               'temperature_c', 'humidity_pct')),
    threshold   FLOAT        NOT NULL CHECK (threshold > 0),
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (device_id, user_id, metric)
);

COMMENT ON TABLE  alert_settings           IS 'Ngưỡng cảnh báo push notification theo từng chỉ số';
COMMENT ON COLUMN alert_settings.metric    IS 'Tên chỉ số cần theo dõi';
COMMENT ON COLUMN alert_settings.threshold IS 'Gửi FCM khi value > threshold';

-- ── 1.5 Lịch sử thông báo đã gửi ────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
    id          SERIAL      PRIMARY KEY,
    device_id   VARCHAR(20) NOT NULL,
    user_id     INTEGER     NOT NULL,
    metric      VARCHAR(30) NOT NULL,
    value       FLOAT       NOT NULL,
    message     TEXT        NOT NULL,
    sent_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index để kiểm tra cooldown 30 phút nhanh
CREATE INDEX IF NOT EXISTS idx_notifications_cooldown
    ON notifications (device_id, user_id, metric, sent_at DESC);

COMMENT ON TABLE notifications IS 'Log FCM đã gửi — dùng để chặn spam trong 30 phút';

-- ── 1.6 Lớp 1 — Buffer real-time (10 slot xoay vòng) ─────────────
CREATE TABLE IF NOT EXISTS readings_buffer (
    slot            INTEGER      NOT NULL CHECK (slot BETWEEN 0 AND 9),
    device_id       VARCHAR(20)  NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    recorded_at     TIMESTAMPTZ,
    -- Khí
    co2_ppm         FLOAT,      -- Carbon Dioxide (MQ-135)
    nh3_ppm         FLOAT,      -- Ammonia (MQ-135)
    benzene_ppm     FLOAT,      -- Benzene (MQ-135)
    co_ppm          FLOAT,      -- Carbon Monoxide (MQ-7)
    -- Bụi
    pm1_ugm3        FLOAT,      -- PM1.0 (PMS5003)
    pm25_ugm3       FLOAT,      -- PM2.5 (PMS5003)
    pm10_ugm3       FLOAT,      -- PM10  (PMS5003)
    -- Môi trường
    temperature_c   FLOAT,      -- Nhiệt độ °C (BME280)
    humidity_pct    FLOAT,      -- Độ ẩm % (BME280)
    pressure_hpa    FLOAT,      -- Áp suất hPa (BME280)
    -- Tổng hợp
    aqi             INTEGER,    -- AQI tính từ PM2.5 + CO
    PRIMARY KEY (slot, device_id)
);

COMMENT ON TABLE  readings_buffer     IS 'Lớp 1: 10 slot xoay vòng mỗi thiết bị — đọc dashboard real-time';
COMMENT ON COLUMN readings_buffer.slot IS '0–9, xoay vòng theo công thức (MAX+1) % 10';

-- ── 1.7 Lớp 3 — Tổng hợp theo giờ (7 ngày) ──────────────────────
CREATE TABLE IF NOT EXISTS hourly_summary (
    id              SERIAL      PRIMARY KEY,
    device_id       VARCHAR(20) NOT NULL,
    hour_start      TIMESTAMPTZ NOT NULL,  -- ví dụ: 2026-06-30 14:00:00+07
    -- Trung bình theo giờ
    co2_avg         FLOAT,
    nh3_avg         FLOAT,
    benzene_avg     FLOAT,
    co_avg          FLOAT,
    pm1_avg         FLOAT,
    pm25_avg        FLOAT,
    pm10_avg        FLOAT,
    temp_avg        FLOAT,
    hum_avg         FLOAT,
    press_avg       FLOAT,
    -- AQI
    aqi_avg         INTEGER,
    aqi_max         INTEGER,
    -- Kiểm soát chất lượng
    sample_count    INTEGER     NOT NULL DEFAULT 0,
    UNIQUE (device_id, hour_start)
);

CREATE INDEX IF NOT EXISTS idx_hourly_device_time
    ON hourly_summary (device_id, hour_start DESC);

COMMENT ON TABLE  hourly_summary              IS 'Lớp 3: Trung bình mỗi giờ — giữ 7 ngày — cho biểu đồ 7 ngày';
COMMENT ON COLUMN hourly_summary.sample_count IS 'Số bản ghi raw được tổng hợp vào giờ này (~60)';

-- ── 1.8 Lớp 4 — Báo cáo AI cuối ngày (7 ngày) ───────────────────
CREATE TABLE IF NOT EXISTS daily_summary (
    id              SERIAL      PRIMARY KEY,
    device_id       VARCHAR(20) NOT NULL,
    report_date     DATE        NOT NULL,
    -- Thống kê AQI ngày
    aqi_avg         INTEGER,
    aqi_max         INTEGER,
    aqi_min         INTEGER,
    -- Thống kê PM2.5 ngày
    pm25_avg        FLOAT,
    pm25_max        FLOAT,
    -- Thống kê CO₂ ngày
    co2_avg         FLOAT,
    co2_max         FLOAT,
    -- Thống kê CO ngày
    co_avg          FLOAT,
    -- Kết quả AI
    pollution_level VARCHAR(30)  -- 'good'|'moderate'|'unhealthy_sensitive'|'unhealthy'|'hazardous'
                    CHECK (pollution_level IN ('good', 'moderate', 'unhealthy_sensitive', 'unhealthy', 'hazardous')),
    main_pollutant  VARCHAR(30), -- 'PM2.5' | 'CO' | 'CO₂' | 'NH₃'
    anomaly_count   INTEGER      NOT NULL DEFAULT 0,
    ai_summary      TEXT,        -- Nhận xét tiếng Việt từ Claude Haiku
    ai_advice       TEXT,        -- Khuyến nghị tiếng Việt từ Claude Haiku
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (device_id, report_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_device_date
    ON daily_summary (device_id, report_date DESC);

COMMENT ON TABLE  daily_summary               IS 'Lớp 4: Báo cáo AI cuối ngày — giữ 7 ngày';
COMMENT ON COLUMN daily_summary.ai_summary    IS 'Nhận xét 2-3 câu về xu hướng chất lượng không khí trong ngày';
COMMENT ON COLUMN daily_summary.ai_advice     IS 'Khuyến nghị hành động cụ thể cho người dùng';
COMMENT ON COLUMN daily_summary.anomaly_count IS 'Số giờ bị Isolation Forest phát hiện bất thường';

-- ================================================================
-- PHẦN 2: HÀM TIỆN ÍCH
-- ================================================================

-- ── 2.1 Tạo bảng Lớp 2 theo ngày (gọi mỗi 00:00) ────────────────
CREATE OR REPLACE FUNCTION create_daily_table(target_date DATE)
RETURNS VOID AS $$
DECLARE
    tbl_name TEXT := 'readings_' || TO_CHAR(target_date, 'YYYY_MM_DD');
BEGIN
    EXECUTE FORMAT('
        CREATE TABLE IF NOT EXISTS %I (
            id              SERIAL      PRIMARY KEY,
            device_id       VARCHAR(20) NOT NULL,
            recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            co2_ppm         FLOAT,
            nh3_ppm         FLOAT,
            benzene_ppm     FLOAT,
            co_ppm          FLOAT,
            pm1_ugm3        FLOAT,
            pm25_ugm3       FLOAT,
            pm10_ugm3       FLOAT,
            temperature_c   FLOAT,
            humidity_pct    FLOAT,
            pressure_hpa    FLOAT,
            aqi             INTEGER
        )', tbl_name);

    -- Index để truy vấn nhanh theo thiết bị + thời gian
    EXECUTE FORMAT('
        CREATE INDEX IF NOT EXISTS %I
        ON %I (device_id, recorded_at ASC)',
        'idx_' || tbl_name || '_device_time',
        tbl_name
    );

    RAISE NOTICE 'Đã tạo bảng %', tbl_name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_daily_table(DATE) IS
    'Tạo bảng readings_YYYY_MM_DD cho ngày chỉ định. Gọi trong cron 00:00 mỗi ngày.';

-- ── 2.2 Upsert vào buffer xoay vòng + cập nhật is_online ─────────
CREATE OR REPLACE FUNCTION insert_reading(
    p_device_id   VARCHAR,
    p_aqi         INTEGER,
    p_co2         FLOAT,
    p_nh3         FLOAT,
    p_benzene     FLOAT,
    p_co          FLOAT,
    p_pm1         FLOAT,
    p_pm25        FLOAT,
    p_pm10        FLOAT,
    p_temp        FLOAT,
    p_hum         FLOAT,
    p_press       FLOAT
) RETURNS VOID AS $$
DECLARE
    next_slot INTEGER;
BEGIN
    -- Tính slot tiếp theo: (MAX slot hiện tại + 1) % 10
    SELECT COALESCE(MAX(slot) + 1, 0) % 10
    INTO   next_slot
    FROM   readings_buffer
    WHERE  device_id = p_device_id;

    INSERT INTO readings_buffer
        (slot, device_id, recorded_at,
         co2_ppm, nh3_ppm, benzene_ppm, co_ppm,
         pm1_ugm3, pm25_ugm3, pm10_ugm3,
         temperature_c, humidity_pct, pressure_hpa,
         aqi)
    VALUES
        (next_slot, p_device_id, NOW(),
         p_co2, p_nh3, p_benzene, p_co,
         p_pm1, p_pm25, p_pm10,
         p_temp, p_hum, p_press,
         p_aqi)
    ON CONFLICT (slot, device_id) DO UPDATE SET
        recorded_at   = NOW(),
        co2_ppm       = p_co2,
        nh3_ppm       = p_nh3,
        benzene_ppm   = p_benzene,
        co_ppm        = p_co,
        pm1_ugm3      = p_pm1,
        pm25_ugm3     = p_pm25,
        pm10_ugm3     = p_pm10,
        temperature_c = p_temp,
        humidity_pct  = p_hum,
        pressure_hpa  = p_press,
        aqi           = p_aqi;

    -- Đồng thời đánh dấu thiết bị online
    UPDATE devices
    SET    is_online = TRUE,
           last_seen = NOW()
    WHERE  device_id = p_device_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION insert_reading IS
    'Ghi 1 bản đọc vào Lớp 1 buffer (xoay vòng 10 slot) và cập nhật is_online.';

-- ── 2.3 Đánh dấu thiết bị offline (gọi từ cron mỗi 5 phút) ──────
CREATE OR REPLACE FUNCTION mark_offline_devices(timeout_minutes INTEGER DEFAULT 5)
RETURNS INTEGER AS $$
DECLARE
    rows_updated INTEGER;
BEGIN
    UPDATE devices
    SET    is_online = FALSE
    WHERE  last_seen < NOW() - (timeout_minutes || ' minutes')::INTERVAL
      AND  is_online = TRUE;

    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RETURN rows_updated;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mark_offline_devices IS
    'Đánh dấu FALSE cho thiết bị không gửi dữ liệu quá N phút. Trả về số hàng cập nhật.';

-- ── 2.4 Xóa bảng Lớp 2 cũ hơn N ngày ───────────────────────────
CREATE OR REPLACE FUNCTION drop_old_daily_tables(keep_days INTEGER DEFAULT 3)
RETURNS TEXT AS $$
DECLARE
    target_date DATE := CURRENT_DATE - keep_days - 1;
    tbl_name    TEXT := 'readings_' || TO_CHAR(target_date, 'YYYY_MM_DD');
    dropped     TEXT := '';
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE  table_schema = 'public'
          AND  table_name   = tbl_name
    ) THEN
        EXECUTE 'DROP TABLE ' || quote_ident(tbl_name);
        dropped := tbl_name;
        RAISE NOTICE 'Đã xóa bảng %', tbl_name;
    END IF;
    RETURN dropped;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION drop_old_daily_tables IS
    'Xóa bảng readings_ cũ hơn keep_days ngày. Gọi trong cron 00:00.';

-- ── 2.5 Lấy tóm tắt trạng thái hệ thống ─────────────────────────
CREATE OR REPLACE FUNCTION system_status()
RETURNS TABLE (
    metric TEXT,
    value  TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'total_devices'::TEXT,       COUNT(*)::TEXT FROM devices
    UNION ALL
    SELECT 'online_devices',            COUNT(*)::TEXT FROM devices WHERE is_online = TRUE
    UNION ALL
    SELECT 'total_users',               COUNT(*)::TEXT FROM users
    UNION ALL
    SELECT 'buffer_records',            COUNT(*)::TEXT FROM readings_buffer
    UNION ALL
    SELECT 'hourly_records_7d',         COUNT(*)::TEXT FROM hourly_summary WHERE hour_start >= NOW() - INTERVAL '7 days'
    UNION ALL
    SELECT 'daily_reports_7d',          COUNT(*)::TEXT FROM daily_summary WHERE report_date >= CURRENT_DATE - 7
    UNION ALL
    SELECT 'notifications_today',       COUNT(*)::TEXT FROM notifications WHERE sent_at >= CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION system_status IS
    'Trả về bảng tóm tắt trạng thái hệ thống. Dùng để monitoring.';

-- ================================================================
-- PHẦN 3: VIEW TIỆN ÍCH
-- ================================================================

-- ── 3.1 View: Bản đọc mới nhất của tất cả thiết bị ──────────────
CREATE OR REPLACE VIEW v_latest_readings AS
SELECT DISTINCT ON (b.device_id)
    b.device_id,
    d.name                AS device_name,
    d.location,
    d.is_online,
    b.recorded_at,
    b.aqi,
    b.co2_ppm,
    b.nh3_ppm,
    b.benzene_ppm,
    b.co_ppm,
    b.pm1_ugm3,
    b.pm25_ugm3,
    b.pm10_ugm3,
    b.temperature_c,
    b.humidity_pct,
    b.pressure_hpa,
    CASE
        WHEN b.aqi IS NULL   THEN 'unknown'
        WHEN b.aqi <= 50     THEN 'good'
        WHEN b.aqi <= 100    THEN 'moderate'
        WHEN b.aqi <= 150    THEN 'unhealthy_sensitive'
        WHEN b.aqi <= 200    THEN 'unhealthy'
        WHEN b.aqi <= 300    THEN 'very_unhealthy'
        ELSE                      'hazardous'
    END AS aqi_level
FROM readings_buffer b
JOIN devices d ON d.device_id = b.device_id
ORDER BY b.device_id, b.recorded_at DESC;

COMMENT ON VIEW v_latest_readings IS
    'Bản đọc mới nhất của từng thiết bị kèm thông tin thiết bị và nhãn AQI.';

-- ── 3.2 View: Thống kê trung bình hôm nay từ hourly_summary ──────
CREATE OR REPLACE VIEW v_today_stats AS
SELECT
    device_id,
    CURRENT_DATE                                  AS report_date,
    ROUND(AVG(aqi_avg))::INTEGER                  AS aqi_avg_today,
    MAX(aqi_max)                                  AS aqi_max_today,
    ROUND(AVG(pm25_avg)::NUMERIC, 1)              AS pm25_avg_today,
    ROUND(AVG(co2_avg)::NUMERIC, 0)               AS co2_avg_today,
    ROUND(AVG(temp_avg)::NUMERIC, 1)              AS temp_avg_today,
    ROUND(AVG(hum_avg)::NUMERIC, 1)               AS hum_avg_today,
    SUM(sample_count)                             AS total_samples_today,
    COUNT(*)                                      AS hours_with_data
FROM hourly_summary
WHERE hour_start >= CURRENT_DATE
  AND hour_start <  CURRENT_DATE + INTERVAL '1 day'
GROUP BY device_id;

COMMENT ON VIEW v_today_stats IS
    'Thống kê tổng hợp hôm nay từ hourly_summary (cập nhật mỗi giờ).';

-- ── 3.3 View: Cảnh báo đang kích hoạt ───────────────────────────
CREATE OR REPLACE VIEW v_active_alerts AS
SELECT
    a.device_id,
    d.name       AS device_name,
    a.user_id,
    u.email      AS user_email,
    a.metric,
    a.threshold,
    -- Lấy giá trị hiện tại từ buffer
    CASE a.metric
        WHEN 'aqi'        THEN b.aqi::FLOAT
        WHEN 'co2_ppm'    THEN b.co2_ppm
        WHEN 'co_ppm'     THEN b.co_ppm
        WHEN 'pm25_ugm3'  THEN b.pm25_ugm3
        WHEN 'nh3_ppm'    THEN b.nh3_ppm
        WHEN 'pm10_ugm3'  THEN b.pm10_ugm3
    END AS current_value,
    -- TRUE nếu đang vượt ngưỡng
    CASE a.metric
        WHEN 'aqi'        THEN b.aqi::FLOAT        > a.threshold
        WHEN 'co2_ppm'    THEN b.co2_ppm           > a.threshold
        WHEN 'co_ppm'     THEN b.co_ppm            > a.threshold
        WHEN 'pm25_ugm3'  THEN b.pm25_ugm3         > a.threshold
        WHEN 'nh3_ppm'    THEN b.nh3_ppm           > a.threshold
        WHEN 'pm10_ugm3'  THEN b.pm10_ugm3         > a.threshold
        ELSE FALSE
    END AS is_exceeded
FROM alert_settings a
JOIN devices d ON d.device_id = a.device_id
JOIN users   u ON u.user_id   = a.user_id
LEFT JOIN LATERAL (
    SELECT * FROM readings_buffer
    WHERE  device_id = a.device_id
    ORDER  BY recorded_at DESC
    LIMIT  1
) b ON TRUE
WHERE a.is_active = TRUE;

COMMENT ON VIEW v_active_alerts IS
    'Danh sách cảnh báo đang kích hoạt kèm giá trị hiện tại — dùng để debug notification.';

-- ── 3.4 View: Thống kê 7 ngày gần nhất theo thiết bị ─────────────
CREATE OR REPLACE VIEW v_weekly_stats AS
SELECT
    device_id,
    report_date,
    aqi_avg,
    aqi_max,
    aqi_min,
    pm25_avg,
    co2_avg,
    pollution_level,
    main_pollutant,
    anomaly_count,
    CASE pollution_level
        WHEN 'good'                  THEN 'Tốt'
        WHEN 'moderate'              THEN 'Trung bình'
        WHEN 'unhealthy_sensitive'   THEN 'Không tốt cho nhóm nhạy cảm'
        WHEN 'unhealthy'             THEN 'Có hại'
        WHEN 'hazardous'             THEN 'Nguy hiểm'
        ELSE 'Chưa có báo cáo'
    END AS pollution_level_vn
FROM daily_summary
WHERE report_date >= CURRENT_DATE - 7
ORDER BY device_id, report_date DESC;

COMMENT ON VIEW v_weekly_stats IS
    'Thống kê 7 ngày gần nhất kèm nhãn tiếng Việt cho màn hình báo cáo Flutter.';

-- ================================================================
-- PHẦN 4: KHỞI TẠO (chạy ngay khi setup)
-- ================================================================

-- Tạo bảng Lớp 2 cho hôm nay (ngày đầu tiên)
SELECT create_daily_table(CURRENT_DATE);

-- Tạo sẵn bảng ngày mai để cron không bị bỏ lỡ nếu chạy sát 00:00
SELECT create_daily_table(CURRENT_DATE + 1);

-- ================================================================
-- PHẦN 5: DỮ LIỆU MẪU (dùng để test — xóa khi deploy thật)
-- ================================================================

-- Thiết bị mẫu
INSERT INTO devices (device_id, name, location, qr_code)
VALUES
    ('SA-001', 'SmartAir Phòng khách',  'indoor',  'SA-001-QR-2026'),
    ('SA-002', 'SmartAir Sân thượng',   'outdoor', 'SA-002-QR-2026'),
    ('SA-003', 'SmartAir Phòng bếp',    'indoor',  'SA-003-QR-2026')
ON CONFLICT (device_id) DO NOTHING;

-- User mẫu
INSERT INTO users (email, fcm_token)
VALUES
    ('admin@smartair.local',  'FCM_TOKEN_ADMIN_PLACEHOLDER'),
    ('user1@smartair.local',  'FCM_TOKEN_USER1_PLACEHOLDER')
ON CONFLICT (email) DO NOTHING;

-- Liên kết user ↔ thiết bị
INSERT INTO user_devices (user_id, device_id)
SELECT u.user_id, d.device_id
FROM users u, devices d
WHERE u.email     = 'admin@smartair.local'
  AND d.device_id IN ('SA-001', 'SA-002', 'SA-003')
ON CONFLICT DO NOTHING;

INSERT INTO user_devices (user_id, device_id)
SELECT u.user_id, d.device_id
FROM users u, devices d
WHERE u.email     = 'user1@smartair.local'
  AND d.device_id = 'SA-001'
ON CONFLICT DO NOTHING;

-- Ngưỡng cảnh báo mặc định cho SA-001
INSERT INTO alert_settings (device_id, user_id, metric, threshold)
SELECT
    'SA-001',
    u.user_id,
    t.metric,
    t.threshold
FROM users u,
     (VALUES
        ('aqi',        100.0),
        ('co2_ppm',   1000.0),
        ('co_ppm',       9.0),
        ('pm25_ugm3',   35.0),
        ('nh3_ppm',     25.0)
     ) AS t(metric, threshold)
WHERE u.email = 'admin@smartair.local'
ON CONFLICT (device_id, user_id, metric) DO NOTHING;

-- Bản đọc buffer mẫu (SA-001, slot 0) — để test GET /api/realtime
SELECT insert_reading(
    'SA-001',   -- device_id
    72,         -- aqi
    845.3,      -- co2_ppm
    3.1,        -- nh3_ppm
    0.04,       -- benzene_ppm
    4.2,        -- co_ppm
    8.5,        -- pm1_ugm3
    17.2,       -- pm25_ugm3
    22.1,       -- pm10_ugm3
    28.4,       -- temperature_c
    64.8,       -- humidity_pct
    1013.2      -- pressure_hpa
);

-- Dữ liệu hourly_summary mẫu cho SA-001 (24 giờ hôm nay — để test biểu đồ 7 ngày)
INSERT INTO hourly_summary
    (device_id, hour_start,
     co2_avg, nh3_avg, benzene_avg, co_avg,
     pm1_avg, pm25_avg, pm10_avg,
     temp_avg, hum_avg, press_avg,
     aqi_avg, aqi_max, sample_count)
SELECT
    'SA-001',
    DATE_TRUNC('hour', NOW()) - (n || ' hours')::INTERVAL,
    -- co2 biến động từ 600–1200 theo giờ
    600  + (n % 12) * 50 + RANDOM() * 30,
    2.5  + RANDOM() * 2,
    0.03 + RANDOM() * 0.02,
    3.0  + RANDOM() * 3,
    -- pm25 cao vào buổi sáng (giờ 7-9) và chiều (17-19)
    5.0  + (CASE WHEN n % 24 BETWEEN 15 AND 17 OR n % 24 BETWEEN 5 AND 7 THEN 15 ELSE 0 END) + RANDOM() * 5,
    10.0 + (CASE WHEN n % 24 BETWEEN 15 AND 17 OR n % 24 BETWEEN 5 AND 7 THEN 20 ELSE 0 END) + RANDOM() * 8,
    14.0 + RANDOM() * 10,
    26.0 + RANDOM() * 4,
    60.0 + RANDOM() * 15,
    1012.0 + RANDOM() * 3,
    50 + (CASE WHEN n % 24 BETWEEN 15 AND 17 OR n % 24 BETWEEN 5 AND 7 THEN 30 ELSE 0 END) + (RANDOM() * 20)::INTEGER,
    80 + (RANDOM() * 30)::INTEGER,
    58 + (RANDOM() * 5)::INTEGER
FROM generate_series(0, 167) AS n  -- 7 ngày × 24 giờ = 168 giờ
ON CONFLICT (device_id, hour_start) DO NOTHING;

-- ================================================================
-- PHẦN 6: QUERY KIỂM TRA SAU KHI CHẠY
-- ================================================================

/*
-- Chạy từng dòng sau để kiểm tra:

-- 1. Danh sách bảng đã tạo
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = 'public'
ORDER  BY table_name;

-- 2. Kiểm tra trạng thái hệ thống
SELECT * FROM system_status();

-- 3. Kiểm tra buffer mẫu
SELECT * FROM v_latest_readings;

-- 4. Kiểm tra hourly data mẫu
SELECT device_id, hour_start::DATE AS ngay, COUNT(*) AS so_gio
FROM hourly_summary
GROUP BY device_id, hour_start::DATE
ORDER BY ngay DESC;

-- 5. Kiểm tra ngưỡng cảnh báo
SELECT d.name, a.metric, a.threshold FROM alert_settings a
JOIN devices d ON d.device_id = a.device_id
ORDER BY d.name, a.metric;

-- 6. Test insert_reading thêm dữ liệu mới
SELECT insert_reading('SA-001',85,900,3.5,0.05,5.1,10,22,28,29,65,1013);
SELECT * FROM v_latest_readings WHERE device_id = 'SA-001';

-- 7. Kiểm tra bảng ngày hôm nay có tồn tại
SELECT table_name FROM information_schema.tables
WHERE table_name = 'readings_' || TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD');
*/
