import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// Splash Screen 启动页
/// - 仅在应用首次加载时展示（bootstrap 未完成期间）
/// - 包含品牌动画：呼吸灯 Logo + 应用名称 + 加载指示器
/// - 底部预留广告位（P5-3），可通过 [adSlot] 参数接入
class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key, this.adSlot});

  /// 底部广告位预留（可选）
  final Widget? adSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Logo 动画区
            const _BreathingLogo(),
            const SizedBox(height: 32),
            // 应用名称
            Text(
              AppConfig.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            // 加载指示器
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const Spacer(flex: 2),
            // 底部广告位（预留）
            if (adSlot != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: adSlot!,
                ),
              )
            else
              const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// 呼吸灯效果的 Logo 动画
class _BreathingLogo extends StatefulWidget {
  const _BreathingLogo();

  @override
  State<_BreathingLogo> createState() => _BreathingLogoState();
}

class _BreathingLogoState extends State<_BreathingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.chat_bubble_rounded,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// 启动页底部广告占位组件（P5-3 预留）
/// 当广告 SDK 接入后，替换此组件即可
class SplashAdPlaceholder extends StatelessWidget {
  const SplashAdPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Ad',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}
