import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Centre d'alertes", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.settings_outlined, color: AppTheme.darkText))
        ],
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Système intelligent post-récolte", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                      ),
                      child: const Center(child: Text("Tout", style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Expanded(
                    child: Center(child: Text("Non lus", style: TextStyle(color: Colors.grey[600]))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(context, "AUJOURD'HUI"),
            _buildAlertItem(
              context, 
              "Température Critique", 
              "L'entrepôt #1 a dépassé le seuil de 25°C. Risque de dégradation des bananes.", 
              "14:20", 
              "Zone de stockage Nord", 
              AppTheme.errorRed, 
              AppTheme.errorBg, 
              Icons.thermostat_rounded
            ),
            const SizedBox(height: 12),
            _buildAlertItem(
              context, 
              "Pic d'humidité", 
              "Humidité détectée à 78% dans l'entrepôt #2. Vérifiez la ventilation.", 
              "10:05", 
              "Capteur H2-A4", 
              AppTheme.warningOrange, 
              AppTheme.warningBg, 
              Icons.water_drop_rounded
            ),
             const SizedBox(height: 24),
            _buildSection(context, "HIER"),
            _buildAlertItem(
              context, 
              "Batterie faible", 
              "Le capteur de l'entrepôt #3 nécessite un changement de pile immédiat.", 
              "Hier, 18:30", 
              "Entrepôt #3", 
              Colors.grey, 
              Colors.grey.shade100, 
              Icons.battery_alert_rounded
            ),
             const SizedBox(height: 12),
            _buildAlertItem(
              context, 
              "Déviation température", 
              "Fluctuation légère détectée. Système de refroidissement auto-ajusté.", 
              "Hier, 09:12", 
              "Zone de tri", 
              Colors.amber[700]!, 
              Colors.amber.shade50, 
              Icons.warning_amber_rounded
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
      ),
    );
  }

  Widget _buildAlertItem(
    BuildContext context, 
    String title, 
    String desc, 
    String time, 
    String location, 
    Color color, 
    Color bgColor, 
    IconData icon
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                 desc,
                 style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(location, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
