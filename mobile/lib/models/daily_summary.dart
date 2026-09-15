class DailySummary {
  final String deviceId;
  final DateTime reportDate;
  final int?    aqiAvg;
  final int?    aqiMax;
  final int?    aqiMin;
  final double? pm25Avg;
  final double? co2Avg;
  final double? coAvg;
  final String? pollutionLevel;
  final String? mainPollutant;
  final int     anomalyCount;
  final String? aiSummary;
  final String? aiAdvice;

  const DailySummary({
    required this.deviceId,
    required this.reportDate,
    this.aqiAvg,
    this.aqiMax,
    this.aqiMin,
    this.pm25Avg,
    this.co2Avg,
    this.coAvg,
    this.pollutionLevel,
    this.mainPollutant,
    this.anomalyCount = 0,
    this.aiSummary,
    this.aiAdvice,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        deviceId:       json['device_id'] as String,
        reportDate:     DateTime.parse(json['report_date'] as String),
        aqiAvg:         (json['aqi_avg']  as num?)?.toInt(),
        aqiMax:         (json['aqi_max']  as num?)?.toInt(),
        aqiMin:         (json['aqi_min']  as num?)?.toInt(),
        pm25Avg:        (json['pm25_avg'] as num?)?.toDouble(),
        co2Avg:         (json['co2_avg']  as num?)?.toDouble(),
        coAvg:          (json['co_avg']   as num?)?.toDouble(),
        pollutionLevel: json['pollution_level'] as String?,
        mainPollutant:  json['main_pollutant']  as String?,
        anomalyCount:   (json['anomaly_count']  as num?)?.toInt() ?? 0,
        aiSummary:      json['ai_summary']  as String?,
        aiAdvice:       json['ai_advice']   as String?,
      );

  String get pollutionLevelVn {
    const map = {
      'good':                'Tốt',
      'moderate':            'Trung bình',
      'unhealthy_sensitive': 'Không tốt — nhóm nhạy cảm',
      'unhealthy':           'Có hại',
      'very_unhealthy':      'Rất có hại',
      'hazardous':           'Nguy hiểm',
    };
    return map[pollutionLevel] ?? pollutionLevel ?? 'Chưa có báo cáo';
  }

  String get dateLabel {
    final d = reportDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
