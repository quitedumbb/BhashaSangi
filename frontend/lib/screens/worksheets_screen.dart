import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/coming_soon_card.dart';

class WorksheetsScreen extends StatelessWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const WorksheetsScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClassroomColors.marigoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: ClassroomColors.marigoldDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vernacular Printable Worksheets',
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
                'Generate printable bilingual classroom sheets for Ol Chiki, Devanagari, and English literacy practice.',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: ClassroomColors.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              // Coming Soon Banner
              const ComingSoonCard(
                title: 'AI Worksheet Generator',
                description:
                    'Generate print-ready classroom PDF worksheets containing letter tracing, vocabulary matching, and bilingual comprehension exercises based on translated lessons.',
                icon: Icons.print_rounded,
                plannedEndpoint: 'POST /worksheets/generate',
                upcomingFeatures: [
                  'Automated Ol Chiki / Warang Chiti script stroke tracing sheets',
                  'Picture-to-vernacular word matching for primary students (Class 1 - 2)',
                  'One-click PDF download formatted for standard A4 black-and-white school printers',
                  'Editable teacher notes and student assessment checkboxes',
                ],
              ),

              const SizedBox(height: 24),

              Text(
                'Worksheet Templates (Design Concept Preview):',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 650;
                  final width = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildWorksheetPreviewCard(
                        width: width,
                        title: 'Ol Chiki Letter Tracing (ᱵ ᱜ ᱦ ᱡ)',
                        category: 'Primary Grade 1 • Literacy',
                        description:
                            'Guided dot tracing for Santali alphabet consonants with vocabulary illustrations.',
                        tag: 'Demo Template',
                      ),
                      _buildWorksheetPreviewCard(
                        width: width,
                        title: 'Living Things Vocabulary Matching',
                        category: 'Primary Grade 2 • Science',
                        description:
                            'Match tree, river, bird, and flower names between State syllabus Hindi and Mother Tongue Santali.',
                        tag: 'Demo Template',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorksheetPreviewCard({
    required double width,
    required String title,
    required String category,
    required String description,
    required String tag,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClassroomColors.warmParchment,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClassroomColors.marigoldLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ClassroomColors.marigoldDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ClassroomColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: ClassroomColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 16, color: ClassroomColors.terracotta),
              const SizedBox(width: 6),
              Text(
                'PDF generator awaiting backend endpoint',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: ClassroomColors.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
