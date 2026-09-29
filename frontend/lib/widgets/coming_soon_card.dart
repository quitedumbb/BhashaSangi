import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class ComingSoonCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String plannedEndpoint;
  final List<String> upcomingFeatures;

  const ComingSoonCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.plannedEndpoint,
    this.upcomingFeatures = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ClassroomColors.borderWarm, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: ClassroomColors.terracotta.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ClassroomColors.marigoldLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ClassroomColors.marigold.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 36, color: ClassroomColors.marigoldDark),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ClassroomColors.warmParchment,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: ClassroomColors.borderWarm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: ClassroomColors.marigoldDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Feature Roadmap • Coming Soon',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.marigoldDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  color: ClassroomColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClassroomColors.creamBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ClassroomColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: ClassroomColors.terracotta,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Backend Status Note',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ClassroomColors.terracotta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The current FastAPI backend does not yet have this endpoint ($plannedEndpoint) activated. Bhasha Sangi presents this preview UI without mocking fake responses, ensuring full alignment with your backend contract.',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: ClassroomColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (upcomingFeatures.isNotEmpty) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Planned Capabilities for Teachers:',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...upcomingFeatures.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: ClassroomColors.earthySage,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: ClassroomColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
