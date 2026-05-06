class LocationSharePayload {
  const LocationSharePayload({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.provider,
    this.poiId = '',
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String provider;
  final String poiId;
}
