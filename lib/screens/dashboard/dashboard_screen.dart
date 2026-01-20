import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 60), // Space for floating cards
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
                    Colors.redAccent.withOpacity(0.1), 
                    Colors.redAccent
                  ),
                  const SizedBox(height: 12),
                  _buildStockItem(
                    context, 
                    "Bananes", 
                    "150 kg", 
                    "Récolté il y a 4j", 
                    Colors.amber.withOpacity(0.1), 
                    Colors.amber
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
  }

  Widget _buildHeader(BuildContext context) {
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
              image: NetworkImage('https://images.unsplash.com/photo-1625246333195-551e512451f8?q=80&w=1000&auto=format&fit=crop'), // Subtle leaf texture
              fit: BoxFit.cover,
              opacity: 0.1,
            )
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AGRO-IA",
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white, 
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "SYSTÈME INTELLIGENT POST-RÉCOLTE",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9), 
                              fontSize: 10, 
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w500
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: _buildMetricCard(context, "TEMPÉRATURE", "21.5°C", Icons.thermostat, const Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(context, "HUMIDITÉ", "67%", CupertinoIcons.drop_fill, Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "TEMPÉRATURE",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildStockItem(BuildContext context, String name, String weight, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Text(weight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.errorRed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Température élevée",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed, fontSize: 15),
                    ),
                    Text(
                      "20:41",
                      style: TextStyle(color: AppTheme.errorRed.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Détectée dans l'entrepôt 1. Risque de dégradation rapide des stocks.",
                  style: TextStyle(color: AppTheme.errorRed.withOpacity(0.8), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPlaceholder(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1553413077-190dd305871c?q=80&w=1000"), // Warehouse
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.location_on, color: AppTheme.errorRed, size: 40),
          ),
          const Positioned(
            left: 16,
            bottom: 16,
            child: Chip(
              label: Text("ENTREPÔT PRINCIPAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        ],
      ),
    );
  }
}
