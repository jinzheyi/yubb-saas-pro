import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _tenantNameController;
  late final TextEditingController _mobileController;
  bool _submitting = false;
  bool _joining = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nicknameController = TextEditingController();
    _tenantNameController = TextEditingController();
    _mobileController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _tenantNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册/加入企业')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '创建企业',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '使用邮箱作为登录主账号。一个账号只能创建一个自己的企业，也可以被邀请加入多家企业。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '邮箱账号'),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '登录密码'),
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return '密码至少 6 位';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: '姓名/昵称'),
                    validator: (value) => _required(value, '请输入姓名或昵称'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tenantNameController,
                    decoration: const InputDecoration(labelText: '企业名称'),
                    validator: (value) => _required(value, '请输入企业名称'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: '手机号（选填，预留）'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? '正在创建...' : '创建并进入企业'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: const Text('加入已有企业'),
              subtitle: const Text('输入企业管理员提供的邀请码；通过后在企业列表中确认切换即可完成加入。'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _openJoin,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJoin() async {
    if (!ref.read(authSessionProvider).isAuthenticated) {
      context.goNamed(RouteNames.login);
      return;
    }
    final code = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('加入已有企业'),
        content: TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: '邀请码'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: _joining
                ? null
                : () async {
                    setState(() => _joining = true);
                    try {
                      final apply = await ref
                          .read(authRemoteDataSourceProvider)
                          .joinByInviteCode(code.text);
                      if (!mounted || !dialogContext.mounted) {
                        return;
                      }
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            apply['status'] == 1
                                ? '申请已通过，请在企业列表确认切换'
                                : '申请已提交，等待企业管理员审批',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        setState(
                          () => _errorMessage = e is ApiException
                              ? e.message
                              : e.toString(),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _joining = false);
                    }
                  },
            child: const Text('提交'),
          ),
        ],
      ),
    );
    code.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final deviceInfo = await ref
          .read(deviceInfoServiceProvider)
          .getOrCreate();
      final token = await ref
          .read(authRemoteDataSourceProvider)
          .registerTenant(
            username: _emailController.text.trim(),
            password: _passwordController.text,
            nickname: _nicknameController.text.trim(),
            tenantName: _tenantNameController.text.trim(),
            mobile: _mobileController.text.trim(),
            deviceType: deviceInfo.deviceType,
            deviceId: deviceInfo.deviceId,
            clientVersion: deviceInfo.clientVersion,
          );
      final permissionInfo = await ref
          .read(authRemoteDataSourceProvider)
          .getPermissionInfoWithSession(
            accessToken: token.accessToken,
            tenantId: token.tenantId,
          );
      final session = AuthSession(
        userId: permissionInfo.userId,
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        tenantId: token.tenantId,
        tenantName: token.tenantName,
        deviceId: deviceInfo.deviceId,
        deviceType: deviceInfo.deviceType,
        deviceName: deviceInfo.deviceName,
        clientVersion: deviceInfo.clientVersion,
        locale: ref.read(appLocaleProvider),
      );
      await ref.read(authSessionProvider.notifier).saveSession(session);
      if (mounted) {
        context.goNamed(RouteNames.conversations);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return '请输入邮箱账号';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return '请输入正确的邮箱账号';
    }
    return null;
  }

  String? _required(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }
    return null;
  }
}
