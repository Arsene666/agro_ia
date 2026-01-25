import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/sensor_data.dart';


class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Capteurs & Analyses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: () {},
          )
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterRow(context),
              const SizedBox(height: 24),
              _buildChartCard(
                context, 
                "Température Moyenne", 
                "21.5°C", 
                "-1.2°", 
                AppTheme.warningOrange, 
                const [
                  FlSpot(0, 20), FlSpot(1, 21), FlSpot(2, 23), FlSpot(3, 25), 
                  FlSpot(4, 24), FlSpot(5, 22), FlSpot(6, 21.5)
                ],
                true
              ),
              const SizedBox(height: 16),
              _buildChartCard(
                context, 
                "Humidité Moyenne", 
                "67%", 
                "+2%", 
                Colors.blue, 
                const [
                   FlSpot(0, 60), FlSpot(1, 62), FlSpot(2, 65), FlSpot(3, 70), 
                   FlSpot(4, 68), FlSpot(5, 66), FlSpot(6, 67)
                ],
                false
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Unités de Stockage", "TOUT VOIR"),
              const SizedBox(height: 16),
              _buildStorageUnit(context, "Entrepôt A", "92%", "EXCELLENT",  Colors.green, true),
              const SizedBox(height: 12),
              _buildStorageUnit(context, "Silo 1 - Grains", "45%", "STABLE", Colors.orange, true),
              const SizedBox(height: 12),
              _buildStorageUnit(context, "Chambre Froide 2", "12%", "FAIBLE", Colors.red, false),
               const SizedBox(height: 60), // Space for fab
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
             Icon(Icons.show_chart, color: AppTheme.primaryGreen, size: 20),
             SizedBox(width: 8),
             Text("Tendances Historiques", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: "24 Dernières Heures",
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13),
            items: ["24 Dernières Heures", "7 Derniers Jours"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (_) {},
          ),
        )
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, String title, String value, String change, Color color, List<FlSpot> spots, bool isTemp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
                  Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(width: 8),
                      Text("($change)", style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  )
                ],
              ),
              Icon(isTemp ? Icons.thermostat : Icons.water_drop, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildStorageUnit(BuildContext context, String name, String status, String statusLabel, Color statusColor, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive ? Border.all(color: Colors.transparent) : Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isActive ? Icons.warehouse_rounded : Icons.warning_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
           Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(isActive ? "ACTIF • TEMPS RÉEL" : "ALERTE", style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
                Icon(Icons.battery_std, size: 16, color: statusColor),
                Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(statusLabel, style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.bold)),
             ],
          )
        ],
      ),
    );
  }
}
