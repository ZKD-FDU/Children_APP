/// 聊天输入敏感内容本地检测（仅用于发送前提示，不替代平台审核）

enum SensitiveCategory {
  privacy,
  sexual,
  bullying,
}

class SensitiveCheckResult {
  final bool hasRisk;
  final SensitiveCategory? category;
  final String message;
  final List<String> matches;

  const SensitiveCheckResult({
    required this.hasRisk,
    this.category,
    this.message = '',
    this.matches = const [],
  });

  static const safe = SensitiveCheckResult(hasRisk: false);
}

class SensitiveWordChecker {
  static const _privacyMessage =
      '这条消息可能包含个人隐私信息，比如联系方式或住址。为了保护自己，请修改后再发送。';
  static const _bullyingMessage =
      '这条消息可能包含不友善的表达。试着换一种更礼貌的说法吧。';
  static const _sexualMessage =
      '这条消息可能包含不适合未成年人交流的内容，请修改后再发送。';

  static SensitiveCheckResult check(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return SensitiveCheckResult.safe;

    final normalized = _normalizeText(raw);

    SensitiveCheckResult? r;

    r = _checkPrivacy(normalized, raw);
    if (r != null) return r;

    r = _checkSexual(normalized, raw);
    if (r != null) return r;

    r = _checkBullying(normalized, raw);
    if (r != null) return r;

    return SensitiveCheckResult.safe;
  }

  /// trim、小写、合并空格、常见分隔归一
  static String _normalizeText(String text) {
    var s = text.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'v\s*x'), 'vx');
    s = s.replaceAll(RegExp(r'w\s*x'), 'wx');
    s = s.replaceAll(RegExp(r'q\s*q'), 'qq');
    s = s.replaceAll(RegExp(r'微\s*信'), '微信');
    s = s.replaceAll(RegExp(r'手\s*机\s*号'), '手机号');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  // --- 隐私 ---
  static const _privacyStrong = [
    '手机号',
    '手机号码',
    '电话号码',
    '电话号',
    '联系电话',
    '联系方式',
    '微信号',
    '微信',
    'vx',
    'wx',
    'v信',
    '微号',
    'qq',
    '扣扣',
    '球球',
    '住址',
    '地址',
    '家庭地址',
    '家里地址',
    '门牌号',
    '门牌',
    '身份证',
    '身份证号',
    '身份证号码',
    '学校名称',
    '学校名',
    '班级',
    '几年级',
    '几班',
    '家长电话',
    '妈妈电话',
    '爸爸电话',
    '真实姓名',
    '全名',
    '本名',
    '定位',
    '位置共享',
    '发定位',
    '银行卡',
    '卡号',
    '支付账号',
    '收款码',
  ];

  static const _privacyVariant = [
    '薇信',
    '威信',
    '围信',
    '微x',
    'vx号',
    'wx号',
    'q号',
    '扣号',
    '球球号',
    '手号',
    '电话联系',
    '留个号',
    '发位置',
    '共享位置',
    '开定位',
  ];

  static const _addrHints = ['地址', '住址', '我家', '小区', '栋', '单元', '室', '门牌'];

  static SensitiveCheckResult? _checkPrivacy(String norm, String raw) {
    final matches = <String>[];

    for (final k in _privacyStrong) {
      if (_containsPhrase(norm, raw, k)) {
        matches.add(k);
        return SensitiveCheckResult(
          hasRisk: true,
          category: SensitiveCategory.privacy,
          message: _privacyMessage,
          matches: matches,
        );
      }
    }
    for (final k in _privacyVariant) {
      if (_containsPhrase(norm, raw, k)) {
        matches.add(k);
        return SensitiveCheckResult(
          hasRisk: true,
          category: SensitiveCategory.privacy,
          message: _privacyMessage,
          matches: matches,
        );
      }
    }

    if (RegExp(r'1[3-9]\d{9}').hasMatch(raw)) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.privacy,
        message: _privacyMessage,
        matches: ['手机号模式'],
      );
    }
    if (RegExp(r'\d{17}[\dXx]').hasMatch(raw)) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.privacy,
        message: _privacyMessage,
        matches: ['身份证模式'],
      );
    }
    if (RegExp(
      r'(?:qq|扣扣|球球)\s*[:：]?\s*\d{5,12}',
      caseSensitive: false,
    ).hasMatch(norm)) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.privacy,
        message: _privacyMessage,
        matches: ['qq号码模式'],
      );
    }
    if (RegExp(
      r'(?:微信|vx|wx|wechat)\s*[:：]?\s*[a-z0-9_-]{5,}',
      caseSensitive: false,
    ).hasMatch(norm)) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.privacy,
        message: _privacyMessage,
        matches: ['微信账号模式'],
      );
    }

    var addrHitCount = 0;
    for (final h in _addrHints) {
      if (_containsPhrase(norm, raw, h)) addrHitCount++;
    }
    if (addrHitCount >= 2) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.privacy,
        message: _privacyMessage,
        matches: ['住址组合信息'],
      );
    }

    return null;
  }

  /// 中文/英文短语：norm 中已小写，强关键词里的英文用小写形式匹配
  static bool _containsPhrase(String norm, String raw, String phrase) {
    final p = phrase.trim();
    if (p.isEmpty) return false;
    final lower = p.toLowerCase();
    if (RegExp(r'^[a-z0-9]+$').hasMatch(lower) && lower.length <= 4) {
      return norm.contains(lower) || raw.toLowerCase().contains(lower);
    }
    return raw.contains(p) || norm.contains(lower);
  }

  // --- 色情/软色情（先于霸凌检测，按需求顺序 2） ---
  static const _sexualStrong = [
    '黄图',
    '小黄图',
    '黄色视频',
    '成人视频',
    '裸照',
    '成人片',
    'a片',
    '约炮',
    '性行为',
    '做爱',
    '性交',
    '自慰',
    '手淫',
    '裸聊',
  ];

  static const _sexualBody = [
    '胸',
    '胸部',
    '乳房',
    '屁股',
    '臀',
    '臀部',
    '大腿',
    '腿',
    '腰',
    '私处',
    '下面',
    '隐私部位',
    '内衣',
    '内裤',
    '脱衣服',
    '脱光',
    '裸体',
  ];

  static const _sexualSoft = [
    '亲亲',
    '接吻',
    '抱抱',
    '摸摸',
    '暧昧',
    '勾引',
    '诱惑',
    '撩',
    '色色',
    '色图',
    '福利图',
    '擦边',
    '身材',
    '腿照',
    '胸照',
    '自拍给我看',
    '发照片',
    '发自拍',
    '发一张给我',
    '脱给我看',
    '给我看看',
    '让我看看',
    '好性感',
    '太性感了',
    '真诱人',
    '发张照',
    '发裸照',
    '发私照',
    '视频给我看',
    '开视频',
    '开摄像头',
    '看看你',
    '给我发一张',
    '来张照片',
    '拍给我看',
    '脱给我看',
  ];

  static const _sexualWeak = [
    '性感',
    '撩人',
    '身材',
    '照片',
    '自拍',
    '抱抱',
    '亲亲',
    '看看',
    '福利',
    '腿',
    '腰',
    '胸',
    '内衣',
  ];

  static SensitiveCheckResult? _checkSexual(String norm, String raw) {
    for (final k in _sexualStrong) {
      if (_containsPhrase(norm, raw, k)) {
        return SensitiveCheckResult(
          hasRisk: true,
          category: SensitiveCategory.sexual,
          message: _sexualMessage,
          matches: [k],
        );
      }
    }

    for (final k in _sexualSoft) {
      if (_containsPhrase(norm, raw, k)) {
        return SensitiveCheckResult(
          hasRisk: true,
          category: SensitiveCategory.sexual,
          message: _sexualMessage,
          matches: [k],
        );
      }
    }

    const actionWords = ['看', '发', '拍', '脱', '摸'];
    for (final a in actionWords) {
      for (final b in _sexualBody) {
        if (raw.contains(a) && raw.contains(b)) {
          return SensitiveCheckResult(
            hasRisk: true,
            category: SensitiveCategory.sexual,
            message: _sexualMessage,
            matches: ['$a+$b'],
          );
        }
      }
    }

    final hasMedia =
        raw.contains('照片') || raw.contains('自拍') || raw.contains('视频');
    final hasBodyOrSexy = raw.contains('裸') ||
        raw.contains('胸') ||
        raw.contains('腿') ||
        raw.contains('内衣') ||
        raw.contains('性感');
    if (hasMedia && hasBodyOrSexy) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.sexual,
        message: _sexualMessage,
        matches: ['媒体与身体/敏感组合'],
      );
    }

    var weakCount = 0;
    for (final w in _sexualWeak) {
      if (raw.contains(w)) weakCount++;
    }
    if (weakCount >= 2) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.sexual,
        message: _sexualMessage,
        matches: ['软色情弱组合'],
      );
    }

    return null;
  }

  // --- 霸凌 ---
  static const _bullyStrong = [
    '滚',
    '滚开',
    '滚远点',
    '滚蛋',
    '废物',
    '垃圾',
    '蠢货',
    '白痴',
    '弱智',
    '神经病',
    '有病吧',
    '脑子有病',
    '恶心',
    '真恶心',
    '讨厌死了',
    '烦死了',
    '臭不要脸',
    '不要脸',
    '闭嘴',
    '少说话',
    '别说了',
    '死开',
    '去死',
    '你去死',
    '揍你',
    '打你',
    '收拾你',
    '弄你',
    '你等着',
    '你完了',
    '有你好看',
    '别逼我',
  ];

  static const _bullyIsolate = [
    '不跟你玩',
    '不要你',
    '别来',
    '别跟着我',
    '没人跟你玩',
    '没人喜欢你',
    '大家都讨厌你',
    '你别加入',
    '不带你',
    '不许你来',
    '你走开',
    '离我们远点',
    '别烦我们',
    '你不配',
    '你不行',
    '你不适合',
  ];

  static const _bullyShame = [
    '真丢人',
    '笑死我了',
    '你好可笑',
    '太菜了',
    '真没用',
    '真差劲',
    '你怎么这么笨',
    '你真烦',
    '你真讨厌',
    '你真蠢',
    '别装了',
    '装什么',
    '装可怜',
    '没人会信你',
    '谁会理你',
  ];

  static const _bullyAppearance = [
    '胖子',
    '瘦猴',
    '丑八怪',
    '丑死了',
    '矮子',
    '土包子',
    '怪胎',
    '你长得真丑',
    '真难看',
    '长这么丑',
    '你家真穷',
    '穷鬼',
    '没家教',
  ];

  static const _bullyWeak = [
    '烦',
    '烦人',
    '讨厌',
    '笨',
    '傻',
    '差',
    '菜',
    '弱',
    '丢人',
    '可笑',
    '没用',
  ];

  static SensitiveCheckResult? _checkBullying(String norm, String raw) {
    for (final list in [
      _bullyStrong,
      _bullyIsolate,
      _bullyShame,
      _bullyAppearance,
    ]) {
      for (final k in list) {
        if (_containsPhrase(norm, raw, k)) {
          return SensitiveCheckResult(
            hasRisk: true,
            category: SensitiveCategory.bullying,
            message: _bullyingMessage,
            matches: [k],
          );
        }
      }
    }

    if (RegExp(
            r'你.{0,6}(烦死了|讨厌|笨|傻|差劲|差|菜|弱|没用|烦人|丢人|可笑|烦)')
        .hasMatch(raw)) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.bullying,
        message: _bullyingMessage,
        matches: ['你+弱贬义组合'],
      );
    }

    var wCount = 0;
    for (final w in _bullyWeak) {
      if (raw.contains(w)) wCount++;
    }
    if (wCount >= 2) {
      return SensitiveCheckResult(
        hasRisk: true,
        category: SensitiveCategory.bullying,
        message: _bullyingMessage,
        matches: ['多弱贬义组合'],
      );
    }

    return null;
  }
}
