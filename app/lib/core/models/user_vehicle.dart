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

  const UserVehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.bodyType,
    this.nickname,
  });

  String get displayName => nickname ?? '$make $model';

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year': year,
    'color': color.name,
    'bodyType': bodyType.name,
    'nickname': nickname,
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
  CarMake(name: 'BMW', models: [
    CarModelEntry('Serie 1', CarBodyType.sedan),
    CarModelEntry('Serie 3', CarBodyType.sedan),
    CarModelEntry('Serie 5', CarBodyType.sedan),
    CarModelEntry('M3', CarBodyType.coupe),
    CarModelEntry('M5', CarBodyType.sedan),
    CarModelEntry('X3', CarBodyType.suv),
    CarModelEntry('X5', CarBodyType.suv),
  ]),
  CarMake(name: 'Mercedes', models: [
    CarModelEntry('Clase A', CarBodyType.sedan),
    CarModelEntry('Clase C', CarBodyType.sedan),
    CarModelEntry('Clase E', CarBodyType.sedan),
    CarModelEntry('GLA', CarBodyType.suv),
    CarModelEntry('GLC', CarBodyType.suv),
    CarModelEntry('AMG GT', CarBodyType.coupe),
  ]),
  CarMake(name: 'Audi', models: [
    CarModelEntry('A3', CarBodyType.sedan),
    CarModelEntry('A4', CarBodyType.sedan),
    CarModelEntry('A6', CarBodyType.sedan),
    CarModelEntry('RS6', CarBodyType.sedan),
    CarModelEntry('Q3', CarBodyType.suv),
    CarModelEntry('Q5', CarBodyType.suv),
    CarModelEntry('Q7', CarBodyType.suv),
  ]),
  CarMake(name: 'Toyota', models: [
    CarModelEntry('Corolla', CarBodyType.sedan),
    CarModelEntry('Camry', CarBodyType.sedan),
    CarModelEntry('GR86', CarBodyType.coupe),
    CarModelEntry('RAV4', CarBodyType.suv),
    CarModelEntry('Hilux', CarBodyType.truck),
    CarModelEntry('Yaris', CarBodyType.sedan),
  ]),
  CarMake(name: 'Honda', models: [
    CarModelEntry('Civic', CarBodyType.sedan),
    CarModelEntry('Accord', CarBodyType.sedan),
    CarModelEntry('City', CarBodyType.sedan),
    CarModelEntry('HR-V', CarBodyType.suv),
    CarModelEntry('CR-V', CarBodyType.suv),
  ]),
  CarMake(name: 'Mazda', models: [
    CarModelEntry('Mazda 2', CarBodyType.sedan),
    CarModelEntry('Mazda 3', CarBodyType.sedan),
    CarModelEntry('Mazda 6', CarBodyType.sedan),
    CarModelEntry('CX-3', CarBodyType.suv),
    CarModelEntry('CX-5', CarBodyType.suv),
    CarModelEntry('MX-5', CarBodyType.coupe),
  ]),
  CarMake(name: 'Volkswagen', models: [
    CarModelEntry('Polo', CarBodyType.sedan),
    CarModelEntry('Golf', CarBodyType.sedan),
    CarModelEntry('Passat', CarBodyType.sedan),
    CarModelEntry('Tiguan', CarBodyType.suv),
    CarModelEntry('Touareg', CarBodyType.suv),
  ]),
  CarMake(name: 'Ford', models: [
    CarModelEntry('Fiesta', CarBodyType.sedan),
    CarModelEntry('Focus', CarBodyType.sedan),
    CarModelEntry('Mustang', CarBodyType.coupe),
    CarModelEntry('Explorer', CarBodyType.suv),
    CarModelEntry('F-150', CarBodyType.truck),
  ]),
  CarMake(name: 'Chevrolet', models: [
    CarModelEntry('Spark', CarBodyType.sedan),
    CarModelEntry('Cruze', CarBodyType.sedan),
    CarModelEntry('Camaro', CarBodyType.coupe),
    CarModelEntry('Silverado', CarBodyType.truck),
    CarModelEntry('Equinox', CarBodyType.suv),
  ]),
  CarMake(name: 'Hyundai', models: [
    CarModelEntry('i20', CarBodyType.sedan),
    CarModelEntry('i30', CarBodyType.sedan),
    CarModelEntry('Elantra', CarBodyType.sedan),
    CarModelEntry('Tucson', CarBodyType.suv),
    CarModelEntry('Santa Fe', CarBodyType.suv),
  ]),
];
