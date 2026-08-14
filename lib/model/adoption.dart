/// 居住类型 -> 中文（0宿舍 1与父母同住 2合租 3整租 4自有住房）
/// 领养状态采用整数传输：0 待审核、1 面谈、2 通过、3 拒绝、4 完成。
String adoptionStatusName(dynamic value) {
  if (value is num) {
    return switch (value.toInt()) {
      0 => 'PENDING',
      1 => 'INTERVIEW',
      2 => 'APPROVED',
      3 => 'REJECTED',
      4 => 'COMPLETED',
      _ => value.toString(),
    };
  }
  final text = value?.toString() ?? '';
  final code = int.tryParse(text);
  if (code != null) return adoptionStatusName(code);
  return text.toUpperCase();
}

int? adoptionStatusCode(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed != null) return parsed;
  return switch (value.toUpperCase()) {
    'PENDING' => 0,
    'INTERVIEW' => 1,
    'APPROVED' => 2,
    'REJECTED' => 3,
    'COMPLETED' => 4,
    _ => null,
  };
}

String adoptionHousingLabel(dynamic value) {
  if (value is num) {
    const map = {0: '宿舍', 1: '与父母同住', 2: '合租', 3: '整租', 4: '自有住房'};
    return map[value.toInt()] ?? '—';
  }
  final str = value?.toString() ?? '';
  if (str.isEmpty) return '—';
  switch (str) {
    case 'DORM':
      return '宿舍';
    case 'WITH_PARENT':
      return '与父母同住';
    case 'RENT_SHARE':
      return '合租';
    case 'RENT_WHOLE':
      return '整租';
    case 'OWN_HOUSE':
      return '自有住房';
  }
  return str;
}

class AdoptionContact {
  final String phone;
  final String wechat;

  const AdoptionContact({required this.phone, required this.wechat});

  factory AdoptionContact.fromJson(Map<String, dynamic> json) {
    return AdoptionContact(
      phone: _stringValue(json['phone']),
      wechat: _stringValue(json['wechat']),
    );
  }

  Map<String, dynamic> toJson() => {'phone': phone, 'wechat': wechat};
}

class AdoptionInfo {
  final int? housing;
  final String experience;
  final String plan;

  const AdoptionInfo({
    required this.housing,
    required this.experience,
    required this.plan,
  });

  factory AdoptionInfo.fromJson(Map<String, dynamic> json) {
    final housingValue = json['housing'];
    return AdoptionInfo(
      housing: housingValue is num
          ? housingValue.toInt()
          : (int.tryParse(housingValue?.toString() ?? '')),
      experience: _stringValue(json['experience']),
      plan: _stringValue(json['plan']),
    );
  }

  Map<String, dynamic> toJson() => {
    'housing': housing,
    'experience': experience,
    'plan': plan,
  };
}

class AdminAdoptionListPage {
  final int total;
  final int? size;
  final int? current;
  final int? pages;
  final List<AdminAdoptionItem> items;

  AdminAdoptionListPage({
    required this.total,
    required this.items,
    this.size,
    this.current,
    this.pages,
  });

  factory AdminAdoptionListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return AdminAdoptionListPage(
      total: _intValue(json['total']) ?? 0,
      size: _intValue(json['size']),
      current: _intValue(json['current']),
      pages: _intValue(json['pages']),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(AdminAdoptionItem.fromJson)
          .toList(),
    );
  }
}

class UserAdoptionListPage {
  final int total;
  final int? size;
  final int? current;
  final int? pages;
  final List<UserAdoptionItem> items;

  UserAdoptionListPage({
    required this.total,
    required this.items,
    this.size,
    this.current,
    this.pages,
  });

  factory UserAdoptionListPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return UserAdoptionListPage(
      total: _intValue(json['total']) ?? 0,
      size: _intValue(json['size']),
      current: _intValue(json['current']),
      pages: _intValue(json['pages']),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(UserAdoptionItem.fromJson)
          .toList(),
    );
  }
}

class UserAdoptionItem {
  final String id;
  final String catId;
  final String catName;
  final String? catAvatar;
  final String status;
  final String? createTime;
  final String? reason;

  UserAdoptionItem({
    required this.id,
    required this.catId,
    required this.catName,
    required this.status,
    this.catAvatar,
    this.createTime,
    this.reason,
  });

  factory UserAdoptionItem.fromJson(Map<String, dynamic> json) {
    return UserAdoptionItem(
      id: _stringValue(json['id']),
      catId: _stringValue(json['catId']),
      catName: _stringValue(json['catName']),
      catAvatar: _nullableString(json['catAvatar']),
      status: adoptionStatusName(json['status']),
      createTime: _nullableString(json['createTime'] ?? json['create_time']),
      reason: _nullableString(json['reason'] ?? json['rejectReason']),
    );
  }
}

class AdminAdoptionItem {
  final String id;
  final String? userId;
  final String userName;
  final String? userAvatar;
  final String? userStudentId;
  final String? userCampus;
  final String? userCollege;
  final String catId;
  final String catName;
  final String? catAvatar;
  final String status;
  final String? createTime;
  final AdoptionContact? contact;
  final AdoptionInfo? info;

  AdminAdoptionItem({
    required this.id,
    required this.userName,
    required this.catId,
    required this.catName,
    required this.status,
    this.userId,
    this.userAvatar,
    this.userStudentId,
    this.userCampus,
    this.userCollege,
    this.catAvatar,
    this.createTime,
    this.contact,
    this.info,
  });

  factory AdminAdoptionItem.fromJson(Map<String, dynamic> json) {
    final contactJson = json['contact'];
    final infoJson = json['info'] ?? json['formDetails'];
    return AdminAdoptionItem(
      id: _stringValue(json['id']),
      userId: _nullableString(json['userId']),
      userName: _stringValue(json['userName'] ?? json['applicantName']),
      userAvatar: _nullableString(json['userAvatar'] ?? json['avatar']),
      userStudentId: _nullableString(json['studentId'] ?? json['sid']),
      userCampus: _nullableString(json['campus']),
      userCollege: _nullableString(json['college']),
      catId: _stringValue(json['catId']),
      catName: _stringValue(json['catName']),
      catAvatar: _nullableString(json['catAvatar']),
      status: adoptionStatusName(json['status']),
      createTime: _nullableString(json['createTime'] ?? json['create_time']),
      contact: contactJson is Map<String, dynamic>
          ? AdoptionContact.fromJson(contactJson)
          : null,
      info: infoJson is Map<String, dynamic>
          ? AdoptionInfo.fromJson(infoJson)
          : null,
    );
  }

  AdminAdoptionItem copyWith({
    String? status,
    AdoptionContact? contact,
    AdoptionInfo? info,
  }) {
    return AdminAdoptionItem(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      userStudentId: userStudentId,
      userCampus: userCampus,
      userCollege: userCollege,
      catId: catId,
      catName: catName,
      catAvatar: catAvatar,
      status: status ?? this.status,
      createTime: createTime,
      contact: contact ?? this.contact,
      info: info ?? this.info,
    );
  }
}

int? _intValue(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final result = value.toString();
  return result.isEmpty ? null : result;
}
