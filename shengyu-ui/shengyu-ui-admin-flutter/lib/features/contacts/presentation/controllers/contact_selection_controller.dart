import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_selection_entry.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/states/contact_selection_state.dart';

class ContactSelectionController extends StateNotifier<ContactSelectionState> {
  ContactSelectionController() : super(const ContactSelectionState());

  void start({int? limit}) {
    state = ContactSelectionState(active: true, limit: limit);
  }

  void end() {
    state = const ContactSelectionState();
  }

  void ensureSelected(ContactSelectionEntry entry) {
    final next = Map<String, ContactSelectionEntry>.from(state.entries);
    next[entry.id] = entry;
    state = state.copyWith(entries: next);
  }

  void addAll(Iterable<ContactSelectionEntry> entries) {
    final next = Map<String, ContactSelectionEntry>.from(state.entries);
    final limit = state.limit;
    for (final entry in entries) {
      if (next.containsKey(entry.id)) {
        continue;
      }
      if (limit != null && limit > 0 && next.length >= limit) {
        break;
      }
      next[entry.id] = entry;
    }
    state = state.copyWith(entries: next);
  }

  void removeAll(Iterable<String> ids) {
    final next = Map<String, ContactSelectionEntry>.from(state.entries);
    for (final id in ids) {
      final existing = next[id];
      if (existing?.isCurrentUser == true) {
        continue;
      }
      next.remove(id);
    }
    state = state.copyWith(entries: next);
  }

  bool toggle(ContactSelectionEntry entry) {
    final next = Map<String, ContactSelectionEntry>.from(state.entries);
    if (next.containsKey(entry.id)) {
      if (entry.isCurrentUser) {
        return true;
      }
      next.remove(entry.id);
      state = state.copyWith(entries: next);
      return false;
    }
    final limit = state.limit;
    if (limit == 1) {
      next.removeWhere(
        (_, existing) => !existing.isCurrentUser || existing.id == entry.id,
      );
      next[entry.id] = entry;
      state = state.copyWith(entries: next);
      return true;
    }
    if (limit != null && limit > 0 && next.length >= limit) {
      return state.isSelected(entry.id);
    }
    next[entry.id] = entry;
    state = state.copyWith(entries: next);
    return true;
  }
}
