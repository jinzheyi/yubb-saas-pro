import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/models/contact_directory_item.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/widgets/contacts_section_widgets.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ContactPickerSearchField extends StatelessWidget {
  const ContactPickerSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: ThemeColors.searchIcon(context),
        ),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: ThemeColors.searchIcon(context),
                ),
              ),
        filled: true,
        fillColor: ThemeColors.searchBarBg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class ContactPickerCategoryAction {
  const ContactPickerCategoryAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final AppIconKind icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class ContactPickerCategoryPanel extends StatelessWidget {
  const ContactPickerCategoryPanel({
    super.key,
    required this.items,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final List<ContactPickerCategoryAction> items;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ListTile(
                onTap: items[index].onTap,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: items[index].color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    items[index].icon,
                    size: 22,
                    color: items[index].color,
                  ),
                ),
                title: Text(
                  items[index].label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
                trailing: AppIcon(
                  AppIconKind.chevronRight,
                  size: 18,
                  color: ThemeColors.chevronColor(context),
                ),
              ),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                  color: ThemeColors.divider(context),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContactPickerSelectableTile extends StatelessWidget {
  const ContactPickerSelectableTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ContactDirectoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.postName.trim().isNotEmpty
        ? item.postName
        : item.departmentName;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ContactsInitialAvatar(
        name: item.name,
        color: getUserAvatarColor(item.userId),
        avatarUrl: item.avatarUrl,
        size: 42,
        borderRadius: 21,
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ThemeColors.textPrimary(context),
        ),
      ),
      subtitle: subtitle.trim().isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: ThemeColors.textSecondary(context),
              ),
            ),
      trailing: Checkbox(
        value: selected,
        onChanged: (_) => onTap(),
        shape: const CircleBorder(),
      ),
    );
  }
}
