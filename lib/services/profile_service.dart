import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';

class ProfileService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Clé unique pour le profil (étant donné qu'on a un seul dispositif)
  // On pourrait utiliser "current_profile" comme identifiant fixe
  static const String PROFILE_KEY = 'user_profile';

  // Option 1: Utiliser un ID fixe (recommandé pour un seul profil)
  Future<void> createOrUpdateProfile(UserProfile profile) async {
    try {
      await _database.child(PROFILE_KEY).set(profile.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du profil: $e');
    }
  }

  // Option 2: Récupérer le profil
  Future<UserProfile?> getProfile() async {
    try {
      final snapshot = await _database.child(PROFILE_KEY).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Convertir les clés dynamiques en Map<String, dynamic>
        Map<String, dynamic> typedData = {};
        data.forEach((key, value) {
          typedData[key.toString()] = value;
        });
        return UserProfile.fromMap(typedData, PROFILE_KEY);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  // Mettre à jour partiellement le profil
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      await _database.child(PROFILE_KEY).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  // Vérifier si un profil existe
  Future<bool> profileExists() async {
    try {
      final snapshot = await _database.child(PROFILE_KEY).get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  // Supprimer le profil (optionnel)
  Future<void> deleteProfile() async {
    try {
      await _database.child(PROFILE_KEY).remove();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du profil: $e');
    }
  }
}