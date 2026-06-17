import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiService _api = ApiService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Unesite e-mail adresu.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _api.post('/api/passwordreset/request', {
        'email': _emailController.text.trim(),
      });
      setState(() {
        _codeSent = true;
        _success = 'Kod je poslan na vaš e-mail.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = 'Unesite kod.');
      return;
    }
    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'Lozinka mora imati najmanje 8 znakova.');
      return;
    }
    if (_newPasswordController.text != _confirmController.text) {
      setState(() => _error = 'Lozinke se ne poklapaju.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _api.post('/api/passwordreset/confirm', {
        'code': _codeController.text.trim(),
        'newPassword': _newPasswordController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lozinka je uspješno promijenjena.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset lozinke'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset,
                  size: 64, color: AppTheme.accent),
              const SizedBox(height: 16),
              const Text(
                'Resetovanje lozinke',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unesite vaš e-mail i poslatćemo vam jednokratni kod za reset lozinke.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent,
                decoration: const InputDecoration(
                  labelText: 'E-mail adresa',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              if (!_codeSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestCode,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Pošalji kod',
                          style: TextStyle(fontSize: 16)),
                ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jednokratni kod',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Nova lozinka',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: !_showConfirm,
                  decoration: InputDecoration(
                    labelText: 'Potvrda nove lozinke',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmReset,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Promijeni lozinku',
                          style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _requestCode,
                  child: const Text('Nisam dobio kod — pošalji ponovo'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center),
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_success!,
                      style: const TextStyle(color: AppTheme.success),
                      textAlign: TextAlign.center),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}