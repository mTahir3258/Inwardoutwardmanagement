// lib/providers/auth_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inward_outward_management/core/models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  bool loading = false;
  String? error;

  // Cached values for quick access by UI/providers
  String? _currentUserRole;
  String? get currentUserRole => _currentUserRole;

  String? _companyId;
  String? get currentCompanyId => _companyId;

  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _setError(String? err) {
    error = err;
    notifyListeners();
  }

  /// Register user and create Firestore 'users' doc.
  /// Role-based logic:
  ///  - If role == 'company' -> set companyId = uid
  ///  - Supplier/Customer: role saved; companyId left empty for now
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _setError(null);
    _setLoading(true);

    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'USER_NULL',
          message: 'User is null after registration',
        );
      }

      // Build AppUser model for Firestore
      final appUser = AppUser(
        uid: user.uid,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      // Convert to map; add role and companyId if role==company
      final map = appUser.toMap();
      map['role'] = role; // ensure role exists
      if (role.trim().toLowerCase() == 'company') {
        // Use uid as companyId for simple mapping
        map['companyId'] = user.uid;
      } else {
        // For supplier/customer we keep companyId empty; later linking can be implemented.
        map['companyId'] = map['companyId'] ?? '';
      }

      // Write to Firestore users collection
      await _fire.collection('users').doc(user.uid).set(map);

      // Update Firebase display name for convenience
      await user.updateDisplayName(name);

      // Cache role/companyId locally for fast access
      _currentUserRole = role.trim().toLowerCase();
      _companyId = (map['companyId']?.toString().isNotEmpty ?? false)
          ? map['companyId']?.toString()
          : (role.trim().toLowerCase() == 'company' ? user.uid : null);

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(e.message ?? 'Auth error: ${e.code}');
      return false;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Sign in user and cache role + companyId from Firestore users doc.
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        _setError('User not found after sign-in');
        _setLoading(false);
        return null;
      }

      // Read Firestore users doc for role/companyId
      final userDoc = await _fire.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        _setError('User document not found in Firestore');
        _setLoading(false);
        return null;
      }

      final data = userDoc.data()!;
      final roleRaw = (data['role'] ?? '').toString();
      if (roleRaw.isEmpty) {
        _setError('Role field missing for user');
        _setLoading(false);
        return null;
      }

      final roleNormalized = roleRaw.trim().toLowerCase();
      _currentUserRole = roleNormalized;

      // companyId may be present (for company users) or empty (for supplier/customer)
      final cid = (data['companyId'] ?? '').toString();
      if (cid.isNotEmpty) {
        _companyId = cid;
      } else {
        // For company users we can default to uid if not explicitly stored
        if (roleNormalized == 'company') _companyId = user.uid;
      }

      _setLoading(false);
      notifyListeners();
      return roleNormalized;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(e.message ?? 'Login failed');
      return null;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return null;
    }
  }

  User? get currentUser => _auth.currentUser;

  /// Sign out and clear cached role/company id
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserRole = null;
    _companyId = null;
    notifyListeners();
  }

  /// Fetch role/company from Firestore (useful for RoleRouter)
  Future<String?> fetchUserRole() async {
    try {
      if (_currentUserRole != null) return _currentUserRole;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _fire.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final roleRaw = (doc['role'] ?? '').toString();
      _currentUserRole = roleRaw.trim().toLowerCase();

      final cid = (doc['companyId'] ?? '').toString();
      _companyId = cid.isNotEmpty
          ? cid
          : (_currentUserRole == 'company' ? uid : null);

      notifyListeners();
      return _currentUserRole;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }
}
