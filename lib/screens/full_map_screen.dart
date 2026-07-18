import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

class FullMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;

  const FullMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: position,
          initialZoom: 16.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flora_id',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: position,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  color: AppColors.danger,
                  size: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
