import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/group_call_record_text.dart';

void main() {
  test('group records never use unrelated join-group wording', () {
    final values = <String>[
      for (var status = 1; status <= 5; status++)
        groupCallRecordText(
          callerName: '张三',
          isVideo: true,
          status: status,
          durationSeconds: 728,
        ),
    ];
    expect(values, everyElement(isNot(contains('加入了群聊'))));
    expect(values[0], '群视频通话已结束 12:08');
    expect(values[1], '张三发起了群视频通话');
    expect(values[4], '群视频通话已取消');
  });

  test('group duration supports hours', () {
    expect(
      groupCallRecordText(
        callerName: '张三',
        isVideo: false,
        status: 1,
        durationSeconds: 3661,
      ),
      '群语音通话已结束 01:01:01',
    );
  });
}
