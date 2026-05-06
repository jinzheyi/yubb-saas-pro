import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/repositories/contacts_repository.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/states/contacts_page_state.dart';

class ContactsPageController extends StateNotifier<ContactsPageState> {
  ContactsPageController(this._repository) : super(const ContactsPageState());

  final ContactsRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getContacts();
      state = state.copyWith(isLoading: false, items: items, clearError: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> refresh() async {
    await load();
  }

  void updateKeyword(String value) {
    state = state.copyWith(keyword: value);
  }
}
