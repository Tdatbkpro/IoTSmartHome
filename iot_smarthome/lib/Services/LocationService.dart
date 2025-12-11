import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show pow, sqrt;

class LocationService {
  Stream<Position?> getCurrentLocationStream() async* {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          yield null;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        yield null;
        return;
      }

      // Lấy vị trí ban đầu
      Position? lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
         
        ),
      );

      yield lastPosition;

      // Lắng nghe stream vị trí và lọc theo khoảng cách
      await for (final position in Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1, // nhận tất cả, mình tự lọc bên dưới
        ),
      )) {
        if (lastPosition == null) {
          lastPosition = position;
          yield position;
          continue;
        }

        final distance = Geolocator.distanceBetween(
          lastPosition.latitude,
          lastPosition.longitude,
          position.latitude,
          position.longitude,
        );

        // ✅ chỉ yield nếu di chuyển > 50m
        if (distance >= 50) {
          lastPosition = position;
          yield position;
        }
      }
    } catch (e) {
      print('Lỗi location stream: $e');
      yield null;
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return _formatVietnameseAddress(placemarks.first);
      }
    } catch (e) {
      print('Lỗi geocoding: $e');
    }
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  String _formatVietnameseAddress(Placemark placemark) {
    final components = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
    ].where((component) => component != null && component.isNotEmpty).toList();
    
    return components.join(', ');
  }
}
