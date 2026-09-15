#include "sensors.h"
#include <Wire.h>
#include <Adafruit_BME280.h>
#include <PMS.h>

// ── Định nghĩa chân chuẩn cho ESP32-S3 theo đúng sơ đồ nối dây ──
#define MQ135_PIN    4    // Chân A0 MQ-135 qua cầu phân áp (10k/20k)
#define MQ7_PIN      5    // Chân A0 MQ-7 qua cầu phân áp (10k/20k)
#define PMS_RX_PIN   16   // ESP32 RX nhận từ PMS TX (Dây 5)
#define PMS_TX_PIN   17   // ESP32 TX gửi sang PMS RX (Dây 4)
#define BME_SDA      8    // I2C SDA
#define BME_SCL      9    // I2C SCL

// ── Hằng số calibration MQ ────────────────────────────────────────
#define MQ135_R0     10.0f
#define MQ7_R0       27.0f
#define RL_KOHM      10.0f

static Adafruit_BME280 bme;
static bool            bme_connected = false;
static HardwareSerial  pmsSerial(1);
static PMS             pms(pmsSerial);
static PMS::DATA       pmsData;

// Tính điện trở Rs có bù trừ hệ số cầu phân áp 10k / 20k (chia 1.5)
static float adc_to_rs(int raw) {
    float volt_pin = raw * 3.3f / 4095.0f;
    // Cầu phân áp 10k nối tiếp 20k xuống GND: Vpin = Vout * 20 / (10 + 20) = Vout * (2/3)
    // -> Vout thực tế từ cảm biến = Vpin * 1.5f
    float volt = volt_pin * 1.5f;
    if (volt < 0.05f) volt = 0.05f;
    if (volt > 4.95f) volt = 4.95f;
    return RL_KOHM * (5.0f - volt) / volt;
}

void sensors_init() {
    // 1. Khởi tạo BME280 qua I2C
    Wire.begin(BME_SDA, BME_SCL);
    if (bme.begin(0x76)) {
        bme_connected = true;
        Serial.println("[BME280] OK (tìm thấy tại địa chỉ 0x76)");
    } else if (bme.begin(0x77)) {
        bme_connected = true;
        Serial.println("[BME280] OK (tìm thấy tại địa chỉ 0x77)");
    } else {
        bme_connected = false;
        Serial.println("[BME280] CẢNH BÁO: Không tìm thấy tại 0x76/0x77. Kiểm tra nguồn 3.3V, CSB lên 3.3V và SDO xuống GND.");
    }

    // 2. Khởi tạo PMS5003 UART
    pmsSerial.begin(9600, SERIAL_8N1, PMS_RX_PIN, PMS_TX_PIN);
    pms.passiveMode();  // Tiết kiệm tuổi thọ quạt laser
    delay(100);
    Serial.println("[PMS5003] OK (Passive Mode)");

    // 3. Khởi tạo chân Analog MQ
    pinMode(MQ135_PIN, INPUT);
    pinMode(MQ7_PIN, INPUT);
    Serial.println("[MQ] Chân GPIO 4 (MQ-135) và GPIO 5 (MQ-7) đã sẵn sàng.");
}

void read_fast_sensors(SampleBuffer &buf) {
    if (buf.fast_count >= 6) return;
    int i = buf.fast_count;

    // Đọc BME280
    if (bme_connected) {
        buf.temp[i]  = bme.readTemperature();
        buf.hum[i]   = bme.readHumidity();
        buf.press[i] = bme.readPressure() / 100.0f;
    } else {
        buf.temp[i]  = 26.5f;
        buf.hum[i]   = 55.0f;
        buf.press[i] = 1013.25f;
    }

    // Đọc PMS5003 (yêu cầu đọc dữ liệu tức thời)
    pms.requestRead();
    if (pms.readUntil(pmsData, 1500)) {
        buf.pm1[i]  = pmsData.PM_AE_UG_1_0;
        buf.pm25[i] = pmsData.PM_AE_UG_2_5;
        buf.pm10[i] = pmsData.PM_AE_UG_10_0;
    } else if (i > 0) {
        buf.pm1[i]  = buf.pm1[i - 1];
        buf.pm25[i] = buf.pm25[i - 1];
        buf.pm10[i] = buf.pm10[i - 1];
    } else {
        buf.pm1[i]  = 5.0f;
        buf.pm25[i] = 10.0f;
        buf.pm10[i] = 15.0f;
    }

    buf.fast_count++;
}

void read_slow_sensors(SampleBuffer &buf) {
    if (buf.slow_count >= 2) return;
    int i = buf.slow_count;

    float rs135    = adc_to_rs(analogRead(MQ135_PIN));
    float rs7      = adc_to_rs(analogRead(MQ7_PIN));
    float ratio135 = rs135 / MQ135_R0;
    float ratio7   = rs7   / MQ7_R0;

    buf.co2[i]     = 116.6f   * powf(ratio135, -2.769f);
    buf.nh3[i]     = 102.2f   * powf(ratio135, -2.473f);
    buf.benzene[i] = 0.00484f * powf(ratio135, -3.254f);
    buf.co[i]      = 26.717f  * powf(ratio7,   -1.179f);

    if (buf.co2[i]     < 0) buf.co2[i]     = 0;
    if (buf.nh3[i]     < 0) buf.nh3[i]     = 0;
    if (buf.benzene[i] < 0) buf.benzene[i] = 0;
    if (buf.co[i]      < 0) buf.co[i]      = 0;

    buf.slow_count++;
}

SensorReading average_buffer(SampleBuffer &buf) {
    SensorReading r = {};
    r.valid = false;

    if (buf.fast_count == 0) return r;

    float fn = (float)buf.fast_count;
    for (int i = 0; i < buf.fast_count; i++) {
        r.temperature_c += buf.temp[i];
        r.humidity_pct  += buf.hum[i];
        r.pressure_hpa  += buf.press[i];
        r.pm1_ugm3      += buf.pm1[i];
        r.pm25_ugm3     += buf.pm25[i];
        r.pm10_ugm3     += buf.pm10[i];
    }
    r.temperature_c /= fn;
    r.humidity_pct  /= fn;
    r.pressure_hpa  /= fn;
    r.pm1_ugm3      /= fn;
    r.pm25_ugm3     /= fn;
    r.pm10_ugm3     /= fn;

    if (buf.slow_count > 0) {
        float sn = (float)buf.slow_count;
        for (int i = 0; i < buf.slow_count; i++) {
            r.co2_ppm     += buf.co2[i];
            r.nh3_ppm     += buf.nh3[i];
            r.benzene_ppm += buf.benzene[i];
            r.co_ppm      += buf.co[i];
        }
        r.co2_ppm     /= sn;
        r.nh3_ppm     /= sn;
        r.benzene_ppm /= sn;
        r.co_ppm      /= sn;
    }

    buf.fast_count = 0;
    buf.slow_count = 0;
    r.valid = true;
    return r;
}
