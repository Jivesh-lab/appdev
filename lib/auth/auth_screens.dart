import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// AuthScreen — Login / Signup entry point
/// Called from main.dart when no user is logged in.
/// On success, calls [onLoginSuccess] with the authenticated User and role.
class AuthScreen extends StatefulWidget {
  final Function(User user, String role) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D5BFF), Color(0xFF4A90E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5BFF).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'ClassPulse',
                  style: TextStyle(
                    color: Color(0xFF2D5BFF),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Live classroom comprehension tool',
                  style: TextStyle(
                    color: Color(0xFF7A8BA3),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 40),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF7A8BA3),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    indicator: BoxDecoration(
                      color: const Color(0xFF2D5BFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 480,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _LoginForm(onLoginSuccess: widget.onLoginSuccess),
                      _SignupForm(onLoginSuccess: widget.onLoginSuccess),
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
}

// ─── Login Form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final Function(User user, String role) onLoginSuccess;
  const _LoginForm({required this.onLoginSuccess});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'teacher';
  bool _isLoading = false;
  String _error = '';
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = await apiService.authenticateUser(
        email,
        pass,
        role: _role,
      );

      if (!mounted) return;

      if (user != null) {
        widget.onLoginSuccess(user, user.role);
      } else {
        setState(() => _error = 'Invalid email or password');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      children: [
        // Role toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: ['teacher', 'student'].map((r) {
              final selected = _role == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2D5BFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r == 'teacher' ? '👨‍🏫 Teacher' : '🎓 Student',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF7A8BA3),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        _InputField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _InputField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF7A8BA3), size: 20),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _error),
        ],

        const SizedBox(height: 24),

        _SubmitButton(
          label: 'Login',
          isLoading: _isLoading,
          onPressed: _login,
        ),
      ],
    );
  }
}

// ─── Sign Up Form ─────────────────────────────────────────────────────────────

class _SignupForm extends StatefulWidget {
  final Function(User user, String role) onLoginSuccess;
  const _SignupForm({required this.onLoginSuccess});

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'teacher';
  bool _isLoading = false;
  String _error = '';
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = await apiService.registerUser(name, email, pass, role: _role);

      if (!mounted) return;

      if (user != null) {
        // Auto-login after signup
        final loggedIn = await apiService.authenticateUser(email, pass, role: _role);
        if (mounted && loggedIn != null) {
          widget.onLoginSuccess(loggedIn, loggedIn.role);
        } else {
          setState(() => _error = 'Account created! Please log in.');
        }
      } else {
        setState(() => _error = 'Email already registered or invalid');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      children: [
        // Role toggle
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: ['teacher', 'student'].map((r) {
              final selected = _role == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2D5BFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      r == 'teacher' ? '👨‍🏫 Teacher' : '🎓 Student',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF7A8BA3),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        _InputField(
          controller: _nameCtrl,
          label: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _InputField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _InputField(
          controller: _passCtrl,
          label: 'Password (min 6 chars)',
          icon: Icons.lock_outline,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF7A8BA3), size: 20),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: _error),
        ],

        const SizedBox(height: 24),

        _SubmitButton(
          label: 'Create Account',
          isLoading: _isLoading,
          onPressed: _signup,
        ),
      ],
    );
  }
}

// ─── Shared UI Widgets ────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A2340)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A8BA3), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF2D5BFF), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF4F7FE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E6F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E6F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D5BFF), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF5350).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF5350), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5BFF),
          elevation: 6,
          shadowColor: const Color(0xFF2D5BFF).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
