import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 通话悬浮窗组件 - 1:1 复刻微信设计
///
/// 核心功能：
/// - 视频通话：本地视频预览 + 媒体状态指示器 + 挂断按钮
/// - 语音通话：头像 + 昵称 + 媒体状态指示器 + 挂断按钮
/// - 群聊通话：显示"多人通话" + 参与人数
/// - 声音同步：麦克风/扬声器状态与主界面实时同步
/// - 可拖拽 + 贴边吸附 + 贴边收纳为窄条
/// - 网络质量指示 + 重连状态指示
/// - 点击可恢复到通话界面
class CallFloatingWindow extends ConsumerStatefulWidget {
  const CallFloatingWindow({
    super.key,
    required this.onRestore,
    required this.onHangup,
  });

  /// 点击恢复到通话界面
  final VoidCallback onRestore;

  /// 挂断通话
  final VoidCallback onHangup;

  @override
  ConsumerState<CallFloatingWindow> createState() =>
      _CallFloatingWindowState();
}

class _CallFloatingWindowState extends ConsumerState<CallFloatingWindow>
    with SingleTickerProviderStateMixin {
  /// 悬浮窗尺寸常量（微信规范）
  static const double _width = 100;
  static const double _videoHeight = 150;
  static const double _audioHeight = 120;
  /// 贴边收纳后的窄条宽度
  static const double _collapsedWidth = 16;

  /// 拖拽偏移量（左上角位置）
  Offset _offset = const Offset(0, 0);

  /// 是否已初始化位置
  bool _positionInitialized = false;

  /// 拖拽过程中记录起始偏移
  Offset _dragStartOffset = Offset.zero;

  /// 拖拽开始时的位置（用于判断是否是点击）
  Offset _dragStartPosition = Offset.zero;

  /// 是否正在拖拽（指针移动超过阈值后标记为 true）
  bool _isDragging = false;

  /// 拖拽距离阈值（小于此值视为点击）
  static const double _tapThreshold = 10.0;

  /// 是否已收纳到屏幕边缘（窄条模式）
  bool _isCollapsed = false;

  /// 收纳动画控制器
  late AnimationController _collapseController;
  late Animation<double> _collapseAnimation;

  /// 贴边吸附的边距
  static const double _edgeMargin = 4.0;
  /// 触发收纳的距离阈值（距边缘小于此值时收纳）
  static const double _collapseThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _collapseAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut),
    );
    // 延迟一帧获取屏幕尺寸后初始化位置（右上角）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_positionInitialized && mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        _offset = Offset(screenWidth - _width - 16, 80);
        _positionInitialized = true;
      }
    });
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  /// 拖拽结束后贴边吸附 + 判断是否需要收纳
  void _snapToEdge() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 计算中心点 x 坐标
    final centerX = _offset.dx + _width / 2;

    // 贴左边或右边
    final targetX =
        centerX < screenWidth / 2 ? _edgeMargin : screenWidth - _width - _edgeMargin;

    // 限制 y 坐标在安全范围内
    final isVideoCall =
        ref.read(activeCallStateProvider).callType == CallType.video;
    final windowHeight = isVideoCall ? _videoHeight : _audioHeight;
    const safeTop = 60.0;
    final safeBottom = screenHeight - windowHeight - 20;
    final targetY = _offset.dy.clamp(safeTop, safeBottom);

    setState(() {
      _offset = Offset(targetX, targetY);
    });

    // 判断是否需要收纳：拖拽到边缘时，如果已经在边缘则收纳
    // 微信逻辑：只有当用户主动拖到边缘并松手时才收纳
    // 这里不做自动收纳，只在用户拖拽到极边缘时触发
    // 收纳通过 _checkCollapse 在拖拽过程中判断
  }

  /// 检查是否应该触发收纳/展开
  void _checkCollapseState() {
    final screenWidth = MediaQuery.of(context).size.width;

    // 判断当前是否贴近左边缘或右边缘
    final isNearLeftEdge = _offset.dx <= _collapseThreshold;
    final isNearRightEdge = _offset.dx >= screenWidth - _width - _collapseThreshold;

    if (isNearLeftEdge || isNearRightEdge) {
      // 贴近边缘 → 收纳
      if (!_isCollapsed) {
        setState(() => _isCollapsed = true);
        _collapseController.forward();
      }
    } else {
      // 远离边缘 → 展开
      if (_isCollapsed) {
        setState(() => _isCollapsed = false);
        _collapseController.reverse();
      }
    }
  }

  /// 点击悬浮窗 → 恢复到通话界面
  void _onTapRestore() {
    // 如果处于收纳状态，先展开
    if (_isCollapsed) {
      setState(() => _isCollapsed = false);
      _collapseController.reverse();
      return;
    }

    final manager = ref.read(callFloatingWindowManagerProvider);

    // 优先使用 restoreCallback（在原始页面 context 中创建，可正确访问 GoRouter）
    final restoreCallback = manager.restoreCallback;
    if (restoreCallback != null) {
      // 关键：先执行回调导航，再隐藏悬浮窗
      // 因为 hide() 会移除 OverlayEntry，导致 widget 被销毁，后续代码无法执行
      restoreCallback();
      manager.hide();
      return;
    }

    // 兜底：使用 onRestore 回调
    widget.onRestore();
    manager.hide();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeCallStateProvider);
    final isVideoCall = state.callType == CallType.video;
    final mediaState = state.mediaState;
    final isGroupCall = state.isGroupCall;
    // 群聊通话显示"多人通话"，单聊显示对方名称
    final title = isGroupCall ? '多人通话' : (state.title ?? '通话中');
    final avatarUrl = isGroupCall
        ? null // 群聊不显示头像
        : (state.isIncoming
            ? state.callerProfile?.avatarUrl
            : state.calleeProfile?.avatarUrl);
    final avatarSeed = isGroupCall
        ? state.groupId
        : (state.isIncoming
            ? state.callerProfile?.userId
            : state.calleeProfile?.userId);
    final windowHeight = isVideoCall ? _videoHeight : _audioHeight;
    final isReconnecting = state.pageStatus == CallPageStatus.reconnecting ||
        mediaState.rtcConnectionStatus == RtcConnectionStatus.reconnecting;
    final participantCount = state.participants.length;

    return AnimatedBuilder(
      animation: _collapseAnimation,
      builder: (context, _) {
        // 计算当前宽度（收纳时从 _width 过渡到 _collapsedWidth）
        final currentWidth = _collapsedWidth +
            (_width - _collapsedWidth) * _collapseAnimation.value;

        return Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              _dragStartOffset = details.globalPosition;
              _dragStartPosition = _offset;
            },
            onPanUpdate: (details) {
              final distance =
                  (details.globalPosition - _dragStartOffset).distance;

              if (distance > _tapThreshold) {
                _isDragging = true;

                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                setState(() {
                  _offset = Offset(
                    (details.globalPosition.dx -
                            _dragStartOffset.dx +
                            _dragStartPosition.dx)
                        .clamp(0, screenWidth - _width),
                    (details.globalPosition.dy -
                            _dragStartOffset.dy +
                            _dragStartPosition.dy)
                        .clamp(0, screenHeight - windowHeight),
                  );
                });

                // 拖拽过程中检查收纳状态
                _checkCollapseState();
              }
            },
            onPanEnd: (details) {
              if (_isDragging) {
                _snapToEdge();
              }
              _isDragging = false;
            },
            onTap: () {
              if (!_isDragging) {
                _onTapRestore();
              }
            },
            child: Container(
              width: currentWidth,
              height: windowHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: isReconnecting
                    ? Border.all(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.6),
                        width: 1.5)
                    : Border.all(color: Colors.white24, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // 收纳模式下只显示窄条指示器
                child: _collapseAnimation.value < 0.3
                    ? _buildCollapsedIndicator(windowHeight)
                    : Stack(
                        children: [
                          // ===== 视频通话且摄像头开启：显示本地视频预览 =====
                          if (isVideoCall &&
                              mediaState.cameraEnabled &&
                              mediaState.localVideoRenderer != null &&
                              mediaState.localTrackReady)
                            Positioned.fill(
                              child: RTCVideoView(
                                mediaState.localVideoRenderer!,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                                mirror: true,
                              ),
                            ),

                          // ===== 语音通话或视频通话但摄像头关闭：显示头像和昵称 =====
                          if (!isVideoCall ||
                              (isVideoCall && !mediaState.cameraEnabled))
                            _buildAvatarBackground(
                              title: title,
                              avatarUrl: avatarUrl,
                              avatarSeed: avatarSeed,
                              isGroupCall: isGroupCall,
                              participantCount: participantCount,
                            ),

                          // ===== 媒体状态指示器（左上角区域）=====
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 通话时长 / 重连指示
                                if (isReconnecting)
                                  _buildReconnectingIndicator()
                                else if (state.pageStatus ==
                                    CallPageStatus.connected)
                                  _buildDurationChip(state.elapsedSeconds),

                                // 麦克风静音指示器（仅静音时显示）
                                if (!mediaState.microphoneEnabled)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 3),
                                    child: _buildMediaIndicatorChip(
                                      icon: Icons.mic_off_rounded,
                                      color: const Color(0xFFE54D4F),
                                    ),
                                  ),

                                // 扬声器/听筒指示器
                                Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: _buildMediaIndicatorChip(
                                    icon: mediaState.speakerEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_down_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ===== 群聊参与人数指示（右上角）=====
                          if (isGroupCall && participantCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _buildParticipantCountChip(
                                  participantCount),
                            ),

                          // ===== 挂断按钮（右下角）=====
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                widget.onHangup();
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE54D4F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_end_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),

                          // ===== 摄像头关闭指示（视频通话时，底部居中）=====
                          if (isVideoCall && !mediaState.cameraEnabled)
                            Positioned(
                              bottom: 6,
                              left: 0,
                              right: 30, // 避开挂断按钮
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.videocam_off_rounded,
                                        color: Colors.white70,
                                        size: 10,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        '摄像头已关',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建头像背景（语音通话 / 视频通话摄像头关闭时）
  Widget _buildAvatarBackground({
    required String title,
    String? avatarUrl,
    String? avatarSeed,
    required bool isGroupCall,
    required int participantCount,
  }) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              const Color(0xFF2A2A2A),
              const Color(0xFF1A1A1A),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 28, left: 8, right: 8, bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGroupCall)
                // 群聊：显示多人图标 + 人数
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.group_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      if (participantCount > 0)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07C160),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$participantCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                // 单聊：显示头像
                AppAvatar(
                  name: title,
                  avatarUrl: avatarUrl,
                  seed: avatarSeed,
                  size: 36,
                  borderRadius: 18,
                  fontSize: 14,
                  textColor: Colors.white,
                ),
              const SizedBox(height: 4),
              Text(
                isGroupCall ? '多人通话' : title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建媒体状态指示小芯片
  Widget _buildMediaIndicatorChip({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 10),
    );
  }

  /// 构建通话时长小芯片
  Widget _buildDurationChip(int elapsedSeconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _formatDuration(elapsedSeconds),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
        ),
      ),
    );
  }

  /// 构建重连指示器（黄色闪烁）
  Widget _buildReconnectingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFFFFC107),
            ),
          ),
          SizedBox(width: 2),
          Text(
            '重连',
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建参与人数小芯片
  Widget _buildParticipantCountChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF07C160).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 8,
          ),
          const SizedBox(width: 1),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建收纳状态下的窄条指示器
  Widget _buildCollapsedIndicator(double windowHeight) {
    return Center(
      child: Container(
        width: 3,
        height: windowHeight * 0.4,
        decoration: BoxDecoration(
          color: Colors.white38,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
