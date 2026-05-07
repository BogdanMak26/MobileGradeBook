import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/local/offline_queue.dart';
import '../../core/network/network_monitor.dart';

class ConnectivityOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectivityOverlay({super.key, required this.child});

  @override
  ConsumerState<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends ConsumerState<ConnectivityOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _bannerCtrl;
  late final Animation<Offset> _bannerSlide;

  late final AnimationController _toastCtrl;
  late final Animation<Offset> _toastSlide;
  late final Animation<double> _toastFade;

  bool _isOnline = true;
  bool _showToast = false;
  int _syncCount = 0;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();

    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bannerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _toastCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _toastSlide = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _toastCtrl,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInCubic,
    ));
    _toastFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _toastCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
        reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(networkMonitorProvider).isOnline) {
        setState(() => _isOnline = false);
        _bannerCtrl.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    _toastCtrl.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _handleOffline() {
    _toastTimer?.cancel();
    if (_showToast) {
      _toastCtrl.stop();
      setState(() => _showToast = false);
    }
    setState(() => _isOnline = false);
    _bannerCtrl.forward();
  }

  void _handleOnline(int pendingCount) {
    setState(() {
      _isOnline = true;
      _showToast = true;
      _syncCount = pendingCount;
    });
    _bannerCtrl.reverse();
    _toastCtrl.forward(from: 0);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 4), _dismissToast);
  }

  void _dismissToast() {
    if (!mounted) return;
    _toastCtrl.reverse().then((_) {
      if (mounted) setState(() => _showToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<NetworkStatus>>(
      networkStatusProvider,
      (_, next) => next.whenData((status) {
        final nowOnline = status == NetworkStatus.online;
        if (nowOnline == _isOnline) return;
        if (!nowOnline) {
          _handleOffline();
        } else {
          _handleOnline(ref.read(offlineQueueProvider));
        }
      }),
    );

    final pendingCount = ref.watch(offlineQueueProvider);
    final mediaPad = MediaQuery.of(context).padding;

    return Stack(
      children: [
        widget.child,

        // Offline banner — slides down from top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: SlideTransition(
              position: _bannerSlide,
              child: _OfflineBanner(
                topPad: mediaPad.top,
                pendingCount: pendingCount,
              ),
            ),
          ),
        ),

        // Online toast — slides up from bottom
        if (_showToast)
          Positioned(
            left: 16,
            right: 16,
            bottom: mediaPad.bottom + 80,
            child: SlideTransition(
              position: _toastSlide,
              child: FadeTransition(
                opacity: _toastFade,
                child: _OnlineToast(syncCount: _syncCount),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Offline Banner ─────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final double topPad;
  final int pendingCount;
  const _OfflineBanner({required this.topPad, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: EdgeInsets.only(
        top: topPad + 7,
        bottom: 9,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white60, size: 14),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              pendingCount > 0
                  ? 'Офлайн • $pendingCount ${_label(pendingCount)} у черзі'
                  : 'Офлайн режим — зміни збережуться при підключенні',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _label(int n) {
    if (n == 1) return 'зміна';
    if (n <= 4) return 'зміни';
    return 'змін';
  }
}

// ── Online Toast ───────────────────────────────────────────────────────────────

class _OnlineToast extends StatelessWidget {
  final int syncCount;
  const _OnlineToast({required this.syncCount});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF166534)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ви онлайн!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    syncCount > 0
                        ? 'Синхронізація $syncCount ${_label(syncCount)}...'
                        : 'Всі дані актуальні',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  String _label(int n) {
    if (n == 1) return 'зміни';
    return 'змін';
  }
}
