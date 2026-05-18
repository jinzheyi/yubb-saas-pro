import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/icons/shengyu_icon_font.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

const _searchHistoryKey = 'IM_SEARCH_HISTORY';
const _searchHotKey = 'IM_SEARCH_HOT';
const _hotSearchTtlMs = 6 * 60 * 60 * 1000;
const _minSearchKeywordLength = 2;
const _searchDebounceMs = 300;
const _searchSameQueryDedupMs = 1200;
const _pageSize = 20;

class CommonGlobalSearchPage extends ConsumerStatefulWidget {
  const CommonGlobalSearchPage({super.key, this.initialKeyword = ''});

  final String initialKeyword;

  @override
  ConsumerState<CommonGlobalSearchPage> createState() =>
      _CommonGlobalSearchPageState();
}

class _CommonGlobalSearchPageState
    extends ConsumerState<CommonGlobalSearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  final List<String> _historyList = <String>[];
  final List<String> _hotList = <String>[];
  final List<_SearchTabItem> _tabs = const <_SearchTabItem>[
    _SearchTabItem(key: 'all', label: '全部'),
    _SearchTabItem(key: 'message', label: '消息'),
    _SearchTabItem(key: 'contact', label: '联系人'),
    _SearchTabItem(key: 'group', label: '群聊'),
    _SearchTabItem(key: 'media', label: '媒体'),
  ];

  List<_GlobalSearchResultItem> _resultList = const <_GlobalSearchResultItem>[];
  _SearchFacets _facets = const _SearchFacets();
  String _activeTab = 'all';
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _currentPageNo = 1;
  int _requestSeq = 0;
  int _hotSearchSeq = 0;
  String _lastFirstPageKey = '';
  int _lastFirstPageAt = 0;
  _SearchResponse? _lastFirstPageResponse;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialKeyword);
    _searchFocusNode = FocusNode();
    Future.microtask(() async {
      await _loadHistoryFromStorage();
      await _loadHotFromStorage();
      if (_normalizedKeyword().isNotEmpty) {
        await _handleSearchConfirm();
      }
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showResultPanel =
        _normalizedKeyword().length >= _minSearchKeywordLength;
    final showTipPanel = _normalizedKeyword().isNotEmpty && !showResultPanel;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            ShengyuIconFont.chaxun,
                            size: 16,
                            color: Color(0xFF98A1B2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF202531),
                              ),
                              decoration: const InputDecoration(
                                hintText: '搜索',
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                              onChanged: (_) {
                                setState(() {});
                                _handleSearchInput();
                              },
                              onSubmitted: (_) => _handleSearchConfirm(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF246BFD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!showResultPanel && _historyList.isNotEmpty)
              _SearchHistoryPanel(
                historyList: _historyList,
                onTap: _searchHistory,
                onClear: _clearHistory,
                onDelete: _deleteHistoryKeyword,
              ),
            if (!showResultPanel && _hotList.isNotEmpty)
              _SearchHotPanel(hotList: _hotList, onTap: _searchHot),
            if (showTipPanel)
              const Expanded(
                child: Center(
                  child: Text(
                    '请输入至少 2 个字符开始搜索',
                    style: TextStyle(fontSize: 14, color: Color(0xFF98A1B2)),
                  ),
                ),
              )
            else if (!showResultPanel)
              const Expanded(child: SizedBox())
            else
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 52,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final tab = _tabs[index];
                          final active = _activeTab == tab.key;
                          return GestureDetector(
                            onTap: () => _switchTab(tab.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFEAF2FF)
                                    : const Color(0xFFF3F4F8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _buildTabLabel(tab),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: active
                                      ? const Color(0xFF246BFD)
                                      : const Color(0xFF697386),
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemCount: _tabs.length,
                      ),
                    ),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 48) {
                            _loadMore();
                          }
                          return false;
                        },
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (_resultList.isNotEmpty)
                              ..._resultList.map(
                                (item) => _SearchResultTile(
                                  item: item,
                                  keyword: _normalizedKeyword(),
                                  onTap: () => _handleResultClick(item),
                                  onAvatarError: () => _handleAvatarError(item),
                                ),
                              ),
                            if (_loading && _resultList.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    '搜索中...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF98A1B2),
                                    ),
                                  ),
                                ),
                              ),
                            if (!_loading && _resultList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 64,
                                ),
                                child: Center(
                                  child: Text(
                                    '未找到“${_normalizedKeyword()}”相关内容',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF697386),
                                    ),
                                  ),
                                ),
                              ),
                            if (_loadingMore && _resultList.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    '加载更多...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF98A1B2),
                                    ),
                                  ),
                                ),
                              ),
                            if (!_loading &&
                                !_loadingMore &&
                                !_hasMore &&
                                _resultList.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    '没有更多了',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF98A1B2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _normalizedKeyword() => _searchController.text.trim();

  Future<void> _loadHistoryFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_searchHistoryKey) ?? const <String>[];
    _historyList
      ..clear()
      ..addAll(list.where((item) => item.trim().isNotEmpty));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchHistoryKey, _historyList);
  }

  Future<void> _loadHotFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final list =
        prefs.getStringList('${_searchHotKey}_list') ?? const <String>[];
    final fetchedAt = prefs.getInt('${_searchHotKey}_fetchedAt') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
    if (list.isNotEmpty &&
        fetchedAt > 0 &&
        age >= 0 &&
        age <= _hotSearchTtlMs) {
      _hotList
        ..clear()
        ..addAll(list.where((item) => item.trim().isNotEmpty));
      if (mounted) {
        setState(() {});
      }
      return;
    }
    await _fetchHotSearch();
  }

  Future<void> _persistHotSearch(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_searchHotKey}_list', list);
    await prefs.setInt(
      '${_searchHotKey}_fetchedAt',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _fetchHotSearch() async {
    final seq = ++_hotSearchSeq;
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/system/im/search/hot',
        queryParameters: {'limit': 10},
      );
      final result = ApiResult.fromJson<Object?>(
        response.data as Map<String, dynamic>,
        dataParser: (raw) => raw,
      ).requireData();
      if (seq != _hotSearchSeq) {
        return;
      }
      final list = switch (result) {
        final List<dynamic> values => values,
        final Map<String, dynamic> map =>
          map['list'] as List<dynamic>? ?? const [],
        _ => const <dynamic>[],
      };
      final normalized = list
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      _hotList
        ..clear()
        ..addAll(normalized);
      await _persistHotSearch(normalized);
      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  void _handleSearchInput() {
    final keyword = _normalizedKeyword();
    if (keyword.isEmpty || keyword.length < _minSearchKeywordLength) {
      _searchTimer?.cancel();
      _requestSeq += 1;
      _resetResultState(clearList: true);
      setState(() {});
      return;
    }
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: _searchDebounceMs),
      () => _searchNow(reset: true),
    );
  }

  Future<void> _handleSearchConfirm() async {
    final keyword = _normalizedKeyword();
    if (keyword.isEmpty) {
      return;
    }
    _historyList.removeWhere((item) => item == keyword);
    _historyList.insert(0, keyword);
    if (_historyList.length > 10) {
      _historyList.removeRange(10, _historyList.length);
    }
    await _persistHistory();
    if (mounted) {
      setState(() {});
    }
    await _searchNow(reset: true);
  }

  void _resetResultState({required bool clearList}) {
    if (clearList) {
      _resultList = const <_GlobalSearchResultItem>[];
    }
    _facets = const _SearchFacets();
    _hasMore = false;
    _currentPageNo = 1;
  }

  Future<void> _searchNow({required bool reset}) async {
    final keyword = _normalizedKeyword();
    if (keyword.length < _minSearchKeywordLength) {
      _resetResultState(clearList: true);
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (reset) {
      _resetResultState(clearList: true);
    } else if (!_hasMore || _loading || _loadingMore) {
      return;
    }
    final pageNo = reset ? 1 : _currentPageNo;
    final firstPageKey = '$_activeTab|$keyword';
    final now = DateTime.now().millisecondsSinceEpoch;
    if (reset &&
        _lastFirstPageResponse != null &&
        firstPageKey == _lastFirstPageKey &&
        now - _lastFirstPageAt <= _searchSameQueryDedupMs) {
      _applySearchResponse(_lastFirstPageResponse!, pageNo: 1, reset: true);
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final seq = ++_requestSeq;
    if (mounted) {
      setState(() {
        if (reset) {
          _loading = true;
        } else {
          _loadingMore = true;
        }
      });
    }
    try {
      final response = await _fetchByGlobalApi(
        keyword: keyword,
        tab: _activeTab,
        pageNo: pageNo,
        pageSize: _pageSize,
      );
      if (seq != _requestSeq) {
        return;
      }
      _applySearchResponse(response, pageNo: pageNo, reset: reset);
      if (reset) {
        _lastFirstPageKey = firstPageKey;
        _lastFirstPageAt = now;
        _lastFirstPageResponse = response;
      }
    } catch (_) {
      if (seq != _requestSeq) {
        return;
      }
      if (reset) {
        _resultList = const <_GlobalSearchResultItem>[];
      }
      _hasMore = false;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<_SearchResponse> _fetchByGlobalApi({
    required String keyword,
    required String tab,
    required int pageNo,
    required int pageSize,
  }) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/system/im/search/global',
      queryParameters: <String, dynamic>{
        'keyword': keyword,
        'tab': tab,
        'pageNo': pageNo,
        'pageSize': pageSize,
        'sort': 'relevance',
        'chatId': '',
      },
    );
    final raw = ApiResult.fromJson<Map<String, dynamic>>(
      response.data as Map<String, dynamic>,
      dataParser: (value) => value as Map<String, dynamic>? ?? const {},
    ).requireData();
    final list = raw['list'] as List<dynamic>? ?? const [];
    return _SearchResponse(
      list: list
          .whereType<Map<String, dynamic>>()
          .map(_mapGlobalItem)
          .toList(growable: false),
      total: _parseInt(raw['total']),
      hasMore: raw['hasMore'] == true,
      facets: _SearchFacets.fromJson(raw['facets'] as Map<String, dynamic>?),
    );
  }

  void _applySearchResponse(
    _SearchResponse response, {
    required int pageNo,
    required bool reset,
  }) {
    _facets = response.facets;
    _hasMore = response.hasMore;
    _currentPageNo = response.hasMore ? pageNo + 1 : pageNo;
    if (reset) {
      _resultList = response.list;
      return;
    }
    final items = <String, _GlobalSearchResultItem>{};
    for (final item in _resultList) {
      items[item.uniqueId] = item;
    }
    for (final item in response.list) {
      items.putIfAbsent(item.uniqueId, () => item);
    }
    _resultList = items.values.toList(growable: false);
  }

  _GlobalSearchResultItem _mapGlobalItem(Map<String, dynamic> raw) {
    final type = _safeString(raw['type']);
    final id = _safeString(raw['id']);
    final chatId = _safeString(raw['chatId']);
    final messageId = _safeString(raw['messageId']);
    final sequence = _safeString(raw['sequence']);
    final title = _safeString(raw['title']);
    final subTitle = _safeString(raw['subTitle']);
    final meta = raw['meta'];
    final avatarUrl = _resolveAvatarUrlByType(type: type, meta: meta, raw: raw);
    final conversationType = _resolveConversationType(meta: meta, raw: raw);
    final targetId = _safeString(
      meta is Map<String, dynamic> ? meta['targetId'] : null,
    );
    final groupId = _safeString(raw['groupId']);
    final avatarId = targetId.isNotEmpty
        ? targetId
        : (groupId.isNotEmpty ? groupId : (chatId.isNotEmpty ? chatId : id));
    return _GlobalSearchResultItem(
      uniqueId: '$type:$id:$chatId:$messageId',
      id: id,
      type: type,
      title: title,
      subTitle: subTitle,
      snippet: _normalizeSnippet(
        type: type,
        value: _safeString(raw['snippet']),
        meta: meta,
      ),
      time: _parseTimeMs(raw['time']),
      chatId: chatId,
      messageId: messageId,
      sequence: sequence,
      typeLabel: _buildTypeLabel(type: type, meta: meta),
      avatarUrl: avatarUrl,
      avatarText: type == 'group' || conversationType == ConversationType.group
          ? getAvatarText(title.isNotEmpty ? title : avatarId)
          : getAvatarText(title.isNotEmpty ? title : avatarId),
      avatarBg: type == 'group' || conversationType == ConversationType.group
          ? getGroupAvatarColor(avatarId)
          : (type == 'contact'
                ? getUserAvatarColor(avatarId)
                : getConversationAvatarColor(
                    ConversationType.direct,
                    avatarId,
                  )),
      avatarIcon: '',
      meta: meta,
    );
  }

  String _normalizeSnippet({
    required String type,
    required String value,
    required Object? meta,
  }) {
    if (type != 'message' && type != 'media') {
      return value;
    }
    final data = meta is Map<String, dynamic>
        ? meta
        : const <String, dynamic>{};
    switch (_safeString(data['messageType'])) {
      case '2':
        return '[图片]';
      case '3':
        return '[语音]';
      case '4':
        return '[视频]';
      case '5':
        final name = _safeString(data['fileName']).isNotEmpty
            ? _safeString(data['fileName'])
            : _safeString(data['name']);
        return name.isNotEmpty ? '[文件] $name' : '[文件]';
      case '6':
      case '105':
        return '[位置]';
      case '7':
        return '[表情]';
      case '8':
        return '[贴纸]';
      default:
        if (value.startsWith('{') || value.startsWith('[')) {
          return '[消息]';
        }
        return value;
    }
  }

  String _buildTypeLabel({required String type, required Object? meta}) {
    if (type == 'contact') {
      return '联系人';
    }
    if (type == 'group') {
      return '群聊';
    }
    if (type == 'media') {
      return '媒体';
    }
    return _resolveConversationType(meta: meta, raw: meta) ==
            ConversationType.group
        ? '群消息'
        : '单聊消息';
  }

  String _resolveAvatarUrlByType({
    required String type,
    required Object? meta,
    required Map<String, dynamic> raw,
  }) {
    final data = meta is Map<String, dynamic>
        ? meta
        : const <String, dynamic>{};
    if (type == 'contact') {
      return _normalizeAvatarUrl(raw['avatar']) == ''
          ? _normalizeAvatarUrl(data['avatar'])
          : _normalizeAvatarUrl(raw['avatar']);
    }
    if (type == 'group') {
      return _normalizeAvatarUrl(raw['targetAvatar']) == ''
          ? _normalizeAvatarUrl(raw['avatar'])
          : _normalizeAvatarUrl(raw['targetAvatar']);
    }
    final conversationAvatar =
        _normalizeAvatarUrl(raw['conversationAvatar']).isNotEmpty
        ? _normalizeAvatarUrl(raw['conversationAvatar'])
        : _normalizeAvatarUrl(raw['targetAvatar']).isNotEmpty
        ? _normalizeAvatarUrl(raw['targetAvatar'])
        : _normalizeAvatarUrl(data['conversationAvatar']).isNotEmpty
        ? _normalizeAvatarUrl(data['conversationAvatar'])
        : _normalizeAvatarUrl(data['targetAvatar']);
    if (conversationAvatar.isNotEmpty) {
      return conversationAvatar;
    }
    return _normalizeAvatarUrl(raw['senderAvatar']).isNotEmpty
        ? _normalizeAvatarUrl(raw['senderAvatar'])
        : _normalizeAvatarUrl(data['senderAvatar']);
  }

  ConversationType _resolveConversationType({
    required Object? meta,
    required Object? raw,
  }) {
    if (meta is Map<String, dynamic>) {
      final fromMeta = _parseInt(meta['conversationType']);
      if (fromMeta == 2) {
        return ConversationType.group;
      }
      if (fromMeta == 1) {
        return ConversationType.direct;
      }
    }
    if (raw is Map<String, dynamic>) {
      final groupId = _safeString(raw['groupId']);
      if (groupId.isNotEmpty && groupId != '0') {
        return ConversationType.group;
      }
    }
    return ConversationType.direct;
  }

  int _parseTimeMs(Object? value) {
    final numeric = _parseInt(value);
    if (numeric > 0) {
      return numeric > 100000000000 ? numeric : numeric * 1000;
    }
    final text = _safeString(value);
    if (text.isEmpty) {
      return 0;
    }
    return DateTime.tryParse(text)?.millisecondsSinceEpoch ?? 0;
  }

  int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(_safeString(value)) ?? 0;
  }

  String _safeString(Object? value) => value?.toString().trim() ?? '';

  String _normalizeAvatarUrl(Object? value) {
    final text = _safeString(value);
    if (text == 'null' || text == 'undefined') {
      return '';
    }
    return text;
  }

  String _buildTabLabel(_SearchTabItem tab) {
    final count = switch (tab.key) {
      'all' => _facets.all,
      'message' => _facets.message,
      'contact' => _facets.contact,
      'group' => _facets.group,
      'media' => _facets.media,
      _ => 0,
    };
    if (_normalizedKeyword().length < _minSearchKeywordLength || count <= 0) {
      return tab.label;
    }
    return count > 99 ? '${tab.label}(99+)' : '${tab.label}($count)';
  }

  Future<void> _switchTab(String tabKey) async {
    if (_activeTab == tabKey) {
      return;
    }
    setState(() {
      _activeTab = tabKey;
    });
    if (_normalizedKeyword().length >= _minSearchKeywordLength) {
      await _searchNow(reset: true);
      return;
    }
    _resetResultState(clearList: true);
    if (mounted) {
      setState(() {});
    }
  }

  void _loadMore() {
    if (_normalizedKeyword().length < _minSearchKeywordLength) {
      return;
    }
    unawaited(_searchNow(reset: false));
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空搜索历史'),
        content: const Text('确认清空全部搜索历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    _historyList.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
    if (mounted) {
      setState(() {});
    }
  }

  void _searchHistory(String keyword) {
    _searchController.text = keyword;
    setState(() {});
    unawaited(_handleSearchConfirm());
  }

  Future<void> _deleteHistoryKeyword(String keyword) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除搜索历史'),
        content: Text('确认删除“$keyword”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    _historyList.removeWhere((item) => item == keyword);
    await _persistHistory();
    if (mounted) {
      setState(() {});
    }
  }

  void _searchHot(String keyword) {
    _searchController.text = keyword;
    setState(() {});
    unawaited(_handleSearchConfirm());
  }

  void _handleResultClick(_GlobalSearchResultItem item) {
    if (item.type == 'contact') {
      context.pushNamed(
        RouteNames.contactsProfile,
        pathParameters: <String, String>{'userId': item.id},
        extra: <String, String>{'name': item.title},
      );
      return;
    }
    if (item.type == 'group') {
      context.pushNamed(
        RouteNames.chat,
        extra: ChatEntryArgs.latest(
          chatId: item.chatId,
          conversationType: ConversationType.group,
          targetId: item.id,
          title: item.title,
        ),
      );
      return;
    }
    if (item.type == 'message' || item.type == 'media') {
      final messageId = item.messageId.isNotEmpty ? item.messageId : item.id;
      if (item.chatId.isEmpty || messageId.isEmpty) {
        return;
      }
      final conversationType = _resolveConversationType(
        meta: item.meta,
        raw: item.meta,
      );
      final targetId = conversationType == ConversationType.group
          ? _safeString(
              item.meta is Map<String, dynamic>
                  ? (item.meta as Map<String, dynamic>)['groupId'] ??
                        (item.meta as Map<String, dynamic>)['targetId']
                  : null,
            )
          : _safeString(
              item.meta is Map<String, dynamic>
                  ? (item.meta as Map<String, dynamic>)['targetId']
                  : null,
            );
      context.pushNamed(
        RouteNames.chat,
        extra: ChatEntryArgs(
          chatId: item.chatId,
          conversationType: conversationType,
          targetId: targetId.isEmpty ? null : targetId,
          title: item.title,
          entryMode: ChatEntryMode.anchor,
          anchorSequence: item.sequence.isNotEmpty ? item.sequence : null,
          anchorMessageId: item.sequence.isEmpty ? messageId : null,
          highlightedMessageId: messageId,
        ),
      );
    }
  }

  void _handleAvatarError(_GlobalSearchResultItem item) {
    final index = _resultList.indexWhere(
      (element) => element.uniqueId == item.uniqueId,
    );
    if (index < 0) {
      return;
    }
    final next = [..._resultList];
    next[index] = item.copyWith(avatarUrl: '');
    setState(() {
      _resultList = next;
    });
  }
}

class _SearchHistoryPanel extends StatelessWidget {
  const _SearchHistoryPanel({
    required this.historyList,
    required this.onTap,
    required this.onClear,
    required this.onDelete,
  });

  final List<String> historyList;
  final ValueChanged<String> onTap;
  final Future<void> Function() onClear;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 13, color: Color(0xFF98A1B2)),
                ),
              ),
              GestureDetector(
                onTap: () => unawaited(onClear()),
                child: const Icon(
                  ShengyuIconFont.shanchu,
                  size: 16,
                  color: Color(0xFF98A1B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: historyList
                .map((item) {
                  return GestureDetector(
                    onTap: () => onTap(item),
                    onLongPress: () => onDelete(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF697386),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SearchHotPanel extends StatelessWidget {
  const _SearchHotPanel({required this.hotList, required this.onTap});

  final List<String> hotList;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热门搜索',
            style: TextStyle(fontSize: 13, color: Color(0xFF98A1B2)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hotList
                .map((item) {
                  return GestureDetector(
                    onTap: () => onTap(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF697386),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.item,
    required this.keyword,
    required this.onTap,
    required this.onAvatarError,
  });

  final _GlobalSearchResultItem item;
  final String keyword;
  final VoidCallback onTap;
  final VoidCallback onAvatarError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultAvatar(item: item, onAvatarError: onAvatarError),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.typeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF697386),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HighlightText(
                            text: item.title,
                            keyword: keyword,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202531),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatResultTime(item.time),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF98A1B2),
                          ),
                        ),
                      ],
                    ),
                    if (item.subTitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _HighlightText(
                        text: item.subTitle,
                        keyword: keyword,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF697386),
                        ),
                      ),
                    ],
                    if (item.snippet.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _HighlightText(
                        text: item.snippet,
                        keyword: keyword,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4E5666),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatResultTime(int timestamp) {
    if (timestamp <= 0) {
      return '';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    if (date.year == now.year) {
      return '$month/$day';
    }
    return '${date.year}/$month/$day';
  }
}

class _ResultAvatar extends StatelessWidget {
  const _ResultAvatar({required this.item, required this.onAvatarError});

  final _GlobalSearchResultItem item;
  final VoidCallback onAvatarError;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: item.avatarText,
      avatarUrl: item.avatarUrl,
      backgroundColor: item.avatarBg,
      size: 44,
      borderRadius: 8,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      onImageError: onAvatarError,
      fallbackChild: item.avatarIcon.isNotEmpty
          ? Text(
              item.avatarIcon,
              style: const TextStyle(
                fontFamily: ShengyuIconFont.family,
                color: Colors.white,
                fontSize: 22,
              ),
            )
          : null,
    );
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.keyword,
    required this.style,
  });

  final String text;
  final String keyword;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lower = text.toLowerCase();
    final query = keyword.toLowerCase();
    final spans = <InlineSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: style.copyWith(color: const Color(0xFF246BFD)),
        ),
      );
      start = index + keyword.length;
      if (start >= text.length) {
        break;
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SearchTabItem {
  const _SearchTabItem({required this.key, required this.label});

  final String key;
  final String label;
}

class _SearchFacets {
  const _SearchFacets({
    this.all = 0,
    this.message = 0,
    this.contact = 0,
    this.group = 0,
    this.media = 0,
  });

  factory _SearchFacets.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const _SearchFacets();
    }
    return _SearchFacets(
      all: int.tryParse('${json['all'] ?? 0}') ?? 0,
      message: int.tryParse('${json['message'] ?? 0}') ?? 0,
      contact: int.tryParse('${json['contact'] ?? 0}') ?? 0,
      group: int.tryParse('${json['group'] ?? 0}') ?? 0,
      media: int.tryParse('${json['media'] ?? 0}') ?? 0,
    );
  }

  final int all;
  final int message;
  final int contact;
  final int group;
  final int media;
}

class _SearchResponse {
  const _SearchResponse({
    required this.list,
    required this.total,
    required this.hasMore,
    required this.facets,
  });

  final List<_GlobalSearchResultItem> list;
  final int total;
  final bool hasMore;
  final _SearchFacets facets;
}

class _GlobalSearchResultItem {
  const _GlobalSearchResultItem({
    required this.uniqueId,
    required this.id,
    required this.type,
    required this.title,
    required this.subTitle,
    required this.snippet,
    required this.time,
    required this.chatId,
    required this.messageId,
    required this.sequence,
    required this.typeLabel,
    required this.avatarUrl,
    required this.avatarText,
    required this.avatarBg,
    required this.avatarIcon,
    required this.meta,
  });

  final String uniqueId;
  final String id;
  final String type;
  final String title;
  final String subTitle;
  final String snippet;
  final int time;
  final String chatId;
  final String messageId;
  final String sequence;
  final String typeLabel;
  final String avatarUrl;
  final String avatarText;
  final Color avatarBg;
  final String avatarIcon;
  final Object? meta;

  _GlobalSearchResultItem copyWith({String? avatarUrl}) {
    return _GlobalSearchResultItem(
      uniqueId: uniqueId,
      id: id,
      type: type,
      title: title,
      subTitle: subTitle,
      snippet: snippet,
      time: time,
      chatId: chatId,
      messageId: messageId,
      sequence: sequence,
      typeLabel: typeLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarText: avatarText,
      avatarBg: avatarBg,
      avatarIcon: avatarIcon,
      meta: meta,
    );
  }
}
