import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const SettingsScreen({super.key, required this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  bool _highContrast = false;
  bool _largeText = false;
  bool _subtleAnimations = true;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testAndSaveUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    ApiConfig.setBaseUrl(newUrl);
    final health = await _apiService.checkHealth();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = health.isConnected;
        _testMessage = health.isConnected
            ? 'Success: Connected! (${health.message})'
            : 'Connection Failed: ${health.error ?? health.message}';
      });

      ClassroomState.instance.refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ClassroomState.instance,
      builder: (context, _) {
        final state = ClassroomState.instance;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ClassroomColors.terracottaLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: ClassroomColors.terracotta,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Classroom Settings & Preferences',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure backend connection, default vernacular teaching dialects, and accessibility options.',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: ClassroomColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. BACKEND API BASE URL CONFIGURATION
                  _buildBackendConfigCard(state),

                  const SizedBox(height: 24),

                  // 2. DEFAULT LANGUAGE PREFERENCES
                  _buildLanguagePreferencesCard(state),

                  const SizedBox(height: 24),

                  // 3. ACCESSIBILITY & DISPLAY
                  _buildAccessibilityCard(),

                  const SizedBox(height: 24),

                  // 4. ABOUT BHASHA SANGI
                  _buildAboutCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackendConfigCard(ClassroomState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_rounded, color: ClassroomColors.terracotta, size: 20),
              const SizedBox(width: 10),
              Text(
                'Classroom Backend API Configuration',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Centralized API base URL used for all HTTP calls. Switch easily between local development, intranet server, or cloud hosting.',
            style: GoogleFonts.notoSans(fontSize: 13, color: ClassroomColors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: GoogleFonts.firaCode(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'http://127.0.0.1:8000',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testAndSaveUrl,
                icon: _isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 16),
                label: Text(_isTesting ? 'Testing…' : 'Apply & Test'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ],
          ),
          if (_testMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? ClassroomColors.sageLight
                    : ClassroomColors.terracottaLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _testMessage!,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _testSuccess
                      ? ClassroomColors.sageDark
                      : ClassroomColors.terracottaDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguagePreferencesCard(ClassroomState state) {
    final languages = state.languages;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate_rounded, color: ClassroomColors.earthySage, size: 20),
              const SizedBox(width: 10),
              Text(
                'Default Teaching Language Pairing',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Languages loaded dynamically from GET /languages. Select default source and target for one-click translation sessions.',
            style: GoogleFonts.notoSans(fontSize: 13, color: ClassroomColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (languages.isEmpty)
            Text(
              'No languages loaded yet. Connect to the backend to configure defaults.',
              style: GoogleFonts.notoSans(color: ClassroomColors.textSubtle),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Source Language',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: state.selectedSourceLanguage?.id,
                        decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                        items: languages.map((l) {
                          return DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.languageName} (${l.nativeName})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final lang = languages.firstWhere((l) => l.id == val);
                            state.selectSourceLanguage(lang);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Target Vernacular',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.earthySage,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: state.selectedTargetLanguage?.id,
                        decoration: const InputDecoration(filled: true, fillColor: Colors.white),
                        items: languages.map((l) {
                          return DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.languageName} (${l.nativeName})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final lang = languages.firstWhere((l) => l.id == val);
                            state.selectTargetLanguage(lang);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessibilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.accessibility_new_rounded, color: ClassroomColors.marigoldDark, size: 20),
              const SizedBox(width: 10),
              Text(
                'Classroom Accessibility & Display',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Display adjustments calibrated for high readability on primary school tablets and projectors.',
            style: GoogleFonts.notoSans(fontSize: 13, color: ClassroomColors.textMuted),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              'High Contrast Text Mode',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Increases contrast between text and parchment cards for sunlight visibility in rural classrooms.',
              style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
            ),
            value: _highContrast,
            activeThumbColor: ClassroomColors.terracotta,
            onChanged: (val) => setState(() => _highContrast = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(
              'Large Classroom Typography',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Enlarges font sizes for blackboard or tablet display to young learners.',
              style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
            ),
            value: _largeText,
            activeThumbColor: ClassroomColors.terracotta,
            onChanged: (val) => setState(() => _largeText = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(
              'Subtle Micro-Interactions',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Gentle hover elevations and transitions for an organic paper-like feel.',
              style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
            ),
            value: _subtleAnimations,
            activeThumbColor: ClassroomColors.terracotta,
            onChanged: (val) => setState(() => _subtleAnimations = val),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ClassroomColors.warmParchment.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ClassroomColors.terracotta,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'About Bhasha Sangi (भाषा संगी)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“AI powered vernacular pedagogy and real time translation tool for mother tongue based primary education.”\n\n'
            'Designed specifically for primary school teachers to bridge standard state syllabus textbooks with local tribal and regional mother tongues (such as Santali in Ol Chiki, Ho in Warang Chiti, Mundari, and allied languages). Built with an earthy, welcoming Indian classroom aesthetic aligned with the National Education Policy (NEP) 2020.',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: ClassroomColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
