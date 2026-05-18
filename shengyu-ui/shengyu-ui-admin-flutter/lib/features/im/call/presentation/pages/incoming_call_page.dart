import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class IncomingCallPage extends ConsumerStatefulWidget {
  const IncomingCallPage({super.key, required this.args});

  final CallLaunchArgs args;

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(callControllerProvider.notifier).initialize(widget.args),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CallState>(callControllerProvider, (previous, next) {
      if (previous?.pageStatus == next.pageStatus) {
        return;
      }
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
    final statusText = ref.watch(incomingCallStatusTextProvider);
    final canReject = ref.watch(canRejectIncomingCallProvider);
    final canAccept = ref.watch(canAcceptIncomingCallProvider);
    final title = state.title ?? widget.args.title ?? '语音通话';
    final avatarUrl = state.callerProfile?.avatarUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF101521),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              const Spacer(),
              AppAvatar(
                name: title,
                avatarUrl: avatarUrl,
                backgroundColor: const Color(0xFF3D75F6),
                size: 72,
                borderRadius: 24,
                fontSize: 28,
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
                      onPressed: canReject
                          ? () async {
                              await ref
                                  .read(callControllerProvider.notifier)
                                  .reject();
                              if (context.mounted) context.pop();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE6E6),
                        foregroundColor: const Color(0xFFE54D4F),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('拒绝'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canAccept
                          ? () async {
                              await ref
                                  .read(callControllerProvider.notifier)
                                  .accept();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25B67B),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('接听'),
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
