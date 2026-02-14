import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseAuth firebaseAuthentication = FirebaseAuth.instance;
  
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> validationForm(
    BuildContext context, {
    VoidCallback? onError,
  }) async {
    if (!formKey.currentState!.validate()) {
      if (onError != null) onError();
      return;
    }

    setLoading(true);

    try {
      await firebaseAuthentication.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passController.text.trim(),
      );

      // AuthGatePage akan otomatis handle redirect
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login berhasil!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login gagal";

      if (e.code == 'user-not-found') {
        message = "Email tidak terdaftar";
      } else if (e.code == 'wrong-password') {
        message = "Password salah";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid";
      } else if (e.code == 'user-disabled') {
        message = "Akun telah dinonaktifkan";
      } else if (e.code == 'too-many-requests') {
        message = "Terlalu banyak percobaan. Coba lagi nanti";
      } else if (e.code == 'network-request-failed') {
        message = "Tidak ada koneksi internet";
      } else if (e.code == 'invalid-credential') {
        message = "Email atau password salah";
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (onError != null) onError();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan. Coba lagi"),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (onError != null) onError();
    } finally {
      setLoading(false);
    }
  }

  // Logout function
  Future<void> logout() async {
    setLoading(true);
    try {
      await firebaseAuthentication.signOut();
      usernameController.clear();
      passController.clear();
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passController.dispose();
    super.dispose();
  }
}