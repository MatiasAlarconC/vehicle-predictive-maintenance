/// Helpers para construir URLs de imagin.studio con los slugs correctos.
class CarImageService {
  CarImageService._();

  static const String _baseUrl = 'https://cdn.imagin.studio/getimage';
  static const String _customer = 'img';

  /// Devuelve la URL de la imagen del auto para el CDN imagin.studio.
  static String buildUrl({
    required String make,
    required String model,
    required int year,
  }) {
    final makeSlug = _makeSlug(make);
    final modelSlug = _modelSlug(make, model);
    return '$_baseUrl'
        '?customer=$_customer'
        '&make=$makeSlug'
        '&modelFamily=$modelSlug'
        '&modelYear=$year'
        '&angle=29'
        '&zoomType=fullscreen';
  }

  // ── Slugs de marcas ──────────────────────────────────────────────────────

  static const Map<String, String> _makeOverrides = {
    'Mercedes': 'mercedes-benz',
    'Land Rover': 'land-rover',
    'Range Rover': 'range-rover',
    'Alfa Romeo': 'alfa-romeo',
    'Aston Martin': 'aston-martin',
  };

  static String _makeSlug(String make) =>
      _makeOverrides[make] ?? make.toLowerCase().replaceAll(' ', '-');

  // ── Slugs de modelos ─────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _modelOverrides = {
    'BMW': {
      'Serie 1': '1-series',
      'Serie 2': '2-series',
      'Serie 3': '3-series',
      'Serie 4': '4-series',
      'Serie 5': '5-series',
      'Serie 7': '7-series',
      'X1': 'x1',
      'X3': 'x3',
      'X5': 'x5',
      'X6': 'x6',
    },
    'Mercedes': {
      'Clase A': 'a-class',
      'Clase B': 'b-class',
      'Clase C': 'c-class',
      'Clase E': 'e-class',
      'Clase S': 's-class',
      'GLA': 'gla',
      'GLC': 'glc',
      'GLE': 'gle',
    },
    'Audi': {
      'A3': 'a3',
      'A4': 'a4',
      'A6': 'a6',
      'Q3': 'q3',
      'Q5': 'q5',
      'Q7': 'q7',
      'TT': 'tt',
    },
    'Volkswagen': {
      'Golf': 'golf',
      'Polo': 'polo',
      'Tiguan': 'tiguan',
      'Touareg': 'touareg',
      'Passat': 'passat',
      'Jetta': 'jetta',
    },
    'Toyota': {
      'Corolla': 'corolla',
      'Camry': 'camry',
      'RAV4': 'rav4',
      'Hilux': 'hilux',
      'Yaris': 'yaris',
      'C-HR': 'c-hr',
      'Fortuner': 'fortuner',
    },
    'Honda': {
      'Civic': 'civic',
      'Accord': 'accord',
      'CR-V': 'cr-v',
      'HR-V': 'hr-v',
      'Fit': 'fit',
    },
    'Mazda': {
      'Mazda2': 'mazda2',
      'Mazda3': 'mazda3',
      'Mazda6': 'mazda6',
      'CX-3': 'cx-3',
      'CX-5': 'cx-5',
      'CX-9': 'cx-9',
    },
    'Ford': {
      'Fiesta': 'fiesta',
      'Focus': 'focus',
      'Escape': 'escape',
      'Explorer': 'explorer',
      'F-150': 'f-150',
      'Ranger': 'ranger',
      'Mustang': 'mustang',
    },
    'Chevrolet': {
      'Cruze': 'cruze',
      'Spark': 'spark',
      'Trax': 'trax',
      'Equinox': 'equinox',
      'Traverse': 'traverse',
      'Silverado': 'silverado',
    },
    'Hyundai': {
      'i10': 'i10',
      'i20': 'i20',
      'i30': 'i30',
      'Elantra': 'elantra',
      'Tucson': 'tucson',
      'Santa Fe': 'santa-fe',
      'Kona': 'kona',
    },
    'Kia': {
      'Rio': 'rio',
      'Cerato': 'cerato',
      'Sportage': 'sportage',
      'Sorento': 'sorento',
      'Stinger': 'stinger',
      'Seltos': 'seltos',
    },
    'Nissan': {
      'Versa': 'versa',
      'Sentra': 'sentra',
      'Altima': 'altima',
      'Frontier': 'frontier',
      'Qashqai': 'qashqai',
      'Murano': 'murano',
      'X-Trail': 'x-trail',
    },
    'Renault': {
      'Clio': 'clio',
      'Sandero': 'sandero',
      'Logan': 'logan',
      'Duster': 'duster',
      'Captur': 'captur',
      'Megane': 'megane',
    },
    'Peugeot': {
      '208': '208',
      '308': '308',
      '408': '408',
      '508': '508',
      '3008': '3008',
      '5008': '5008',
    },
    'Jeep': {
      'Renegade': 'renegade',
      'Compass': 'compass',
      'Wrangler': 'wrangler',
      'Grand Cherokee': 'grand-cherokee',
    },
  };

  static String _modelSlug(String make, String model) {
    final override = _modelOverrides[make]?[model];
    if (override != null) return override;
    return model.toLowerCase().replaceAll(' ', '-').replaceAll('/', '-');
  }
}
