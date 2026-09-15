class Reading {
  final String deviceId;
  final DateTime recordedAt;
  final double? co2Ppm;
  final double? nh3Ppm;
  final double? benzenePpm;
  final double? coPpm;
  final double? pm1Ugm3;
  final double? pm25Ugm3;
  final double? pm10Ugm3;
  final double? temperatureC;
  final double? humidityPct;
  final double? pressureHpa;
  final int aqi;

  const Reading({
    required this.deviceId,
    required this.recordedAt,
    this.co2Ppm,
    this.nh3Ppm,
    this.benzenePpm,
    this.coPpm,
    this.pm1Ugm3,
    this.pm25Ugm3,
    this.pm10Ugm3,
    this.temperatureC,
    this.humidityPct,
    this.pressureHpa,
    required this.aqi,
  });

  factory Reading.fromJson(Map<String, dynamic> json) => Reading(
        deviceId:    json['device_id'] as String,
        recordedAt:  DateTime.parse(json['recorded_at'] as String),
        co2Ppm:      (json['co2_ppm']       as num?)?.toDouble(),
        nh3Ppm:      (json['nh3_ppm']       as num?)?.toDouble(),
        benzenePpm:  (json['benzene_ppm']   as num?)?.toDouble(),
        coPpm:       (json['co_ppm']        as num?)?.toDouble(),
        pm1Ugm3:     (json['pm1_ugm3']      as num?)?.toDouble(),
        pm25Ugm3:    (json['pm25_ugm3']     as num?)?.toDouble(),
        pm10Ugm3:    (json['pm10_ugm3']     as num?)?.toDouble(),
        temperatureC:(json['temperature_c'] as num?)?.toDouble(),
        humidityPct: (json['humidity_pct']  as num?)?.toDouble(),
        pressureHpa: (json['pressure_hpa']  as num?)?.toDouble(),
        aqi:         (json['aqi'] as num).toInt(),
      );

  String get aqiLevel {
    if (aqi <= 50)  return 'Tốt';
    if (aqi <= 100) return 'Trung bình';
    if (aqi <= 150) return 'Không tốt';
    if (aqi <= 200) return 'Có hại';
    if (aqi <= 300) return 'Rất có hại';
    return 'Nguy hiểm';
  }
}
