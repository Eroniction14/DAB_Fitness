import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';

/// Returns the user's city, or '' if location is off, denied or unavailable.
Future<String> getCity() async {
  try {
    final location = Location();

    var serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return '';
    }

    var permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.grantedLimited) {
      return '';
    }

    final here =
        await location.getLocation().timeout(const Duration(seconds: 10));

    final places = await geo.Geocoding()
        .placemarkFromCoordinates(here.latitude, here.longitude);
    return places.isEmpty ? '' : (places.first.locality ?? '');
  } catch (e) {
    debugPrint('Could not get location: $e');
    return '';
  }
}