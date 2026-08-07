enum ScaleTransport { bluetoothLowEnergy }

/// Presentation-independent identity and discovery metadata for a scale.
final class ScaleDevice {
  ScaleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.lastSeenAt,
    this.transport = ScaleTransport.bluetoothLowEnergy,
    Iterable<String> advertisedServiceIds = const [],
  }) : advertisedServiceIds = List.unmodifiable(advertisedServiceIds);

  final String id;
  final String? name;
  final int? rssi;
  final DateTime lastSeenAt;
  final ScaleTransport transport;
  final List<String> advertisedServiceIds;

  String get displayName {
    final candidate = name?.trim();
    return candidate == null || candidate.isEmpty
        ? 'Bluetooth weight scale'
        : candidate;
  }

  ScaleDevice copyWith({
    String? name,
    int? rssi,
    DateTime? lastSeenAt,
    Iterable<String>? advertisedServiceIds,
  }) {
    return ScaleDevice(
      id: id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      transport: transport,
      advertisedServiceIds: advertisedServiceIds ?? this.advertisedServiceIds,
    );
  }

  @override
  bool operator ==(Object other) => other is ScaleDevice && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ScaleDevice(id: $id, name: $name, rssi: $rssi)';
}
