/// 固定业务类型的协议值与展示文案。
///
/// 服务端对这些字段统一使用整数。`fromApi` 保留旧字符串响应的解析，
/// 便于后端灰度期间客户端仍能稳定展示；可配置类型请使用 TypeService。
enum CatStatus {
  onCampus(0, '在校'),
  graduated(1, '毕业'),
  departed(2, '喵星'),
  hospitalized(3, '住院');

  final int code;
  final String label;
  const CatStatus(this.code, this.label);

  static CatStatus fromApi(dynamic value) => _enumByCodeOrText(
    CatStatus.values,
    value,
    fallback: CatStatus.onCampus,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {'ON_CAMPUS': CatStatus.onCampus},
  );
}

enum CatGender {
  unknown(0, '未知'),
  male(1, '公'),
  female(2, '母');

  final int code;
  final String label;
  const CatGender(this.code, this.label);

  static CatGender fromApi(dynamic value) => _enumByCodeOrText(
    CatGender.values,
    value,
    fallback: CatGender.unknown,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {
      'UNKNOWN': CatGender.unknown,
      'MALE': CatGender.male,
      'FEMALE': CatGender.female,
    },
  );
}

enum CatNeuteredType {
  earCut(0, '剪耳'),
  uncut(1, '未剪耳');

  final int code;
  final String label;
  const CatNeuteredType(this.code, this.label);

  static CatNeuteredType fromApi(dynamic value) => _enumByCodeOrText(
    CatNeuteredType.values,
    value,
    fallback: CatNeuteredType.earCut,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {
      'EAR_CUT': CatNeuteredType.earCut,
      'UNCUT': CatNeuteredType.uncut,
    },
  );
}

enum CatHealthStatus {
  healthy(0, '健康'),
  sick(1, '生病'),
  recovering(2, '恢复中');

  final int code;
  final String label;
  const CatHealthStatus(this.code, this.label);

  static CatHealthStatus fromApi(dynamic value) => _enumByCodeOrText(
    CatHealthStatus.values,
    value,
    fallback: CatHealthStatus.healthy,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {
      'HEALTHY': CatHealthStatus.healthy,
      'SICK': CatHealthStatus.sick,
      'RECOVERING': CatHealthStatus.recovering,
    },
  );
}

enum AdoptionStatus {
  pending(0, 'PENDING', '待审核'),
  interview(1, 'INTERVIEW', '面谈中'),
  approved(2, 'APPROVED', '已通过'),
  rejected(3, 'REJECTED', '已拒绝'),
  completed(4, 'COMPLETED', '已完成');

  final int code;
  final String apiName;
  final String label;
  const AdoptionStatus(this.code, this.apiName, this.label);

  static AdoptionStatus? tryFromApi(dynamic value) => _tryEnumByCodeOrText(
    AdoptionStatus.values,
    value,
    (item) => item.code,
    (item) => item.apiName,
  );
}

enum AdoptionHousing {
  dorm(0, '宿舍'),
  withParents(1, '与父母同住'),
  sharedRental(2, '合租'),
  wholeRental(3, '整租'),
  ownHouse(4, '自有住房');

  final int code;
  final String label;
  const AdoptionHousing(this.code, this.label);

  static AdoptionHousing? tryFromApi(dynamic value) => _tryEnumByCodeOrText(
    AdoptionHousing.values,
    value,
    (item) => item.code,
    (item) => item.label,
    legacyTexts: const {
      'DORM': AdoptionHousing.dorm,
      'WITH_PARENT': AdoptionHousing.withParents,
      'RENT_SHARE': AdoptionHousing.sharedRental,
      'RENT_WHOLE': AdoptionHousing.wholeRental,
      'OWN_HOUSE': AdoptionHousing.ownHouse,
    },
  );
}

enum SosStatus {
  pending(0, 'PENDING', '待处理'),
  processing(1, 'PROCESSING', '处理中'),
  resolved(2, 'RESOLVED', '已完成');

  final int code;
  final String apiName;
  final String label;
  const SosStatus(this.code, this.apiName, this.label);

  static SosStatus? tryFromApi(dynamic value) => _tryEnumByCodeOrText(
    SosStatus.values,
    value,
    (item) => item.code,
    (item) => item.apiName,
  );
}

enum UserBanStatus {
  normal(0, '正常'),
  banned(1, '封禁');

  final int code;
  final String label;
  const UserBanStatus(this.code, this.label);

  static UserBanStatus fromApi(dynamic value) => _enumByCodeOrText(
    UserBanStatus.values,
    value,
    fallback: UserBanStatus.normal,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {
      'NORMAL': UserBanStatus.normal,
      'BANNED': UserBanStatus.banned,
    },
  );
}

enum AnnouncementStatus {
  draft(0, '草稿'),
  published(1, '已发布');

  final int code;
  final String label;
  const AnnouncementStatus(this.code, this.label);

  static AnnouncementStatus fromApi(dynamic value) => _enumByCodeOrText(
    AnnouncementStatus.values,
    value,
    fallback: AnnouncementStatus.published,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {
      'DRAFT': AnnouncementStatus.draft,
      'PUBLISHED': AnnouncementStatus.published,
    },
  );
}

enum AnnouncementType {
  healthKnowledge(0, '健康知识'),
  feedingGuide(1, '喂养指南'),
  behaviorInterpretation(2, '行为解读'),
  campusNews(3, '校园资讯');

  final int code;
  final String label;
  const AnnouncementType(this.code, this.label);

  static AnnouncementType fromApi(dynamic value) => _enumByCodeOrText(
    AnnouncementType.values,
    value,
    fallback: AnnouncementType.campusNews,
    code: (item) => item.code,
    text: (item) => item.label,
    legacyTexts: const {
      'HEALTH': AnnouncementType.healthKnowledge,
      'FEEDING': AnnouncementType.feedingGuide,
      'BEHAVIOR': AnnouncementType.behaviorInterpretation,
      'NEWS': AnnouncementType.campusNews,
    },
  );
}

T _enumByCodeOrText<T>(
  List<T> values,
  dynamic value, {
  required T fallback,
  required int Function(T item) code,
  required String Function(T item) text,
  Map<String, T> legacyTexts = const {},
}) =>
    _tryEnumByCodeOrText(values, value, code, text, legacyTexts: legacyTexts) ??
    fallback;

T? _tryEnumByCodeOrText<T>(
  List<T> values,
  dynamic value,
  int Function(T item) code,
  String Function(T item) text, {
  Map<String, T> legacyTexts = const {},
}) {
  final numericValue = value is num ? value.toInt() : int.tryParse('$value');
  if (numericValue != null) {
    for (final item in values) {
      if (code(item) == numericValue) return item;
    }
  }
  final stringValue = value?.toString().trim() ?? '';
  if (stringValue.isEmpty) return null;
  final normalized = stringValue.toUpperCase();
  final legacy = legacyTexts[normalized];
  if (legacy != null) return legacy;
  for (final item in values) {
    if (text(item) == stringValue || text(item).toUpperCase() == normalized) {
      return item;
    }
  }
  return null;
}
