class Cat {
  final String id;
  final String name;
  final String avatar;
  final String color;
  final String campus;
  final String locationName;
  final String status;
  final List<String> tags;
  final bool isNeutered;
  final int popularity;
  final String lastSeenTime;
  final String roleName;

  Cat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.color,
    required this.campus,
    required this.locationName,
    required this.status,
    required this.tags,
    required this.isNeutered,
    required this.popularity,
    required this.lastSeenTime,
    required this.roleName,
  });

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String,
        color: json['color'] as String,
        campus: json['campus'] as String,
        locationName: json['locationName'] as String,
        status: json['status'] as String,
        tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
        isNeutered: json['isNeutered'] as bool,
        popularity: (json['popularity'] as num).toInt(),
        lastSeenTime: json['lastSeenTime'] as String,
        roleName: json['roleName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'color': color,
        'campus': campus,
        'locationName': locationName,
        'status': status,
        'tags': tags,
        'isNeutered': isNeutered,
        'popularity': popularity,
        'lastSeenTime': lastSeenTime,
        'roleName': roleName,
      };
}

class CatPage {
  final int total;
  final List<Cat> items;

  CatPage({required this.total, required this.items});

  factory CatPage.fromJson(Map<String, dynamic> json) => CatPage(
        total: (json['total'] as num).toInt(),
        items: (json['items'] as List<dynamic>)
            .map((e) => Cat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
