import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider 作用域检查工具
/// 
/// 用于在开发阶段检测不当的 Provider 共享问题。
/// 通过 ProviderObserver 监听 Provider 的创建和访问模式，
/// 发现潜在的多实例共享风险。
/// 
/// 使用方式：
/// ```dart
/// ProviderScope(
///   observers: [ProviderScopeChecker()],
///   child: MyApp(),
/// )
/// ```
class ProviderScopeChecker extends ProviderObserver {
  // 记录每个 Provider 的访问次数
  final Map<String, int> _providerAccessCount = {};
  
  // 记录每个 Provider 的创建时间
  final Map<String, DateTime> _providerCreationTime = {};
  
  // 需要监控的 Provider 列表（通常是 family-scoped 的 Provider）
  static const Set<String> _monitoredProviders = {
    'chatControllerProvider',
    'chatTimelineControllerProvider',
    'chatMediaControllerProvider',
    'chatMessageActionControllerProvider',
    'chatRuntimeNoticeProvider',
    'chatRealtimeSignalProvider',
    'chatReceiptLastVisibleChatIdProvider',
  };

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    
    final providerName = provider.name ?? provider.runtimeType.toString();
    
    // 检查是否是监控的 Provider
    if (_isMonitoredProvider(providerName)) {
      _providerCreationTime[providerName] = DateTime.now();
      _providerAccessCount[providerName] = 0;
      
      debugPrint('[ProviderScopeChecker] ✅ Provider 创建: $providerName');
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    
    final providerName = provider.name ?? provider.runtimeType.toString();
    
    if (_isMonitoredProvider(providerName)) {
      _providerAccessCount[providerName] = 
          (_providerAccessCount[providerName] ?? 0) + 1;
      
      // 如果访问次数异常高，可能是共享问题
      if (_providerAccessCount[providerName]! > 100) {
        debugPrint(
          '[ProviderScopeChecker] ⚠️ 警告: $providerName 访问次数过高 '
          '(${_providerAccessCount[providerName]} 次)，可能存在共享问题'
        );
      }
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (!kDebugMode) return;
    
    final providerName = provider.name ?? provider.runtimeType.toString();
    
    if (_isMonitoredProvider(providerName)) {
      final creationTime = _providerCreationTime[providerName];
      final accessCount = _providerAccessCount[providerName] ?? 0;
      
      if (creationTime != null) {
        final lifetime = DateTime.now().difference(creationTime);
        debugPrint(
          '[ProviderScopeChecker] 🗑️ Provider 销毁: $providerName '
          '(生命周期: ${lifetime.inSeconds}s, 访问次数: $accessCount)'
        );
      }
      
      _providerCreationTime.remove(providerName);
      _providerAccessCount.remove(providerName);
    }
  }

  /// 检查是否是监控的 Provider
  bool _isMonitoredProvider(String providerName) {
    return _monitoredProviders.any(
      (monitored) => providerName.contains(monitored),
    );
  }

  /// 打印当前所有监控 Provider 的状态（用于调试）
  void printStatus() {
    if (!kDebugMode) return;
    
    debugPrint('\n[ProviderScopeChecker] === 当前 Provider 状态 ===');
    for (final entry in _providerAccessCount.entries) {
      final providerName = entry.key;
      final accessCount = entry.value;
      final creationTime = _providerCreationTime[providerName];
      final lifetime = creationTime != null
          ? DateTime.now().difference(creationTime).inSeconds
          : 0;
      
      debugPrint(
        '  $providerName: 访问 $accessCount 次, 生命周期 ${lifetime}s'
      );
    }
    debugPrint('===================================\n');
  }
}

/// Provider 作用域检查扩展
/// 
/// 提供便捷方法来检查特定 Provider 的作用域是否正确
extension ProviderScopeCheckerExtension on Ref {
  /// 检查 Provider 是否应该使用 family-scoped
  /// 
  /// 使用示例：
  /// ```dart
  /// final myProvider = Provider.autoDispose<MyState>((ref) {
  ///   ref.checkShouldBeFamilyScoped('chatId', 'myProvider');
  ///   return MyState();
  /// });
  /// ```
  void checkShouldBeFamilyScoped(String scopeKey, String providerName) {
    if (!kDebugMode) return;
    
    // 这里可以添加更复杂的检查逻辑
    // 例如：检查是否有多个实例同时存在
    debugPrint(
      '[ProviderScopeChecker] 🔍 检查 Provider: $providerName, '
      'scopeKey: $scopeKey'
    );
  }
}
