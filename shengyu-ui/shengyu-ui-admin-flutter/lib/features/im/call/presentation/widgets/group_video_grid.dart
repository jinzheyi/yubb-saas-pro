import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_participant_view_model.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/widgets/call_video_tile.dart';

class GroupVideoGrid extends StatelessWidget {
  const GroupVideoGrid({super.key, required this.participants});

  final List<CallParticipantViewModel> participants;

  @override
  Widget build(BuildContext context) {
    final visible = participants.take(9).toList(growable: false);
    if (visible.isEmpty) return const ColoredBox(color: Color(0xFF0B0B0D));
    if (visible.length == 1) return CallVideoTile(participant: visible.first);
    if (visible.length == 2) {
      return Column(
        children: [
          for (final participant in visible)
            Expanded(child: _tile(participant)),
        ],
      );
    }
    if (visible.length == 3) {
      return Column(
        children: [
          Expanded(child: _tile(visible[0])),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(visible[1])),
                Expanded(child: _tile(visible[2])),
              ],
            ),
          ),
        ],
      );
    }
    final columns = visible.length == 4 ? 2 : 3;
    // 5～9 人始终保持固定 3×3 格位，避免第 7 人加入时全部画面缩放重排。
    final rows = visible.length == 4 ? 2 : 3;
    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Expanded(
            child: Row(
              children: [
                for (var column = 0; column < columns; column++)
                  Expanded(
                    child: row * columns + column < visible.length
                        ? KeyedSubtree(
                            key: ValueKey(
                              'group-video-cell-${row * columns + column}',
                            ),
                            child: _tile(visible[row * columns + column]),
                          )
                        : SizedBox(
                            key: ValueKey(
                              'group-video-empty-${row * columns + column}',
                            ),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tile(CallParticipantViewModel participant) => Padding(
    padding: const EdgeInsets.all(.5),
    child: CallVideoTile(participant: participant),
  );
}
