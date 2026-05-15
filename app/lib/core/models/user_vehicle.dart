import 'dart:ui';

enum CarBodyType { sedan, suv, coupe, truck }

enum VehicleColor {
  pearlWhite,
  midnightBlack,
  metallicSilver,
  racingBlue,
  racingRed,
  emeraldGreen,
  titaniumGray,
  navyBlue,
}

extension VehicleColorExt on VehicleColor {
  Color get color {
    switch (this) {
      case VehicleColor.pearlWhite:      return const Color(0xFFEEEEEE);
      case VehicleColor.midnightBlack:   return const Color(0xFF1A1A2E);
      case VehicleColor.metallicSilver:  return const Color(0xFF9E9E9E);
      case VehicleColor.racingBlue:      return const Color(0xFF0D47A1);
      case VehicleColor.racingRed:       return const Color(0xFFC62828);
      case VehicleColor.emeraldGreen:    return const Color(0xFF1B5E20);
      case VehicleColor.titaniumGray:    return const Color(0xFF546E7A);
      case VehicleColor.navyBlue:        return const Color(0xFF1A237E);
    }
  }

  String get label {
    switch (this) {
      case VehicleColor.pearlWhite:      return 'Blanco Perla';
      case VehicleColor.midnightBlack:   return 'Negro Medianoche';
      case VehicleColor.metallicSilver:  return 'Plata Metálico';
      case VehicleColor.racingBlue:      return 'Azul Racing';
      case VehicleColor.racingRed:       return 'Rojo Racing';
      case VehicleColor.emeraldGreen:    return 'Verde Esmeralda';
      case VehicleColor.titaniumGray:    return 'Gris Titanio';
      case VehicleColor.navyBlue:        return 'Azul Marino';
    }
  }
}

class UserVehicle {
  final String make;
  final String model;
  final int year;
  final VehicleColor color;
  final CarBodyType bodyType;
  final String? nickname;
  /// Absolute file path to a user-supplied photo (nullable).
  final String? customImagePath;

  const UserVehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.bodyType,
    this.nickname,
    this.customImagePath,
  });

  String get displayName => nickname ?? '$make $model';

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year': year,
    'color': color.name,
    'bodyType': bodyType.name,
    'nickname': nickname,
    'customImagePath': customImagePath,
  };

  factory UserVehicle.fromJson(Map<String, dynamic> j) => UserVehicle(
    make: j['make'] as String,
    model: j['model'] as String,
    year: j['year'] as int,
    color: VehicleColor.values.firstWhere((e) => e.name == j['color'],
        orElse: () => VehicleColor.midnightBlack),
    bodyType: CarBodyType.values.firstWhere((e) => e.name == j['bodyType'],
        orElse: () => CarBodyType.sedan),
    nickname: j['nickname'] as String?,
    customImagePath: j['customImagePath'] as String?,
  );
}

// Car catalog
class CarMake {
  final String name;
  final List<CarModelEntry> models;
  const CarMake({required this.name, required this.models});
}

class CarModelEntry {
  final String name;
  final CarBodyType bodyType;
  const CarModelEntry(this.name, this.bodyType);
}

const List<CarMake> kCarCatalog = [
  // ── German ─────────────────────────────────────────────────────────────────
  CarMake(name: 'BMW', models: [
    CarModelEntry('Serie 1', CarBodyType.sedan),
    CarModelEntry('Serie 2', CarBodyType.coupe),
    CarModelEntry('Serie 3', CarBodyType.sedan),
    CarModelEntry('Serie 4', CarBodyType.coupe),
    CarModelEntry('Serie 5', CarBodyType.sedan),
    CarModelEntry('Serie 6', CarBodyType.coupe),
    CarModelEntry('Serie 7', CarBodyType.sedan),
    CarModelEntry('Serie 8', CarBodyType.coupe),
    CarModelEntry('M2', CarBodyType.coupe),
    CarModelEntry('M3', CarBodyType.sedan),
    CarModelEntry('M4', CarBodyType.coupe),
    CarModelEntry('M5', CarBodyType.sedan),
    CarModelEntry('M8', CarBodyType.coupe),
    CarModelEntry('X1', CarBodyType.suv),
    CarModelEntry('X2', CarBodyType.suv),
    CarModelEntry('X3', CarBodyType.suv),
    CarModelEntry('X4', CarBodyType.suv),
    CarModelEntry('X5', CarBodyType.suv),
    CarModelEntry('X6', CarBodyType.suv),
    CarModelEntry('X7', CarBodyType.suv),
    CarModelEntry('i4', CarBodyType.sedan),
    CarModelEntry('i5', CarBodyType.sedan),
    CarModelEntry('i7', CarBodyType.sedan),
    CarModelEntry('iX', CarBodyType.suv),
  ]),
  CarMake(name: 'Mercedes', models: [
    CarModelEntry('Clase A', CarBodyType.sedan),
    CarModelEntry('Clase B', CarBodyType.sedan),
    CarModelEntry('Clase C', CarBodyType.sedan),
    CarModelEntry('Clase E', CarBodyType.sedan),
    CarModelEntry('Clase S', CarBodyType.sedan),
    CarModelEntry('CLA', CarBodyType.coupe),
    CarModelEntry('GLA', CarBodyType.suv),
    CarModelEntry('GLB', CarBodyType.suv),
    CarModelEntry('GLC', CarBodyType.suv),
    CarModelEntry('GLE', CarBodyType.suv),
    CarModelEntry('GLS', CarBodyType.suv),
    CarModelEntry('AMG GT', CarBodyType.coupe),
  ]),
  CarMake(name: 'Audi', models: [
    CarModelEntry('A1', CarBodyType.sedan),
    CarModelEntry('A3', CarBodyType.sedan),
    CarModelEntry('A4', CarBodyType.sedan),
    CarModelEntry('A5', CarBodyType.coupe),
    CarModelEntry('A6', CarBodyType.sedan),
    CarModelEntry('A8', CarBodyType.sedan),
    CarModelEntry('RS3', CarBodyType.sedan),
    CarModelEntry('RS6', CarBodyType.sedan),
    CarModelEntry('TT', CarBodyType.coupe),
    CarModelEntry('Q2', CarBodyType.suv),
    CarModelEntry('Q3', CarBodyType.suv),
    CarModelEntry('Q5', CarBodyType.suv),
    CarModelEntry('Q7', CarBodyType.suv),
    CarModelEntry('Q8', CarBodyType.suv),
    CarModelEntry('e-tron', CarBodyType.suv),
  ]),
  CarMake(name: 'Volkswagen', models: [
    CarModelEntry('Polo', CarBodyType.sedan),
    CarModelEntry('Golf', CarBodyType.sedan),
    CarModelEntry('Golf GTI', CarBodyType.sedan),
    CarModelEntry('Jetta', CarBodyType.sedan),
    CarModelEntry('Passat', CarBodyType.sedan),
    CarModelEntry('Arteon', CarBodyType.coupe),
    CarModelEntry('T-Cross', CarBodyType.suv),
    CarModelEntry('T-Roc', CarBodyType.suv),
    CarModelEntry('Tiguan', CarBodyType.suv),
    CarModelEntry('Touareg', CarBodyType.suv),
    CarModelEntry('ID.3', CarBodyType.sedan),
    CarModelEntry('ID.4', CarBodyType.suv),
  ]),
  CarMake(name: 'Porsche', models: [
    CarModelEntry('911', CarBodyType.coupe),
    CarModelEntry('718 Boxster', CarBodyType.coupe),
    CarModelEntry('718 Cayman', CarBodyType.coupe),
    CarModelEntry('Panamera', CarBodyType.sedan),
    CarModelEntry('Macan', CarBodyType.suv),
    CarModelEntry('Cayenne', CarBodyType.suv),
    CarModelEntry('Taycan', CarBodyType.sedan),
  ]),
  CarMake(name: 'Opel', models: [
    CarModelEntry('Corsa', CarBodyType.sedan),
    CarModelEntry('Astra', CarBodyType.sedan),
    CarModelEntry('Insignia', CarBodyType.sedan),
    CarModelEntry('Mokka', CarBodyType.suv),
    CarModelEntry('Grandland', CarBodyType.suv),
    CarModelEntry('Crossland', CarBodyType.suv),
  ]),

  // ── Japanese ────────────────────────────────────────────────────────────────
  CarMake(name: 'Toyota', models: [
    CarModelEntry('Yaris', CarBodyType.sedan),
    CarModelEntry('Yaris Cross', CarBodyType.suv),
    CarModelEntry('Corolla', CarBodyType.sedan),
    CarModelEntry('Corolla Cross', CarBodyType.suv),
    CarModelEntry('Camry', CarBodyType.sedan),
    CarModelEntry('C-HR', CarBodyType.suv),
    CarModelEntry('RAV4', CarBodyType.suv),
    CarModelEntry('Fortuner', CarBodyType.suv),
    CarModelEntry('Rush', CarBodyType.suv),
    CarModelEntry('Innova', CarBodyType.suv),
    CarModelEntry('Land Cruiser', CarBodyType.suv),
    CarModelEntry('Land Cruiser Prado', CarBodyType.suv),
    CarModelEntry('Hilux', CarBodyType.truck),
    CarModelEntry('GR86', CarBodyType.coupe),
    CarModelEntry('GR Supra', CarBodyType.coupe),
    CarModelEntry('Prius', CarBodyType.sedan),
    CarModelEntry('Highlander', CarBodyType.suv),
  ]),
  CarMake(name: 'Honda', models: [
    CarModelEntry('Jazz', CarBodyType.sedan),
    CarModelEntry('Civic', CarBodyType.sedan),
    CarModelEntry('Civic Type R', CarBodyType.sedan),
    CarModelEntry('Accord', CarBodyType.sedan),
    CarModelEntry('City', CarBodyType.sedan),
    CarModelEntry('HR-V', CarBodyType.suv),
    CarModelEntry('CR-V', CarBodyType.suv),
    CarModelEntry('Pilot', CarBodyType.suv),
    CarModelEntry('Passport', CarBodyType.suv),
    CarModelEntry('Ridgeline', CarBodyType.truck),
  ]),
  CarMake(name: 'Mazda', models: [
    CarModelEntry('Mazda 2', CarBodyType.sedan),
    CarModelEntry('Mazda 3', CarBodyType.sedan),
    CarModelEntry('Mazda 6', CarBodyType.sedan),
    CarModelEntry('CX-3', CarBodyType.suv),
    CarModelEntry('CX-30', CarBodyType.suv),
    CarModelEntry('CX-5', CarBodyType.suv),
    CarModelEntry('CX-9', CarBodyType.suv),
    CarModelEntry('MX-5', CarBodyType.coupe),
    CarModelEntry('MX-30', CarBodyType.suv),
  ]),
  CarMake(name: 'Subaru', models: [
    CarModelEntry('Impreza', CarBodyType.sedan),
    CarModelEntry('WRX', CarBodyType.sedan),
    CarModelEntry('BRZ', CarBodyType.coupe),
    CarModelEntry('Legacy', CarBodyType.sedan),
    CarModelEntry('Outback', CarBodyType.suv),
    CarModelEntry('Forester', CarBodyType.suv),
    CarModelEntry('Crosstrek', CarBodyType.suv),
    CarModelEntry('Ascent', CarBodyType.suv),
  ]),
  CarMake(name: 'Mitsubishi', models: [
    CarModelEntry('Mirage', CarBodyType.sedan),
    CarModelEntry('Eclipse Cross', CarBodyType.suv),
    CarModelEntry('Outlander', CarBodyType.suv),
    CarModelEntry('ASX', CarBodyType.suv),
    CarModelEntry('Pajero Sport', CarBodyType.suv),
    CarModelEntry('L200', CarBodyType.truck),
  ]),
  CarMake(name: 'Suzuki', models: [
    CarModelEntry('Swift', CarBodyType.sedan),
    CarModelEntry('Swift Sport', CarBodyType.sedan),
    CarModelEntry('Baleno', CarBodyType.sedan),
    CarModelEntry('S-Cross', CarBodyType.suv),
    CarModelEntry('Vitara', CarBodyType.suv),
    CarModelEntry('Jimny', CarBodyType.suv),
    CarModelEntry('Grand Vitara', CarBodyType.suv),
  ]),
  CarMake(name: 'Lexus', models: [
    CarModelEntry('UX', CarBodyType.suv),
    CarModelEntry('NX', CarBodyType.suv),
    CarModelEntry('RX', CarBodyType.suv),
    CarModelEntry('GX', CarBodyType.suv),
    CarModelEntry('LX', CarBodyType.suv),
    CarModelEntry('IS', CarBodyType.sedan),
    CarModelEntry('ES', CarBodyType.sedan),
    CarModelEntry('GS', CarBodyType.sedan),
    CarModelEntry('LS', CarBodyType.sedan),
    CarModelEntry('LC', CarBodyType.coupe),
  ]),
  CarMake(name: 'Infiniti', models: [
    CarModelEntry('Q50', CarBodyType.sedan),
    CarModelEntry('Q60', CarBodyType.coupe),
    CarModelEntry('QX50', CarBodyType.suv),
    CarModelEntry('QX60', CarBodyType.suv),
    CarModelEntry('QX80', CarBodyType.suv),
  ]),
  CarMake(name: 'Nissan', models: [
    CarModelEntry('March', CarBodyType.sedan),
    CarModelEntry('Note', CarBodyType.sedan),
    CarModelEntry('Versa', CarBodyType.sedan),
    CarModelEntry('Sentra', CarBodyType.sedan),
    CarModelEntry('Altima', CarBodyType.sedan),
    CarModelEntry('Maxima', CarBodyType.sedan),
    CarModelEntry('Kicks', CarBodyType.suv),
    CarModelEntry('Juke', CarBodyType.suv),
    CarModelEntry('Qashqai', CarBodyType.suv),
    CarModelEntry('Murano', CarBodyType.suv),
    CarModelEntry('X-Trail', CarBodyType.suv),
    CarModelEntry('Pathfinder', CarBodyType.suv),
    CarModelEntry('Terra', CarBodyType.suv),
    CarModelEntry('Armada', CarBodyType.suv),
    CarModelEntry('Frontier', CarBodyType.truck),
    CarModelEntry('Navara', CarBodyType.truck),
    CarModelEntry('GT-R', CarBodyType.coupe),
    CarModelEntry('Z', CarBodyType.coupe),
  ]),

  // ── Korean ──────────────────────────────────────────────────────────────────
  CarMake(name: 'Hyundai', models: [
    CarModelEntry('Grand i10', CarBodyType.sedan),
    CarModelEntry('i10', CarBodyType.sedan),
    CarModelEntry('i20', CarBodyType.sedan),
    CarModelEntry('i30', CarBodyType.sedan),
    CarModelEntry('i30 N', CarBodyType.sedan),
    CarModelEntry('Accent', CarBodyType.sedan),
    CarModelEntry('Elantra', CarBodyType.sedan),
    CarModelEntry('Sonata', CarBodyType.sedan),
    CarModelEntry('Venue', CarBodyType.suv),
    CarModelEntry('Creta', CarBodyType.suv),
    CarModelEntry('Kona', CarBodyType.suv),
    CarModelEntry('Tucson', CarBodyType.suv),
    CarModelEntry('Santa Fe', CarBodyType.suv),
    CarModelEntry('Palisade', CarBodyType.suv),
    CarModelEntry('Stargazer', CarBodyType.suv),
    CarModelEntry('Ioniq 5', CarBodyType.suv),
    CarModelEntry('Ioniq 6', CarBodyType.sedan),
  ]),
  CarMake(name: 'Kia', models: [
    CarModelEntry('Picanto', CarBodyType.sedan),
    CarModelEntry('Rio', CarBodyType.sedan),
    CarModelEntry('Cerato', CarBodyType.sedan),
    CarModelEntry('K5', CarBodyType.sedan),
    CarModelEntry('Stinger', CarBodyType.sedan),
    CarModelEntry('Sonet', CarBodyType.suv),
    CarModelEntry('Seltos', CarBodyType.suv),
    CarModelEntry('Stonic', CarBodyType.suv),
    CarModelEntry('Niro', CarBodyType.suv),
    CarModelEntry('Sportage', CarBodyType.suv),
    CarModelEntry('Sorento', CarBodyType.suv),
    CarModelEntry('Telluride', CarBodyType.suv),
    CarModelEntry('Carnival', CarBodyType.suv),
    CarModelEntry('EV6', CarBodyType.suv),
  ]),

  // ── American ─────────────────────────────────────────────────────────────────
  CarMake(name: 'Ford', models: [
    CarModelEntry('Puma', CarBodyType.suv),
    CarModelEntry('Fiesta', CarBodyType.sedan),
    CarModelEntry('Focus', CarBodyType.sedan),
    CarModelEntry('Focus ST', CarBodyType.sedan),
    CarModelEntry('Focus RS', CarBodyType.sedan),
    CarModelEntry('Mustang', CarBodyType.coupe),
    CarModelEntry('Mustang Mach-E', CarBodyType.suv),
    CarModelEntry('Kuga', CarBodyType.suv),
    CarModelEntry('Explorer', CarBodyType.suv),
    CarModelEntry('Bronco', CarBodyType.suv),
    CarModelEntry('Edge', CarBodyType.suv),
    CarModelEntry('Expedition', CarBodyType.suv),
    CarModelEntry('F-150', CarBodyType.truck),
    CarModelEntry('Ranger', CarBodyType.truck),
    CarModelEntry('Maverick', CarBodyType.truck),
    CarModelEntry('S-Max', CarBodyType.suv),
  ]),
  CarMake(name: 'Chevrolet', models: [
    CarModelEntry('Spark', CarBodyType.sedan),
    CarModelEntry('Cruze', CarBodyType.sedan),
    CarModelEntry('Malibu', CarBodyType.sedan),
    CarModelEntry('Camaro', CarBodyType.coupe),
    CarModelEntry('Corvette', CarBodyType.coupe),
    CarModelEntry('Trax', CarBodyType.suv),
    CarModelEntry('Trailblazer', CarBodyType.suv),
    CarModelEntry('Blazer', CarBodyType.suv),
    CarModelEntry('Equinox', CarBodyType.suv),
    CarModelEntry('Traverse', CarBodyType.suv),
    CarModelEntry('Tahoe', CarBodyType.suv),
    CarModelEntry('Suburban', CarBodyType.suv),
    CarModelEntry('Colorado', CarBodyType.truck),
    CarModelEntry('Silverado', CarBodyType.truck),
  ]),
  CarMake(name: 'Dodge', models: [
    CarModelEntry('Challenger', CarBodyType.coupe),
    CarModelEntry('Charger', CarBodyType.sedan),
    CarModelEntry('Durango', CarBodyType.suv),
  ]),
  CarMake(name: 'Jeep', models: [
    CarModelEntry('Renegade', CarBodyType.suv),
    CarModelEntry('Compass', CarBodyType.suv),
    CarModelEntry('Cherokee', CarBodyType.suv),
    CarModelEntry('Grand Cherokee', CarBodyType.suv),
    CarModelEntry('Wrangler', CarBodyType.suv),
    CarModelEntry('Gladiator', CarBodyType.truck),
  ]),
  CarMake(name: 'Tesla', models: [
    CarModelEntry('Model 3', CarBodyType.sedan),
    CarModelEntry('Model S', CarBodyType.sedan),
    CarModelEntry('Model X', CarBodyType.suv),
    CarModelEntry('Model Y', CarBodyType.suv),
    CarModelEntry('Cybertruck', CarBodyType.truck),
  ]),

  // ── French ──────────────────────────────────────────────────────────────────
  CarMake(name: 'Renault', models: [
    CarModelEntry('Twingo', CarBodyType.sedan),
    CarModelEntry('Clio', CarBodyType.sedan),
    CarModelEntry('Sandero', CarBodyType.sedan),
    CarModelEntry('Logan', CarBodyType.sedan),
    CarModelEntry('Megane', CarBodyType.sedan),
    CarModelEntry('Megane E-Tech', CarBodyType.suv),
    CarModelEntry('Captur', CarBodyType.suv),
    CarModelEntry('Duster', CarBodyType.suv),
    CarModelEntry('Arkana', CarBodyType.suv),
    CarModelEntry('Kadjar', CarBodyType.suv),
    CarModelEntry('Koleos', CarBodyType.suv),
  ]),
  CarMake(name: 'Peugeot', models: [
    CarModelEntry('108', CarBodyType.sedan),
    CarModelEntry('208', CarBodyType.sedan),
    CarModelEntry('308', CarBodyType.sedan),
    CarModelEntry('408', CarBodyType.sedan),
    CarModelEntry('508', CarBodyType.sedan),
    CarModelEntry('2008', CarBodyType.suv),
    CarModelEntry('3008', CarBodyType.suv),
    CarModelEntry('5008', CarBodyType.suv),
    CarModelEntry('Rifter', CarBodyType.suv),
  ]),
  CarMake(name: 'Citroën', models: [
    CarModelEntry('C1', CarBodyType.sedan),
    CarModelEntry('C3', CarBodyType.sedan),
    CarModelEntry('C3 Aircross', CarBodyType.suv),
    CarModelEntry('C4', CarBodyType.sedan),
    CarModelEntry('C5 X', CarBodyType.sedan),
    CarModelEntry('C5 Aircross', CarBodyType.suv),
    CarModelEntry('Berlingo', CarBodyType.suv),
  ]),

  // ── Italian ─────────────────────────────────────────────────────────────────
  CarMake(name: 'Fiat', models: [
    CarModelEntry('500', CarBodyType.sedan),
    CarModelEntry('500X', CarBodyType.suv),
    CarModelEntry('Panda', CarBodyType.sedan),
    CarModelEntry('Tipo', CarBodyType.sedan),
  ]),
  CarMake(name: 'Alfa Romeo', models: [
    CarModelEntry('Giulia', CarBodyType.sedan),
    CarModelEntry('Giulia Quadrifoglio', CarBodyType.sedan),
    CarModelEntry('Stelvio', CarBodyType.suv),
    CarModelEntry('Stelvio Quadrifoglio', CarBodyType.suv),
    CarModelEntry('Tonale', CarBodyType.suv),
  ]),

  // ── Chinese (creciente en Latinoamérica) ───────────────────────────────────
  CarMake(name: 'Haval', models: [
    CarModelEntry('H1', CarBodyType.suv),
    CarModelEntry('H2', CarBodyType.suv),
    CarModelEntry('H6', CarBodyType.suv),
    CarModelEntry('Jolion', CarBodyType.suv),
    CarModelEntry('Dargo', CarBodyType.suv),
    CarModelEntry('H9', CarBodyType.suv),
  ]),
  CarMake(name: 'Chery', models: [
    CarModelEntry('QQ', CarBodyType.sedan),
    CarModelEntry('Arrizo 5', CarBodyType.sedan),
    CarModelEntry('Arrizo 6', CarBodyType.sedan),
    CarModelEntry('Tiggo 2', CarBodyType.suv),
    CarModelEntry('Tiggo 4', CarBodyType.suv),
    CarModelEntry('Tiggo 5x', CarBodyType.suv),
    CarModelEntry('Tiggo 7', CarBodyType.suv),
    CarModelEntry('Tiggo 8', CarBodyType.suv),
  ]),
  CarMake(name: 'JAC', models: [
    CarModelEntry('J2', CarBodyType.sedan),
    CarModelEntry('J4', CarBodyType.sedan),
    CarModelEntry('J7', CarBodyType.sedan),
    CarModelEntry('S2', CarBodyType.suv),
    CarModelEntry('S3', CarBodyType.suv),
    CarModelEntry('S4', CarBodyType.suv),
    CarModelEntry('T6', CarBodyType.truck),
    CarModelEntry('T8', CarBodyType.truck),
  ]),
  CarMake(name: 'MG', models: [
    CarModelEntry('MG3', CarBodyType.sedan),
    CarModelEntry('MG5', CarBodyType.sedan),
    CarModelEntry('MG6', CarBodyType.sedan),
    CarModelEntry('ZS', CarBodyType.suv),
    CarModelEntry('ZS EV', CarBodyType.suv),
    CarModelEntry('HS', CarBodyType.suv),
    CarModelEntry('RX5', CarBodyType.suv),
    CarModelEntry('Marvel R', CarBodyType.suv),
  ]),

  // ── Premium coreano ───────────────────────────────────────────────────────────
  CarMake(name: 'Genesis', models: [
    CarModelEntry('G70', CarBodyType.sedan),
    CarModelEntry('G80', CarBodyType.sedan),
    CarModelEntry('G90', CarBodyType.sedan),
    CarModelEntry('GV70', CarBodyType.suv),
    CarModelEntry('GV80', CarBodyType.suv),
    CarModelEntry('GV60', CarBodyType.suv),
  ]),

  // ── Czech/Spanish ────────────────────────────────────────────────────────────
  CarMake(name: 'Skoda', models: [
    CarModelEntry('Fabia', CarBodyType.sedan),
    CarModelEntry('Octavia', CarBodyType.sedan),
    CarModelEntry('Octavia RS', CarBodyType.sedan),
    CarModelEntry('Superb', CarBodyType.sedan),
    CarModelEntry('Karoq', CarBodyType.suv),
    CarModelEntry('Kodiaq', CarBodyType.suv),
    CarModelEntry('Enyaq', CarBodyType.suv),
  ]),
  CarMake(name: 'SEAT', models: [
    CarModelEntry('Ibiza', CarBodyType.sedan),
    CarModelEntry('Leon', CarBodyType.sedan),
    CarModelEntry('Leon ST', CarBodyType.sedan),
    CarModelEntry('Arona', CarBodyType.suv),
    CarModelEntry('Ateca', CarBodyType.suv),
    CarModelEntry('Tarraco', CarBodyType.suv),
  ]),

  // ── Swedish/British ──────────────────────────────────────────────────────────
  CarMake(name: 'Volvo', models: [
    CarModelEntry('XC40', CarBodyType.suv),
    CarModelEntry('XC60', CarBodyType.suv),
    CarModelEntry('XC90', CarBodyType.suv),
    CarModelEntry('S60', CarBodyType.sedan),
    CarModelEntry('V60', CarBodyType.sedan),
    CarModelEntry('V90', CarBodyType.sedan),
    CarModelEntry('C40', CarBodyType.suv),
  ]),
  CarMake(name: 'Land Rover', models: [
    CarModelEntry('Defender 90', CarBodyType.suv),
    CarModelEntry('Defender 110', CarBodyType.suv),
    CarModelEntry('Discovery', CarBodyType.suv),
    CarModelEntry('Discovery Sport', CarBodyType.suv),
    CarModelEntry('Range Rover', CarBodyType.suv),
    CarModelEntry('Range Rover Sport', CarBodyType.suv),
    CarModelEntry('Range Rover Evoque', CarBodyType.suv),
    CarModelEntry('Range Rover Velar', CarBodyType.suv),
  ]),
  CarMake(name: 'Jaguar', models: [
    CarModelEntry('XE', CarBodyType.sedan),
    CarModelEntry('XF', CarBodyType.sedan),
    CarModelEntry('XJ', CarBodyType.sedan),
    CarModelEntry('F-Type', CarBodyType.coupe),
    CarModelEntry('E-Pace', CarBodyType.suv),
    CarModelEntry('F-Pace', CarBodyType.suv),
    CarModelEntry('I-Pace', CarBodyType.suv),
  ]),
];
