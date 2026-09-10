import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _submitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('修改密码'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _PasswordField(
                      controller: _oldPasswordController,
                      label: '当前密码',
                      hintText: '请输入当前登录密码',
                      visible: _oldPasswordVisible,
                      onVisibilityChanged: () {
                        setState(
                          () => _oldPasswordVisible = !_oldPasswordVisible,
                        );
                      },
                      validator: _passwordValidator,
                    ),
                    const SizedBox(height: 18),
                    _PasswordField(
                      controller: _newPasswordController,
                      label: '新密码',
                      hintText: '请输入 4-50 位新密码',
                      visible: _newPasswordVisible,
                      onVisibilityChanged: () {
                        setState(
                          () => _newPasswordVisible = !_newPasswordVisible,
                        );
                      },
                      validator: (value) {
                        final error = _passwordValidator(value);
                        if (error != null) return error;
                        if (value == _oldPasswordController.text) {
                          return '新密码不能与当前密码相同';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _PasswordField(
                      controller: _confirmPasswordController,
                      label: '确认新密码',
                      hintText: '请再次输入新密码',
                      visible: _confirmPasswordVisible,
                      onVisibilityChanged: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请再次输入新密码';
                        }
                        if (value != _newPasswordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('确认修改'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return '请输入密码';
    if (value.length < 4 || value.length > 50) return '密码长度需为 4-50 位';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authRemoteDataSourceProvider)
          .updatePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('密码修改成功'),
          backgroundColor: Color(0xFF07C160),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException && error.message.isNotEmpty
          ? error.message
          : '密码修改失败，请稍后重试';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF4B4B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.visible,
    required this.onVisibilityChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool visible;
  final VoidCallback onVisibilityChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: IconButton(
          tooltip: visible ? '隐藏密码' : '显示密码',
          onPressed: onVisibilityChanged,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }
}
