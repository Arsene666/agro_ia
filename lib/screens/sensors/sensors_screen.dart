import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:agro_ia/services/stock_service.dart';
import 'package:agro_ia/models/stock_item.dart';
import 'package:agro_ia/theme/app_theme.dart';

// ==================================================
//  MODEL : Un point de donnée historique
// ==================================================
class SensorPoint {
  final DateTime time;
  final double temperature;
  final double humidity;
  const SensorPoint({
    required this.time,
    required this.temperature,
    required this.humidity,
  });
}

// Support de classe pour les Recommendations
enum _Urgency { high, medium, ok }

class _Recommendation {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final _Urgency urgency;

  const _Recommendation({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.urgency,
  });
}

class SensorsPredictionsScreen extends StatefulWidget {
  const SensorsPredictionsScreen({super.key});

  @override
  State<SensorsPredictionsScreen> createState() => _SensorsPredictionsScreenState();
}

class _SensorsPredictionsScreenState extends State<SensorsPredictionsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final StockService _stockService = StockService();

  List<SensorPoint> _history = [];
  Map<String, dynamic> _lotPredictions = {};
  bool _loading = true;

  int _activeChart = 0; // 0 = Temp, 1 = Hum
  int _hoursRange = 24;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadAll();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    await Future.wait([
      _loadHistory(),
      _loadIAPredictions(),
    ]);

    if (mounted) {
      setState(() => _loading = false);
      _animController.forward(from: 0);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final snap = await _db.child('sensor_history').limitToLast(60).get();
      if (!snap.exists) return;

      final raw = snap.value as Map<dynamic, dynamic>;
      final List<SensorPoint> pts = [];

      raw.forEach((key, val) {
        final map = val as Map<dynamic, dynamic>;
        final ts = map['timestamp'] as String? ?? '';
        if (ts.isNotEmpty) {
          pts.add(SensorPoint(
            time: DateTime.parse(ts),
            temperature: (map['temperature'] ?? 0).toDouble(),
            humidity: (map['humidity'] ?? 0).toDouble(),
          ));
        }
      });

      pts.sort((a, b) => a.time.compareTo(b.time));
      setState(() {
        _history = pts;
      });
    } catch (e) {
      debugPrint('Erreur historique: $e');
    }
  }

  Future<void> _loadIAPredictions() async {
    try {
      final snap = await _db.child('lot_predictions').get();
      if (snap.exists) {
        setState(() {
          _lotPredictions = Map<String, dynamic>.from(snap.value as Map);
        });
      }
    } catch (e) {
      debugPrint('Erreur IA: $e');
    }
  }

  List<SensorPoint> get _filteredHistory {
    if (_history.isEmpty) return [];
    return _history;
  }

  List<_Recommendation> get _recommendations {
    final List<_Recommendation> recs = [];

    _lotPredictions.forEach((lotId, data) {
      final status = data['status'] as String? ?? '';
      final expiryDays = data['predicted_expiry_days'] ?? 0;

      if (status == "risk_detected") {
        recs.add(_Recommendation(
          icon: Icons.warning_amber_rounded,
          color: AppTheme.errorRed,
          title: 'Risque sur $lotId',
          detail: 'L\'IA a détecté une anomalie de conservation.',
          urgency: _Urgency.high,
        ));
      } else if (expiryDays <= 3 && expiryDays > 0) {
        recs.add(_Recommendation(
          icon: Icons.timer_outlined,
          color: Colors.orange,
          title: 'Échéance : $lotId',
          detail: 'Rotation prioritaire : expiration sous $expiryDays jours.',
          urgency: _Urgency.medium,
        ));
      }
    });

    if (_history.isNotEmpty) {
      if (_history.last.humidity > 75) {
        recs.add(const _Recommendation(
          icon: CupertinoIcons.drop_fill,
          color: Colors.blue,
          title: 'Humidité élevée',
          detail: 'Activez la ventilation forcée.',
          urgency: _Urgency.medium,
        ));
      }
    }

    if (recs.isEmpty) {
      recs.add(const _Recommendation(
        icon: Icons.check_circle_outline,
        color: AppTheme.primaryGreen,
        title: 'Système stable',
        detail: 'Les conditions sont optimales.',
        urgency: _Urgency.ok,
      ));
    }
    return recs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            onRefresh: _loadAll,
            color: AppTheme.primaryGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildChartToggle(),
                  const SizedBox(height: 12),
                  _buildRangeSelector(),
                  const SizedBox(height: 16),
                  _buildChartCard(),
                  const SizedBox(height: 32),
                  _buildRecommendationsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Capteurs & Analyses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(
            _history.isNotEmpty
                ? 'Dernier relevé : ${DateFormat('HH:mm').format(_history.last.time)}'
                : 'En attente de données',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ]),
        IconButton(
          onPressed: _loadAll,
          icon: const Icon(CupertinoIcons.refresh, color: AppTheme.primaryGreen),
        )
      ],
    );
  }

  Widget _buildChartToggle() {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10)],
      ),
      child: Row(children: [
        _toggleBtn(0, Icons.thermostat, 'Température'),
        _toggleBtn(1, CupertinoIcons.drop_fill, 'Humidité'),
      ]),
    );
  }

  Widget _toggleBtn(int idx, IconData icon, String label) {
    bool active = _activeChart == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeChart = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [6, 12, 24].map((h) => GestureDetector(
        onTap: () => setState(() => _hoursRange = h),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hoursRange == h ? AppTheme.primaryGreen.withValues(alpha:0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hoursRange == h ? AppTheme.primaryGreen : Colors.grey.shade200),
          ),
          child: Text('${h}h',
              style: TextStyle(
                  fontSize: 11,
                  color: _hoursRange == h ? AppTheme.primaryGreen : Colors.grey)),
        ),
      )).toList(),
    );
  }

  Widget _buildChartCard() {
    final pts = _filteredHistory;
    final isTmp = _activeChart == 0;
    final color = isTmp ? Colors.orange.shade800 : Colors.blue.shade700;
    final unit = isTmp ? '°C' : '%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  pts.isNotEmpty
                      ? '${(isTmp ? pts.last.temperature : pts.last.humidity).toStringAsFixed(1)}$unit'
                      : '--',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: color)),
              const Icon(Icons.auto_graph, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: pts.length < 2
                ? const Center(child: Text('Données insuffisantes'))
                : _SensorChart(
              points: pts,
              getValue: isTmp ? (p) => p.temperature : (p) => p.humidity,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recs = _recommendations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommandations IA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...recs.map((r) => _RecommendationCard(rec: r)),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final _Recommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(rec.icon, color: rec.color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(rec.detail,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================
//  PAINTER : Dessin de la courbe
// =================================================
class _SensorChart extends StatelessWidget {
  final List<SensorPoint> points;
  final double Function(SensorPoint) getValue;
  final Color color;
  const _SensorChart({required this.points, required this.getValue, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(points: points, getValue: getValue, color: color),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<SensorPoint> points;
  final double Function(SensorPoint) getValue;
  final Color color;
  _ChartPainter({required this.points, required this.getValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final List<double> values = points.map(getValue).toList();
    final double maxVal = values.reduce(math.max);
    final double minVal = values.reduce(math.min);

    // Ajout d'une marge pour que la courbe ne touche pas les bords
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);
    final double padding = range * 0.15;
    final double viewMin = minVal - padding;
    final double viewMax = maxVal + padding;
    final double viewRange = viewMax - viewMin;

    final double widthStep = size.width / (points.length - 1);
    final Path path = Path();
    final Path fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final double x = i * widthStep;
      final double y = size.height - ((values[i] - viewMin) / viewRange * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == points.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    // Dessin du dégradé sous la courbe
    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha:0.2), color.withValues(alpha:0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Dessin de la ligne principale
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}