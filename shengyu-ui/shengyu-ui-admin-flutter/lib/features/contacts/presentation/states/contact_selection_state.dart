import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';

class ContactSelectionState {
  const ContactSelectionState({
    this.active = false,
    this.limit,
    this.entries = const <String, ContactSelectionEntry>{},
  });

  final bool active;
  final int? limit;
  final Map<String, ContactSelectionEntry> entries;

  int get count => entries.length;

  bool isSelected(String id) => entries.containsKey(id);

  ContactSelectionState copyWith({
    bool? active,
    int? limit,
    Map<String, ContactSelectionEntry>? entries,
  }) {
    return ContactSelectionState(
      active: active ?? this.active,
      limit: limit ?? this.limit,
      entries: entries ?? this.entries,
    );
  }
}
