class LocationSearchItemDto {
  const LocationSearchItemDto({
    required this.poiId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.provider,
  });

  final String poiId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String provider;

  factory LocationSearchItemDto.fromJson(Map<String, dynamic> json) {
    return LocationSearchItemDto(
      poiId: json['poiId']?.toString() ?? json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ??
          json['title']?.toString() ??
          json['poiName']?.toString() ??
          '',
      address:
          json['address']?.toString() ??
          json['addr']?.toString() ??
          json['fullAddress']?.toString() ??
          '',
      latitude: _toDouble(json['latitude'] ?? json['lat']),
      longitude: _toDouble(json['longitude'] ?? json['lng']),
      provider:
          json['provider']?.toString() ??
          json['source']?.toString() ??
          'tencent',
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('${value ?? ''}') ?? double.nan;
  }
}
