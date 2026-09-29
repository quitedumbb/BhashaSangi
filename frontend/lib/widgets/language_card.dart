import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/language.dart';

class LanguageCard extends StatefulWidget {
  final Language language;
  final bool isSourceSelected;
  final bool isTargetSelected;
  final VoidCallback onSelectAsSource;
  final VoidCallback onSelectAsTarget;

  const LanguageCard({
    super.key,
    required this.language,
    required this.isSourceSelected,
    required this.isTargetSelected,
    required this.onSelectAsSource,
    required this.onSelectAsTarget,
  });

  @override
  State<LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<LanguageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSourceSelected || widget.isTargetSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ClassroomColors.terracotta
                : _isHovered
                    ? ClassroomColors.marigold
                    : ClassroomColors.borderWarm,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ClassroomColors.terracotta.withOpacity(0.08)
                  : _isHovered
                      ? ClassroomColors.marigold.withOpacity(0.08)
                      : Colors.black.withOpacity(0.02),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Language Code badge & Script badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ClassroomColors.warmParchment,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ClassroomColors.borderSubtle),
                    ),
                    child: Text(
                      widget.language.languageCode.toUpperCase(),
                      style: ClassroomTheme.highlightFont(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.terracottaDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.language.script.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClassroomColors.sageLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.language.script,
                        style: ClassroomTheme.highlightFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.sageDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Native name prominent
              Text(
                widget.language.nativeName.isNotEmpty
                    ? widget.language.nativeName
                    : widget.language.languageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              const SizedBox(height: 4),

              // English name
              Text(
                widget.language.languageName,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ClassroomColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              const Divider(height: 1),
              const SizedBox(height: 12),

              // Selection actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onSelectAsSource,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: widget.isSourceSelected
                            ? ClassroomColors.terracotta
                            : Colors.transparent,
                        foregroundColor: widget.isSourceSelected
                            ? Colors.white
                            : ClassroomColors.terracottaDark,
                        side: BorderSide(
                          color: ClassroomColors.terracotta,
                          width: widget.isSourceSelected ? 1.5 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        widget.isSourceSelected ? 'Source ✓' : 'Use as Source',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onSelectAsTarget,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: widget.isTargetSelected
                            ? ClassroomColors.marigold
                            : Colors.transparent,
                        foregroundColor: widget.isTargetSelected
                            ? Colors.white
                            : ClassroomColors.marigoldDark,
                        side: BorderSide(
                          color: ClassroomColors.marigold,
                          width: widget.isTargetSelected ? 1.5 : 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        widget.isTargetSelected ? 'Target ✓' : 'Use as Target',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
