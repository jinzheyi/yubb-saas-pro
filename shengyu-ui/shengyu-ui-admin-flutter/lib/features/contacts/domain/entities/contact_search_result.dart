import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/department_summary.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';

class ContactSearchResult {
  const ContactSearchResult({
    required this.contacts,
    required this.departments,
  });

  final List<ContactDirectoryItem> contacts;
  final List<DepartmentSummary> departments;
}
