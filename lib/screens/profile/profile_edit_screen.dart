import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;

  // Contrôleurs pour les champs de texte
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _locationController;
  late TextEditingController _superficieController;
  late TextEditingController _type_cultureController;
  late TextEditingController _exploitationController;


  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs avec les valeurs existantes si on édite
    _nomController = TextEditingController(text: widget.profile?.Nom ?? '');
    _prenomController = TextEditingController(text: widget.profile?.prenom ?? '');
    _locationController = TextEditingController(text: widget.profile?.location ?? '');
    _superficieController = TextEditingController(
      text: widget.profile?.superficie.toString() ?? '',
    );
    _type_cultureController = TextEditingController(
      text: widget.profile?.type_culture ?? '',
    );
    _exploitationController = TextEditingController(
      text: widget.profile?.exploitation ?? '',
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _locationController.dispose();
    _superficieController.dispose();
    _type_cultureController.dispose();
    _exploitationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final profile = UserProfile(
        Nom: _nomController.text,
        prenom: _prenomController.text,
        location: _locationController.text,
        superficie: double.parse(_superficieController.text),
        type_culture: _type_cultureController.text,
        exploitation: _exploitationController.text,
        createdAt: widget.profile?.createdAt ?? now,
        updatedAt: now,
      );

      await _profileService.createOrUpdateProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil sauvegardé avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Créer un profil' : 'Modifier le profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations de base
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'agriculteur *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prenom *',
                  prefixIcon: Icon(Icons.agriculture),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Dakar, Sénégal',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _superficieController,
                decoration: const InputDecoration(
                  labelText: 'Superficie (hectares) *',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                  suffixText: 'ha',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Champ requis';
                  if (double.tryParse(value!) == null) return 'Nombre valide requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _type_cultureController,
                decoration: const InputDecoration(
                  labelText: "Type de culture*",
                  prefixIcon: Icon(Icons.water_drop),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Tomates, Maïs, Patates',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _exploitationController,
                decoration: const InputDecoration(
                  labelText: 'Exploitations*',
                  prefixIcon: Icon(Icons.landscape),
                  border: OutlineInputBorder(),
                  hintText: 'Nom de la ferme',
                ),
              ),
              const SizedBox(height: 24),

              // Bouton de sauvegarde
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Sauvegarder le profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}