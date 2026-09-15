# -*- coding: utf-8 -*-
"""
AI Engine cho SmartAir:
  1. generate_summary()         -- nhan xet + khuyen nghi cuoi ngay
  2. answer_chat()              -- tra loi chatbox dua tren du lieu thuc
  3. generate_realtime_warning() -- canh bao push notification
"""
import os
import json
import urllib.request
import urllib.error
from dotenv import load_dotenv
from random_forest import AQI_LEVEL_VN

load_dotenv()


def _call_api(prompt: str, max_tokens: int = 600) -> str:
    """
    Goi Google Gemini API hoac OpenAI-compatible API.
    Tu dong phat hien loai key:
      - GEMINI_API_KEY hoac API_KEY bat dau bang 'AQ.' hoac 'AIza' -> Gemini
      - Nguoc lai -> OpenAI-compatible (ckey.vn, OpenRouter...)
    """
    gemini_key = os.getenv("GEMINI_API_KEY", "").strip()
    api_key = gemini_key or os.getenv("API_KEY", "").strip() or os.getenv("ANTHROPIC_API_KEY", "").strip()
    base_url = os.getenv("API_BASE_URL", "").strip().rstrip("/")
    model = os.getenv("MODEL_NAME", "").strip()

    if not api_key:
        raise ValueError("Chua cau hinh API Key (GEMINI_API_KEY, API_KEY, hoac ANTHROPIC_API_KEY)")

    # ----- Google Gemini -----
    is_gemini = (
        bool(gemini_key)
        or api_key.startswith("AIza")
        or api_key.startswith("AQ.")
        or "generativelanguage.googleapis.com" in base_url
        or "gemini" in model.lower()
    )

    if is_gemini:
        # chon model: uu tien tu .env, fallback sang gemini-3.6-flash
        gemini_model = model if ("gemini" in model.lower() and model) else "gemini-3.6-flash"
        url = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{gemini_model}:generateContent?key={api_key}"
        )
        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "maxOutputTokens": max_tokens,
                "temperature": 0.4,
            },
        }
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return data["candidates"][0]["content"]["parts"][0]["text"]
        except urllib.error.HTTPError as he:
            err = he.read().decode("utf-8", errors="ignore")
            print(f"[Gemini HTTPError] {he.code}: {err[:300]}")
            raise

    # ----- OpenAI-compatible -----
    if not base_url:
        base_url = "https://api.openai.com/v1"
    if not model:
        model = "gpt-4o-mini"

    url = f"{base_url}/chat/completions"
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "temperature": 0.4,
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        return data["choices"][0]["message"]["content"]


# ---------------------------------------------------------------------------
# 1. generate_summary
# ---------------------------------------------------------------------------

def generate_summary(
    hourly_rows: list,
    level: str,
    main_pollutant: str,
    anomaly_hours: list | None = None,
) -> tuple[str, str]:
    """
    Tao nhan xet + khuyen nghi cuoi ngay.
    Returns: (ai_summary, ai_advice)
    """
    hourly_str = ", ".join(
        f"{i}h->AQI={r[5]},T={r[3] or 0:.1f}C,Hum={r[4] or 0:.0f}%,PM2.5={r[2] or 0:.0f}"
        for i, r in enumerate(hourly_rows)
    )

    anomaly_note = ""
    if anomaly_hours:
        anomaly_note = (
            "\nCac gio bat thuong (spike): "
            + ", ".join(str(h) + "h" for h in anomaly_hours)
        )

    level_vn = AQI_LEVEL_VN.get(level, level)

    prompt = (
        "Ban la chuyen gia phan tich chat luong khong khi va vi khi hau moi truong song tai Viet Nam.\n\n"
        f"Du lieu theo gio hom nay (0h-{len(hourly_rows)-1}h) bao gom AQI, Nhiet do (°C), Do am (%) va Bui:\n"
        f"{hourly_str}{anomaly_note}\n\n"
        f"Muc danh gia tong the: {level_vn}\n"
        f"Chi so / yeu to dang chu y nhat: {main_pollutant}\n\n"
        "Viet CHINH XAC 2 dong, moi dong bat dau bang nhan sau:\n"
        "NHAN XET: (2-3 cau mo ta xu huong AQI trong ngay, gio cao diem, nguyen nhan co the)\n"
        "KHUYEN NGHI: (1-2 cau hanh dong cu the, thuc te cho nguoi dung)"
    )

    try:
        text = _call_api(prompt, max_tokens=400)
        summary = ""
        advice = ""
        for line in text.strip().splitlines():
            line = line.strip()
            if line.startswith("NHAN XET:"):
                summary = line.removeprefix("NHAN XET:").strip()
            elif line.startswith("KHUYEN NGHI:"):
                advice = line.removeprefix("KHUYEN NGHI:").strip()
        if not summary:
            summary = text[:300]
        return summary, advice
    except Exception as e:
        print(f"[API] generate_summary error: {e}")
        return (
            f"Muc o nhiem hom nay: {level_vn}. Khi chinh: {main_pollutant}.",
            "Theo doi chi so AQI thuong xuyen va han che ra ngoai khi AQI > 100.",
        )


# ---------------------------------------------------------------------------
# 2. answer_chat
# ---------------------------------------------------------------------------

def answer_chat(question: str, context: dict) -> str:
    """
    Tra loi cau hoi nguoi dung dua tren du lieu thuc tu DB.

    context = {
        "current": { ban doc moi nhat tu readings_buffer },
        "hourly":  [ 24 ban ghi hourly_summary gan nhat ],
        "daily":   { ban ghi daily_summary hom nay },
    }
    """
    current = context.get("current", {})
    daily = context.get("daily", {})
    hourly = context.get("hourly", [])

    aqi = current.get("aqi", "chua co")
    pm25 = current.get("pm25_ugm3", "chua co")
    co2 = current.get("co2_ppm", "chua co")
    co = current.get("co_ppm", "chua co")
    temp = current.get("temperature_c", "chua co")
    hum = current.get("humidity_pct", "chua co")

    level_vn = AQI_LEVEL_VN.get(daily.get("pollution_level", ""), "Chua co bao cao hom nay")
    pollutant = daily.get("main_pollutant", "chua xac dinh")
    ai_sum = daily.get("ai_summary", "")
    aqi_max = daily.get("aqi_max", "chua co")

    recent_trend = ""
    if hourly:
        last6 = hourly[:6]
        trend_str = ", ".join(str(r.get("aqi_avg", "?")) for r in last6)
        recent_trend = f"\nAQI 6h gan nhat (moi -> cu): {trend_str}"

    prompt = (
        "Ban la Tro ly AI chuyen gia cua SmartAir - He sinh thai giam sat vi khi hau, chat luong khong khi"
        " va Du lich Xanh tai Viet Nam.\n\n"

        "=== THONG SO KHONG KHI THUC TE TAI TRAM DO NGAY LUC NAY ===\n"
        f"- AQI: {aqi} | PM2.5: {pm25} ug/m3\n"
        f"- CO2: {co2} ppm | CO: {co} ppm\n"
        f"- Nhiet do: {temp} do C | Do am: {hum}%{recent_trend}\n"
        f"- Danh gia ngay: {level_vn} (AQI cao nhat: {aqi_max}, Chat gay hai chinh: {pollutant})\n"
        f"- Nhan dinh tu dong: {ai_sum or 'He thong dang ghi nhan du lieu on dinh'}\n\n"

        "=== CAU HOI CUA NGUOI DUNG ===\n"
        f"{question}\n\n"

        "=== QUY TAC PHAN HOI (HAY LAM THEO CHINH XAC) ===\n"
        "1. GIONG VAN: Am ap, chuyen nghiep, thong minh, an can nhu mot bac si gia dinh va chuyen gia du lich nghi duong.\n"
        "2. DINH DANG:\n"
        "   - Dung cac bieu tuong phu hop o dau dong (nhu [Cay xanh], [Xe], [Nui], [Ba lo], [Den]...) lam dau muc.\n"
        "   - Chia doan ro rang, ngan gon, suc tich, de nhin tren man hinh smartphone.\n"
        f"3. KHI HOI VE KHONG KHI / SUC KHOE:\n"
        f"   - Nhan dinh ngay muc do an toan cua AQI ({aqi}) va PM2.5 ({pm25}) doi voi nguoi lon, nguoi gia va tre nho.\n"
        "   - Dua ra 2-3 loi khuyen thuc te (mo/dong cua so, dung may loc khi, thoi diem ra ngoai).\n"
        "4. KHI HOI VE DU LICH, NGHI DUONG CUOI TUAN HOAC DIA DANH (nhu Sapa, Tam Dao, Ba Vi, Moc Chau, Da Lat...):\n"
        "   - Canh quan noi bat nen den.\n"
        "   - Khoang cach va thoi gian di chuyen.\n"
        "   - Goi y phuong tien (o to tu lai, xe limousine giu ong nam, tau hoa).\n"
        "   - Hanh trang can chuan bi (ao am day, giay chong tron, thuoc men co ban...).\n"
        "5. Luon ket thuc bang mot cau chuc suc khoe hoac goi mo tich cuc.\n"
        "6. Tong do dai: 150-300 tu. Khong qua dai dong, khong lap lai."
    )

    try:
        return _call_api(prompt, max_tokens=700).strip()
    except Exception as e:
        print(f"[API] answer_chat error: {e}")
        return "Xin loi, hien tai he thong AI dang ban xu ly hoac chua the ket noi. Ban vui long thu lai sau it giay nhe!"


# ---------------------------------------------------------------------------
# 3. generate_realtime_warning
# ---------------------------------------------------------------------------

def generate_realtime_warning(readings: list, is_anomaly: bool) -> str:
    """
    Phan tich chuoi du lieu readings_buffer gan day va tao cau canh bao push notification.
    """
    readings_str = "\n".join(
        f"- AQI={r.get('aqi') or '?'}, PM2.5={r.get('pm25_ugm3') or '?'}ug/m3,"
        f" CO2={r.get('co2_ppm') or '?'}ppm, CO={r.get('co_ppm') or '?'}ppm,"
        f" Temp={r.get('temperature_c') or '?'}C, Hum={r.get('humidity_pct') or '?'}%"
        for r in reversed(readings)
    )

    anomaly_status = "Phat hien di thuong" if is_anomaly else "Binh thuong"

    prompt = (
        "Ban la tro ly AI giam sat chat luong khong khi. Duoi day la chuoi du lieu do gan day nhat"
        " tu thiet bi (tu cu den moi):\n"
        f"{readings_str}\n\n"
        f"Trang thai phat hien bat thuong (AI Outlier): {anomaly_status}\n\n"
        "Nhiem vu: Phan tich cac so lieu va viet mot cau canh bao ngan gon (toi da 2 cau) bang tieng Viet"
        " de lam noi dung thong bao day (push notification) gui toi dien thoai nguoi dung.\n"
        "Yeu cau:\n"
        "- Nhan dinh nhanh ve tinh trang hien tai va dua ra du doan xu huong tiep theo.\n"
        "- KHONG liet ke cu the cac con so tho. Hay noi ve tinh trang chung.\n"
        "- Noi dung ngan gon, tu nhien, mang tinh canh bao va du doan ro rang.\n"
        "Chi tra ve dung noi dung cau canh bao, khong them bot loi dan."
    )

    try:
        return _call_api(prompt, max_tokens=300).strip()
    except Exception as e:
        print(f"[API] generate_realtime_warning error: {e}")
        return ""
