import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/forgot_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _user;
  List<dynamic> _cities = [];
  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.get(ApiConfig.me),
        _api.get(ApiConfig.cities),
      ]);
      setState(() {
        _user = results[0];
        _cities = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

Future<void> _loadProfile() async {
  try {
    final data = await _api.get(ApiConfig.me);
    setState(() => _user = data);
  } catch (_) {}
}
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final token = await _storage.read(key: 'token');

      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path,
            filename: picked.name),
      });

      final response = await dio.post(
        '${ApiConfig.baseUrl}/api/upload/profile-image',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final imageUrl =
          '${ApiConfig.baseUrl}${response.data['url']}';

      await _api.put(ApiConfig.me, {
        'firstName': _user!['firstName'],
        'lastName': _user!['lastName'],
        'phoneNumber': _user!['phoneNumber'],
        'driverLicenseNo': _user!['driverLicenseNo'],
        'cityId': _user!['cityId'],
        'profileImageUrl': imageUrl,
      });

      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilna slika je uspješno ažurirana.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _user == null ? null : () => _showEditProfile(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text('Greška pri učitavanju profila.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildAvatar(),
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                        const SizedBox(height: 16),
                        _buildActionsCard(),
                        const SizedBox(height: 16),
                        _buildLogoutButton(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildAvatar() {
    final name = '${_user!['firstName']} ${_user!['lastName']}';
    final initials =
        '${_user!['firstName'][0]}${_user!['lastName'][0]}';
    final imageUrl = _user!['profileImageUrl'];

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
  radius: 48,
  backgroundColor: AppTheme.accent,
  backgroundImage: imageUrl != null
      ? NetworkImage('$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}')
      : null,
  child: imageUrl == null
      ? Text(
          initials.toUpperCase(),
          style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        )
      : null,
),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap:
                    _isUploadingImage ? null : _pickAndUploadImage,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingImage
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark),
        ),
        Text(
          _user!['role'] == 'Admin' ? 'Administrator' : 'Klijent',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lični podaci',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.email_outlined, 'E-mail', _user!['email']),
            if (_user!['phoneNumber'] != null)
              _buildInfoRow(Icons.phone_outlined, 'Telefon',
                  _user!['phoneNumber']),
            if (_user!['city'] != null)
              _buildInfoRow(Icons.location_city_outlined, 'Grad',
                  _user!['city']),
            _buildInfoRow(
              Icons.credit_card_outlined,
              'Vozačka dozvola',
              _user!['driverLicenseNo'] ?? 'Nije unesena',
              valueColor: _user!['driverLicenseNo'] == null
                  ? AppTheme.error
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: valueColor ?? AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistika',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today,
                    '${_user!['reservationCount']}',
                    'Rezervacija',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.payments_outlined,
                    '${_user!['totalSpent']} KM',
                    'Ukupno potrošeno',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accent, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outlined,
                color: AppTheme.accent),
            title: const Text('Promjena lozinke'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePassword,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined,
                color: AppTheme.accent),
            title: const Text('Zaboravljena lozinka'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout, color: AppTheme.error),
        label: const Text('Odjava',
            style: TextStyle(color: AppTheme.error, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Odjava'),
              content: const Text(
                  'Jeste li sigurni da se želite odjaviti?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Odjavi se'),
                ),
              ],
            ),
          );
          if (confirm == true && mounted) {
            await context.read<AuthProvider>().logout();
          }
        },
      ),
    );
  }

  void _showEditProfile() {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: _user!['firstName']);
    final lastNameController = TextEditingController(text: _user!['lastName']);
    final phoneController = TextEditingController(text: _user!['phoneNumber'] ?? '');
    final licenseController = TextEditingController(text: _user!['driverLicenseNo'] ?? '');
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    int? selectedCityId = _user!['cityId'];
    bool changePassword = false;
    bool showOldPw = false;
    bool showNewPw = false;
    bool showConfirmPw = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Uredi profil',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'Ime'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ime je obavezno.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Prezime'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Prezime je obavezno.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      helperText: 'Format: +387XXXXXXXX ili 06XXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Telefon je obavezan.';
                      if (!RegExp(r'^\+?[\d\s\-]{8,15}$').hasMatch(v.trim())) {
                        return 'Unesite ispravan broj telefona (npr. +38761123456).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: licenseController,
                    decoration: const InputDecoration(labelText: 'Broj vozačke dozvole'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedCityId,
                    decoration: const InputDecoration(
                      labelText: 'Grad',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Odaberite grad')),
                      ..._cities.map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name']),
                          )),
                    ],
                    onChanged: (val) => setModalState(() => selectedCityId = val),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Promijeni lozinku'),
                    value: changePassword,
                    onChanged: (v) => setModalState(() => changePassword = v ?? false),
                  ),
                  if (changePassword) ...[
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: !showOldPw,
                      decoration: InputDecoration(
                        labelText: 'Trenutna lozinka',
                        suffixIcon: IconButton(
                          icon: Icon(showOldPw ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setModalState(() => showOldPw = !showOldPw),
                        ),
                      ),
                      validator: (v) => changePassword && (v == null || v.isEmpty)
                          ? 'Trenutna lozinka je obavezna.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: !showNewPw,
                      decoration: InputDecoration(
                        labelText: 'Nova lozinka',
                        helperText: 'Min. 8 znakova, mora sadržavati cifru.',
                        suffixIcon: IconButton(
                          icon: Icon(showNewPw ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setModalState(() => showNewPw = !showNewPw),
                        ),
                      ),
                      validator: (v) {
                        if (!changePassword) return null;
                        if (v == null || v.isEmpty) return 'Nova lozinka je obavezna.';
                        if (v.length < 8) return 'Lozinka mora imati najmanje 8 znakova.';
                        if (!RegExp(r'\d').hasMatch(v)) return 'Lozinka mora sadržavati najmanje jednu cifru.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirmPw,
                      decoration: InputDecoration(
                        labelText: 'Potvrda nove lozinke',
                        suffixIcon: IconButton(
                          icon: Icon(showConfirmPw ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setModalState(() => showConfirmPw = !showConfirmPw),
                        ),
                      ),
                      validator: (v) {
                        if (!changePassword) return null;
                        if (v != newPasswordController.text) return 'Lozinke se ne poklapaju.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            await _api.put(ApiConfig.me, {
                              'firstName': firstNameController.text.trim(),
                              'lastName': lastNameController.text.trim(),
                              'phoneNumber': phoneController.text.trim(),
                              'driverLicenseNo': licenseController.text.trim(),
                              'cityId': selectedCityId,
                              'profileImageUrl': _user!['profileImageUrl'],
                            });
                            if (changePassword && newPasswordController.text.isNotEmpty) {
                              await _api.post('${ApiConfig.me}/change-password', {
                                'currentPassword': oldPasswordController.text,
                                'newPassword': newPasswordController.text,
                              });
                            }
                            Navigator.pop(ctx);
                            _loadProfile();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil je uspješno ažuriran.'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                            );
                          }
                        },
                        child: const Text('Sačuvaj'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePassword() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Promjena lozinke',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: currentController,
                obscureText: !showCurrent,
                decoration: InputDecoration(
                  labelText: 'Trenutna lozinka',
                  suffixIcon: IconButton(
                    icon: Icon(showCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setModalState(
                        () => showCurrent = !showCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: !showNew,
                decoration: InputDecoration(
                  labelText: 'Nova lozinka',
                  suffixIcon: IconButton(
                    icon: Icon(showNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setModalState(() => showNew = !showNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: !showConfirm,
                decoration: InputDecoration(
                  labelText: 'Potvrda nove lozinke',
                  suffixIcon: IconButton(
                    icon: Icon(showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setModalState(
                        () => showConfirm = !showConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (newController.text !=
                          confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Lozinke se ne poklapaju.'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      if (newController.text.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Nova lozinka mora imati najmanje 8 znakova.'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }
                      try {
                        await _api.post(
                            '${ApiConfig.me}/change-password', {
                          'currentPassword': currentController.text,
                          'newPassword': newController.text,
                        });
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Lozinka je uspješno promijenjena.'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
                    child: const Text('Promijeni lozinku'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}