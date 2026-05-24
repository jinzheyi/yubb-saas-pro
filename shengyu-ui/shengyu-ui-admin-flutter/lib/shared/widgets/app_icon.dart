import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';

enum AppIconKind {
  chatOutline,
  chatFill,
  contactsOutline,
  contactsFill,
  widgetsOutline,
  widgetsFill,
  personOutline,
  personFill,
  history,
  sync,
  qr,
  groupAdd,
  more,
  search,
  close,
  chevronLeft,
  chevronRight,
  chevronUp,
  chevronDown,
  muteOff,
  groupsOutline,
  groupsFill,
  at,
  photo,
  camera,
  location,
  folder,
  badge,
  starOutline,
  redo,
  delete,
  add,
  tune,
  smile,
  collections,
  backspace,
  expandMore,
  keyboard,
  mic,
  openInFull,
  quote,
  copy,
  checklist,
  undo,
  checkCircle,
  arrowForward,
  topic,
  error,
  play,
  pause,
  file,
  image,
  video,
  download,
  refresh,
  check,
  warning,
  locationOff,
  myLocation,
  place,
  tree,
  apartment,
}

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.kind, {
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth,
  });

  final AppIconKind kind;
  final double size;
  final Color color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final legacyIconData = _resolveLegacyIconData(kind);
    if (legacyIconData != null) {
      return Icon(legacyIconData, size: size, color: color);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppIconPainter(
          kind: kind,
          color: color,
          strokeWidth: strokeWidth ?? math.max(1.5, size * 0.08),
        ),
      ),
    );
  }
}

IconData? _resolveLegacyIconData(AppIconKind kind) {
  switch (kind) {
    case AppIconKind.chatOutline:
      return ShengyuIconFont.xiaoxi;
    case AppIconKind.chatFill:
      return ShengyuIconFont.xiaoxi;
    case AppIconKind.contactsOutline:
      return ShengyuIconFont.tongxunlu;
    case AppIconKind.contactsFill:
      return ShengyuIconFont.tongxunlu;
    case AppIconKind.widgetsOutline:
      return ShengyuIconFont.gongzuotai;
    case AppIconKind.widgetsFill:
      return ShengyuIconFont.gongzuotai;
    case AppIconKind.personOutline:
      return ShengyuIconFont.wode;
    case AppIconKind.personFill:
      return ShengyuIconFont.wode;
    case AppIconKind.groupAdd:
      return ShengyuIconFont.yonghu1;
    case AppIconKind.more:
      return ShengyuIconFont.shezhi;
    case AppIconKind.chevronLeft:
      return ShengyuIconFont.jiantouLiebiaoxiangzuo;
    case AppIconKind.chevronRight:
      return ShengyuIconFont.jiantouLiebiaoxiangyou;
    case AppIconKind.qr:
      return ShengyuIconFont.erweima;
    case AppIconKind.muteOff:
      return ShengyuIconFont.miandarao;
    case AppIconKind.at:
      return ShengyuIconFont.aite;
    case AppIconKind.photo:
      return ShengyuIconFont.tupian1;
    case AppIconKind.camera:
      return ShengyuIconFont.paishe;
    case AppIconKind.location:
      return ShengyuIconFont.dingwei;
    case AppIconKind.folder:
      return ShengyuIconFont.wenjian;
    case AppIconKind.badge:
      return ShengyuIconFont.yonghu;
    case AppIconKind.starOutline:
      return ShengyuIconFont.shoucang;
    case AppIconKind.redo:
      return ShengyuIconFont.zhuanfa;
    case AppIconKind.delete:
      return ShengyuIconFont.shanchu;
    case AppIconKind.add:
      return ShengyuIconFont.jiahao;
    case AppIconKind.backspace:
      return ShengyuIconFont.jianhao;
    case AppIconKind.smile:
      return ShengyuIconFont.biaoqingbao;
    case AppIconKind.collections:
      return ShengyuIconFont.tianjiatupian;
    case AppIconKind.keyboard:
      return ShengyuIconFont.jianpan;
    case AppIconKind.mic:
      return ShengyuIconFont.yuyin;
    case AppIconKind.openInFull:
      return ShengyuIconFont.zhankaiquanpingkuozhan;
    case AppIconKind.quote:
      return ShengyuIconFont.yinyong;
    case AppIconKind.copy:
      return ShengyuIconFont.fuzhi;
    case AppIconKind.checklist:
      return ShengyuIconFont.messageMultiSelect;
    case AppIconKind.tree:
      return ShengyuIconFont.flZuzhi;
    case AppIconKind.apartment:
      return ShengyuIconFont.bumen;
    default:
      return null;
  }
}

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter({
    required this.kind,
    required this.color,
    required this.strokeWidth,
  });

  final AppIconKind kind;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case AppIconKind.chatOutline:
        _drawChatOutline(canvas, size);
      case AppIconKind.chatFill:
        _drawChatFill(canvas, size);
      case AppIconKind.contactsOutline:
        _drawContactsOutline(canvas, size);
      case AppIconKind.contactsFill:
        _drawContactsFill(canvas, size);
      case AppIconKind.widgetsOutline:
        _drawWidgetsOutline(canvas, size);
      case AppIconKind.widgetsFill:
        _drawWidgetsFill(canvas, size);
      case AppIconKind.personOutline:
        _drawPersonOutline(canvas, size);
      case AppIconKind.personFill:
        _drawPersonFill(canvas, size);
      case AppIconKind.history:
        _drawHistory(canvas, size);
      case AppIconKind.sync:
        _drawSync(canvas, size);
      case AppIconKind.qr:
        _drawQr(canvas, size);
      case AppIconKind.groupAdd:
        _drawGroupAdd(canvas, size);
      case AppIconKind.more:
        _drawMore(canvas, size);
      case AppIconKind.search:
        _drawSearch(canvas, size);
      case AppIconKind.close:
        _drawClose(canvas, size);
      case AppIconKind.chevronLeft:
        _drawChevronLeft(canvas, size);
      case AppIconKind.chevronRight:
        _drawChevronRight(canvas, size);
      case AppIconKind.chevronUp:
        _drawChevron(canvas, size, upward: true);
      case AppIconKind.chevronDown:
        _drawChevron(canvas, size, upward: false);
      case AppIconKind.muteOff:
        _drawMuteOff(canvas, size);
      case AppIconKind.groupsOutline:
        _drawGroupsOutline(canvas, size);
      case AppIconKind.groupsFill:
        _drawGroupsFill(canvas, size);
      case AppIconKind.at:
        _drawAt(canvas, size);
      case AppIconKind.photo:
        _drawPhoto(canvas, size);
      case AppIconKind.camera:
        _drawCamera(canvas, size);
      case AppIconKind.location:
        _drawLocation(canvas, size);
      case AppIconKind.folder:
        _drawFolder(canvas, size);
      case AppIconKind.badge:
        _drawBadge(canvas, size);
      case AppIconKind.starOutline:
        _drawStar(canvas, size);
      case AppIconKind.redo:
        _drawRedo(canvas, size);
      case AppIconKind.delete:
        _drawDelete(canvas, size);
      case AppIconKind.add:
        _drawAdd(canvas, size);
      case AppIconKind.tune:
        _drawTune(canvas, size);
      case AppIconKind.smile:
        _drawSmile(canvas, size);
      case AppIconKind.collections:
        _drawCollections(canvas, size);
      case AppIconKind.backspace:
        _drawBackspace(canvas, size);
      case AppIconKind.expandMore:
        _drawExpandMore(canvas, size);
      case AppIconKind.keyboard:
        _drawKeyboard(canvas, size);
      case AppIconKind.mic:
        _drawMic(canvas, size);
      case AppIconKind.openInFull:
        _drawOpenInFull(canvas, size);
      case AppIconKind.quote:
        _drawQuote(canvas, size);
      case AppIconKind.copy:
        _drawCopy(canvas, size);
      case AppIconKind.checklist:
        _drawChecklist(canvas, size);
      case AppIconKind.undo:
        _drawUndo(canvas, size);
      case AppIconKind.checkCircle:
        _drawCheckCircle(canvas, size);
      case AppIconKind.arrowForward:
        _drawArrowForward(canvas, size);
      case AppIconKind.topic:
        _drawTopic(canvas, size);
      case AppIconKind.error:
        _drawError(canvas, size);
      case AppIconKind.play:
        _drawPlay(canvas, size);
      case AppIconKind.pause:
        _drawPause(canvas, size);
      case AppIconKind.file:
        _drawFile(canvas, size);
      case AppIconKind.image:
        _drawImage(canvas, size);
      case AppIconKind.video:
        _drawVideo(canvas, size);
      case AppIconKind.download:
        _drawDownload(canvas, size);
      case AppIconKind.refresh:
        _drawRefresh(canvas, size);
      case AppIconKind.check:
        _drawCheck(canvas, size);
      case AppIconKind.warning:
        _drawWarning(canvas, size);
      case AppIconKind.locationOff:
        _drawLocationOff(canvas, size);
      case AppIconKind.myLocation:
        _drawMyLocation(canvas, size);
      case AppIconKind.place:
        _drawPlace(canvas, size);
      case AppIconKind.tree:
        // Falls through to iconfont via _resolveLegacyIconData, never reaches here
        break;
      case AppIconKind.apartment:
        // Falls through to iconfont via _resolveLegacyIconData, never reaches here
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }

  Paint _strokePaint() => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fillPaint() => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  void _drawChatOutline(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.14,
        size.width * 0.72,
        size.height * 0.58,
      ),
      Radius.circular(size.width * 0.14),
    );
    canvas.drawRRect(bubble, paint);
    final tail = Path()
      ..moveTo(size.width * 0.33, size.height * 0.72)
      ..lineTo(size.width * 0.28, size.height * 0.88)
      ..lineTo(size.width * 0.42, size.height * 0.76);
    canvas.drawPath(tail, paint);
  }

  void _drawChatFill(Canvas canvas, Size size) {
    final paint = _fillPaint();
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.12,
            size.height * 0.14,
            size.width * 0.74,
            size.height * 0.58,
          ),
          Radius.circular(size.width * 0.16),
        ),
      )
      ..moveTo(size.width * 0.32, size.height * 0.69)
      ..lineTo(size.width * 0.28, size.height * 0.88)
      ..lineTo(size.width * 0.45, size.height * 0.74)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawContactsOutline(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: false, group: true);
  }

  void _drawContactsFill(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: true, group: true);
  }

  void _drawWidgetsOutline(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final gap = size.width * 0.1;
    final tile = (size.width - gap * 3) / 2;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            gap + col * (tile + gap),
            gap + row * (tile + gap),
            tile,
            tile,
          ),
          Radius.circular(size.width * 0.08),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  void _drawWidgetsFill(Canvas canvas, Size size) {
    final paint = _fillPaint();
    final gap = size.width * 0.1;
    final tile = (size.width - gap * 3) / 2;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            gap + col * (tile + gap),
            gap + row * (tile + gap),
            tile,
            tile,
          ),
          Radius.circular(size.width * 0.08),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  void _drawPersonOutline(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: false, group: false);
  }

  void _drawPersonFill(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: true, group: false);
  }

  void _drawPersonGlyph(
    Canvas canvas,
    Size size, {
    required bool filled,
    required bool group,
  }) {
    final paint = filled ? _fillPaint() : _strokePaint();
    final secondaryPaint = filled ? _fillPaint() : _strokePaint();
    secondaryPaint.color = color.withValues(alpha: 0.84);
    final headRadius = size.width * 0.12;
    final backCenter = Offset(size.width * 0.36, size.height * 0.38);
    final frontCenter = Offset(
      group ? size.width * 0.6 : size.width * 0.5,
      size.height * 0.33,
    );
    if (group) {
      canvas.drawCircle(backCenter, headRadius, secondaryPaint);
    }
    canvas.drawCircle(frontCenter, headRadius, paint);
    final frontBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(frontCenter.dx, size.height * 0.7),
        width: size.width * 0.38,
        height: size.height * 0.28,
      ),
      Radius.circular(size.width * 0.12),
    );
    canvas.drawRRect(frontBody, paint);
    if (group) {
      final backBody = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(backCenter.dx, size.height * 0.74),
          width: size.width * 0.28,
          height: size.height * 0.22,
        ),
        Radius.circular(size.width * 0.1),
      );
      canvas.drawRRect(backBody, secondaryPaint);
    }
  }

  void _drawHistory(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.14,
        size.width * 0.72,
        size.height * 0.72,
      ),
      math.pi * 0.18,
      math.pi * 1.64,
      false,
      paint,
    );
    final arrow = Path()
      ..moveTo(size.width * 0.16, size.height * 0.3)
      ..lineTo(size.width * 0.14, size.height * 0.14)
      ..lineTo(size.width * 0.29, size.height * 0.2);
    canvas.drawPath(arrow, paint);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.32),
      Offset(size.width * 0.5, size.height * 0.52),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.52),
      Offset(size.width * 0.64, size.height * 0.6),
      paint,
    );
  }

  void _drawSync(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.16,
        size.height * 0.16,
        size.width * 0.56,
        size.height * 0.56,
      ),
      math.pi * 0.3,
      math.pi * 0.95,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.56,
        size.height * 0.56,
      ),
      math.pi * 1.3,
      math.pi * 0.95,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.2),
      Offset(size.width * 0.76, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.2),
      Offset(size.width * 0.72, size.height * 0.1),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.8),
      Offset(size.width * 0.24, size.height * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.8),
      Offset(size.width * 0.28, size.height * 0.9),
      paint,
    );
  }

  void _drawQr(Canvas canvas, Size size) {
    final paint = _strokePaint();
    void drawFinder(double left, double top) {
      final outer = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, size.width * 0.24, size.width * 0.24),
        Radius.circular(size.width * 0.04),
      );
      final inner = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left + size.width * 0.06,
          top + size.width * 0.06,
          size.width * 0.12,
          size.width * 0.12,
        ),
        Radius.circular(size.width * 0.02),
      );
      canvas.drawRRect(outer, paint);
      canvas.drawRRect(inner, paint);
    }

    drawFinder(size.width * 0.1, size.height * 0.1);
    drawFinder(size.width * 0.56, size.height * 0.1);
    drawFinder(size.width * 0.1, size.height * 0.56);
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.58),
      Offset(size.width * 0.7, size.height * 0.58),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.58),
      Offset(size.width * 0.7, size.height * 0.72),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.66),
      Offset(size.width * 0.88, size.height * 0.66),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.76),
      Offset(size.width * 0.82, size.height * 0.88),
      paint,
    );
  }

  void _drawGroupAdd(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: false, group: true);
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.74, size.height * 0.32),
      Offset(size.width * 0.74, size.height * 0.56),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.44),
      Offset(size.width * 0.86, size.height * 0.44),
      paint,
    );
  }

  void _drawMore(Canvas canvas, Size size) {
    final paint = _fillPaint();
    for (final dx in <double>[0.28, 0.5, 0.72]) {
      canvas.drawCircle(
        Offset(size.width * dx, size.height * 0.5),
        size.width * 0.06,
        paint,
      );
    }
  }

  void _drawSearch(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.44),
      size.width * 0.2,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.58),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );
  }

  void _drawClose(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.24),
      Offset(size.width * 0.76, size.height * 0.76),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.24),
      Offset(size.width * 0.24, size.height * 0.76),
      paint,
    );
  }

  void _drawChevronLeft(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.62, size.height * 0.22)
      ..lineTo(size.width * 0.34, size.height * 0.5)
      ..lineTo(size.width * 0.62, size.height * 0.78);
    canvas.drawPath(path, paint);
  }

  void _drawChevron(Canvas canvas, Size size, {required bool upward}) {
    final paint = _strokePaint();
    final y1 = upward ? 0.62 : 0.38;
    final y2 = upward ? 0.38 : 0.62;
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * y1)
      ..lineTo(size.width * 0.5, size.height * y2)
      ..lineTo(size.width * 0.76, size.height * y1);
    canvas.drawPath(path, paint);
  }

  void _drawChevronRight(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.22)
      ..lineTo(size.width * 0.64, size.height * 0.5)
      ..lineTo(size.width * 0.34, size.height * 0.78);
    canvas.drawPath(path, paint);
  }

  void _drawMuteOff(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final body = Path()
      ..moveTo(size.width * 0.28, size.height * 0.38)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.22,
        size.width * 0.4,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2,
        size.width * 0.54,
        size.height * 0.32,
      )
      ..lineTo(size.width * 0.6, size.height * 0.48);
    canvas.drawPath(body, paint);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.42,
        size.width * 0.42,
        size.height * 0.34,
      ),
      0,
      math.pi,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.18),
      Offset(size.width * 0.8, size.height * 0.82),
      paint,
    );
  }

  void _drawGroupsOutline(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: false, group: true);
  }

  void _drawGroupsFill(Canvas canvas, Size size) {
    _drawPersonGlyph(canvas, size, filled: true, group: true);
  }

  void _drawAt(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.5),
      size.width * 0.26,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.08,
      paint,
    );
    final tail = Path()
      ..moveTo(size.width * 0.58, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.5,
        size.width * 0.74,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.18,
        size.width * 0.56,
        size.height * 0.18,
      );
    canvas.drawPath(tail, paint);
  }

  void _drawPhoto(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.18,
          size.width * 0.76,
          size.height * 0.64,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.38),
      size.width * 0.06,
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.7)
      ..lineTo(size.width * 0.42, size.height * 0.48)
      ..lineTo(size.width * 0.56, size.height * 0.62)
      ..lineTo(size.width * 0.72, size.height * 0.44)
      ..lineTo(size.width * 0.82, size.height * 0.56);
    canvas.drawPath(path, paint);
  }

  void _drawCamera(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.28,
          size.width * 0.68,
          size.height * 0.46,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.2,
        size.width * 0.14,
        size.height * 0.1,
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.51),
      size.width * 0.12,
      paint,
    );
  }

  void _drawLocation(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.56,
        size.width * 0.22,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.14,
        size.width * 0.5,
        size.height * 0.14,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.14,
        size.width * 0.78,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.56,
        size.width * 0.5,
        size.height * 0.86,
      );
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.38),
      size.width * 0.09,
      paint,
    );
  }

  void _drawFolder(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.34)
      ..lineTo(size.width * 0.36, size.height * 0.34)
      ..lineTo(size.width * 0.44, size.height * 0.24)
      ..lineTo(size.width * 0.86, size.height * 0.24)
      ..lineTo(size.width * 0.86, size.height * 0.74)
      ..lineTo(size.width * 0.14, size.height * 0.74)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawBadge(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.24,
          size.height * 0.16,
          size.width * 0.52,
          size.height * 0.68,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.36),
      size.width * 0.08,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.42,
        size.width * 0.32,
        size.height * 0.22,
      ),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _drawStar(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + i * math.pi * 2 / 5;
      final innerAngle = outerAngle + math.pi / 5;
      final outer = Offset(
        size.width * 0.5 + math.cos(outerAngle) * size.width * 0.28,
        size.height * 0.5 + math.sin(outerAngle) * size.width * 0.28,
      );
      final inner = Offset(
        size.width * 0.5 + math.cos(innerAngle) * size.width * 0.12,
        size.height * 0.5 + math.sin(innerAngle) * size.width * 0.12,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRedo(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.24,
        size.width * 0.5,
        size.height * 0.5,
      ),
      math.pi * 0.15,
      math.pi * 1.2,
      false,
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.62, size.height * 0.2)
      ..lineTo(size.width * 0.82, size.height * 0.24)
      ..lineTo(size.width * 0.72, size.height * 0.4);
    canvas.drawPath(path, paint);
  }

  void _drawDelete(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.3,
        size.width * 0.44,
        size.height * 0.46,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.3),
      Offset(size.width * 0.78, size.height * 0.3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.2),
      paint,
    );
  }

  void _drawAdd(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.78),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.5),
      Offset(size.width * 0.78, size.height * 0.5),
      paint,
    );
  }

  void _drawTune(Canvas canvas, Size size) {
    final paint = _strokePaint();
    for (final (y, x) in <(double, double)>[
      (0.28, 0.6),
      (0.5, 0.36),
      (0.72, 0.68),
    ]) {
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * y),
        Offset(size.width * 0.8, size.height * y),
        paint,
      );
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        size.width * 0.05,
        _fillPaint()..color = color,
      );
    }
  }

  void _drawSmile(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.3,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.42),
      size.width * 0.03,
      _fillPaint(),
    );
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.42),
      size.width * 0.03,
      _fillPaint(),
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.42,
        size.width * 0.32,
        size.height * 0.24,
      ),
      0,
      math.pi,
      false,
      paint,
    );
  }

  void _drawCollections(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.24,
          size.width * 0.42,
          size.height * 0.46,
        ),
        Radius.circular(size.width * 0.06),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.32,
          size.width * 0.42,
          size.height * 0.46,
        ),
        Radius.circular(size.width * 0.06),
      ),
      paint,
    );
  }

  void _drawBackspace(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.5)
      ..lineTo(size.width * 0.34, size.height * 0.26)
      ..lineTo(size.width * 0.82, size.height * 0.26)
      ..lineTo(size.width * 0.82, size.height * 0.74)
      ..lineTo(size.width * 0.34, size.height * 0.74)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.46, size.height * 0.38),
      Offset(size.width * 0.66, size.height * 0.62),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.38),
      Offset(size.width * 0.46, size.height * 0.62),
      paint,
    );
  }

  void _drawExpandMore(Canvas canvas, Size size) {
    _drawChevron(canvas, size, upward: false);
  }

  void _drawKeyboard(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.26,
          size.width * 0.72,
          size.height * 0.44,
        ),
        Radius.circular(size.width * 0.06),
      ),
      paint,
    );
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawCircle(
          Offset(
            size.width * (0.26 + col * 0.11),
            size.height * (0.38 + row * 0.12),
          ),
          size.width * 0.015,
          _fillPaint()..color = color,
        );
      }
    }
  }

  void _drawMic(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.16,
          size.width * 0.24,
          size.height * 0.38,
        ),
        Radius.circular(size.width * 0.12),
      ),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.26,
        size.height * 0.28,
        size.width * 0.48,
        size.height * 0.38,
      ),
      0,
      math.pi,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.66),
      Offset(size.width * 0.5, size.height * 0.84),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.84),
      Offset(size.width * 0.62, size.height * 0.84),
      paint,
    );
  }

  void _drawOpenInFull(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.4),
      Offset(size.width * 0.24, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.24),
      Offset(size.width * 0.4, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.24),
      Offset(size.width * 0.76, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.24),
      Offset(size.width * 0.76, size.height * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.6),
      Offset(size.width * 0.24, size.height * 0.76),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.76),
      Offset(size.width * 0.4, size.height * 0.76),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.76),
      Offset(size.width * 0.76, size.height * 0.76),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.76),
      Offset(size.width * 0.76, size.height * 0.6),
      paint,
    );
  }

  void _drawQuote(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.22,
        size.width * 0.22,
        size.height * 0.24,
      ),
      math.pi * 0.1,
      math.pi * 1.1,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.22,
        size.width * 0.22,
        size.height * 0.24,
      ),
      math.pi * 0.1,
      math.pi * 1.1,
      false,
      paint,
    );
  }

  void _drawCopy(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.24,
          size.height * 0.28,
          size.width * 0.4,
          size.height * 0.46,
        ),
        Radius.circular(size.width * 0.06),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.18,
          size.width * 0.4,
          size.height * 0.46,
        ),
        Radius.circular(size.width * 0.06),
      ),
      paint,
    );
  }

  void _drawChecklist(Canvas canvas, Size size) {
    final paint = _strokePaint();
    for (final y in <double>[0.3, 0.5, 0.7]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * y,
          size.width * 0.1,
          size.height * 0.1,
        ),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.36, size.height * (y + 0.05)),
        Offset(size.width * 0.76, size.height * (y + 0.05)),
        paint,
      );
    }
  }

  void _drawUndo(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.24,
        size.width * 0.5,
        size.height * 0.5,
      ),
      math.pi * 0.2,
      math.pi * 1.15,
      false,
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.2)
      ..lineTo(size.width * 0.16, size.height * 0.28)
      ..lineTo(size.width * 0.3, size.height * 0.42);
    canvas.drawPath(path, paint);
  }

  void _drawCheckCircle(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.32,
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.32, size.height * 0.52)
      ..lineTo(size.width * 0.46, size.height * 0.66)
      ..lineTo(size.width * 0.7, size.height * 0.38);
    canvas.drawPath(path, paint);
  }

  void _drawArrowForward(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.76, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.28),
      Offset(size.width * 0.76, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.72),
      Offset(size.width * 0.76, size.height * 0.5),
      paint,
    );
  }

  void _drawTopic(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.18,
          size.width * 0.72,
          size.height * 0.58,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.34),
      Offset(size.width * 0.74, size.height * 0.34),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.5),
      Offset(size.width * 0.62, size.height * 0.5),
      paint,
    );
  }

  void _drawError(Canvas canvas, Size size) {
    final fill = _fillPaint();
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.34,
      fill,
    );
    final mark = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, strokeWidth * 0.9)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.28),
      Offset(size.width * 0.5, size.height * 0.56),
      mark,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.72),
      size.width * 0.03,
      Paint()..color = Colors.white,
    );
  }

  void _drawPlay(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.24)
      ..lineTo(size.width * 0.74, size.height * 0.5)
      ..lineTo(size.width * 0.34, size.height * 0.76)
      ..close();
    canvas.drawPath(path, _fillPaint());
  }

  void _drawPause(Canvas canvas, Size size) {
    final fill = _fillPaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.22,
          size.width * 0.14,
          size.height * 0.56,
        ),
        Radius.circular(size.width * 0.04),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.58,
          size.height * 0.22,
          size.width * 0.14,
          size.height * 0.56,
        ),
        Radius.circular(size.width * 0.04),
      ),
      fill,
    );
  }

  void _drawFile(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.16)
      ..lineTo(size.width * 0.58, size.height * 0.16)
      ..lineTo(size.width * 0.74, size.height * 0.32)
      ..lineTo(size.width * 0.74, size.height * 0.82)
      ..lineTo(size.width * 0.28, size.height * 0.82)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.16),
      Offset(size.width * 0.58, size.height * 0.32),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.32),
      Offset(size.width * 0.74, size.height * 0.32),
      paint,
    );
  }

  void _drawImage(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.2,
          size.width * 0.68,
          size.height * 0.58,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.38),
      size.width * 0.05,
      paint,
    );
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.68)
      ..lineTo(size.width * 0.42, size.height * 0.5)
      ..lineTo(size.width * 0.52, size.height * 0.6)
      ..lineTo(size.width * 0.68, size.height * 0.44)
      ..lineTo(size.width * 0.76, size.height * 0.68);
    canvas.drawPath(path, paint);
  }

  void _drawVideo(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.24,
          size.width * 0.46,
          size.height * 0.48,
        ),
        Radius.circular(size.width * 0.08),
      ),
      paint,
    );
    final lens = Path()
      ..moveTo(size.width * 0.62, size.height * 0.38)
      ..lineTo(size.width * 0.82, size.height * 0.28)
      ..lineTo(size.width * 0.82, size.height * 0.68)
      ..lineTo(size.width * 0.62, size.height * 0.58)
      ..close();
    canvas.drawPath(lens, paint);
  }

  void _drawDownload(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.62),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.48),
      Offset(size.width * 0.5, size.height * 0.64),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.48),
      Offset(size.width * 0.5, size.height * 0.64),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.78),
      Offset(size.width * 0.76, size.height * 0.78),
      paint,
    );
  }

  void _drawRefresh(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.18,
        size.width * 0.64,
        size.height * 0.64,
      ),
      -math.pi * 0.2,
      math.pi * 1.45,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, size.height * 0.18),
      Offset(size.width * 0.72, size.height * 0.34),
      paint,
    );
  }

  void _drawCheck(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.54),
      Offset(size.width * 0.42, size.height * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.7),
      Offset(size.width * 0.76, size.height * 0.3),
      paint,
    );
  }

  void _drawWarning(Canvas canvas, Size size) {
    final paint = _strokePaint();
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.14)
      ..lineTo(size.width * 0.84, size.height * 0.78)
      ..lineTo(size.width * 0.16, size.height * 0.78)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.34),
      Offset(size.width * 0.5, size.height * 0.56),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.67),
      size.width * 0.02,
      _fillPaint(),
    );
  }

  void _drawLocationOff(Canvas canvas, Size size) {
    _drawLocation(canvas, size);
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.18),
      Offset(size.width * 0.8, size.height * 0.82),
      _strokePaint(),
    );
  }

  void _drawMyLocation(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.24,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.06,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.14),
      Offset(size.width * 0.5, size.height * 0.28),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.72),
      Offset(size.width * 0.5, size.height * 0.86),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.5),
      Offset(size.width * 0.28, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.5),
      Offset(size.width * 0.86, size.height * 0.5),
      paint,
    );
  }

  void _drawPlace(Canvas canvas, Size size) {
    _drawLocation(canvas, size);
  }

  void _drawTree(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.34),
      size.width * 0.12,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.34),
      size.width * 0.12,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.54),
      size.width * 0.16,
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.62),
      Offset(size.width * 0.5, size.height * 0.84),
      paint,
    );
  }

  void _drawApartment(Canvas canvas, Size size) {
    final paint = _strokePaint();
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.2,
        size.width * 0.52,
        size.height * 0.58,
      ),
      paint,
    );
    for (final x in <double>[0.34, 0.5, 0.66]) {
      for (final y in <double>[0.3, 0.44, 0.58]) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * (x - 0.04),
            size.height * (y - 0.03),
            size.width * 0.08,
            size.height * 0.06,
          ),
          paint,
        );
      }
    }
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.62),
      Offset(size.width * 0.5, size.height * 0.78),
      paint,
    );
  }
}
