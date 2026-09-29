import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';

enum AppRouteItem {
  home('HOME', Icons.home_rounded, true),
  languages('LANGUAGES', Icons.translate_rounded, true),
  lessons('LESSONS', Icons.library_books_rounded, true),
  translate('TRANSLATE', Icons.edit_note_rounded, true),
  downloads('DOWNLOADS', Icons.download_for_offline_rounded, true),
  worksheets('CHAPTER NOTES', Icons.menu_book_rounded, true),
  learningCards('LEARNING CARDS', Icons.style_rounded, true),
  communityVoice('COMMUNITY VOICE', Icons.record_voice_over_rounded, false),
  syncStatus('SYNC STATUS', Icons.sync_rounded, true),
  settings('SETTINGS', Icons.tune_rounded, true),
  login('LOGIN / LOGOUT', Icons.account_circle_rounded, true);

  final String title;
  final IconData icon;
  final bool hasActiveApi;

  const AppRouteItem(this.title, this.icon, this.hasActiveApi);
}

class AppDrawer extends StatelessWidget {
  final AppRouteItem currentRoute;
  final ValueChanged<AppRouteItem> onSelectRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onSelectRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ClassroomColors.creamBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Cultural Classroom Motif
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: ClassroomColors.borderWarm),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ClassroomColors.terracotta,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ClassroomColors.terracotta.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BHASHA SANGI',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: ClassroomColors.terracotta,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'भाषा संगी • Mother Tongue Pedagogy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: ClassroomColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ClassroomColors.warmParchment,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ClassroomColors.borderSubtle),
                    ),
                    child: Text(
                      'Primary Classroom Edition',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: AppRouteItem.values.map((item) {
                  final isSelected = currentRoute == item;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).maybePop();
                          onSelectRoute(item);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ClassroomColors.terracotta
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : ClassroomColors.textMuted,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : ClassroomColors.textDark,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (!item.hasActiveApi)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : ClassroomColors.marigoldLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'SOON',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : ClassroomColors.marigoldDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Teacher Profile Footer in Drawer
            AnimatedBuilder(
              animation: AuthService.instance,
              builder: (context, _) {
                final teacher = AuthService.instance.currentTeacher;
                final isAuth = AuthService.instance.isAuthenticated;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: ClassroomColors.borderWarm),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: ClassroomColors.terracottaLight,
                        child: Text(
                          isAuth && teacher != null
                              ? teacher.fullName.substring(0, 1)
                              : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: ClassroomColors.terracottaDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAuth && teacher != null
                                  ? teacher.fullName
                                  : 'Guest Teacher',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ClassroomColors.textDark,
                              ),
                            ),
                            Text(
                              isAuth && teacher != null
                                  ? teacher.schoolName
                                  : 'Demo Session',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSans(
                                fontSize: 11,
                                color: ClassroomColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
