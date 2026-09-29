import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class ErrorView extends StatefulWidget {
  final String friendlyMessage;
  final String? technicalDetails;
  final VoidCallback? onRetry;
  final String? actionLabel;

  const ErrorView({
    super.key,
    required this.friendlyMessage,
    this.technicalDetails,
    this.onRetry,
    this.actionLabel,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ClassroomColors.borderWarm, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: ClassroomColors.terracotta.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ClassroomColors.terracottaLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ClassroomColors.terracotta.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 32,
                  color: ClassroomColors.terracotta,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Classroom Notice',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.terracotta,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.friendlyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textDark,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check if the FastAPI backend service is running locally on http://127.0.0.1:8000 and has CORS enabled.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: ClassroomColors.textMuted,
                  height: 1.45,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(widget.actionLabel ?? 'Try Connecting Again'),
                ),
              ],
              if (widget.technicalDetails != null &&
                  widget.technicalDetails!.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  icon: Icon(
                    _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: ClassroomColors.textSubtle,
                  ),
                  label: Text(
                    _showDetails ? 'Hide Technical Details' : 'View Technical Details (Dev)',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: ClassroomColors.textSubtle,
                    ),
                  ),
                ),
                if (_showDetails) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ClassroomColors.slateChalkboard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      widget.technicalDetails!,
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: ClassroomColors.chalkWhite,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
