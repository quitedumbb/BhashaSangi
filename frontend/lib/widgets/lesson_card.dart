import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/translation.dart';

class LessonCard extends StatefulWidget {
  final Translation translation;

  const LessonCard({super.key, required this.translation});

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool _copied = false;

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied text to clipboard',
          style: GoogleFonts.notoSans(color: Colors.white),
        ),
        backgroundColor: ClassroomColors.slateChalkboard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.translation;
    final isPending = t.isPending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ClassroomColors.terracotta.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Lesson Title + Language Route Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: ClassroomColors.creamBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: ClassroomColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ClassroomColors.terracottaLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 16,
                    color: ClassroomColors.terracotta,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.lessonTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.textDark,
                        ),
                      ),
                      if (t.sessionTag.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 12, color: ClassroomColors.terracotta),
                            const SizedBox(width: 4),
                            Text(
                              t.sessionTag,
                              style: ClassroomTheme.highlightFont(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ClassroomColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ClassroomColors.borderWarm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.sourceLanguage,
                        style: ClassroomTheme.highlightFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.terracottaDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: ClassroomColors.textSubtle,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.targetLanguage,
                        style: ClassroomTheme.highlightFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.earthySage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Original Text (${t.sourceLanguage})',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.textSubtle,
                        letterSpacing: 0.3,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: _copied
                            ? ClassroomColors.earthySage
                            : ClassroomColors.textSubtle,
                      ),
                      tooltip: 'Copy original text',
                      onPressed: () => _copyToClipboard(t.sourceText, context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ClassroomColors.warmParchment.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ClassroomColors.borderSubtle),
                  ),
                  child: SelectableText(
                    t.sourceText,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: ClassroomColors.textDark,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Translation section
                Text(
                  'Vernacular Translation (${t.targetLanguage})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.textSubtle,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                if (isPending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ClassroomColors.marigoldLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClassroomColors.marigold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 18,
                          color: ClassroomColors.marigoldDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Translation Pending',
                                style: ClassroomTheme.highlightFont(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ClassroomColors.marigoldDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'AI translation service is pending integration. The teacher draft has been saved to the library.',
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: ClassroomColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ClassroomColors.sageLight.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ClassroomColors.earthySage.withOpacity(0.2),
                      ),
                    ),
                    child: SelectableText(
                      t.translatedText,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.textDark,
                        height: 1.45,
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Footer: Method / Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending
                            ? ClassroomColors.marigoldLight
                            : ClassroomColors.sageLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Method: ${t.translationMethod}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPending
                              ? ClassroomColors.marigoldDark
                              : ClassroomColors.sageDark,
                        ),
                      ),
                    ),
                    Text(
                      'Record #${t.id}',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: ClassroomColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
