# extended_text_field (Forked for Flutter 3.44 Compatibility)

## Source
Forked from `extended_text_field` 14.0.0

## Changes Made for Flutter 3.44
1. `layoutInlineChildren` — added `ChildLayoutHelper.getBaseline` as 3rd parameter
   - File: `lib/src/official/rendering/editable.dart`

2. `isSelectionWithinTextBounds` — removed in Flutter 3.44, replaced with manual bounds check
   - File: `lib/src/official/widgets/editable_text.dart`

3. `ExtendSelectionByPageIntent` — removed in Flutter 3.44
   - File: `lib/src/official/widgets/editable_text.dart`
   - Removed method `_extendSelectionByPage` and its action registration

## How to Update to Official Version
When the official package supports Flutter 3.44+:

1. Remove `dependency_overrides` from `pubspec.yaml`
2. Delete this `_packages/extended_text_field` directory
3. Run `flutter pub get`
