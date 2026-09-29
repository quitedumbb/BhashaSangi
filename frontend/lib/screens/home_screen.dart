import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/voice_translate_dialog.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  void _showSpeakNotice(BuildContext context) {
    VoiceTranslateDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO SECTION
              _buildHeroSection(context),

              const SizedBox(height: 24),

              // PROMINENT COMPACT "SPEAK & TRANSLATE" ONE-TAP ACTION
              _buildSpeakAndTranslateAction(context),

              const SizedBox(height: 36),

              // "YOUR CLASSROOM" SECTION HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Classroom',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: ClassroomColors.textDark,
                          ),
                        ),
                        Text(
                          'Vernacular learning tools calibrated for primary education',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: ClassroomColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: ClassroomColors.terracotta),
                    tooltip: 'Refresh classroom data',
                    onPressed: () => ClassroomState.instance.refreshAll(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // "YOUR CLASSROOM" DASHBOARD CARDS
              _buildDashboardCards(context),

              const SizedBox(height: 36),

              // TEACHER PEDAGOGY GUIDANCE STRIP
              _buildPedagogyNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ClassroomColors.terracotta.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ClassroomColors.sageLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 15,
                      color: ClassroomColors.earthySage,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NEP 2020 Aligned • Mother Tongue Primary Instruction',
                      style: ClassroomTheme.highlightFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.earthySage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Teach in their language.\nHelp them learn with confidence.',
                style: GoogleFonts.poppins(
                  fontSize: isNarrow ? 24 : 32,
                  fontWeight: FontWeight.w800,
                  color: ClassroomColors.textDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Bhasha Sangi bridges textbooks and tribal mother tongues in primary classrooms. Empower teachers to deliver lessons in regional vernacular dialects like Santali, Ho, and Mundari with clear pedagogical support.',
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  color: ClassroomColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpeakAndTranslateAction(BuildContext context) {
    return InkWell(
      onTap: () => _showSpeakNotice(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: ClassroomColors.terracottaLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ClassroomColors.terracotta.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ClassroomColors.terracotta.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ClassroomColors.terracotta,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ClassroomColors.terracotta.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'SPEAK & TRANSLATE',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.terracottaDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClassroomColors.marigoldLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Bhashini Voice AI (ASR + TTS)',
                          style: ClassroomTheme.highlightFont(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: ClassroomColors.earthySage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Speak in your language • Listen to vernacular mother tongue pronunciation',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: ClassroomColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: ClassroomColors.terracotta,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    return AnimatedBuilder(
      animation: ClassroomState.instance,
      builder: (context, _) {
        final state = ClassroomState.instance;
        final languageCount = state.languages.length;
        final translationCount = state.translations.length;
        final isConnected = state.isBackendConnected;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            final isDesktop = constraints.maxWidth > 960;

            final cardWidth = isDesktop
                ? (constraints.maxWidth - 32) / 3
                : isWide
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // 1. Languages Available
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Languages Available',
                  subtitle: isConnected
                      ? '$languageCount vernacular ${languageCount == 1 ? 'language' : 'languages'} active'
                      : 'Catalog offline',
                  badgeText: isConnected ? '$languageCount Languages' : 'Offline',
                  badgeColor: isConnected
                      ? ClassroomColors.sageLight
                      : ClassroomColors.marigoldLight,
                  badgeTextColor: isConnected
                      ? ClassroomColors.sageDark
                      : ClassroomColors.marigoldDark,
                  icon: Icons.translate_rounded,
                  iconBgColor: ClassroomColors.sageLight,
                  iconColor: ClassroomColors.earthySage,
                  actionText: 'Browse Languages',
                  onTap: () => onNavigate(AppRouteItem.languages),
                ),

                // 2. Translation Library
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Translation Library',
                  subtitle: isConnected
                      ? '$translationCount classroom ${translationCount == 1 ? 'lesson' : 'lessons'} recorded'
                      : 'Connecting to database…',
                  badgeText: isConnected ? '$translationCount Saved' : 'Pending Sync',
                  badgeColor: isConnected
                      ? ClassroomColors.terracottaLight
                      : ClassroomColors.warmParchment,
                  badgeTextColor: ClassroomColors.terracottaDark,
                  icon: Icons.library_books_rounded,
                  iconBgColor: ClassroomColors.terracottaLight,
                  iconColor: ClassroomColors.terracotta,
                  actionText: 'Open Library',
                  onTap: () => onNavigate(AppRouteItem.lessons),
                ),

                // 3. Quick Translate
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Quick Translate',
                  subtitle: 'Compose & adapt lessons into local scripts and dialects',
                  badgeText: 'Active Tool',
                  badgeColor: ClassroomColors.marigoldLight,
                  badgeTextColor: ClassroomColors.marigoldDark,
                  icon: Icons.edit_note_rounded,
                  iconBgColor: ClassroomColors.marigoldLight,
                  iconColor: ClassroomColors.marigoldDark,
                  actionText: 'Start Translation',
                  onTap: () => onNavigate(AppRouteItem.translate),
                ),

                // 4. Class 3 Chapter Notes & AI Study Material
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Class 3 Chapter Notes (AI)',
                  subtitle: 'JCERT Science (EVS) & English notes, vocabulary, activities, and voice audio',
                  badgeText: 'AI Study Material',
                  badgeColor: ClassroomColors.sageLight,
                  badgeTextColor: ClassroomColors.sageDark,
                  icon: Icons.menu_book_rounded,
                  iconBgColor: ClassroomColors.sageLight,
                  iconColor: ClassroomColors.earthySage,
                  actionText: 'Open Chapter Notes',
                  onTap: () => onNavigate(AppRouteItem.worksheets),
                ),

                // 5. Notes Downloads & PDFs
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Notes Downloads & PDFs',
                  subtitle: 'Download Class 3 chapter notes and teacher speech sessions as printable PDFs',
                  badgeText: 'PDF Export Ready',
                  badgeColor: ClassroomColors.terracottaLight,
                  badgeTextColor: ClassroomColors.terracottaDark,
                  icon: Icons.download_for_offline_rounded,
                  iconBgColor: ClassroomColors.sageLight,
                  iconColor: ClassroomColors.earthySage,
                  actionText: 'Open Downloads',
                  onTap: () => onNavigate(AppRouteItem.downloads),
                ),

                // 6. Daily Learning Cards (Santali & Hindi)
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Daily Learning Cards',
                  subtitle: '10 words daily • English to Santali (Ol Chiki) & Hindi • Bhashini Voice Pronunciation',
                  badgeText: '10 Words / Day',
                  badgeColor: ClassroomColors.marigoldLight,
                  badgeTextColor: ClassroomColors.marigoldDark,
                  icon: Icons.style_rounded,
                  iconBgColor: ClassroomColors.marigoldLight,
                  iconColor: ClassroomColors.marigoldDark,
                  actionText: 'Practice Flashcards',
                  onTap: () => onNavigate(AppRouteItem.learningCards),
                ),

                // 7. Sync Status
                _ClassroomDashboardCard(
                  width: cardWidth,
                  title: 'Sync Status',
                  subtitle: isConnected
                      ? 'FastAPI server online & responsive'
                      : 'Server connection requires verification',
                  badgeText: isConnected ? 'Online' : 'Check Server',
                  badgeColor: isConnected
                      ? ClassroomColors.sageLight
                      : ClassroomColors.terracottaLight,
                  badgeTextColor: isConnected
                      ? ClassroomColors.sageDark
                      : ClassroomColors.terracottaDark,
                  icon: Icons.sync_rounded,
                  iconBgColor: ClassroomColors.warmParchment,
                  iconColor: ClassroomColors.terracotta,
                  actionText: 'View Sync Details',
                  onTap: () => onNavigate(AppRouteItem.syncStatus),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPedagogyNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClassroomColors.warmParchment.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: ClassroomColors.marigoldDark,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher Tip for Primary Multilingual Classes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Begin each science and math concept with everyday vernacular storytelling before transitioning into standard curriculum vocabulary.',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: ClassroomColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomDashboardCard extends StatefulWidget {
  final double width;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String actionText;
  final VoidCallback onTap;

  const _ClassroomDashboardCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.actionText,
    required this.onTap,
  });

  @override
  State<_ClassroomDashboardCard> createState() => _ClassroomDashboardCardState();
}

class _ClassroomDashboardCardState extends State<_ClassroomDashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: widget.width,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? ClassroomColors.terracotta.withOpacity(0.5)
                : ClassroomColors.borderWarm,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? ClassroomColors.terracotta.withOpacity(0.08)
                  : Colors.black.withOpacity(0.02),
              blurRadius: _isHovered ? 14 : 4,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: widget.iconColor, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.badgeText,
                          style: ClassroomTheme.highlightFont(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: ClassroomColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        widget.actionText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.terracotta,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: ClassroomColors.terracotta,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
