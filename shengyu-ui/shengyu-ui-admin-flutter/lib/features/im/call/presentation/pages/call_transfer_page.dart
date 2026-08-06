import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 通话转接页面 - 微信风格
///
/// 用于在通话中选择转接对象
/// 支持搜索、单选、显示联系人列表
class CallTransferPage extends ConsumerStatefulWidget {
  const CallTransferPage({super.key});

  @override
  ConsumerState<CallTransferPage> createState() => _CallTransferPageState();
}

class _CallTransferPageState extends ConsumerState<CallTransferPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(starContactsProvider);
    final callState = ref.watch(activeCallStateProvider);
    
    // 过滤当前通话的对端用户（不能转接给正在通话的人）
    final currentCalleeId = callState.calleeId;
    final currentCallerId = callState.callerProfile?.userId;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '选择转接对象',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),
          
          // 联系人列表
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF07C160)),
              ),
              error: (error, stack) => Center(
                child: Text(
                  '加载失败: $error',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              data: (contacts) {
                // 过滤搜索关键字和当前通话对端
                final filteredContacts = contacts.where((contact) {
                  final matchesSearch = _searchKeyword.isEmpty ||
                      contact.name.contains(_searchKeyword);
                  
                  // 排除当前通话的对端
                  final isNotCurrentCallPartner = 
                      contact.userId != currentCalleeId &&
                      contact.userId != currentCallerId;
                  
                  return matchesSearch && isNotCurrentCallPartner;
                }).toList();

                if (filteredContacts.isEmpty) {
                  return const Center(
                    child: Text(
                      '暂无可转接的联系人',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return _buildContactItem(contact);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchKeyword = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索联系人',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// 构建联系人项
  Widget _buildContactItem(ContactDirectoryItem contact) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppAvatar(
        name: contact.name,
        avatarUrl: contact.avatarUrl,
        seed: contact.userId,
        size: 48,
        borderRadius: 8,
        fontSize: 18,
        textColor: Colors.white,
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () => _onTransferSelected(contact),
    );
  }

  /// 转接选择确认
  void _onTransferSelected(ContactDirectoryItem contact) {
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          '转接给 ${contact.name}?',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          '转接后当前通话将结束，对方将收到转接请求',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '取消',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 发起转接
              ref.read(callControllerProvider.notifier).initiateTransfer(
                    contact.userId,
                    contact.name,
                  );
              // 返回通话页面（检查 context 是否仍然有效）
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text(
              '确认转接',
              style: TextStyle(color: Color(0xFF07C160)),
            ),
          ),
        ],
      ),
    );
  }
}
