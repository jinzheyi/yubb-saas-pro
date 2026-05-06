import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/controllers/contact_selection_controller.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/states/contact_selection_state.dart';

final contactSelectionControllerProvider =
    StateNotifierProvider<ContactSelectionController, ContactSelectionState>((
      ref,
    ) {
      return ContactSelectionController();
    });
