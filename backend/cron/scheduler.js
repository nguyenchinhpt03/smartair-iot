const cron = require('node-cron');
const pool  = require('../db/pool');
const axios = require('axios');

function scheduleJobs() {

    // ────────────────────────────────────────────────────────────────
    // Mỗi giờ tròn: tổng hợp hourly_summary từ Lớp 2
    // ────────────────────────────────────────────────────────────────
    cron.schedule('0 * * * *', async () => {
        const label = '[cron hourly]';
        try {
            // Giờ vừa kết thúc (cron chạy lúc :00 → giờ N-1)
            const prevHour = new Date();
            prevHour.setMinutes(0, 0, 0);
            prevHour.setHours(prevHour.getHours() - 1);
            const hourStart = prevHour.toISOString();

            // Bảng ngày của giờ vừa qua
            const tblDate = prevHour.toLocaleDateString('sv');
            const tbl     = 'readings_' + tblDate.replace(/-/g, '_');

            // Kiểm tra bảng có tồn tại không
            const { rows: tableCheck } = await pool.query(
                `SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'public' AND table_name = $1`,
                [tbl]
            );
            if (!tableCheck.length) {
                console.log(`${label} Bảng ${tbl} không tồn tại — bỏ qua`);
                return;
            }

            const { rows } = await pool.query(`
                SELECT
                    device_id,
                    DATE_TRUNC('hour', recorded_at)              AS hour_start,
                    ROUND(AVG(co2_ppm)::NUMERIC,    1)           AS co2_avg,
                    ROUND(AVG(nh3_ppm)::NUMERIC,    2)           AS nh3_avg,
                    ROUND(AVG(benzene_ppm)::NUMERIC, 3)          AS benzene_avg,
                    ROUND(AVG(co_ppm)::NUMERIC,     2)           AS co_avg,
                    ROUND(AVG(pm1_ugm3)::NUMERIC,   1)           AS pm1_avg,
                    ROUND(AVG(pm25_ugm3)::NUMERIC,  1)           AS pm25_avg,
                    ROUND(AVG(pm10_ugm3)::NUMERIC,  1)           AS pm10_avg,
                    ROUND(AVG(temperature_c)::NUMERIC, 1)        AS temp_avg,
                    ROUND(AVG(humidity_pct)::NUMERIC,  1)        AS hum_avg,
                    ROUND(AVG(pressure_hpa)::NUMERIC,  1)        AS press_avg,
                    ROUND(AVG(aqi))::INTEGER                      AS aqi_avg,
                    MAX(aqi)                                      AS aqi_max,
                    COUNT(*)                                      AS sample_count
                FROM ${tbl}
                WHERE recorded_at >= $1
                  AND recorded_at <  $1::TIMESTAMPTZ + INTERVAL '1 hour'
                GROUP BY device_id, DATE_TRUNC('hour', recorded_at)
            `, [hourStart]);

            for (const row of rows) {
                await pool.query(`
                    INSERT INTO hourly_summary
                        (device_id, hour_start,
                         co2_avg, nh3_avg, benzene_avg, co_avg,
                         pm1_avg, pm25_avg, pm10_avg,
                         temp_avg, hum_avg, press_avg,
                         aqi_avg, aqi_max, sample_count)
                    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
                    ON CONFLICT (device_id, hour_start) DO UPDATE SET
                        co2_avg      = EXCLUDED.co2_avg,
                        pm25_avg     = EXCLUDED.pm25_avg,
                        aqi_avg      = EXCLUDED.aqi_avg,
                        aqi_max      = EXCLUDED.aqi_max,
                        sample_count = EXCLUDED.sample_count
                `, [
                    row.device_id,   row.hour_start,
                    row.co2_avg,     row.nh3_avg,   row.benzene_avg, row.co_avg,
                    row.pm1_avg,     row.pm25_avg,  row.pm10_avg,
                    row.temp_avg,    row.hum_avg,   row.press_avg,
                    row.aqi_avg,     row.aqi_max,   row.sample_count,
                ]);
            }

            // Xóa hourly_summary cũ hơn 7 ngày
            const { rowCount } = await pool.query(
                `DELETE FROM hourly_summary WHERE hour_start < NOW() - INTERVAL '7 days'`
            );

            console.log(`${label} Tổng hợp ${rows.length} thiết bị cho giờ ${hourStart}, xóa ${rowCount} bản cũ`);
        } catch (err) {
            console.error(`${label} ERROR:`, err.message);
        }
    });

    // ────────────────────────────────────────────────────────────────
    // 23:59 mỗi ngày: gọi AI Engine tạo báo cáo ngày
    // ────────────────────────────────────────────────────────────────
    cron.schedule('59 23 * * *', async () => {
        const label = '[cron 23:59]';
        const today = new Date().toLocaleDateString('sv');
        try {
            const tbl = 'readings_' + today.replace(/-/g, '_');

            // Kiểm tra bảng tồn tại
            const { rows: tableCheck } = await pool.query(
                `SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'public' AND table_name = $1`,
                [tbl]
            );
            if (!tableCheck.length) {
                console.log(`${label} Bảng ${tbl} không tồn tại — bỏ qua`);
                return;
            }

            const { rows: devices } = await pool.query(
                `SELECT DISTINCT device_id FROM ${tbl}`
            );

            for (const { device_id } of devices) {
                try {
                    await axios.post(
                        `${process.env.AI_ENGINE_URL}/daily_report`,
                        { device_id, date: today },
                        { timeout: 60000 }
                    );
                    console.log(`${label} Báo cáo AI xong cho ${device_id}`);
                } catch (err) {
                    console.error(`${label} AI Engine lỗi cho ${device_id}:`, err.message);
                }
            }

            // Xóa daily_summary cũ hơn 7 ngày
            const { rowCount } = await pool.query(
                `DELETE FROM daily_summary WHERE report_date < CURRENT_DATE - 7`
            );
            console.log(`${label} Xóa ${rowCount} báo cáo cũ`);
        } catch (err) {
            console.error(`${label} ERROR:`, err.message);
        }
    });

    // ────────────────────────────────────────────────────────────────
    // 00:00 mỗi ngày: tạo bảng ngày mới, xóa bảng cũ hơn 3 ngày
    // ────────────────────────────────────────────────────────────────
    cron.schedule('0 0 * * *', async () => {
        const label = '[cron 00:00]';
        try {
        const today = new Date().toLocaleDateString('sv');

            // Tạo bảng ngày hôm nay
            await pool.query(`SELECT create_daily_table($1::DATE)`, [today]);
            console.log(`${label} Đã tạo bảng readings_${today.replace(/-/g, '_')}`);

            // Xóa bảng của 4 ngày trước (giữ 3 ngày: hôm nay, hôm qua, ngày kia)
            const result = await pool.query(`SELECT drop_old_daily_tables(3)`);
            const dropped = result.rows[0].drop_old_daily_tables;
            if (dropped) console.log(`${label} Đã xóa bảng: ${dropped}`);
        } catch (err) {
            console.error(`${label} ERROR:`, err.message);
        }
    });

    // ────────────────────────────────────────────────────────────────
    // Mỗi 5 phút: đánh dấu thiết bị offline (last_seen > 5 phút)
    // ────────────────────────────────────────────────────────────────
    cron.schedule('*/5 * * * *', async () => {
        try {
            const { rows } = await pool.query(`SELECT mark_offline_devices(5)`);
            const count = rows[0].mark_offline_devices;
            if (count > 0) console.log(`[cron offline] Đánh dấu ${count} thiết bị offline`);
        } catch (err) {
            console.error('[cron offline] ERROR:', err.message);
        }
    });

    // ────────────────────────────────────────────────────────────────
    // [TẮT] Giả lập dữ liệu đo — đã tắt để chỉ nhận dữ liệu thật từ ESP32
    // ────────────────────────────────────────────────────────────────
    // setInterval(async () => { ... }, 15000);

    console.log('[Cron] Tất cả cron jobs đã được đăng ký');
}

module.exports = { scheduleJobs };
