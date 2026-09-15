const admin = require('firebase-admin');
const pool  = require('../db/pool');

// Khởi tạo Firebase Admin SDK một lần duy nhất
if (!admin.apps.length) {
    try {
        admin.initializeApp({
            credential: admin.credential.cert(
                require('../firebase-service-account.json')
            ),
        });
        console.log('[FCM] Firebase Admin initialized');
    } catch (err) {
        console.warn('[FCM] Firebase Admin init failed (no service account?):', err.message);
    }
}

// Map metric → tên hiển thị tiếng Việt
const METRIC_LABELS = {
    aqi:          'AQI',
    co2_ppm:      'CO₂',
    co_ppm:       'CO (Carbon Monoxide)',
    pm25_ugm3:    'Bụi mịn PM2.5',
    pm10_ugm3:    'Bụi PM10',
    nh3_ppm:      'NH₃ (Amoniac)',
    benzene_ppm:  'Benzene',
    temperature_c:'Nhiệt độ',
    humidity_pct: 'Độ ẩm',
};

/**
 * Kiểm tra ngưỡng cảnh báo và gửi FCM nếu cần.
 * Cooldown 30 phút: không gửi lại cùng metric trong 30 phút.
 * @param {string} device_id
 * @param {object} data - JSON từ ESP32
 */
async function sendAlertIfNeeded(device_id, data) {
    // Lấy tất cả ngưỡng đang active cho thiết bị này (chỉ lấy user có fcm_enabled = TRUE)
    const { rows: settings } = await pool.query(
        `SELECT a.metric, a.threshold, u.fcm_token, u.user_id
         FROM alert_settings a
         JOIN user_devices ud
           ON  ud.device_id = a.device_id
           AND ud.user_id   = a.user_id
         JOIN users u
           ON  u.user_id    = ud.user_id
         WHERE a.device_id = $1
           AND a.is_active  = TRUE
           AND u.fcm_enabled = TRUE`,
        [device_id]
    );

    // Map metric → giá trị hiện tại từ payload ESP32
    const valueMap = {
        aqi:          data.aqi,
        co2_ppm:      data.co2_ppm,
        co_ppm:       data.co_ppm,
        pm25_ugm3:    data.pm25_ugm3,
        pm10_ugm3:    data.pm10_ugm3,
        nh3_ppm:      data.nh3_ppm,
        benzene_ppm:  data.benzene_ppm,
        temperature_c:data.temperature_c,
        humidity_pct: data.humidity_pct,
    };

    for (const s of settings) {
        if (!s.fcm_token || s.fcm_token.startsWith('FCM_TOKEN_')) continue;
        const value = valueMap[s.metric];
        if (value === undefined || value === null || value <= s.threshold) continue;

        // Kiểm tra cooldown 30 phút (Tạm thời tắt để test thông báo tức thì)
        /*
        const { rows: recent } = await pool.query(
            `SELECT 1 FROM notifications
             WHERE device_id = $1
               AND user_id   = $2
               AND metric    = $3
               AND sent_at   > NOW() - INTERVAL '30 minutes'
             LIMIT 1`,
            [device_id, s.user_id, s.metric]
        );
        if (recent.length > 0) continue;
        */

        const label   = METRIC_LABELS[s.metric] || s.metric;
        const msgBody = `${label} đang ở mức ${value} — vượt ngưỡng ${s.threshold} bạn đặt`;

        try {
            if (admin.apps.length > 0) {
                await admin.messaging().send({
                    token: s.fcm_token,
                    notification: {
                        title: '⚠️ SmartAir — Cảnh báo chất lượng không khí',
                        body:  msgBody,
                    },
                    data: {
                        device_id,
                        metric: s.metric,
                        value:  String(value),
                    },
                    android: {
                        priority: 'high',
                        notification: { channelId: 'smartair_alerts' },
                    },
                    apns: {
                        payload: { aps: { sound: 'default', badge: 1 } },
                    },
                });
                console.log(`[FCM] Sent alert to user ${s.user_id}: ${label}=${value}`);
            } else {
                console.log(`[FCM Mock] Notification simulated (no service account) for user ${s.user_id}: ${msgBody}`);
            }

            // Ghi log thông báo đã gửi
            await pool.query(
                `INSERT INTO notifications (device_id, user_id, metric, value, message)
                 VALUES ($1, $2, $3, $4, $5)`,
                [device_id, s.user_id, s.metric, value, msgBody]
            );
        } catch (err) {
            console.error('[FCM] Send failed:', err.message);
        }
    }
}

/**
 * Gửi cảnh báo dị thường thời gian thực phát hiện bởi Isolation Forest.
 * Cooldown 15 phút để tránh spam cảnh báo dị thường.
 */
async function sendAnomalyAlertIfNeeded(device_id, latestReading) {
    try {
        // Lấy tất cả người dùng theo dõi thiết bị này và đã bật thông báo
        const { rows: users } = await pool.query(
            `SELECT u.user_id, u.fcm_token
             FROM user_devices ud
             JOIN users u ON u.user_id = ud.user_id
             WHERE ud.device_id = $1
               AND u.fcm_enabled = TRUE`,
            [device_id]
        );

        if (users.length === 0) return;

        for (const u of users) {
            if (!u.fcm_token || u.fcm_token.startsWith('FCM_TOKEN_')) continue;
            // Kiểm tra cooldown 15 phút cho cảnh báo dị thường (Tạm thời tắt để test thông báo tức thì)
            /*
            const { rows: recent } = await pool.query(
                `SELECT 1 FROM notifications
                 WHERE device_id = $1
                   AND user_id   = $2
                   AND metric    = 'anomaly'
                   AND sent_at   > NOW() - INTERVAL '15 minutes'
                 LIMIT 1`,
                [device_id, u.user_id]
            );
            if (recent.length > 0) continue;
            */

            const msgBody = `Phát hiện biến động chỉ số bất thường (Outlier) bằng thuật toán AI tại thiết bị phòng khách!`;

            if (u.fcm_token && admin.apps.length > 0) {
                await admin.messaging().send({
                    token: u.fcm_token,
                    notification: {
                        title: '🚨 SmartAir — Phát hiện dị thường (AI)',
                        body:  msgBody,
                    },
                    data: {
                        device_id,
                        metric: 'anomaly',
                        value:  String(latestReading.aqi || 0),
                    },
                    android: {
                        priority: 'high',
                        notification: { channelId: 'smartair_alerts' },
                    },
                    apns: {
                        payload: { aps: { sound: 'default', badge: 1 } },
                    },
                });
            }

            // Ghi log thông báo đã gửi
            await pool.query(
                `INSERT INTO notifications (device_id, user_id, metric, value, message)
                 VALUES ($1, $2, 'anomaly', $3, $4)`,
                [device_id, u.user_id, latestReading.aqi || 0, msgBody]
            );

            console.log(`[FCM Anomaly] Sent anomaly alert to user ${u.user_id} for device ${device_id}`);
        }
    } catch (err) {
        console.error('[FCM Anomaly] Send failed:', err.message);
    }
}

/**
 * Tạo nội dung cảnh báo của AI và đưa ra dự đoán dựa trên các số liệu đã đo,
 * không liệt kê chi tiết các con số thô để nội dung tự nhiên và gọn gàng.
 */
function getAIPredictionMessage(data, isAnomaly) {
    if (isAnomaly) {
        return "AI phát hiện biến động không khí bất thường. Dự đoán có nguồn ô nhiễm hoặc khói bụi đột ngột phát sinh gần thiết bị, khuyến nghị kiểm tra phòng và bật máy lọc không khí.";
    }
    
    // Dự đoán dựa trên các số liệu đã đo
    const aqi = data.aqi || 0;
    const pm25 = data.pm25_ugm3 || 0;
    const co2 = data.co2_ppm || 0;
    const co = data.co_ppm || 0;

    if (aqi > 200) {
        return "Chất lượng không khí đang ở mức cực kỳ nguy hại. Dự đoán nồng độ ô nhiễm tích tụ cao sẽ gây ảnh hưởng nghiêm trọng đến sức khỏe hô hấp, khuyến nghị đóng kín toàn bộ cửa và bật máy lọc ở mức tối đa.";
    }
    if (co > 9) {
        return "Nồng độ khí CO đang tăng cao vượt ngưỡng an toàn. Dự đoán nguy cơ thiếu oxy và ngộ độc khí nếu tiếp tục đóng kín cửa, khuyến nghị tắt các thiết bị đốt và thông gió khẩn cấp.";
    }
    if (pm25 > 75) {
        return "Phát hiện mật độ bụi mịn trong phòng đang ở mức cao. Dự đoán các hạt bụi mịn lơ lửng sẽ đi sâu vào đường hô hấp, khuyến nghị bật máy lọc không khí để nhanh chóng làm sạch phòng.";
    }
    if (co2 > 1000) {
        return "Không khí trong phòng có dấu hiệu bí bách và ngột ngạt do tích tụ khí CO₂. Dự đoán người ngồi trong phòng sẽ có cảm giác buồn ngủ, uể oải và giảm tập trung, nên mở hé cửa sổ hoặc bật quạt thông gió.";
    }
    if (aqi > 100) {
        return "Chất lượng không khí trong phòng đang giảm xuống mức kém. Dự đoán nồng độ ô nhiễm sẽ tiếp tục tăng nếu không có biện pháp xử lý, khuyên bạn nên hạn chế mở cửa đón không khí bên ngoài.";
    }

    return "Phát hiện một số chỉ số chất lượng không khí vượt mức bình thường. Dự đoán tình trạng ô nhiễm nhẹ, khuyên bạn nên bật máy lọc không khí.";
}

/**
 * Gửi cảnh báo hợp nhất (gộp cả cảnh báo chỉ số vượt ngưỡng và dị thường AI thành 1 thông báo duy nhất).
 * Thực hiện logic state machine để giảm thiểu tin nhắn spam và tối ưu trải nghiệm người dùng:
 * - Trường hợp 1: Nếu không khí đang ở mức an toàn kéo dài -> thông báo định kỳ 6 tiếng 1 lần.
 * - Trường hợp 2: Nếu đột ngột tăng lên mức không an toàn -> thông báo ngay lập tức.
 *   Nếu tiếp tục ở mức không an toàn -> không gửi thêm thông báo nào nữa.
 *   Khi chuyển từ không an toàn về an toàn -> thông báo ngay lập tức 1 lần duy nhất, sau đó quay lại Trường hợp 1.
 */
async function sendUnifiedAlert(device_id, data, isAnomaly) {
    try {
        // 1. Lấy tất cả ngưỡng đang hoạt động cho thiết bị này (chỉ lấy user đã bật FCM)
        const { rows: settings } = await pool.query(
            `SELECT a.metric, a.threshold, u.fcm_token, u.user_id
             FROM alert_settings a
             JOIN user_devices ud
               ON  ud.device_id = a.device_id
               AND ud.user_id   = a.user_id
             JOIN users u
               ON  u.user_id    = ud.user_id
             WHERE a.device_id = $1
               AND a.is_active  = TRUE
               AND u.fcm_enabled = TRUE`,
            [device_id]
        );

        // Map metric -> giá trị hiện tại
        const valueMap = {
            aqi:          data.aqi,
            co2_ppm:      data.co2_ppm,
            co_ppm:       data.co_ppm,
            pm25_ugm3:    data.pm25_ugm3,
            pm10_ugm3:    data.pm10_ugm3,
            nh3_ppm:      data.nh3_ppm,
            benzene_ppm:  data.benzene_ppm,
            temperature_c:data.temperature_c,
            humidity_pct: data.humidity_pct,
        };

        // Đơn vị đo hiển thị
        const metricUnits = {
            aqi:          '',
            co2_ppm:      ' ppm',
            co_ppm:       ' ppm',
            pm25_ugm3:    ' µg/m³',
            pm10_ugm3:    ' µg/m³',
            nh3_ppm:      ' ppm',
            benzene_ppm:  ' ppm',
            temperature_c:'°C',
            humidity_pct: '%',
        };

        // Nhóm settings theo user_id
        const userAlerts = {};
        for (const s of settings) {
            if (!s.fcm_token || s.fcm_token.startsWith('FCM_TOKEN_')) continue;
            if (!userAlerts[s.user_id]) {
                userAlerts[s.user_id] = {
                    fcm_token: s.fcm_token,
                    thresholds: []
                };
            }
            userAlerts[s.user_id].thresholds.push(s);
        }

        // Lấy danh sách tất cả users liên kết với thiết bị
        const { rows: linkedUsers } = await pool.query(
            `SELECT ud.user_id, u.fcm_token
             FROM user_devices ud
             JOIN users u ON u.user_id = ud.user_id
             WHERE ud.device_id = $1
               AND u.fcm_enabled = TRUE`,
            [device_id]
        );

        for (const u of linkedUsers) {
            if (!u.fcm_token || u.fcm_token.startsWith('FCM_TOKEN_')) continue;
            if (!userAlerts[u.user_id]) {
                userAlerts[u.user_id] = {
                    fcm_token: u.fcm_token,
                    thresholds: []
                };
            }
        }

        const usersToNotify = [];
        let needsAiWarning = false;

        // 2. Kiểm tra State Machine cho từng user
        for (const [userIdStr, userConfig] of Object.entries(userAlerts)) {
            const user_id = parseInt(userIdStr, 10);
            const exceededList = [];
            let primaryExceededMetric = null;
            let primaryExceededValue = null;

            // Xác định xem chỉ số nào vượt ngưỡng đã cấu hình của user này
            for (const s of userConfig.thresholds) {
                const value = valueMap[s.metric];
                if (value === undefined || value === null || value <= s.threshold) continue;

                const label = METRIC_LABELS[s.metric] || s.metric;
                const unit = metricUnits[s.metric] || '';
                exceededList.push(`${label} (${value}${unit} > ngưỡng ${s.threshold}${unit})`);

                if (!primaryExceededMetric) {
                    primaryExceededMetric = s.metric;
                    primaryExceededValue = value;
                }
            }

            // Trạng thái hiện tại đối với user này: không an toàn nếu có dị thường AI hoặc có chỉ số vượt ngưỡng cài đặt
            const isCurrentUnsafe = isAnomaly || exceededList.length > 0;

            // Truy vấn thông báo gần đây nhất gửi tới user này
            const { rows: lastNotifRows } = await pool.query(
                `SELECT metric, sent_at FROM notifications 
                 WHERE device_id = $1 AND user_id = $2 
                 ORDER BY sent_at DESC LIMIT 1`,
                [device_id, user_id]
            );
            const lastNotif = lastNotifRows[0];

            let shouldNotify = false;
            let title = '';
            let msgBody = '';
            let saveMetric = 'safe';
            let saveValue = data.aqi || 0;

            if (!isCurrentUnsafe) {
                // HỆ THỐNG AN TOÀN
                if (lastNotif && lastNotif.metric !== 'safe') {
                    // TRƯỜNG HỢP 2: Chuyển từ KHÔNG AN TOÀN về AN TOÀN -> gửi thông báo ngay lập tức 1 lần
                    shouldNotify = true;
                    title = '✅ SmartAir — Không khí đã an toàn trở lại';
                    msgBody = 'Chất lượng không khí đã được cải thiện và trở lại mức an toàn. Cảm ơn bạn đã thực hiện các biện pháp làm sạch!';
                    saveMetric = 'safe';
                    saveValue = data.aqi || 0;
                } else {
                    // TRƯỜNG HỢP 1: An toàn kéo dài -> gửi thông báo định kỳ 6 tiếng 1 lần
                    let isTimeToSend = false;
                    if (!lastNotif) {
                        isTimeToSend = true; // Chưa từng thông báo
                    } else {
                        const lastSentTime = new Date(lastNotif.sent_at).getTime();
                        const hoursSinceLast = (Date.now() - lastSentTime) / (1000 * 60 * 60);
                        if (hoursSinceLast >= 6) {
                            isTimeToSend = true;
                        }
                    }

                    if (isTimeToSend) {
                        shouldNotify = true;
                        title = '🍀 SmartAir — Chất lượng không khí an toàn';
                        msgBody = 'Chất lượng không khí trong khu vực của bạn hiện đang ở mức an toàn. Hãy tiếp tục duy trì không gian thông thoáng!';
                        saveMetric = 'safe';
                        saveValue = data.aqi || 0;
                    }
                }
            } else {
                // HỆ THỐNG KHÔNG AN TOÀN
                if (!lastNotif || lastNotif.metric === 'safe') {
                    // TRƯỜNG HỢP 2: Đột ngột tăng lên không an toàn (hoặc có khí tăng bất thường) -> cảnh báo ngay lập tức
                    shouldNotify = true;
                    needsAiWarning = true; // Cần phân tích sâu từ AI Claude

                    if (isAnomaly) {
                        title = '🚨 SmartAir — Phát hiện dị thường (AI)';
                        saveMetric = 'anomaly';
                        saveValue = data.aqi || 0;
                    } else {
                        title = '⚠️ SmartAir — Cảnh báo chỉ số vượt ngưỡng';
                        saveMetric = primaryExceededMetric || 'aqi';
                        saveValue = primaryExceededValue !== null ? primaryExceededValue : (data.aqi || 0);
                    }
                } else {
                    // TRƯỜPO HỢP 2: Tiếp tục không an toàn -> KHÔNG thông báo nữa để tránh spam phiền toái
                    shouldNotify = false;
                }
            }

            if (shouldNotify) {
                usersToNotify.push({
                    user_id,
                    fcm_token: userConfig.fcm_token,
                    title,
                    msgBody, // Sẽ điền nội dung AI ở bước tiếp theo nếu không an toàn
                    saveMetric,
                    saveValue,
                    isUnsafe: isCurrentUnsafe
                });
            }
        }

        if (usersToNotify.length === 0) return;

        // 3. Gọi AI Engine một lần duy nhất nếu có ít nhất một user cần thông báo Cảnh báo động
        let aiWarning = "";
        if (needsAiWarning) {
            try {
                const { rows: bufferReadings } = await pool.query(
                    `SELECT aqi, pm25_ugm3, co2_ppm, co_ppm, temperature_c, humidity_pct, recorded_at 
                     FROM readings_buffer 
                     WHERE device_id = $1 
                     ORDER BY recorded_at DESC LIMIT 10`,
                    [device_id]
                );

                const axios = require('axios');
                const aiRes = await axios.post(
                    `${process.env.AI_ENGINE_URL}/realtime_warning`,
                    {
                        readings: bufferReadings,
                        is_anomaly: isAnomaly
                    },
                    { timeout: 8000 }
                );
                aiWarning = aiRes.data.warning;
            } catch (err) {
                console.error('[FCM AI Warning] Failed to call AI Engine:', err.message);
            }
        }

        // 4. Duyệt qua từng user cần nhận và gửi thông báo qua FCM
        for (const client of usersToNotify) {
            const { user_id, fcm_token, title, saveMetric, saveValue, isUnsafe } = client;
            let msgBody = client.msgBody;

            // Nếu là cảnh báo không an toàn, sử dụng nội dung do AI tạo ra (fallback về logic offline)
            if (isUnsafe) {
                msgBody = aiWarning || getAIPredictionMessage(data, isAnomaly);
            }

            try {
                if (admin.apps.length > 0) {
                    await admin.messaging().send({
                        token: fcm_token,
                        notification: {
                            title: title,
                            body:  msgBody,
                        },
                        data: {
                            device_id,
                            metric: saveMetric,
                            value:  String(saveValue),
                        },
                        android: {
                            priority: 'high',
                            notification: { channelId: 'smartair_alerts' },
                        },
                        apns: {
                            payload: { aps: { sound: 'default', badge: 1 } },
                        },
                    });
                    console.log(`[FCM Unified] Sent notification to user ${user_id}: [${title}] ${msgBody}`);
                } else {
                    console.log(`[FCM Unified Mock] Simulated notification for user ${user_id}: [${title}] ${msgBody}`);
                }

                // Ghi nhận lịch sử thông báo gửi thành công vào Database
                await pool.query(
                    `INSERT INTO notifications (device_id, user_id, metric, value, message)
                     VALUES ($1, $2, $3, $4, $5)`,
                    [device_id, user_id, saveMetric, saveValue, msgBody]
                );
            } catch (err) {
                console.error(`[FCM Unified] Send failed for user ${user_id}:`, err.message);
            }
        }
    } catch (err) {
        console.error('[FCM Unified] Unified alert check error:', err.message);
    }
}

module.exports = { sendAlertIfNeeded, sendAnomalyAlertIfNeeded, sendUnifiedAlert };


