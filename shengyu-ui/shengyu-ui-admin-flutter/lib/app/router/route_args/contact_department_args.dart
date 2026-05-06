import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';

class ContactDepartmentArgs extends ContactPickerArgs {
  const ContactDepartmentArgs({
    super.selectionMode = false,
    super.selectionLimit,
    this.initialDeptId,
    this.initialDeptName,
  });

  final String? initialDeptId;
  final String? initialDeptName;
}
