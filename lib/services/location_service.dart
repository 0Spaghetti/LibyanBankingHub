import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<LatLng?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showLocationDialog(
          context,
          "خدمات الموقع معطلة",
          "يرجى تفعيل خدمات الموقع (GPS) لتتمكن من رؤية موقعك على الخريطة.",
          onOpenSettings: () => Geolocator.openLocationSettings(),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم رفض إذن الوصول للموقع")),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showLocationDialog(
          context,
          "إذن الموقع مرفوض دائماً",
          "لقد قمت برفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق.",
          onOpenSettings: () => Geolocator.openAppSettings(),
        );
      }
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر جلب الموقع الحالي")),
        );
      }
      return null;
    }
  }

  static void _showLocationDialog(
    BuildContext context,
    String title,
    String content, {
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(content, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              onOpenSettings();
              Navigator.pop(ctx);
            },
            child: const Text("الإعدادات"),
          ),
        ],
      ),
    );
  }
}
