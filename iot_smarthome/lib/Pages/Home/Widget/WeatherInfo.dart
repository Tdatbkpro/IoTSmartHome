import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Services/WeatherService.dart';
import 'package:iot_smarthome/Providers/Location&WeatherProvider.dart';

class WeatherInfoHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = 1.0 - (shrinkOffset / maxExtent).clamp(0.0, 1.0);

    return Container(
      color: const Color.fromARGB(255, 41, 129, 228).withOpacity(opacity.clamp(0.7, 1.0)),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Consumer(
          builder: (context, ref, _) {
            final addressAsync = ref.watch(currentAddressProvider);
            final weatherAsync = ref.watch(weatherDataProvider);

            return _buildCompactLocationWeatherInfo(addressAsync, weatherAsync, ref);
          },
        ),
      ),
    );
  }

  Widget _buildCompactLocationWeatherInfo(
    AsyncValue<String> addressAsync,
    AsyncValue<WeatherData> weatherAsync,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        // 📍 Location
        const Icon(Icons.location_on, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: addressAsync.when(
            loading: () => _buildText("Đang lấy vị trí...", color: Colors.white70),
            error: (error, stack) => _buildText("Không thể lấy vị trí", color: Colors.white70),
            data: (address) => _buildText(
              address,
              color: Colors.white,
              weight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 🌦 Weather
        weatherAsync.when(
          loading: () => _buildCompactWeatherItem("☀️ --°C",  "--%"),
          error: (error, stack) => _buildCompactWeatherItem("--°C", "--%"),
          data: (weather) {
            final weatherService = ref.read(weatherServiceProvider);
            final icon = weatherService.getWeatherIcon(weather.condition);
            return _buildCompactWeatherItem(
              "$icon ${weather.temperature.toStringAsFixed(0)}°C",
              "${weather.humidity}%",
            );
          },
        ),

        const SizedBox(width: 16),

        // ⏰ Time
        _buildCompactTimeInfo(),
      ],
    );
  }

  Widget _buildCompactWeatherItem(String temp, String humidity) {
    return Row(
      children: [
        _buildText(temp, size: 16, weight: FontWeight.bold),
        const SizedBox(width: 8),
        Icon(Icons.water_drop, size: 14, color: Colors.lightBlue.shade200),
        const SizedBox(width: 2),
        _buildText(humidity, size: 14, color: Colors.white),
      ],
    );
  }

  Widget _buildCompactTimeInfo() {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        return Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              DateFormat('HH:mm').format(now),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildText(String text,
      {double size = 14, Color color = Colors.white, FontWeight? weight}) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(fontSize: size, color: color, fontWeight: weight),
    );
  }

  // Chiều cao an toàn
  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 48; // Cho phép ẩn khi bị overlap

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
