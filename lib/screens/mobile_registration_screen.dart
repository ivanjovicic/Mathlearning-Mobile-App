import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/auth_provider.dart';

class MobileRegistrationScreen extends StatefulWidget {
  const MobileRegistrationScreen({super.key});

  @override
  State<MobileRegistrationScreen> createState() =>
      _MobileRegistrationScreenState();
}

class _MobileRegistrationScreenState extends State<MobileRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.instance.registerMobileUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );

      if (result.success) {
        if (mounted) {
          context.read<AuthProvider>().login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colorScheme.tertiary,
              duration: const Duration(seconds: 3),
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.onTertiary),
                  const SizedBox(width: 12),
                  Text(
                    'Registracija uspesna! Dobrodosao/la!',
                    style: TextStyle(color: colorScheme.onTertiary),
                  ),
                ],
              ),
            ),
          );
          Navigator.of(context).pushReplacementNamed("/home");
        }
      } else {
        setState(() {
          _errorMessage = _localizeRegistrationError(result.error);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _localizeRegistrationError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 48,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kreiraj nalog',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pridruzi se zajednici za ucenje matematike!',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _textField(
                  controller: _displayNameController,
                  labelText: 'Prikazano ime',
                  prefixIcon: Icons.badge,
                  colorScheme: colorScheme,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesi prikazano ime';
                    }
                    if (value.trim().length < 2) {
                      return 'Prikazano ime mora imati najmanje 2 karaktera';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _usernameController,
                  labelText: 'Korisnicko ime',
                  prefixIcon: Icons.person,
                  colorScheme: colorScheme,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesi korisnicko ime';
                    }
                    if (value.trim().length < 3) {
                      return 'Korisnicko ime mora imati najmanje 3 karaktera';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                      return 'Koristi samo slova, brojeve i donju crtu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _emailController,
                  labelText: 'Imejl',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  colorScheme: colorScheme,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unesi imejl';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Unesi ispravnu imejl adresu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _passwordController,
                  labelText: 'Lozinka',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  colorScheme: colorScheme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Unesi lozinku';
                    }
                    if (value.length < 6) {
                      return 'Lozinka mora imati najmanje 6 karaktera';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _confirmPasswordController,
                  labelText: 'Potvrdi lozinku',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  colorScheme: colorScheme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Potvrdi lozinku';
                    }
                    if (value != _passwordController.text) {
                      return 'Lozinke se ne poklapaju';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      border: Border.all(color: colorScheme.error),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Kreiraj nalog',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Vec imas nalog? ',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Prijavi se',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    border: Border.all(color: colorScheme.tertiary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: colorScheme.tertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonus dobrodoslice!',
                              style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Dobijas 100 zlatnika za pocetak ucenja',
                              style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      validator: validator,
    );
  }

  String _localizeRegistrationError(String? rawError) {
    final raw = (rawError ?? '').trim();
    if (raw.isEmpty) {
      return 'Registracija nije uspela. Pokusaj ponovo.';
    }

    final value = raw.toLowerCase();
    if (value.contains('username') &&
        (value.contains('exists') ||
            value.contains('taken') ||
            value.contains('already'))) {
      return 'Korisnicko ime je zauzeto.';
    }
    if (value.contains('email') &&
        (value.contains('exists') ||
            value.contains('taken') ||
            value.contains('already'))) {
      return 'Imejl adresa je vec zauzeta.';
    }
    if (value.contains('invalid email') || value.contains('email is invalid')) {
      return 'Imejl adresa nije ispravna.';
    }
    if (value.contains('password') && value.contains('weak')) {
      return 'Lozinka je preslaba.';
    }
    if (value.contains('timeout') ||
        value.contains('socket') ||
        value.contains('network') ||
        value.contains('connection')) {
      return 'Greska u mrezi. Pokusaj ponovo.';
    }
    if (value.contains('registration failed') ||
        value.contains('mobile registration failed')) {
      return 'Registracija nije uspela. Pokusaj ponovo.';
    }

    // Keep backend message only when it already looks localized.
    final looksLocalized =
        value.contains('nije') ||
        value.contains('gresk') ||
        value.contains('uspes') ||
        value.contains('lozink') ||
        value.contains('korisnick');
    return looksLocalized
        ? raw
        : 'Registracija trenutno nije uspela. Pokusaj ponovo.';
  }
}
