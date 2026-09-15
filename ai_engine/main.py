"""
SmartAir AI Engine — FastAPI
Endpoints:
  POST /daily_report  — Tạo báo cáo AI cuối ngày
  POST /chat          — Trả lời chatbox
  GET  /health        — Health check
"""
import os
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, field_validator

from isolation_forest import detect_anomaly, get_anomaly_hours
from random_forest import classify_pollution, compute_daily_stats
from claude_api import generate_summary, answer_chat, generate_realtime_warning

load_dotenv()
app = FastAPI(title="SmartAir AI Engine", version="1.0.0")


# ── DB connection ────────────────────────────────────────────────────
def get_conn():
    return psycopg2.connect(
        os.getenv("DATABASE_URL"),
        cursor_factory=psycopg2.extras.RealDictCursor,
    )


# ── Request models ───────────────────────────────────────────────────
class DailyReportRequest(BaseModel):
    device_id: str
    date: str  # YYYY-MM-DD

    @field_validator("date")
    @classmethod
    def validate_date(cls, v: str) -> str:
        import re
        if not re.match(r"^\d{4}-\d{2}-\d{2}$", v):
            raise ValueError("date must be YYYY-MM-DD")
        return v


class ChatRequest(BaseModel):
    question: str
    context: dict

    @field_validator("question")
    @classmethod
    def validate_question(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("question cannot be empty")
        if len(v) > 500:
            raise ValueError("question too long (max 500 chars)")
        return v


# ── Endpoints ────────────────────────────────────────────────────────
@app.post("/daily_report")
def daily_report(req: DailyReportRequest):
    conn = get_conn()
    cur  = conn.cursor()

    try:
        cur.execute("""
            SELECT co2_avg, co_avg, pm25_avg, temp_avg, hum_avg,
                   aqi_avg::int AS aqi_avg, aqi_max::int AS aqi_max
            FROM hourly_summary
            WHERE device_id = %s
              AND hour_start::date = %s
            ORDER BY hour_start ASC
        """, (req.device_id, req.date))
        rows = cur.fetchall()

        if not rows:
            return {"status": "no_data", "message": f"Không có dữ liệu hourly cho {req.device_id} ngày {req.date}"}

        row_tuples = [
            (r["co2_avg"], r["co_avg"], r["pm25_avg"], r["temp_avg"],
             r["hum_avg"], r["aqi_avg"], r["aqi_max"])
            for r in rows
        ]

        anomaly_count = detect_anomaly(row_tuples)
        anomaly_hours = get_anomaly_hours(row_tuples)

        level, main_pollutant = classify_pollution(row_tuples)

        stats = compute_daily_stats(row_tuples)

        summary, advice = generate_summary(row_tuples, level, main_pollutant, anomaly_hours)

        cur.execute("""
            INSERT INTO daily_summary
                (device_id, report_date,
                 aqi_avg, aqi_max, aqi_min,
                 pm25_avg, pm25_max,
                 co2_avg, co2_max,
                 co_avg,
                 pollution_level, main_pollutant,
                 anomaly_count, ai_summary, ai_advice)
            VALUES
                (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (device_id, report_date) DO UPDATE SET
                aqi_avg        = EXCLUDED.aqi_avg,
                aqi_max        = EXCLUDED.aqi_max,
                aqi_min        = EXCLUDED.aqi_min,
                pm25_avg       = EXCLUDED.pm25_avg,
                pm25_max       = EXCLUDED.pm25_max,
                co2_avg        = EXCLUDED.co2_avg,
                co_avg         = EXCLUDED.co_avg,
                pollution_level = EXCLUDED.pollution_level,
                main_pollutant  = EXCLUDED.main_pollutant,
                anomaly_count   = EXCLUDED.anomaly_count,
                ai_summary      = EXCLUDED.ai_summary,
                ai_advice       = EXCLUDED.ai_advice,
                created_at      = NOW()
        """, (
            req.device_id, req.date,
            stats.get("aqi_avg"),  stats.get("aqi_max"),  stats.get("aqi_min"),
            stats.get("pm25_avg"), stats.get("pm25_max"),
            stats.get("co2_avg"),  stats.get("co2_max"),
            stats.get("co_avg"),
            level, main_pollutant,
            anomaly_count, summary, advice,
        ))
        conn.commit()

        return {
            "status":         "ok",
            "device_id":      req.device_id,
            "date":           req.date,
            "level":          level,
            "main_pollutant": main_pollutant,
            "anomaly_count":  anomaly_count,
            "hours_analyzed": len(rows),
        }

    except Exception as e:
        conn.rollback()
        print(f"[/daily_report] ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
        conn.close()


class RealtimeAnomalyRequest(BaseModel):
    readings: list[dict]


@app.post("/realtime_anomaly")
def realtime_anomaly(req: RealtimeAnomalyRequest):
    """
    Nhận chuỗi 10 bản ghi gần nhất và chạy Isolation Forest.
    Kiểm tra xem bản ghi cuối cùng (mới nhất) có phải là dị thường hay không.
    """
    try:
        readings = req.readings
        if len(readings) < 5:
            return {"is_anomaly": False}

        import numpy as np
        from sklearn.ensemble import IsolationForest

        # Xây dựng ma trận X (AQI, PM2.5) từ chuỗi dữ liệu
        X = np.array([
            [float(r.get("aqi") or 0), float(r.get("pm25_ugm3") or 0)]
            for r in readings
        ])

        # Chạy Isolation Forest với contamination=0.1
        model = IsolationForest(
            contamination=0.1,
            n_estimators=100,
            random_state=42,
        )
        labels = model.fit_predict(X)

        # Bản ghi cuối cùng (mới nhất) có phải outlier (-1)
        is_anomaly = bool(labels[-1] == -1)
        return {"is_anomaly": is_anomaly}
    except Exception as e:
        print(f"[/realtime_anomaly] ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat")
def chat(req: ChatRequest):
    """Trả lời câu hỏi chatbox dựa trên context dữ liệu thực."""
    try:
        answer = answer_chat(req.question, req.context)
        return {"answer": answer}
    except Exception as e:
        print(f"[/chat] ERROR: {e}")
        raise HTTPException(status_code=500, detail="AI Engine lỗi")


class RealtimeWarningRequest(BaseModel):
    readings: list[dict]
    is_anomaly: bool


@app.post("/realtime_warning")
def realtime_warning(req: RealtimeWarningRequest):
    """
    Phân tích dữ liệu readings_buffer và gọi Claude tạo nội dung cảnh báo & dự đoán.
    """
    try:
        warning = generate_realtime_warning(req.readings, req.is_anomaly)
        return {"warning": warning}
    except Exception as e:
        print(f"[/realtime_warning] ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))



@app.get("/health")
def health():
    """Health check — Node.js backend dùng endpoint này để kiểm tra AI Engine."""
    try:
        conn = get_conn()
        conn.close()
        db_ok = True
    except Exception:
        db_ok = False

    return {
        "status": "ok" if db_ok else "degraded",
        "db":     "connected" if db_ok else "unreachable",
    }


if __name__ == "__main__":
    import uvicorn
    print("[AI Engine] Starting FastAPI at http://0.0.0.0:8000...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
