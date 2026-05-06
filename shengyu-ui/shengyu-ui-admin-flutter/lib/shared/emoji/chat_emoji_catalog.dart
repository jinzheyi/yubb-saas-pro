abstract final class ChatEmojiCatalog {
  static final Map<String, String> sourceAssetByCode = <String, String>{
    ..._buildGroup(
      _faceCodes,
      sourceFolder: 'face',
      targetFolder: 'face',
      safeFolder: false,
    ),
    ..._buildGroup(
      _gestureCodes,
      sourceFolder: 'gesture',
      targetFolder: 'gesture',
      safeFolder: false,
    ),
    ..._buildGroup(
      _animalCodes,
      sourceFolder: 'animal',
      targetFolder: 'animal',
      safeFolder: false,
    ),
    ..._buildGroup(
      _blessingCodes,
      sourceFolder: 'blessing',
      targetFolder: 'blessing',
      safeFolder: false,
    ),
    ..._buildGroup(
      _otherCodes,
      sourceFolder: 'other',
      targetFolder: 'other',
      safeFolder: false,
    ),
  };

  static final Map<String, String> assetByCode = <String, String>{
    ..._buildGroup(
      _faceCodes,
      sourceFolder: 'face',
      targetFolder: 'face',
      safeFolder: true,
    ),
    ..._buildGroup(
      _gestureCodes,
      sourceFolder: 'gesture',
      targetFolder: 'gesture',
      safeFolder: true,
    ),
    ..._buildGroup(
      _animalCodes,
      sourceFolder: 'animal',
      targetFolder: 'animal',
      safeFolder: true,
    ),
    ..._buildGroup(
      _blessingCodes,
      sourceFolder: 'blessing',
      targetFolder: 'blessing',
      safeFolder: true,
    ),
    ..._buildGroup(
      _otherCodes,
      sourceFolder: 'other',
      targetFolder: 'other',
      safeFolder: true,
    ),
  };

  static final List<String> codes = assetByCode.keys.toList(growable: false);

  static final RegExp tokenRegExp = RegExp(r'\[[\u4e00-\u9fa5\w]+\]');
  static final RegExp _assetPathRegExp = RegExp(
    r'(?:/static|assets)/images/emoji/([^/\s]+)/([^/\s]+?)\.png',
    caseSensitive: false,
  );
  static const Map<String, String> _legacyNameAliases = <String, String>{
    '傻笑': '微笑',
  };

  static String? assetFor(String code) => assetByCode[code];
  static String? sourceAssetFor(String code) => sourceAssetByCode[code];

  static List<String> candidateAssetsFor(String code) {
    final seen = <String>{};
    final items = <String>[];
    void add(String? value) {
      final asset = value?.trim() ?? '';
      if (asset.isEmpty || !seen.add(asset)) {
        return;
      }
      items.add(asset);
    }

    add(assetFor(code));
    add(sourceAssetFor(code));
    return items;
  }

  static String normalizeName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return _legacyNameAliases[trimmed] ?? trimmed;
  }

  static String decodeAssetLikePath(String rawPath) {
    var current = rawPath.trim();
    for (var i = 0; i < 3; i++) {
      final decoded = Uri.decodeFull(current);
      if (decoded == current) {
        break;
      }
      current = decoded;
    }
    return current;
  }

  static String? normalizeTokenContent(String rawContent) {
    final trimmed = rawContent.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (assetByCode.containsKey(trimmed)) {
      return trimmed;
    }
    final tokenFromPath = tokenForAssetLikePath(trimmed);
    if (tokenFromPath != null) {
      return tokenFromPath;
    }
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final normalizedName = normalizeName(
        trimmed.substring(1, trimmed.length - 1),
      );
      final token = '[$normalizedName]';
      return assetByCode.containsKey(token) ? token : null;
    }
    final normalizedName = normalizeName(trimmed);
    final token = '[$normalizedName]';
    return assetByCode.containsKey(token) ? token : null;
  }

  static String? tokenForAssetLikePath(String rawPath) {
    if (rawPath.trim().isEmpty) {
      return null;
    }
    final decodedPath = decodeAssetLikePath(rawPath);
    final match = _assetPathRegExp.firstMatch(decodedPath);
    if (match == null) {
      return null;
    }
    final name = normalizeName(match.group(2) ?? '');
    if (name.isEmpty) {
      return null;
    }
    final token = '[$name]';
    return assetByCode.containsKey(token) ? token : null;
  }

  static String? assetForAssetLikePath(String rawPath) {
    final token = tokenForAssetLikePath(rawPath);
    if (token == null) {
      return null;
    }
    return assetFor(token);
  }

  static Map<String, String> _buildGroup(
    List<String> names, {
    required String sourceFolder,
    required String targetFolder,
    required bool safeFolder,
  }) {
    return <String, String>{
      for (var index = 0; index < names.length; index++)
        '[${names[index]}]': safeFolder
            ? 'assets/images/emoji_safe/$targetFolder/${(index + 1).toString().padLeft(3, '0')}.png'
            : 'assets/images/emoji/$sourceFolder/${names[index]}.png',
    };
  }

  static const List<String> _faceCodes = <String>[
    '666',
    'Emm',
    '亲亲',
    '偷笑',
    '傲慢',
    '再见',
    '加油',
    '发呆',
    '发怒',
    '可怜',
    '右哼哼',
    '叹气',
    '吃瓜',
    '吐',
    '呲牙',
    '咒骂',
    '哇',
    '嘘',
    '嘿哈',
    '囧',
    '困',
    '坏笑',
    '大哭',
    '天啊',
    '失望',
    '奸笑',
    '好的',
    '委屈',
    '害羞',
    '尴尬',
    '得意',
    '微笑',
    '快哭了',
    '恐惧',
    '悠闲',
    '惊恐',
    '惊讶',
    '愉快',
    '憨笑',
    '打脸',
    '抓狂',
    '抠鼻',
    '捂脸',
    '撇嘴',
    '擦汗',
    '敲打',
    '无语',
    '旺柴',
    '晕',
    '机智',
    '汗',
    '流泪',
    '生病',
    '疑问',
    '白眼',
    '皱眉',
    '睡',
    '破涕为笑',
    '社会社会',
    '笑脸',
    '翻白眼',
    '耶',
    '脸红',
    '色',
    '苦涩',
    '衰',
    '裂开',
    '让我看看',
    '调皮',
    '鄙视',
    '闭嘴',
    '阴险',
    '难过',
    '骷髅',
    '鼓掌',
  ];

  static const List<String> _gestureCodes = <String>[
    'OK',
    '勾引',
    '合十',
    '弱',
    '强',
    '抱拳',
    '拥抱',
    '拳头',
    '握手',
    '胜利',
  ];

  static const List<String> _animalCodes = <String>['发抖', '猪头', '跳跳', '转圈'];

  static const List<String> _blessingCodes = <String>[
    '庆祝',
    '烟花',
    '爆竹',
    '發',
    '礼物',
    '福',
    '红包',
  ];

  static const List<String> _otherCodes = <String>[
    '便便',
    '凋谢',
    '咖啡',
    '啤酒',
    '嘴唇',
    '太阳',
    '心碎',
    '月亮',
    '炸弹',
    '爱心',
    '玫瑰',
    '菜刀',
    '蛋糕',
  ];
}
