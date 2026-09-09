import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum _Mode { join, create }

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _tenant = TextEditingController();
  final _invite = TextEditingController();
  final _mobile = TextEditingController();
  _Mode _mode = _Mode.join;
  bool _busy = false;
  bool _sending = false;
  int _seconds = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    for (final item in [_email, _code, _name, _tenant, _invite, _mobile]) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final joining = _mode == _Mode.join;
    return Scaffold(
      appBar: AppBar(title: const Text('加入或创建企业')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              joining ? '加入已有企业' : '创建企业',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              joining
                  ? '优先使用邀请码加入。邮箱验证码确认账号归属；首次使用该邮箱时，初始登录密码将发送到邮箱。'
                  : '使用邮箱验证码创建企业。已有账号不会被重置密码；首次使用该邮箱时，系统将发送初始登录密码。',
            ),
            const SizedBox(height: 20),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(
                  value: _Mode.join,
                  icon: Icon(Icons.group_add_outlined),
                  label: Text('加入企业'),
                ),
                ButtonSegment(
                  value: _Mode.create,
                  icon: Icon(Icons.add_business_outlined),
                  label: Text('创建企业'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _mode = value.first;
                      _error = null;
                    }),
            ),
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '邮箱账号'),
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '邮箱验证码',
                            counterText: '',
                          ),
                          validator: (v) => (v ?? '').trim().length == 6
                              ? null
                              : '请输入 6 位邮箱验证码',
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _sending || _seconds > 0
                              ? null
                              : _sendCode,
                          child: Text(
                            _seconds > 0 ? '${_seconds}s 后重发' : '发送验证码',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (joining) ...[
                    TextFormField(
                      controller: _invite,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: '邀请码'),
                      validator: (v) => _required(v, '请输入企业邀请码'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: '姓名/昵称（选填）'),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: '姓名/昵称'),
                      validator: (v) => _required(v, '请输入姓名或昵称'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tenant,
                      decoration: const InputDecoration(labelText: '企业名称'),
                      validator: (v) => _required(v, '请输入企业名称'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '手机号（选填，预留）',
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? '正在提交...'
                          : joining
                          ? '验证并加入企业'
                          : '验证并创建企业',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.goNamed(RouteNames.login),
                    child: const Text('我已有账号，返回登录'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final message = _emailValidator(_email.text);
    if (message != null) return setState(() => _error = message);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(authRemoteDataSourceProvider)
          .sendRegisterEmailCode(email: _email.text.trim());
      _timer?.cancel();
      setState(() => _seconds = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _seconds <= 1) {
          timer.cancel();
          if (mounted) setState(() => _seconds = 0);
        } else {
          setState(() => _seconds--);
        }
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证码已发送，请查收邮箱')));
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(authRemoteDataSourceProvider);
      final result = _mode == _Mode.join
          ? await api.joinTenantByInvite(
              email: _email.text.trim(),
              emailCode: _code.text.trim(),
              inviteCode: _invite.text.trim(),
              nickname: _name.text.trim(),
            )
          : await api.registerTenant(
              username: _email.text.trim(),
              emailCode: _code.text.trim(),
              nickname: _name.text.trim(),
              tenantName: _tenant.text.trim(),
              mobile: _mobile.text.trim(),
              deviceType: 3,
              deviceId: 'register',
              clientVersion: 'register',
            );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('提交成功'),
          content: Text(result['message'] as String? ?? '操作成功，请使用邮箱账号登录。'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('去登录'),
            ),
          ],
        ),
      );
      if (mounted) context.goNamed(RouteNames.login);
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object e) => e is ApiException ? e.message : '操作失败，请稍后重试';
  String? _emailValidator(String? value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value?.trim() ?? '')
      ? null
      : '请输入正确的邮箱账号';
  String? _required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;
}
