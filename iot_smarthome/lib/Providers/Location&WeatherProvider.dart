// providers.dart - Thêm các providers mới
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:iot_smarthome/Services/LocationService.dart';
import 'dart:convert';

import 'package:iot_smarthome/Services/WeatherService.dart';

// Provider cho location service
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Provider cho weather service
final weatherServiceProvider = Provider<WeatherService>((ref) => WeatherService());

// Stream provider cho current location
final currentLocationProvider = StreamProvider<Position?>((ref) async* {
  final locationService = ref.read(locationServiceProvider);
  yield* locationService.getCurrentLocationStream();
});

// Stream provider cho current address
final currentAddressProvider = StreamProvider<String>((ref) async* {
  final location = ref.watch(currentLocationProvider);
  final locationService = ref.read(locationServiceProvider);
  
  if (location.hasValue && location.value != null) {
    final address = await locationService.getAddressFromLatLng(
      location.value!.latitude, 
      location.value!.longitude
    );
    yield address;
  } else {
    yield "Đang lấy vị trí...";
  }
});

// Stream provider cho weather data
final weatherDataProvider = StreamProvider<WeatherData>((ref) async* {
  final location = ref.watch(currentLocationProvider);
  final weatherService = ref.read(weatherServiceProvider);
  
  if (location.hasValue && location.value != null) {
    final weather = await weatherService.getWeatherData(
      location.value!.latitude,
      location.value!.longitude,
    );
    yield weather;
  } else {
    yield WeatherData(
      temperature: 0,
      humidity: 0,
      description: "Đang tải...",
      condition: "unknown",
    );
  }
});