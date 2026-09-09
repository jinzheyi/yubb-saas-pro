import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/auth/tenant_list_item_dto.dart';
import 'package:shengyu_ui_admin_im/features/profile/domain/services/tenant_switch_service.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class TenantSwitchPage extends ConsumerStatefulWidget {
  const TenantSwitchPage({super.key});

  /// 以左侧滑出面板形式显示
  static Future<void> showAsLeftSheet(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'tenant_switch',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.85,
            child: const TenantSwitchPage(),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<TenantSwitchPage> createState() => _TenantSwitchPageState();
}

class _TenantSwitchPageState extends ConsumerState<TenantSwitchPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 仅在租户列表为空时加载（避免重复请求）
    Future.microtask(() {
      final currentState = ref.read(tenantSwitchServiceProvider);
      if (currentState.tenantList.isEmpty) {
        ref.read(tenantSwitchServiceProvider.notifier).loadTenantList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantSwitchServiceProvider);
    final strings = AppLocalizations.of(context);

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, strings),
            _buildSearchBar(strings),
            Expanded(
              child:
                  state.switchStatus == TenantSwitchStatus.loading &&
                      state.tenantList.isEmpty
                  ? _buildLoading(strings)
                  : _buildTenantList(context, state, strings),
            ),
            _buildFooter(context, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.tenantSwitchTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: strings.tenantSearchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildLoading(AppLocalizations strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(strings.tenantSwitching),
        ],
      ),
    );
  }

  Widget _buildTenantList(
    BuildContext context,
    TenantSwitchState state,
    AppLocalizations strings,
  ) {
    final tenantList = state.tenantList;
    final currentTenantId = ref.read(authSessionProvider).tenantId;

    // 过滤搜索结果
    final filteredList = _searchQuery.isEmpty
        ? tenantList
        : tenantList
              .where((t) => t.tenantName.toLowerCase().contains(_searchQuery))
              .toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? strings.tenantNoTenants
              : strings.tenantNoSearchResults,
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final tenant = filteredList[index];
        final isCurrent = tenant.id == currentTenantId;
        final canSwitch = tenant.isSwitchable && !isCurrent;

        return _TenantListTile(
          tenant: tenant,
          isCurrent: isCurrent,
          canSwitch: canSwitch,
          strings: strings,
          onTap: canSwitch
              ? () => _handleTenantSwitch(context, tenant, strings)
              : null,
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.pushNamed(RouteNames.register);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(strings.tenantCreateOrJoin),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1677FF)),
              foregroundColor: const Color(0xFF1677FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTenantSwitch(
    BuildContext context,
    TenantListItemDto tenant,
    AppLocalizations strings,
  ) async {
    if (tenant.waitingConfirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认加入企业'),
          content: Text(
            '你已被邀请加入“${tenant.tenantName}”。切换进入后，将正式加入该企业并同步企业通讯录。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认加入'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    final result = await ref
        .read(tenantSwitchServiceProvider.notifier)
        .switchTenant(targetTenantId: tenant.id);

    if (!context.mounted) return;

    if (result.success) {
      Navigator.pop(context);

      // 显示切换成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.tenantSwitchSuccess),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // 切换成功后导航到会话列表页（根页面）
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class _TenantListTile extends StatelessWidget {
  const _TenantListTile({
    required this.tenant,
    required this.isCurrent,
    required this.canSwitch,
    required this.strings,
    this.onTap,
  });

  final TenantListItemDto tenant;
  final bool isCurrent;
  final bool canSwitch;
  final AppLocalizations strings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFF0F7FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: const Color(0xFFE5E5E5), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tenant.tenantName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: canSwitch || isCurrent ? null : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1677FF,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            strings.tenantCurrent,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1677FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tenant.loginDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      strings.tenantLastLogin(_formatTime(tenant.loginDate!)),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (tenant.userStatusText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tenant.userStatusText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB7791F),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Color(0xFF1677FF), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: isCurrent ? const Color(0xFF1677FF) : Colors.grey,
      child: Text(
        tenant.tenantName.isNotEmpty ? tenant.tenantName[0] : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return strings.tenantTimeJustNow;
    if (diff.inMinutes < 60) {
      return strings.tenantTimeMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) return strings.tenantTimeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return strings.tenantTimeDaysAgo(diff.inDays);

    return '${time.month}-${time.day}';
  }
}
