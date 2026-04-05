import 'package:flutter/material.dart';
import 'package:agro_ia/models/stock_item.dart';
import 'package:agro_ia/services/prediction_service.dart';
import 'package:agro_ia/services/stock_service.dart';
import 'package:intl/intl.dart';

class StockDetailScreen extends StatefulWidget {
  final StockItem stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final PredictionService _predictionService = PredictionService();
  final StockService _stockService = StockService();
  Map<String, dynamic>? _predictions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() => _isLoading = true);

    try {
      final predictions = await _predictionService.getLotPrediction(widget.stock.id);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur chargement prédictions: $e');
    }
  }

  Future<void> _deleteStock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le lot'),
        content: Text('Voulez-vous vraiment supprimer ${widget.stock.productName} ?'),
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
      try {
        await _stockService.deleteStock(widget.stock.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lot supprimé avec succès')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stock.productName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteStock,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildPredictionCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildFlowRecommendation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stock.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.stock.unit,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    widget.stock.statusIcon,
                    color: widget.stock.statusColor,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: widget.stock.conservationPercentage / 100,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(widget.stock.statusColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Conservation: ${widget.stock.conservationPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_predictions == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.science_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Aucune prédiction disponible'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadPredictions,
                child: const Text('Actualiser'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _predictions!['status'];
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'critical':
        statusColor = Colors.orange;
        statusIcon = Icons.priority_high;
        break;
      case 'warning':
        statusColor = Colors.yellow.shade700;
        statusIcon = Icons.info_outline;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prédictions IA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statut: ${_getStatusText(status)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Durée restante: ${_predictions!['predicted_expiry_days']} jours',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Risque de contamination',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRiskIndicator(_predictions!['contamination_risk']),
                      const SizedBox(width: 8),
                      Text(_getRiskText(_predictions!['contamination_risk'])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Action recommandée',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(_predictions!['recommended_action']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String risk) {
    Color color;
    switch (risk) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du lot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Localisation', widget.stock.location, Icons.location_on),
            _buildInfoRow('Date de récolte',
                DateFormat('dd/MM/yyyy HH:mm').format(widget.stock.harvestDate as DateTime),
                Icons.calendar_today),
            _buildInfoRow('Jours depuis récolte',
                '${widget.stock.daysSinceHarvest} jours',
                Icons.timer),
            if (widget.stock.notes != null && widget.stock.notes!.isNotEmpty)
              _buildInfoRow('Notes', widget.stock.notes!, Icons.note),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowRecommendation() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Schéma d\'écoulement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            if (widget.stock.stockStatus == 'critical')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lot prioritaire - À écouler dans les 3 jours',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Recommandations :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.stock.stockStatus == 'critical')
              _buildRecommendationItem(
                'Vente express',
                'Proposer des promotions sur ce produit',
                Icons.sell,
              ),
            _buildRecommendationItem(
              'Transformation',
              'Envisager la transformation (séchage, conserve)',
              Icons.factory,
            ),
            _buildRecommendationItem(
              'Don',
              'Si expiration imminente, donner à des associations',
              Icons.volunteer_activism,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'expired':
        return 'Périmé';
      case 'critical':
        return 'Critique - Expiration imminente';
      case 'warning':
        return 'Attention - À surveiller';
      default:
        return 'Bon état';
    }
  }

  String _getRiskText(String? risk) {
    switch (risk) {
      case 'high':
        return 'Élevé - Action immédiate requise';
      case 'medium':
        return 'Moyen - Surveiller attentivement';
      default:
        return 'Faible - Conditions normales';
    }
  }
}