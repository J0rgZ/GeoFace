import 'dart:math';

class LocationHelper {
  // Calcular distancia entre dos coordenadas en metros
  static double calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371000; // Radio de la Tierra en metros
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance;
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }
}