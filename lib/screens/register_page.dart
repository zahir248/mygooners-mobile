import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;
  bool _acceptTerms = false;
  String? _errorMessage;
  Map<String, List<String>>? _fieldErrors;

  final AuthService _authService = AuthService();
  // Configure Google Sign-In with Android Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: ApiConfig.googleAndroidClientId,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Sila terima Syarat Perkhidmatan dan Dasar Privasi untuk meneruskan.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = null;
    });

    try {
      final result = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );

      if (result['success']) {
        // Save user token and info
        final prefs = await SharedPreferences.getInstance();
        if (result['token'] != null) {
          await prefs.setString('auth_token', result['token']);
        }
        
        // Save user info
        if (result['user'] != null) {
          final user = result['user'] as Map<String, dynamic>;
          await prefs.setString('user_name', user['name'] ?? '');
          await prefs.setString('user_email', user['email'] ?? '');
        }

        if (mounted) {
          // Show success message and navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berjaya! Selamat datang ke MyGooners!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Pendaftaran gagal. Sila cuba lagi.';
          _fieldErrors = result['errors'] as Map<String, List<String>>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ralat berlaku. Sila semak sambungan internet anda.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is already signed in, if so sign out to force account picker
      final currentUser = await _googleSignIn.signInSilently();
      if (currentUser != null) {
        await _googleSignIn.signOut();
      }
      
      // Sign in with Google (this will show account picker)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Validate that we have required fields
      if (googleUser.id.isEmpty || googleUser.email.isEmpty) {
        setState(() {
          _errorMessage = 'Maklumat Google tidak lengkap. Sila cuba lagi.';
          _isLoading = false;
        });
        return;
      }

      // Send user info to backend
      final result = await _authService.loginWithGoogle(
        googleId: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? googleUser.email.split('@')[0],
        photoUrl: googleUser.photoUrl,
      );

      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        if (result['token'] != null) {
          await prefs.setString('auth_token', result['token']);
        }
        
        // Save user info
        if (result['user'] != null) {
          final user = result['user'] as Map<String, dynamic>;
          await prefs.setString('user_name', user['name'] ?? '');
          await prefs.setString('user_email', user['email'] ?? '');
        }

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Log masuk Google gagal.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ralat berlaku semasa log masuk dengan Google: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildGoogleIcon() {
    return Image.network(
      'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to a simple colored circle with "G" if image fails to load
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4285F4), // Blue
                Color(0xFFEA4335), // Red
                Color(0xFFFBBC05), // Yellow
                Color(0xFF34A853), // Green
              ],
              stops: [0.0, 0.33, 0.66, 1.0],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTermsModal() {
    showDialog(
      context: context,
      builder: (context) => _TermsModal(),
    );
  }

  void _showPrivacyModal() {
    showDialog(
      context: context,
      builder: (context) => _PrivacyModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/hero-section.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
          ),
          child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                        label: const Text('Back', style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register Card
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width > 400 ? 32.0 : 24.0,
                          vertical: 32.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            const Text(
                              'Sertai komuniti Arsenal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Menjadi sebahagian daripada keluarga MyGooners',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Name field
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Nama Penuh',
                                hintText: 'Nama penuh anda',
                                prefixIcon: const Icon(Icons.person_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                errorText: _fieldErrors?['name']?.first,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Sila masukkan nama penuh';
                                }
                                if (value.length < 2) {
                                  return 'Nama mesti sekurang-kurangnya 2 aksara';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Alamat Emel',
                                hintText: 'emel@anda.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                errorText: _fieldErrors?['email']?.first,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Sila masukkan alamat emel';
                                }
                                if (!value.contains('@')) {
                                  return 'Sila masukkan alamat emel yang sah';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Kata Laluan',
                                hintText: 'Pilih kata laluan yang kuat',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                errorText: _fieldErrors?['password']?.first,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Sila masukkan kata laluan';
                                }
                                if (value.length < 6) {
                                  return 'Kata laluan mesti sekurang-kurangnya 6 aksara';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password confirmation field
                            TextFormField(
                              controller: _passwordConfirmationController,
                              obscureText: _obscurePasswordConfirmation,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleRegister(),
                              decoration: InputDecoration(
                                labelText: 'Sahkan Kata Laluan',
                                hintText: 'Sahkan kata laluan anda',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePasswordConfirmation
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePasswordConfirmation = !_obscurePasswordConfirmation;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Sila sahkan kata laluan';
                                }
                                if (value != _passwordController.text) {
                                  return 'Kata laluan tidak sepadan';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Terms and Privacy checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.red[600],
                                ),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'Saya bersetuju dengan ',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      GestureDetector(
                                        onTap: _showTermsModal,
                                        child: Text(
                                          'Syarat Perkhidmatan',
                                          style: TextStyle(
                                            color: Colors.red[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        ' dan ',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      GestureDetector(
                                        onTap: _showPrivacyModal,
                                        child: Text(
                                          'Dasar Privasi',
                                          style: TextStyle(
                                            color: Colors.red[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Register button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.person_add_outlined, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Cipta Akaun',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Atau teruskan dengan',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Google login button
                            Center(
                              child: InkWell(
                                onTap: _isLoading ? null : _handleGoogleLogin,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _buildGoogleIcon(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login link
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Sudah mempunyai akaun? ',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacementNamed('/login');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Log masuk di sini',
                                    style: TextStyle(
                                      color: Colors.red[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

// Terms of Service Modal
class _TermsModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Syarat Perkhidmatan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '1. Penerimaan Syarat',
                      'Dengan menggunakan platform MyGooners, anda bersetuju untuk mematuhi semua syarat dan terma yang dinyatakan di sini. Jika anda tidak bersetuju dengan mana-mana bahagian syarat ini, sila jangan gunakan perkhidmatan kami.',
                    ),
                    _buildSection(
                      '2. Penggunaan Platform',
                      'MyGooners adalah platform komuniti Arsenal yang menyediakan perkhidmatan marketplace untuk produk dan perkhidmatan berkaitan Arsenal. Pengguna boleh membeli, menjual, dan berinteraksi dalam komuniti yang selamat dan mesra.',
                    ),
                    _buildSection(
                      '3. Akaun Pengguna',
                      'Anda bertanggungjawab untuk mengekalkan kerahsiaan akaun anda dan kata laluan. Semua aktiviti yang berlaku di bawah akaun anda adalah tanggungjawab anda. Beritahu kami dengan segera jika anda mengesyaki sebarang penggunaan yang tidak dibenarkan.',
                    ),
                    _buildSection(
                      '4. Kandungan Pengguna',
                      'Pengguna bertanggungjawab untuk semua kandungan yang mereka muat naik, termasuk ulasan, gambar, dan maklumat produk. Kandungan mesti mematuhi garis panduan komuniti dan tidak boleh mengandungi bahan yang menyinggung, memfitnah, atau melanggar hak cipta.',
                    ),
                    _buildSection(
                      '5. Transaksi dan Pembayaran',
                      'Semua transaksi dijalankan melalui sistem pembayaran yang selamat. MyGooners bertindak sebagai perantara dan tidak bertanggungjawab untuk sebarang pertikaian antara pembeli dan penjual. Pengguna digalakkan untuk menyelesaikan sebarang isu secara aman.',
                    ),
                    _buildSection(
                      '6. Penggantungan dan Penamatan',
                      'Kami berhak untuk menggantung atau menamatkan akaun pengguna yang melanggar syarat perkhidmatan. Penggantungan boleh dilakukan tanpa notis awal jika terdapat pelanggaran serius terhadap garis panduan komuniti.',
                    ),
                    _buildSection(
                      '7. Pindaan Syarat',
                      'Kami berhak untuk mengubah suai syarat perkhidmatan pada bila-bila masa. Perubahan akan diberitahu kepada pengguna melalui platform atau emel. Penggunaan berterusan selepas perubahan dianggap sebagai penerimaan syarat baharu.',
                    ),
                    _buildSection(
                      '8. Hubungi Kami',
                      'Jika anda mempunyai sebarang pertanyaan mengenai syarat perkhidmatan, sila hubungi pasukan sokongan kami melalui emel atau borang hubungan yang disediakan di platform.',
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Privacy Policy Modal
class _PrivacyModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dasar Privasi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '1. Maklumat Yang Kami Kumpul',
                      'Kami mengumpul maklumat yang anda berikan secara langsung, seperti nama, alamat emel, dan maklumat profil. Kami juga mengumpul maklumat secara automatik melalui cookies dan teknologi serupa untuk meningkatkan pengalaman pengguna.',
                    ),
                    _buildSection(
                      '2. Penggunaan Maklumat',
                      'Maklumat yang dikumpul digunakan untuk menyediakan, mengekalkan, dan meningkatkan perkhidmatan kami; memproses transaksi; menghantar notifikasi penting; dan memberikan sokongan pelanggan. Kami tidak menjual, menyewa, atau berkongsi maklumat peribadi anda dengan pihak ketiga tanpa kebenaran anda.',
                    ),
                    _buildSection(
                      '3. Keselamatan Data',
                      'Kami melaksanakan langkah-langkah keselamatan teknikal dan organisasi yang sesuai untuk melindungi maklumat peribadi anda daripada akses, penggunaan, atau pendedahan yang tidak dibenarkan. Data anda dienkripsi semasa penghantaran dan penyimpanan.',
                    ),
                    _buildSection(
                      '4. Cookies dan Teknologi Serupa',
                      'Kami menggunakan cookies dan teknologi serupa untuk mengingati pilihan anda, memahami bagaimana anda menggunakan platform kami, dan menyesuaikan kandungan. Anda boleh mengawal penggunaan cookies melalui tetapan pelayar anda.',
                    ),
                    _buildSection(
                      '5. Perkongsian Maklumat',
                      'Kami mungkin berkongsi maklumat anda dalam situasi tertentu, seperti mematuhi undang-undang, melindungi hak dan keselamatan kami, atau dengan kebenaran anda. Kami tidak berkongsi maklumat peribadi untuk tujuan pemasaran tanpa kebenaran eksplisit.',
                    ),
                    _buildSection(
                      '6. Hak Pengguna',
                      'Anda mempunyai hak untuk mengakses, membetulkan, atau memadamkan maklumat peribadi anda. Anda juga boleh menarik balik kebenaran untuk pemprosesan data pada bila-bila masa. Untuk melaksanakan hak ini, sila hubungi pasukan sokongan kami.',
                    ),
                    _buildSection(
                      '7. Penyimpanan Data',
                      'Kami menyimpan maklumat peribadi anda selagi diperlukan untuk menyediakan perkhidmatan atau mematuhi kewajipan undang-undang. Apabila data tidak lagi diperlukan, kami akan memadamkannya dengan selamat atau menganonimkannya.',
                    ),
                    _buildSection(
                      '8. Pindaan Dasar',
                      'Kami mungkin mengemas kini dasar privasi ini dari semasa ke semasa. Perubahan ketara akan diberitahu kepada anda melalui platform atau emel. Kami menggalakkan anda untuk mengkaji dasar ini secara berkala.',
                    ),
                    _buildSection(
                      '9. Hubungi Kami',
                      'Jika anda mempunyai sebarang pertanyaan mengenai dasar privasi kami atau cara kami memproses maklumat peribadi anda, sila hubungi pegawai perlindungan data kami melalui emel atau borang hubungan yang disediakan.',
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
