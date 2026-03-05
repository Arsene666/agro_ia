import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../models/weather_data.dart';
import '../../services/sensor_history_service.dart';
import '../../services/weather_service.dart';

import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/sensor_data.dart';
import 'manual_entry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

final SensorHistoryService _sensorHistoryService = SensorHistoryService();

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await _weatherService.fetchWeather();
    setState(() {
      _weatherData = data;
      _weatherLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorData?>(
      stream: _firebaseService.getSensorStream(),
      builder: (context, snapshot) {
        // Chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Erreur ou pas de données
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("Aucune donnée capteur disponible")),
          );
        }

        final sensor = snapshot.data!;

        _sensorHistoryService.maybeSaveSensorData(
          temperature: sensor.temperature,
          humidity: sensor.humidity,
        );

        return Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          // FIX: Move floatingActionButton here, outside the body
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManualEntryScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, sensor),
                const SizedBox(height: 60),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, "Statut des stocks", "Voir tout"),
                      const SizedBox(height: 16),

                      _buildStockItem(
                        context,
                        "Tomates",
                        "200 kg",
                        "Récolté il y a 2j",
                        Colors.redAccent.withValues(alpha: 0.1),
                        Colors.redAccent,
                      ),

                      // The button was removed from here to fix the syntax error

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Alertes", ""),
                      const SizedBox(height: 16),
                      _buildAlertCard(context),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Prévision météorologique", ""),
                      const SizedBox(height: 16),
                      _buildWeatherCard(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context, SensorData sensor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1625246333195-551e512451f8?q=80&w=1000',
              ),
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.arrow_2_circlepath,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AGRO-IA",
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        "SYSTÈME INTELLIGENT POST-RÉCOLTE",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Cards flottantes
        Positioned(
          bottom: -40,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  "TEMPÉRATURE",
                  "${sensor.temperature.toStringAsFixed(1)}°C",
                  Icons.thermostat,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  context,
                  "HUMIDITÉ",
                  "${sensor.humidity.toStringAsFixed(0)}%",
                  CupertinoIcons.drop_fill,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= CONTENU =================

  Widget _buildSectionHeader(
      BuildContext context, String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildStockItem(
    BuildContext context,
    String name,
    String weight,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined,
                color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Text(weight,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      // ignore: prefer_const_constructors
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded,
              color: AppTheme.errorRed, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Température élevée détectée dans l'entrepôt principal.",
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
  String _weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '🌤️';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    return '⛈️';
  }
  String _weatherLabel(int code) {
    if (code == 0) return 'Ensoleillé';
    if (code <= 3) return 'Partiellement nuageux';
    if (code <= 48) return 'Brumeux';
    if (code <= 67) return 'Pluvieux';
    if (code <= 77) return 'Neigeux';
    if (code <= 82) return 'Averses';
    return 'Orageux';
  }
  Widget _buildWeatherCard(BuildContext context) {
    if (_weatherLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weatherData == null) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text("Météo indisponible")),
      );
    }
    final w = _weatherData!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${w.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _weatherLabel(w.weatherCode),
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.air, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${w.windspeed.toStringAsFixed(0)} km/h',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Text(_weatherIcon(w.weatherCode),
                  style: const TextStyle(fontSize: 60)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: w.hourly.map((h) {
              return Column(
                children: [
                  Text(_weatherIcon(h.code),
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('${h.temp.toStringAsFixed(0)}°',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(h.hour,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }




}
