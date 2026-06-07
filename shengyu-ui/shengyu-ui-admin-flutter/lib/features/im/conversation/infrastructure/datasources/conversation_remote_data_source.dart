import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/infrastructure/dtos/conversation_sync_response_dto.dart';

class ConversationRemoteDataSource {
  const ConversationRemoteDataSource({required this.dio, required this.currentUserId});

  final Dio dio;
  final String currentUserId;

  Future<List<ConversationDto>> fetchConversationList() async {
    final response = await dio.get('/system/im/conversation/list');
    final result = ApiResult.fromJson<List<ConversationDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) => _mapConversationList(raw),
    );
    return result.requireData();
  }

  Future<ConversationSyncResponseDto> syncConversationList({
    required String cursorVersion,
    int limit = 200,
  }) async {
    final response = await dio.get(
      '/system/im/conversation/sync',
      queryParameters: {'cursorVersion': cursorVersion, 'limit': limit},
    );
    final result = ApiResult.fromJson<ConversationSyncResponseDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return ConversationSyncResponseDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
          currentUserId: currentUserId,
        );
      },
    );
    return result.requireData();
  }

  Future<void> updateConversationSettings({
    required String chatId,
    bool? isPinned,
    bool? noDisturb,
  }) async {
    final data = <String, dynamic>{'chatId': chatId};
    if (isPinned != null) {
      data['isPinned'] = isPinned;
    }
    if (noDisturb != null) {
      data['noDisturb'] = noDisturb;
    }
    await dio.put('/system/im/conversation/update', data: data);
  }

  Future<void> deleteConversation({required String chatId}) async {
    await dio.delete(
      '/system/im/conversation/delete',
      queryParameters: {'chatId': chatId},
    );
  }

  Future<void> markConversationRead({
    required String chatId,
    required String readSequence,
  }) async {
    await dio.put(
      '/system/im/conversation/mark-read-seq',
      queryParameters: {'chatId': chatId, 'readSequence': readSequence},
    );
  }

  List<ConversationDto> _mapConversationList(Object? raw) {
    final items = switch (raw) {
      final List<dynamic> list => list,
      final Map<String, dynamic> map =>
        map['list'] as List<dynamic>? ??
            map['records'] as List<dynamic>? ??
            map['items'] as List<dynamic>? ??
            const [],
      _ => const [],
    };
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => ConversationDto.fromJson(e, currentUserId: currentUserId))
        .toList();
  }
}
