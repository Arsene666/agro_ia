import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/sensor_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();

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

        return Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
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

                      const SizedBox(height: 12),

                      _buildStockItem(
                        context,
                        "Bananes",
                        "150 kg",
                        "Récolté il y a 4j",
                        Colors.amber.withValues(alpha: 0.1),
                        Colors.amber,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Alertes", ""),
                      const SizedBox(height: 16),
                      _buildAlertCard(context),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "Emplacement", ""),
                      const SizedBox(height: 16),
                      _buildLocationPlaceholder(context),

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

  Widget _buildLocationPlaceholder(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
              "https://images.unsplash.com/photo-1553413077-190dd305871c?q=80&w=1000"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
