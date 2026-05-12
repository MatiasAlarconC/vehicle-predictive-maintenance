class VehicleReading {
  final DateTime timestamp;
  final double rpm;
  final double engineTemp;
  final double speed;
  final double engineLoad;
  final double voltage;
  final double maf;

  const VehicleReading({
    required this.timestamp,
    required this.rpm,
    required this.engineTemp,
    required this.speed,
    required this.engineLoad,
    required this.voltage,
    required this.maf,
  });

  bool get isAnomalous => engineTemp > 105 || voltage < 11.5 || rpm > 5500;
}
