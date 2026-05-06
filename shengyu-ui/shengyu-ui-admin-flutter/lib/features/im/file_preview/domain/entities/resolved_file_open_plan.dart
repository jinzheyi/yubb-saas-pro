import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';

class ResolvedFileOpenPlan {
  const ResolvedFileOpenPlan({
    required this.renderStrategy,
    required this.shouldOpenInPage,
    required this.shouldUseEmbeddedViewer,
    required this.shouldOpenExternal,
    required this.shouldDownloadOnly,
    this.resolvedUrl,
    this.fallbackMessage,
  });

  final FileRenderStrategy renderStrategy;
  final bool shouldOpenInPage;
  final bool shouldUseEmbeddedViewer;
  final bool shouldOpenExternal;
  final bool shouldDownloadOnly;
  final String? resolvedUrl;
  final String? fallbackMessage;

  factory ResolvedFileOpenPlan.inPage({
    required FileRenderStrategy renderStrategy,
    String? resolvedUrl,
  }) {
    return ResolvedFileOpenPlan(
      renderStrategy: renderStrategy,
      shouldOpenInPage: true,
      shouldUseEmbeddedViewer: false,
      shouldOpenExternal: false,
      shouldDownloadOnly: false,
      resolvedUrl: resolvedUrl,
    );
  }

  factory ResolvedFileOpenPlan.embedded({
    required FileRenderStrategy renderStrategy,
    String? resolvedUrl,
  }) {
    return ResolvedFileOpenPlan(
      renderStrategy: renderStrategy,
      shouldOpenInPage: true,
      shouldUseEmbeddedViewer: true,
      shouldOpenExternal: false,
      shouldDownloadOnly: false,
      resolvedUrl: resolvedUrl,
    );
  }

  factory ResolvedFileOpenPlan.downloadOnly({
    required FileRenderStrategy renderStrategy,
    String? resolvedUrl,
    String? fallbackMessage,
  }) {
    return ResolvedFileOpenPlan(
      renderStrategy: renderStrategy,
      shouldOpenInPage: false,
      shouldUseEmbeddedViewer: false,
      shouldOpenExternal: false,
      shouldDownloadOnly: true,
      resolvedUrl: resolvedUrl,
      fallbackMessage: fallbackMessage,
    );
  }
}
