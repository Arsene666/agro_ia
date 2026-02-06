import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedUnit = 'kg';
  final List<String> _units = ['kg', 'tonnes', 'caisses', 'sacs'];

  // Dark Theme Colors for this specific screen
  static const Color _backgroundColor = Color(0xFF051109); // Very dark green/black
  static const Color _cardColor = Color(0xFF0A1F13); // Slightly lighter
  static const Color _inputColor = Color(0xFF0F2B1B); 
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _neonGreen = Color(0xFF00E676); // For the Save button
  static const Color _textWhite = Colors.white;
  static const Color _textGrey = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Initialize date and time with current values
    final now = DateTime.now();
    _dateController.text = "${now.day}/${now.month}/${now.year}";
    _timeController.text = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primaryGreen,
              onPrimary: _textWhite,
              surface: _cardColor,
              onSurface: _textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primaryGreen,
              onPrimary: _textWhite,
              surface: _cardColor,
              onSurface: _textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (context.mounted) {
        setState(() {
          _timeController.text = picked.format(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saisie Manuelle',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _textWhite,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: _primaryGreen),
            onPressed: () {
              // Show info dialog
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JOURNAL POST-RÉCOLTE',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textGrey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Détails du nouveau lot',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textWhite,
                ),
              ),
              const SizedBox(height: 32),
              
              // Product Name
              _buildLabel('Nom du produit'),
              _buildTextField(
                controller: _productController,
                hintText: 'ex: Tomates, Maïs',
                suffixIcon: Icons.delete_outline,
              ),
              const SizedBox(height: 20),

              // Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Quantité/Poids'),
                        _buildTextField(
                          controller: _quantityController,
                          hintText: '0.00',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Unité'),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _inputColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              dropdownColor: _inputColor,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: _textWhite,
                              ),
                              icon: const Icon(Icons.keyboard_arrow_down, color: _textGrey),
                              items: _units.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedUnit = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Date de récolte'),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _dateController,
                              hintText: 'JJ/MM/AAAA',
                              suffixIcon: Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Heure'),
                        GestureDetector(
                          onTap: () => _selectTime(context),
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _timeController,
                              hintText: 'HH:MM',
                              suffixIcon: Icons.access_time,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Storage Location
              _buildLabel('Lieu de stockage'),
              _buildTextField(
                controller: _locationController,
                hintText: 'ex: Entrepôt B, Zone 4',
                prefixIcon: Icons.location_on,
                prefixIconColor: _primaryGreen,
              ),
              const SizedBox(height: 20),

              // Additional Notes
              _buildLabel('Notes supplémentaires (Optionnel)'),
              _buildTextField(
                controller: _notesController,
                hintText: 'Décrire la qualité, la variété ou les instructions spécifiques...',
                maxLines: 4,
              ),
              
              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _neonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _neonGreen.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sensors, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Monitoring Active',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _textWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "L'entrée déclenchera l'appairage des capteurs en temps réel pour ce lot.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process data
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Produit enregistré avec succès!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: Colors.black,
                    elevation: 4,
                    shadowColor: _neonGreen.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Enregistrer le produit',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFB0BEC5),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? suffixIcon,
    IconData? prefixIcon,
    Color? prefixIconColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
        fontSize: 16,
        color: _textWhite,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(
          fontSize: 16,
          color: Colors.white24,
        ),
        filled: true,
        fillColor: _inputColor,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen),
        ),
        suffixIcon: suffixIcon != null 
            ? Icon(suffixIcon, color: _textGrey) 
            : null,
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: prefixIconColor ?? _textGrey) 
            : null,
      ),
    );
  }
}
