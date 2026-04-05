import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:agro_ia/services/stock_service.dart';
import 'package:agro_ia/services/prediction_service.dart';
import 'package:agro_ia/models/stock_item.dart';
import 'package:agro_ia/screens/dashboard/stock_detail_screen.dart';


import '../../models/weather_data.dart';
import '../../services/sensor_history_service.dart';
import '../../services/weather_service.dart';

import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/sensor_data.dart';
import 'all_stocks_screen.dart';
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
  final StockService _stockService = StockService();
  final PredictionService _predictionService = PredictionService();
  WeatherData? _weatherData;
  bool _weatherLoading = true;

  List<StockItem> _stocks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Chargement des stocks...'); // Debug
      final stocks = await _stockService.getAllStocks();
      print('Nombre de stocks chargés: ${stocks.length}'); // Debug

      if (stocks.isNotEmpty) {
        print('Premier stock: ${stocks.first.productName}'); // Debug
        print('Quantité: ${stocks.first.quantity}'); // Debug
        print('Localisation: ${stocks.first.location}'); // Debug
      }

      setState(() {
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur détaillée: $e'); // Debug
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Future<void> _loadWeather() async {
    final data = await _weatherService.fetchWeather();
    setState(() {
      _weatherData = data;
      _weatherLoading = false;
    });
  }

  // Naviguer vers la page de tous les stocks
  void _navigateToAllStocks() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllStocksScreen()),
    );
    if (result == true) {
      _refresh();
    }
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
          //floatingActionButton
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManualEntryScreen(),
                ),
              );
              if (result == true) {
                _refresh();
              }
            },
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(context, sensor),
                  const SizedBox(height: 60),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "Statut des stocks",
                          "Voir tout",
                          onActionTap: _navigateToAllStocks,
                        ),
                        const SizedBox(height: 16),

                        // Afficher les stocks dynamiques
                        _buildStockList(),

                        const SizedBox(height: 24),
                        _buildSectionHeader(context, "Alertes", ""),
                        const SizedBox(height: 16),
                        _buildAlertCard(context),

                        const SizedBox(height: 24),
                        _buildSectionHeader(
                            context, "Prévision météorologique", ""),
                        const SizedBox(height: 16),
                        _buildWeatherCard(context),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
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
      BuildContext context, String title, String action, {VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action.isNotEmpty)
        GestureDetector(
        onTap: onActionTap,
        child:Text(
            action,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }


// Liste dynamique des stocks
Widget _buildStockList() {
  if (_isLoading) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (_error != null) {
    return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Erreur: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  if (_stocks.isEmpty) {
    return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
            children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 12),
              Text(
                'Aucun produit en stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Ajoutez votre premier produit avec le bouton +',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
        ),
    );
  }

  // Afficher les 3 premiers stocks seulement
  final displayStocks = _stocks.take(3).toList();

  return Column(
      children: [
      ...displayStocks.map((stock) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _buildDynamicStockCard(stock),
  )),
  if (_stocks.length > 3)
  Padding(
  padding: const EdgeInsets.only(top: 8),
  child: TextButton(
  onPressed: _navigateToAllStocks,
  child: Text(
  'Et ${_stocks.length - 3} autre(s) produit(s)...',
  style: const TextStyle(color: AppTheme.primaryGreen),
  ),
  ),
  ),
      ],
  );
}





// Carte de stock dynamique avec données réelles
Widget _buildDynamicStockCard(StockItem stock) {
  // Déterminer la couleur et l'icône selon le statut
  Color statusColor;
  IconData statusIcon;
  String statusLabel;

  switch (stock.stockStatus) {
    case 'expired':
      statusColor = Colors.red;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Périmé';
      break;
    case 'critical':
      statusColor = Colors.orange;
      statusIcon = Icons.priority_high;
      statusLabel = 'Urgent';
      break;
    case 'warning':
      statusColor = Colors.yellow.shade700;
      statusIcon = Icons.info_outline;
      statusLabel = 'À surveiller';
      break;
    default:
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusLabel = 'Bon état';
  }

  return GestureDetector(
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockDetailScreen(stock: stock),
        ),
      );
      if (result == true) {
        _refresh();
      }
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône avec statut
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Informations du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                      stock.location,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      'Récolté il y a ${stock.daysSinceHarvest}j',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantité et statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stock.quantity.toStringAsFixed(0)} ${stock.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildAlertCard(BuildContext context) {
  // Analyser les stocks pour générer des alertes dynamiques
  final criticalStocks = _stocks.where((s) => s.stockStatus == 'critical' || s.stockStatus == 'expired').toList();

  if (criticalStocks.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Aucune alerte critique. Tous les stocks sont en bonne état.",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  // Afficher la première alerte critique
  final firstCritical = criticalStocks.first;
  String alertMessage;

  if (firstCritical.stockStatus == 'expired') {
    alertMessage = "${firstCritical.productName} est périmé. Veuillez l'éliminer immédiatement.";
  } else {
    alertMessage = "${firstCritical.productName} arrive à expiration dans moins de 3 jours. Priorisez son écoulement.";
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.errorBg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppTheme.errorRed, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            alertMessage,
            style: const TextStyle(color: AppTheme.errorRed),
          ),
        ),
        if (criticalStocks.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${criticalStocks.length - 1}',
              style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
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

