import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  List<dynamic> _cities = [];
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final data = await ApiService().get(ApiConfig.cities);
      setState(() => _cities = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      await api.post(ApiConfig.register, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text.trim(),
        'driverLicenseNo': _licenseController.text.trim(),
        'cityId': _selectedCityId,
      });

      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registracija'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ime',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ime je obavezno.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prezime',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Prezime je obavezno.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail adresa',
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: 'Format: ime@domen.com',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'E-mail je obavezan.';
                    final emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Unesite ispravnu e-mail adresu (npr. ime@domen.com).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Lozinka',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    helperText: 'Min. 8 znakova, mora sadržavati cifru.',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Lozinka je obavezna.';
                    if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova.';
                    if (!RegExp(r'\d').hasMatch(v)) return 'Lozinka mora sadržavati najmanje jednu cifru.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Potvrda lozinke',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Potvrda lozinke je obavezna.';
                    if (v != _passwordController.text) return 'Lozinke se ne poklapaju.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Broj telefona',
                    prefixIcon: Icon(Icons.phone_outlined),
                    helperText: 'Format: +387XXXXXXXX ili 06XXXXXXXX',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Telefon je obavezan.';
                    final phoneRegex = RegExp(r'^\+?[\d\s\-]{8,15}$');
                    if (!phoneRegex.hasMatch(v.trim())) {
                      return 'Unesite ispravan broj telefona (npr. +38761123456).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'Broj vozačke dozvole',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Broj vozačke dozvole je obavezan.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCityId,
                  decoration: const InputDecoration(
                    labelText: 'Grad (opcionalno)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Odaberite grad'),
                    ),
                    ..._cities.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name']),
                        )),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedCityId = val),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Registracija',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}