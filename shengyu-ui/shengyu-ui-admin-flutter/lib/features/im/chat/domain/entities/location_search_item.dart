class LocationSearchItem {
  const LocationSearchItem({
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
}
