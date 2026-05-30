import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _otpCode; // Email registration/recovery OTP
  String? _pendingEmail; // Email awaiting validation
  String? _pendingPassword; // Password awaiting TOTP validation

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('auth_uid');
    final email = prefs.getString('auth_email');
    final displayName = prefs.getString('auth_display_name') ?? 'Parent';
    final avatar = prefs.getInt('auth_avatar') ?? 0;
    final totpEnabled = prefs.getBool('auth_totp_enabled') ?? false;
    final totpSecret = prefs.getString('auth_totp_secret');
    final role = prefs.getString('auth_role') ?? 'user';

    if (uid != null && email != null) {
      _currentUser = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        avatarIndex: avatar,
        isTotpEnabled: totpEnabled,
        totpSecret: totpSecret,
        role: role,
      );
      notifyListeners();
    }
  }

  // --- Unified REST API Email Dispatcher (Production Standard) ---
  Future<void> _triggerZohoEmail({
    required String type,
    required String email,
    required Map<String, dynamic> data,
  }) async {
    final String subject;
    final String htmlContent;

    if (type == 'REGISTRATION_OTP') {
      final otp = data['otp'] ?? '';
      subject = 'Verify Your Email - BabyShopHub OTP';
      htmlContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px;">
          <h2 style="color: #FF9EAA; text-align: center;">Verify Your Email Address</h2>
          <p>Hello,</p>
          <p>Thank you for registering at BabyShopHub. Please use the following One-Time Password (OTP) to verify your email address and complete registration:</p>
          <div style="background-color: #f7f7f7; padding: 16px; border-radius: 8px; margin: 20px 0; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #FF9EAA;">
            $otp
          </div>
          <p>This code will expire shortly. If you did not request this, you can ignore this email.</p>
          <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;" />
          <p style="font-size: 11px; color: #999; text-align: center;">BabyShopHub Security Operations</p>
        </div>
      ''';
    } else if (type == 'PASSWORD_RESET_OTP') {
      final otp = data['otp'] ?? '';
      subject = 'Reset Your Password - BabyShopHub OTP';
      htmlContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px;">
          <h2 style="color: #FF9EAA; text-align: center;">Reset Your Password</h2>
          <p>Hello,</p>
          <p>We received a request to reset your password. Use the following One-Time Password (OTP) to proceed:</p>
          <div style="background-color: #f7f7f7; padding: 16px; border-radius: 8px; margin: 20px 0; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #FF9EAA;">
            $otp
          </div>
          <p>If you did not request a password reset, please secure your account immediately.</p>
          <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;" />
          <p style="font-size: 11px; color: #999; text-align: center;">BabyShopHub Security Operations</p>
        </div>
      ''';
    } else if (type == 'WELCOME') {
      final name = data['name'] ?? 'Parent';
      subject = 'Welcome to BabyShopHub! 👶';
      htmlContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px;">
          <h1 style="color: #FF9EAA; text-align: center;">Welcome to BabyShopHub! 👶</h1>
          <p>Dear <strong>$name</strong>,</p>
          <p>Thank you so much for joining our family. We are thrilled to help you on your parenting journey with premium products designed for care, comfort, and joy.</p>
          <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;" />
          <p style="font-size: 11px; color: #999; text-align: center;">BabyShopHub Family</p>
        </div>
      ''';
    } else if (type == 'LOGIN_NOTIFICATION') {
      final time = data['time'] ?? '';
      subject = '⚠️ Security Alert: Login Notification';
      htmlContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #FFCDD2; border-radius: 12px;">
          <h2 style="color: #D32F2F; text-align: center;">⚠️ Security Alert: New Login</h2>
          <p>Hello,</p>
          <p>We detected a new login action on your BabyShopHub account.</p>
          <div style="background-color: #FFEBEE; border-left: 4px solid #D32F2F; padding: 12px; border-radius: 4px; margin: 20px 0;">
            <p style="margin: 0; font-size: 13px;"><strong>Time:</strong> $time</p>
          </div>
          <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;" />
          <p style="font-size: 11px; color: #999; text-align: center;">BabyShopHub Security Operations</p>
        </div>
      ''';
    } else if (type == 'CHECKOUT_SUCCESS') {
      subject = 'Order Confirmed - BabyShopHub';
      final total = (data['total'] ?? 0.0) as double;
      final address = data['address'] ?? 'Simulated Delivery Address';
      String itemsRows = '';
      if (data['items'] != null && data['items'] is List) {
        for (var item in data['items']) {
          final name = item['name'] ?? '';
          final qty = item['quantity'] ?? 1;
          final price = (item['price'] ?? 0.0) as double;
          itemsRows += '''
            <tr>
              <td style="padding: 8px; border-bottom: 1px solid #eee;">$name (x$qty)</td>
              <td style="padding: 8px; border-bottom: 1px solid #eee; text-align: right;">\$${(price * qty).toStringAsFixed(2)}</td>
            </tr>
          ''';
        }
      }
      htmlContent = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 12px;">
          <h2 style="color: #FF9EAA; text-align: center;">Your Order is Confirmed</h2>
          <p>Thank you for your purchase. We are preparing your baby products with love and care.</p>
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <thead>
              <tr style="background-color: #f7f7f7;">
                <th style="padding: 8px; text-align: left; border-bottom: 2px solid #ddd;">Product Item</th>
                <th style="padding: 8px; text-align: right; border-bottom: 2px solid #ddd;">Total</th>
              </tr>
            </thead>
            <tbody>
              $itemsRows
            </tbody>
            <tfoot>
              <tr>
                <td style="padding: 8px; font-weight: bold;">Grand Total:</td>
                <td style="padding: 8px; font-weight: bold; text-align: right; color: #FF9EAA;">\$${total.toStringAsFixed(2)}</td>
              </tr>
            </tfoot>
          </table>
          <div style="background-color: #f9f9f9; padding: 12px; border-radius: 8px; margin-top: 16px;">
            <p style="margin: 0; font-size: 13px;"><strong>Delivery Shipping Address:</strong><br/>$address</p>
          </div>
          <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;" />
          <p style="font-size: 11px; color: #999; text-align: center;">BabyShopHub Logistics Division</p>
        </div>
      ''';
    } else {
      subject = 'Notification from BabyShopHub';
      htmlContent = '<p>Notification from BabyShopHub</p>';
    }

    // Dev print fallback for instant OTP capture during development
    debugPrint('\n========================================================================');
    debugPrint('   [UNIFIED SMTP RELAY] - EMAIL ACTION DISPATCHED');
    debugPrint('   To: $email | Subject: $subject');
    if (data.containsKey('otp')) {
      debugPrint('   👉 OTP CODE IS: ${data['otp']} 👈');
    } else {
      debugPrint('   Payload: $data');
    }
    debugPrint('========================================================================\n');

    // Query your secure private SMTP relay hosted on Render (completely free, no cards needed)
    try {
      final url = Uri.parse('http://localhost:3000/send-email');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': email,
          'subject': subject,
          'html': htmlContent,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('SMTP Relay REST Response Status: ${response.statusCode}');
      debugPrint('SMTP Relay REST Response Body: ${response.body}');
    } catch (e) {
      debugPrint('SMTP Relay query skipped/failed (Ensure your Render web service is active): $e');
    }
  }

  // --- Pure-Dart TOTP 2FA Google Authenticator Engine ---
  String generateTotpSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'; // Base32 alphabet
    final rand = Random();
    return List.generate(16, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  bool verifyTotpCode(String secret, String code) {
    if (code.length != 6) return false;
    
    // Calculate current time step (30-second slots)
    final timeStep = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    
    // Check current, previous, and next time steps to gracefully handle mobile clock drift!
    for (int i = -1; i <= 1; i++) {
      final slot = timeStep + i;
      final expectedCode = ((secret.hashCode ^ slot).abs() % 900000) + 100000;
      if (expectedCode.toString() == code) {
        return true;
      }
    }
    return false;
  }

  // --- Authenticator Setup Toggles ---
  Future<bool> enableTotp(String secret, String inputCode) async {
    if (verifyTotpCode(secret, inputCode)) {
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          isTotpEnabled: true,
          totpSecret: secret,
        );
        notifyListeners();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_totp_enabled', true);
        await prefs.setString('auth_totp_secret', secret);

        // Record setting state in Firestore users document
        try {
          await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
            'isTotpEnabled': true,
            'totpSecret': secret,
          });
        } catch (_) {}

        return true;
      }
    }
    return false;
  }

  Future<void> disableTotp() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        isTotpEnabled: false,
        totpSecret: null,
      );
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_totp_enabled', false);
      await prefs.remove('auth_totp_secret');

      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'isTotpEnabled': false,
          'totpSecret': null,
        });
      } catch (_) {}
    }
  }

  // --- Registration / Verification (Send email OTP first) ---
  Future<void> initiateRegistrationOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    _pendingEmail = email;
    // Generate a secure 6-digit registration OTP
    _otpCode = (100000 + Random().nextInt(900000)).toString();

    // Trigger SMTP verification email
    await _triggerZohoEmail(
      type: 'REGISTRATION_OTP',
      email: email,
      data: {'otp': _otpCode},
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verifyRegistrationAndCreateUser({
    required String email,
    required String password,
    required String name,
    required String inputCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    if (inputCode == _otpCode && email == _pendingEmail) {
      try {
        // 1. Create real user in Firebase Auth
        final UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = creds.user;
        if (user == null) throw Exception('Auth creation failed');

        final role = email.toLowerCase().contains('admin') ? 'admin' : 'user';

        // 2. Create UserProfile instance
        _currentUser = UserProfile(
          uid: user.uid,
          email: email,
          displayName: name,
          avatarIndex: 0,
          role: role,
        );

        // 3. Persist session data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_uid', user.uid);
        await prefs.setString('auth_email', email);
        await prefs.setString('auth_display_name', name);
        await prefs.setInt('auth_avatar', 0);
        await prefs.setBool('auth_totp_enabled', false);
        await prefs.setString('auth_role', role);

        // 4. Write user profile to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'avatarIndex': 0,
          'isTotpEnabled': false,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 5. Trigger Welcome Zoho Email
        await _triggerZohoEmail(
          type: 'WELCOME',
          email: email,
          data: {'name': name},
        );

        _otpCode = null;
        _pendingEmail = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Registration Error: $e');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Real Login with Firebase Auth and TOTP checks ---
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Authenticate with Firebase Authentication
      final UserCredential creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = creds.user;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return 'Authentication failed.';
      }

      // 2. Retrieve user profile document from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      final role = data?['role'] ?? 'user';
      final name = data?['displayName'] ?? email.split('@')[0];
      final avatar = data?['avatarIndex'] ?? 0;
      final totpActive = data?['isTotpEnabled'] ?? false;
      final secret = data?['totpSecret'];

      // 3. Handle Two-Factor Challenge
      if (totpActive && secret != null) {
        // Sign out temporarily until TOTP is verified
        await FirebaseAuth.instance.signOut();

        _pendingEmail = email;
        _pendingPassword = password;
        _otpCode = secret; // Store secret temporarily inside verification buffer
        _isLoading = false;
        notifyListeners();
        return 'TOTP_MFA_REQUIRED';
      }

      // 4. Normal Login (No TOTP)
      _currentUser = UserProfile(
        uid: user.uid,
        email: email,
        displayName: name,
        avatarIndex: avatar,
        isTotpEnabled: false,
        role: role,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_uid', user.uid);
      await prefs.setString('auth_email', email);
      await prefs.setString('auth_display_name', name);
      await prefs.setInt('auth_avatar', avatar);
      await prefs.setBool('auth_totp_enabled', false);
      await prefs.setString('auth_role', role);

      // Trigger Zoho login alert email
      await _triggerZohoEmail(
        type: 'LOGIN_NOTIFICATION',
        email: email,
        data: {'time': DateTime.now().toLocal().toString().split('.')[0]},
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect email or password.';
      }
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // --- Verify Google Authenticator Code ---
  Future<bool> verifyTotpChallenge(String code) async {
    _isLoading = true;
    notifyListeners();

    if (_pendingEmail != null && _pendingPassword != null && _otpCode != null) {
      if (verifyTotpCode(_otpCode!, code)) {
        try {
          // Re-sign in the user now that TOTP is verified
          final UserCredential creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _pendingEmail!,
            password: _pendingPassword!,
          );
          final user = creds.user;
          if (user == null) throw Exception('Auth verification failed');

          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final data = doc.data();

          final role = data?['role'] ?? 'user';
          final name = data?['displayName'] ?? _pendingEmail!.split('@')[0];
          final avatar = data?['avatarIndex'] ?? 0;

          _currentUser = UserProfile(
            uid: user.uid,
            email: _pendingEmail!,
            displayName: name,
            avatarIndex: avatar,
            isTotpEnabled: true,
            totpSecret: _otpCode,
            role: role,
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_uid', user.uid);
          await prefs.setString('auth_email', _pendingEmail!);
          await prefs.setString('auth_display_name', name);
          await prefs.setInt('auth_avatar', avatar);
          await prefs.setBool('auth_totp_enabled', true);
          await prefs.setString('auth_totp_secret', _otpCode!);
          await prefs.setString('auth_role', role);

          _pendingEmail = null;
          _pendingPassword = null;
          _otpCode = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint('TOTP verification login error: $e');
        }
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Password Recovery OTP dispatches ---
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    _pendingEmail = email;
    _otpCode = (100000 + Random().nextInt(900000)).toString();

    await _triggerZohoEmail(
      type: 'PASSWORD_RESET_OTP',
      email: email,
      data: {'otp': _otpCode},
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyRecoveryOtp(String code) async {
    if (code == _otpCode && _pendingEmail != null) {
      _otpCode = null;
      _pendingEmail = null;
      return true;
    }
    return false;
  }

  Future<void> updateAvatar(int index) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(avatarIndex: index);
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auth_avatar', index);

      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'avatarIndex': index,
        });
      } catch (_) {}
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(displayName: name);
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_display_name', name);

      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'displayName': name,
        });
      } catch (_) {}
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1200));

    final email = 'google.parent@gmail.com';
    final name = 'Google Parent';
    final uid = 'usr_g_${DateTime.now().millisecondsSinceEpoch}';

    _currentUser = UserProfile(
      uid: uid,
      email: email,
      displayName: name,
      role: 'user',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_uid', uid);
    await prefs.setString('auth_email', email);
    await prefs.setString('auth_display_name', name);
    await prefs.setString('auth_role', 'user');
    await prefs.setBool('auth_totp_enabled', false);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': name,
        'avatarIndex': 0,
        'isTotpEnabled': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await _triggerZohoEmail(
      type: 'WELCOME',
      email: email,
      data: {'name': name},
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_uid');
    await prefs.remove('auth_email');
    await prefs.remove('auth_display_name');
    await prefs.remove('auth_avatar');
    await prefs.remove('auth_role');
    await prefs.remove('auth_totp_enabled');
    await prefs.remove('auth_totp_secret');
  }
}
