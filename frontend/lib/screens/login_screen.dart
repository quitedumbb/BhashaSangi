import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';

enum AuthTab { login, register }

class LoginScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const LoginScreen({super.key, required this.onNavigate});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthTab _currentTab = AuthTab.login;

  // Login Controllers
  final TextEditingController _loginUsernameController = TextEditingController(text: 'sunita');
  final TextEditingController _loginPasswordController = TextEditingController(text: 'password123');

  // Register Controllers
  final TextEditingController _regFullNameController = TextEditingController();
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regSchoolController = TextEditingController(text: 'Govt. Primary School');
  final TextEditingController _regDistrictController = TextEditingController(text: 'Dumka');
  final TextEditingController _regStateController = TextEditingController(text: 'Jharkhand');
  String _regGrade = 'Classes 1 - 8';

  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regSchoolController.dispose();
    _regDistrictController.dispose();
    _regStateController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.instance.login(
      username: username,
      password: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Welcome back!',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: ClassroomColors.earthySage,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed. Please check credentials.'),
          backgroundColor: ClassroomColors.errorRust,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    final fullName = _regFullNameController.text.trim();
    final username = _regUsernameController.text.trim();
    final password = _regPasswordController.text.trim();

    if (fullName.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Full Name, Username, and Password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.instance.register(
      username: username,
      fullName: fullName,
      password: password,
      email: _regEmailController.text.trim(),
      schoolName: _regSchoolController.text.trim(),
      district: _regDistrictController.text.trim(),
      state: _regStateController.text.trim(),
      primaryGrade: _regGrade,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Teacher registered & saved into MySQL + SQLite! Welcome, $fullName.',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: ClassroomColors.earthySage,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registration failed.'),
          backgroundColor: ClassroomColors.errorRust,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleLogout() {
    AuthService.instance.logout();
    setState(() => _currentTab = AuthTab.login);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged out successfully. You can sign in with another account.',
          style: GoogleFonts.notoSans(color: Colors.white),
        ),
        backgroundColor: ClassroomColors.slateChalkboard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _fillDemoCredentials() {
    setState(() {
      _currentTab = AuthTab.login;
      _loginUsernameController.text = 'sunita';
      _loginPasswordController.text = 'password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final isAuth = AuthService.instance.isAuthenticated;
        final teacher = AuthService.instance.currentTeacher;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cultural Header Badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ClassroomColors.terracotta,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: ClassroomColors.terracotta.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Teacher Classroom Portal',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dual MySQL & Local SQLite Database Authentication',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: ClassroomColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // If logged in: Show Teacher Profile Card
                  if (isAuth && teacher != null) ...[
                    _buildActiveTeacherCard(teacher),
                  ] else ...[
                    // Tab Bar: Login vs Register
                    _buildAuthTabBar(),

                    const SizedBox(height: 18),

                    // Active Form (Login or Register)
                    if (_currentTab == AuthTab.login)
                      _buildLoginForm()
                    else
                      _buildRegisterForm(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = AuthTab.login),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentTab == AuthTab.login ? ClassroomColors.terracotta : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      size: 16,
                      color: _currentTab == AuthTab.login ? Colors.white : ClassroomColors.textDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Log In (लॉग इन)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _currentTab == AuthTab.login ? FontWeight.w700 : FontWeight.w500,
                        color: _currentTab == AuthTab.login ? Colors.white : ClassroomColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = AuthTab.register),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _currentTab == AuthTab.register ? ClassroomColors.terracotta : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 16,
                      color: _currentTab == AuthTab.register ? Colors.white : ClassroomColors.textDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Register (पंजीकरण)',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: _currentTab == AuthTab.register ? FontWeight.w700 : FontWeight.w500,
                        color: _currentTab == AuthTab.register ? Colors.white : ClassroomColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClassroomColors.borderWarm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Teacher Login',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              TextButton.icon(
                onPressed: _fillDemoCredentials,
                icon: const Icon(Icons.flash_on_rounded, size: 15, color: ClassroomColors.marigoldDark),
                label: Text(
                  'Fill Demo (Sunita)',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: ClassroomColors.marigoldDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Username
          Text('Username or Email', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
          const SizedBox(height: 6),
          TextField(
            controller: _loginUsernameController,
            decoration: const InputDecoration(
              hintText: 'e.g. sunita or sunita.soren@primary.edu.in',
              prefixIcon: Icon(Icons.account_circle_outlined, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          Text('Password', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
          const SizedBox(height: 6),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClassroomColors.terracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login_rounded, color: Colors.white),
              label: Text(
                _isLoading ? 'Authenticating…' : 'Log In & Load Classroom',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sync note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClassroomColors.warmParchment.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync_rounded, size: 16, color: ClassroomColors.earthySage),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Online accounts sync with MySQL; offline sessions run on local SQLite.',
                    style: GoogleFonts.notoSans(fontSize: 11, color: ClassroomColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClassroomColors.borderWarm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Teacher Registration',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ClassroomColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Register and save teacher credentials into central MySQL & local SQLite.',
            style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Full Name
          Text('Full Name *', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
          const SizedBox(height: 4),
          TextField(
            controller: _regFullNameController,
            decoration: const InputDecoration(hintText: 'e.g. Ramesh Tudu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline, size: 20)),
          ),
          const SizedBox(height: 12),

          // Username & Email Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Username *', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regUsernameController,
                      decoration: const InputDecoration(hintText: 'e.g. ramesh_tudu', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email (Optional)', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regEmailController,
                      decoration: const InputDecoration(hintText: 'ramesh@primary.edu.in', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Password
          Text('Password *', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
          const SizedBox(height: 4),
          TextField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            decoration: InputDecoration(
              hintText: '••••••••',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPassword ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // School & District
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('School Name', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regSchoolController,
                      decoration: const InputDecoration(hintText: 'Govt. Primary School', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('District', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regDistrictController,
                      decoration: const InputDecoration(hintText: 'Dumka / Khunti', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // State & Assigned Class Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('State', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _regStateController,
                      decoration: const InputDecoration(hintText: 'Jharkhand', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Grades', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: ClassroomColors.textDark)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _regGrade,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                      items: const [
                        DropdownMenuItem(value: 'Classes 1 - 8', child: Text('Classes 1 - 8')),
                        DropdownMenuItem(value: 'Class 1', child: Text('Class 1')),
                        DropdownMenuItem(value: 'Class 2', child: Text('Class 2')),
                        DropdownMenuItem(value: 'Class 3', child: Text('Class 3')),
                        DropdownMenuItem(value: 'Classes 4 - 5', child: Text('Classes 4 - 5')),
                        DropdownMenuItem(value: 'Classes 6 - 8', child: Text('Classes 6 - 8')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _regGrade = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClassroomColors.earthySage,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _handleRegister,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.how_to_reg_rounded, color: Colors.white),
              label: Text(
                _isLoading ? 'Registering…' : 'Register & Save in MySQL + SQLite',
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTeacherCard(TeacherProfile teacher) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: ClassroomColors.terracottaLight,
                child: Text(
                  teacher.fullName.isNotEmpty ? teacher.fullName.substring(0, 1) : 'T',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ClassroomColors.terracottaDark,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.textDark,
                      ),
                    ),
                    Text(
                      teacher.emailOrUsername,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: ClassroomColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ClassroomColors.sageLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: ClassroomColors.earthySage),
                    const SizedBox(width: 4),
                    Text(
                      'Authenticated',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.sageDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildProfileRow('School:', teacher.schoolName),
          const SizedBox(height: 8),
          _buildProfileRow('District & State:', '${teacher.district}, ${teacher.state}'),
          const SizedBox(height: 8),
          _buildProfileRow('Assigned Grades:', teacher.primaryGrade),
          const SizedBox(height: 14),

          // Database sync badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ClassroomColors.sageLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage_rounded, size: 16, color: ClassroomColors.earthySage),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Teacher Profile synchronized with MySQL & Local SQLite Database.',
                    style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: ClassroomColors.earthySage),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ClassroomColors.errorRust,
                    side: const BorderSide(color: ClassroomColors.errorRust),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onNavigate(AppRouteItem.home),
                  icon: const Icon(Icons.dashboard_rounded, size: 16, color: Colors.white),
                  label: const Text('Classroom Home', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClassroomColors.terracotta,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ClassroomColors.textSubtle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ClassroomColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
