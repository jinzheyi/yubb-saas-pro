import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class OutgoingCallPage extends ConsumerStatefulWidget {
  const OutgoingCallPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends ConsumerState<OutgoingCallPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = ref.read(callControllerProvider.notifier);
      await controller.initialize(widget.args);
      await controller.startOutgoing();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      if ((next.pageStatus == CallPageStatus.ended ||
              next.pageStatus == CallPageStatus.failed) &&
          context.mounted) {
        final navigator = Navigator.of(context);
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (mounted && navigator.canPop()) {
            navigator.pop();
          }
        });
      }
    });

    final state = ref.watch(activeCallStateProvider);
    final statusText = ref.watch(outgoingCallStatusTextProvider);
    final canCancel = ref.watch(canCancelOutgoingCallProvider);
    final title = state.title ?? widget.args.title ?? '新通话';
    final avatarUrl = state.calleeProfile?.avatarUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF111A28),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('返回'),
                ),
              ),
              const Spacer(),
              AppAvatar(
                name: title,
                avatarUrl: avatarUrl,
                backgroundColor: const Color(0xFF246BFD),
                size: 76,
                borderRadius: 24,
                fontSize: 30,
                textColor: Colors.white,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: const TextStyle(fontSize: 14, color: Color(0xFFB8C0CC)),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: canCancel
                          ? () async {
                              await ref
                                  .read(callControllerProvider.notifier)
                                  .cancel();
                              if (context.mounted) context.pop();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE6E6),
                        foregroundColor: const Color(0xFFE54D4F),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('取消'),
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
