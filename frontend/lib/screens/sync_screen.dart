import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';

class SyncScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const SyncScreen({super.key, required this.onNavigate});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final ApiService _apiService = ApiService();
  bool _isTestingHealth = false;
  BackendHealth? _directHealthResult;

  Future<void> _testConnection() async {
    setState(() => _isTestingHealth = true);
    final health = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        _directHealthResult = health;
        _isTestingHealth = false;
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
        final isConnected = state.isBackendConnected;
        final health = _directHealthResult ?? state.backendHealth;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Description
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ClassroomColors.terracottaLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          color: ClassroomColors.terracotta,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Backend Sync & Health Status',
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
                    'Real-time connectivity diagnostics linking Flutter Web with your FastAPI backend.',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: ClassroomColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Connection Status Main Card
                  _buildMainStatusCard(isConnected, health),

                  const SizedBox(height: 20),

                  // Metrics Cards: Languages Count & Translations Count
                  _buildMetricsRow(state),

                  const SizedBox(height: 24),

                  // CORS & Backend Integration Status Card
                  _buildCorsGuidanceCard(isConnected),

                  const SizedBox(height: 24),

                  // Endpoint Manifest Table
                  _buildEndpointsTable(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainStatusCard(bool isConnected, BackendHealth? health) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? ClassroomColors.earthySage : ClassroomColors.terracotta,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? ClassroomColors.earthySage : ClassroomColors.terracotta)
                .withOpacity(0.05),
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
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? ClassroomColors.earthySage
                          : ClassroomColors.errorRust,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isConnected ? 'Backend: Connected' : 'Backend: Offline / Unreachable',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isConnected
                          ? ClassroomColors.earthySage
                          : ClassroomColors.errorRust,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isTestingHealth ? null : _testConnection,
                icon: _isTestingHealth
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(_isTestingHealth ? 'Pinging…' : 'Ping GET /'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildStatusRow(
            label: 'Backend URL:',
            value: ApiConfig.baseUrl,
            isMonospace: true,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            label: 'Health Check Endpoint:',
            value: ApiConfig.healthEndpoint,
            isMonospace: true,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            label: 'Last Health Response:',
            value: health?.message ?? 'No response received yet',
            isMonospace: false,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            label: 'Last Sync Timestamp:',
            value: ClassroomState.instance.lastSyncTime != null
                ? ClassroomState.instance.lastSyncTime!
                    .toLocal()
                    .toString()
                    .split('.')
                    .first
                : 'Not available yet',
            isMonospace: false,
          ),

          if (health?.error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ClassroomColors.terracottaLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Diagnostic Note: ${health!.error}',
                style: GoogleFonts.firaCode(
                  fontSize: 11,
                  color: ClassroomColors.terracottaDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required bool isMonospace,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
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
            style: isMonospace
                ? GoogleFonts.firaCode(
                    fontSize: 13,
                    color: ClassroomColors.textDark,
                  )
                : GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ClassroomColors.textDark,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(ClassroomState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        final langMetric = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ClassroomColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: ClassroomColors.earthySage,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Languages Count',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.languages.length} Active',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.textDark,
                      ),
                    ),
                    Text(
                      'Source: GET /languages',
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

        final transMetric = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ClassroomColors.terracottaLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_books_rounded,
                  color: ClassroomColors.terracotta,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Translation Library',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ClassroomColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.translations.length} Records',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.textDark,
                      ),
                    ),
                    Text(
                      'Source: GET /translations',
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

        if (isNarrow) {
          return Column(
            children: [
              langMetric,
              const SizedBox(height: 12),
              transMetric,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: langMetric),
            const SizedBox(width: 16),
            Expanded(child: transMetric),
          ],
        );
      },
    );
  }

  Widget _buildCorsGuidanceCard(bool isConnected) {
    if (isConnected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ClassroomColors.sageLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ClassroomColors.earthySage.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ClassroomColors.earthySage,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CORS & Cross-Origin Security Active',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ClassroomColors.earthySage,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FastAPI backend is successfully accepting cross-origin requests from Flutter Web.',
                    style: GoogleFonts.notoSans(
                      fontSize: 12.5,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClassroomColors.warmParchment.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: ClassroomColors.terracotta,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Troubleshooting: FastAPI CORS Configuration',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.terracottaDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If the backend is running but Flutter Web cannot reach it, ensure CORS middleware is configured in your FastAPI backend:',
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: ClassroomColors.textDark,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ClassroomColors.slateChalkboard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              'from fastapi.middleware.cors import CORSMiddleware\n\n'
              'app.add_middleware(\n'
              '    CORSMiddleware,\n'
              '    allow_origins=["*"], # Or ["http://localhost:*", "http://127.0.0.1:*"] for strict local\n'
              '    allow_credentials=True,\n'
              '    allow_methods=["*"],\n'
              '    allow_headers=["*"],\n'
              ')',
              style: GoogleFonts.firaCode(
                fontSize: 12,
                color: ClassroomColors.chalkWhite,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointsTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backend API Contract Manifest',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ClassroomColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildEndpointItem(
            method: 'GET',
            path: '/',
            desc: 'Backend health check ping',
            status: 'Active',
            statusColor: ClassroomColors.earthySage,
          ),
          const Divider(height: 16),
          _buildEndpointItem(
            method: 'GET',
            path: '/languages',
            desc: 'Active language catalog with scripts',
            status: 'Active',
            statusColor: ClassroomColors.earthySage,
          ),
          const Divider(height: 16),
          _buildEndpointItem(
            method: 'GET',
            path: '/translations',
            desc: 'Saved classroom translations library',
            status: 'Active',
            statusColor: ClassroomColors.earthySage,
          ),
          const Divider(height: 16),
          _buildEndpointItem(
            method: 'POST',
            path: '/translate',
            desc: 'Submit lesson translation draft to MySQL',
            status: 'Active',
            statusColor: ClassroomColors.earthySage,
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointItem({
    required String method,
    required String path,
    required String desc,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: method == 'GET'
                ? ClassroomColors.sageLight
                : ClassroomColors.terracottaLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            method,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: method == 'GET'
                  ? ClassroomColors.sageDark
                  : ClassroomColors.terracottaDark,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                path,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textDark,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: ClassroomColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
