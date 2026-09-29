import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/coming_soon_card.dart';

class CommunityVoiceScreen extends StatelessWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const CommunityVoiceScreen({super.key, required this.onNavigate});

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
                      color: ClassroomColors.terracottaLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: ClassroomColors.terracotta,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Community Voice & Dialect Contributions',
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
                'Crowdsource authentic vernacular speech samples from native community speakers and tribal elders.',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: ClassroomColors.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              // Coming Soon Banner
              const ComingSoonCard(
                title: 'Community Voice Vault',
                description:
                    'Empower community elders, vernacular storytellers, and primary teachers to record authentic regional dialect audio samples to train and fine-tune BHASHINI vernacular models.',
                icon: Icons.mic_none_rounded,
                plannedEndpoint: 'POST /community/recordings & GET /community/sentences',
                upcomingFeatures: [
                  'Classroom sentence prompt recording with waveform visualization',
                  'Community elder validation & upvoting for dialect fidelity',
                  'Contribution leaderboard celebrating vernacular language preservation',
                  'BHASHINI ASR dataset alignment for unrepresented tribal dialects',
                ],
              ),

              const SizedBox(height: 24),

              // Mock Concept Recording Deck (Clearly marked as Demo)
              Text(
                'Voice Contribution Interface (Prototype Concept):',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ClassroomColors.borderWarm),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClassroomColors.warmParchment,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Target Dialect: Santali (Dumka Sub-dialect)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.terracottaDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '“ᱦᱟᱹᱛᱤ ᱫᱚ ᱵᱤᱨ ᱨᱮ ᱛᱟᱦᱮᱸᱱᱟᱭ”',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hạti dọ bir re tahen-a-e (The elephant lives in the forest)',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: ClassroomColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Record Button Preview
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ClassroomColors.terracottaLight,
                        border: Border.all(color: ClassroomColors.terracotta, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.mic_rounded, color: ClassroomColors.terracotta, size: 32),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Community recording endpoint is not connected yet in the FastAPI backend.',
                                style: GoogleFonts.notoSans(color: Colors.white),
                              ),
                              backgroundColor: ClassroomColors.slateChalkboard,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to Record Audio (Demo Preview)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
