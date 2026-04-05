import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/alert_service.dart';
import '../../models/alert.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertService _alertService = AlertService();

  List<Alert> _alerts = [];
  bool _isLoading = true;
  bool _showOnlyUnread = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  // ============================================================
  // DONNÉES
  // ============================================================

  Future<void> _loadAlerts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final alerts = await _alertService.getAllAlerts();
      setState(() { _alerts = alerts; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _markAsRead(Alert alert) async {
    if (alert.isRead) return;
    await _alertService.markAsRead(alert.id);
    setState(() {
      final i = _alerts.indexWhere((a) => a.id == alert.id);
      if (i != -1) {
        _alerts[i] = Alert(
          id: alert.id,
          titre: alert.titre,
          description: alert.description,
          time: alert.time,
          type: alert.type,
          severity: alert.severity,
          isRead: true,
          createdAt: alert.createdAt,
          metadata: alert.metadata,
        );
      }
    });
  }

  Future<void> _markAllAsRead() async {
    await _alertService.markAllAsRead();
    await _loadAlerts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les alertes marquées comme lues')),
      );
    }
  }

  Future<void> _deleteAlert(Alert alert) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: Text('Supprimer "${alert.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _alertService.deleteAlert(alert.id);
      await _loadAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte supprimée')),
        );
      }
    }
  }

  List<Alert> get _filteredAlerts =>
      _showOnlyUnread ? _alerts.where((a) => !a.isRead).toList() : _alerts;

  Map<String, List<Alert>> get _groupedAlerts {
    final Map<String, List<Alert>> grouped = {};
    final now = DateTime.now();
    for (final alert in _filteredAlerts) {
      final diff = now.difference(alert.createdAt);
      final key = diff.inDays == 0
          ? "AUJOURD'HUI"
          : diff.inDays == 1
          ? "HIER"
          : diff.inDays <= 7
          ? "CES 7 DERNIERS JOURS"
          : "PLUS ANCIEN";
      grouped.putIfAbsent(key, () => []).add(alert);
    }
    return grouped;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Centre d'alertes",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_alerts.any((a) => !a.isRead))
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded,
                  color: AppTheme.primaryGreen),
              tooltip: 'Tout marquer comme lu',
            ),
          IconButton(
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh, color: AppTheme.darkText),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSmsSettingsDialog,
        icon: const Icon(Icons.sms_outlined),
        label: const Text('Configurer SMS'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadAlerts, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _filteredAlerts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: _loadAlerts,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: _buildGroupedAlerts(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTRE
  // ============================================================

  Widget _buildFilterBar() {
    final unreadCount = _alerts.where((a) => !a.isRead).length;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _filterTab("Tout (${_alerts.length})", !_showOnlyUnread,
                  () => setState(() => _showOnlyUnread = false)),
          _filterTab("Non lus ($unreadCount)", _showOnlyUnread,
                  () => setState(() => _showOnlyUnread = true)),
        ],
      ),
    );
  }

  Widget _filterTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4)]
                : [],
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? AppTheme.primaryGreen
                      : Colors.grey[600],
                )),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÉTAT VIDE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyUnread
                ? Icons.check_circle_outline
                : Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyUnread
                ? "Aucune alerte non lue"
                : "Aucune alerte pour le moment",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text("Les alertes apparaîtront ici automatiquement",
              style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ============================================================
  // LISTE GROUPÉE
  // ============================================================

  List<Widget> _buildGroupedAlerts() {
    final widgets = <Widget>[];
    for (final entry in _groupedAlerts.entries) {
      widgets.add(_buildSectionHeader(entry.key));
      for (final alert in entry.value) {
        widgets.add(_buildAlertItem(alert));
        widgets.add(const SizedBox(height: 12));
      }
    }
    return widgets;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1)),
    );
  }

  // ============================================================
  // CARTE ALERTE
  // ============================================================

  Widget _buildAlertItem(Alert alert) {
    return GestureDetector(
      onTap: () {
        _markAsRead(alert);
        _showAlertDetail(alert);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : alert.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isRead
                ? Colors.grey.withValues(alpha: 0.1)
                : alert.color.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: alert.bgColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(alert.icon, color: alert.color, size: 24),
            ),
            const SizedBox(width: 14),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + heure
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // ● point non-lu
                            if (!alert.isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle),
                              ),
                            Expanded(
                              child: Text(
                                alert.titre,
                                style: TextStyle(
                                  fontWeight: alert.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 14,
                                  color: alert.isRead
                                      ? Colors.black87
                                      : alert.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(alert.time,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Description
                  Text(
                    alert.description,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Badge sévérité + bouton SMS rapide
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: alert.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getSeverityText(alert.severity),
                          style: TextStyle(
                              fontSize: 10,
                              color: alert.color,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      // Bouton SMS rapide
                      GestureDetector(
                        onTap: () => _retrySms(alert),
                        child: Row(
                          children: [
                            Icon(Icons.sms_outlined,
                                size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text('SMS',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bouton supprimer
            GestureDetector(
              onTap: () => _deleteAlert(alert),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child:
                Icon(Icons.close, size: 16, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DÉTAIL ALERTE (Bottom Sheet)
  // ============================================================

  void _showAlertDetail(Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: alert.bgColor, shape: BoxShape.circle),
                  child: Icon(alert.icon, color: alert.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.titre,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(alert.time,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(alert.description,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5)),
            const SizedBox(height: 16),
            _infoRow(Icons.priority_high, 'Sévérité',
                _getSeverityText(alert.severity)),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, 'Date',
                _formatFullDate(alert.createdAt)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _retrySms(alert);
                },
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Envoyer SMS maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG CONFIGURATION SMS TWILIO
  // ============================================================

  Future<void> _showSmsSettingsDialog() async {
    final phoneController = TextEditingController();
    final currentPhone = await _alertService.getSmsPhoneNumber();
    phoneController.text = currentPhone ?? '';
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Alertes SMS — Twilio'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut Twilio configuré
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Twilio configuré ✓\nSMS automatiques pour les alertes critiques.',
                        style:
                        TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Numéro destinataire des SMS :',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),

              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: '+33 6XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone,
                      color: AppTheme.primaryGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryGreen, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Déclencheurs SMS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMS envoyés automatiquement pour :',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    SizedBox(height: 6),
                    Text(
                      'Température > 30°C ou < 10°C\n'
                          'Humidité > 80% ou < 30%\n'
                          'Stock périmé ou critique\n'
                          'Anti-doublon : 1 SMS / 30 min / type',
                      style: TextStyle(
                          fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          // Bouton test SMS
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _sendTestSms();
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Tester'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (phoneController.text.isNotEmpty) {
                _alertService
                    .setSmsPhoneNumber(phoneController.text.trim());
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Numéro SMS enregistré'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SMS
  // ============================================================

  Future<void> _retrySms(Alert alert) async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Envoi SMS...')));
    final sent = await _alertService.sendSmsAlert(alert);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent
              ? '✓ SMS envoyé avec succès'
              : '✗ Échec — vérifiez la config Twilio'),
          backgroundColor: sent ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestSms() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi du SMS de test...')));

    final now = TimeOfDay.now();
    final testAlert = Alert(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      titre: 'Test SMS AGRO-IA',
      description:
      'Ceci est un message de test. Votre système d\'alertes fonctionne correctement ✓',
      time:
      '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      type: AlertType.general,
      severity: AlertSeverity.medium,
      createdAt: DateTime.now(),
    );

    final sent = await _alertService.sendSmsAlert(testAlert);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent
              ? '✓ SMS de test envoyé !'
              : '✗ Échec — Vérifiez la configuration Twilio'),
          backgroundColor: sent ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical: return '🚨 CRITIQUE';
      case AlertSeverity.high:     return '⚠️ URGENT';
      case AlertSeverity.medium:   return '📋 ATTENTION';
      default:                     return 'ℹ️ INFO';
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 10),
        Text('$label : ',
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ),
      ],
    );
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year} à $h:$m';
  }
}