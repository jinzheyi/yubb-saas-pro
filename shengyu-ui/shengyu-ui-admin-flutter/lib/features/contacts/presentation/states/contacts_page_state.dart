import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';

class ContactsPageState {
  const ContactsPageState({
    this.isLoading = false,
    this.keyword = '',
    this.items = const <ContactDirectoryItem>[],
    this.errorMessage,
  });

  final bool isLoading;
  final String keyword;
  final List<ContactDirectoryItem> items;
  final String? errorMessage;

  List<ContactDirectoryItem> get filteredItems {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return items;
    }
    return items.where((item) {
      return item.name.contains(trimmed) ||
          item.departmentName.contains(trimmed);
    }).toList();
  }

  ContactsPageState copyWith({
    bool? isLoading,
    String? keyword,
    List<ContactDirectoryItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContactsPageState(
      isLoading: isLoading ?? this.isLoading,
      keyword: keyword ?? this.keyword,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
