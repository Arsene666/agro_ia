import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/stock_item.dart';
import '../../services/stock_service.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final StockService _stockService = StockService();

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedUnit = 'kg';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;
  int _currentStep = 0;

  // Produits suggérés
  final List<Map<String, dynamic>> _suggestedProducts = [
    {'name': 'Tomates', 'icon': '🍅'},
    {'name': 'Maïs', 'icon': '🌽'},
    {'name': 'Manioc', 'icon': '🌿'},
    {'name': 'Ignames', 'icon': '🥔'},
    {'name': 'Bananes', 'icon': '🍌'},
    {'name': 'Arachides', 'icon': '🥜'},
  ];

  static const Color _green = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFFE8F5E9);
  static const Color _darkBg = Color(0xFFF7F9F7);

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // CORRECTION : Utiliser harvestDateStr au lieu de harvestDate
    final item = StockItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: _productController.text.trim(),
      quantity: double.tryParse(_quantityController.text) ?? 0,
      unit: _selectedUnit,
      harvestDateStr: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',  // Changé ici
      harvestTime: _selectedTime.format(context),
      location: _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),  // notes peut être null
      createdAt: DateTime.now(),
    );

    final success = await _stockService.saveStockItem(item);
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      // Succès
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: _lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: _green, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Produit enregistré !',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.productName} (${item.quantity} ${item.unit}) a été ajouté au stock.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);  // Retourne true pour indiquer un succès
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Retour au Dashboard',
                      style: GoogleFonts.outfit()),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: CustomScrollView(
        slivers: [
          // AppBar stylisée
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _green,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouveau lot',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Enregistrement post-récolte',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === SECTION 1 : Produit ===
                    _sectionTitle('🌱', 'Identification du produit'),
                    const SizedBox(height: 12),

                    // Suggestions rapides
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final p = _suggestedProducts[i];
                          final selected =
                              _productController.text == p['name'];
                          return GestureDetector(
                            onTap: () => setState(
                                    () => _productController.text = p['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? _green : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? _green
                                      : Colors.grey.withOpacity(0.2),
                                ),
                                boxShadow: selected
                                    ? [
                                  BoxShadow(
                                    color: _green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Text(p['icon'],
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    p['name'],
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Champ produit
                    _buildCard(
                      child: TextFormField(
                        controller: _productController,
                        style: GoogleFonts.outfit(fontSize: 16),
                        decoration: _inputDeco(
                          label: 'Nom du produit',
                          hint: 'ex: Tomates cerises',
                          icon: Icons.grass_rounded,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Champ obligatoire'
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quantité + Unité
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCard(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'))
                              ],
                              style: GoogleFonts.outfit(fontSize: 16),
                              decoration: _inputDeco(
                                label: 'Quantité',
                                hint: '0.00',
                                icon: Icons.scale_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Obligatoire';
                                if (double.tryParse(v) == null)
                                  return 'Invalide';
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCard(
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: _inputDeco(
                                  label: 'Unité', hint: '', icon: null),
                              style: GoogleFonts.outfit(
                                  fontSize: 15, color: Colors.black87),
                              items: ['kg', 'tonnes', 'caisses', 'sacs']
                                  .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedUnit = v!),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // === SECTION 2 : Date & Lieu ===
                    _sectionTitle('📍', 'Date & Lieu de stockage'),
                    const SizedBox(height: 12),

                    // Date & Heure
                    Row(
                      children: [
                        Expanded(
                          child: _buildCard(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: _inputDeco(
                                  label: 'Date de récolte',
                                  hint: '',
                                  icon: Icons.calendar_month_rounded,
                                ),
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: GoogleFonts.outfit(fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCard(
                            child: InkWell(
                              onTap: _selectTime,
                              child: InputDecorator(
                                decoration: _inputDeco(
                                  label: 'Heure',
                                  hint: '',
                                  icon: Icons.access_time_rounded,
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                  style: GoogleFonts.outfit(fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Lieu
                    _buildCard(
                      child: TextFormField(
                        controller: _locationController,
                        style: GoogleFonts.outfit(fontSize: 16),
                        decoration: _inputDeco(
                          label: 'Lieu de stockage',
                          hint: 'ex: Entrepôt B, Zone 4',
                          icon: Icons.warehouse_rounded,
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Champ obligatoire'
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === SECTION 3 : Notes ===
                    _sectionTitle('📝', 'Notes & Qualité'),
                    const SizedBox(height: 12),

                    _buildCard(
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        style: GoogleFonts.outfit(fontSize: 15),
                        decoration: _inputDeco(
                          label: 'Observations (optionnel)',
                          hint:
                          'Qualité, variété, conditions de récolte...',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bannière info capteurs
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border:
                        Border.all(color: _green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sensors,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monitoring automatique activé',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _green,
                                  ),
                                ),
                                Text(
                                  'Température & humidité enregistrées toutes les 3 jours.',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Bouton enregistrer
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: _green.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_alt_rounded,
                                size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Enregistrer dans le stock',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
      hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: _green, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}