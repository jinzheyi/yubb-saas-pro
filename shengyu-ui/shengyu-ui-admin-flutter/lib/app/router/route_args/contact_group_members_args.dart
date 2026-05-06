import 'package:shengyu_ui_admin_im/app/router/route_args/contact_picker_args.dart';

class ContactGroupMembersArgs extends ContactPickerArgs {
  const ContactGroupMembersArgs({
    required this.groupId,
    required this.groupName,
    super.selectionMode = true,
    super.selectionLimit,
  });

  final String groupId;
  final String groupName;
}
