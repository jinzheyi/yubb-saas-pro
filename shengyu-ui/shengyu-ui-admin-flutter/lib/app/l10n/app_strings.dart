import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_locale_controller.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

final appStringsProvider = Provider<AppLocalizations>((ref) {
  return lookupAppLocalizations(ref.watch(appLocaleObjectProvider));
});
