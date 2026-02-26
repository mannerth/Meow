import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/cat_detail.dart';
import 'package:meow/model/user.dart';

class MeowEditPage extends StatefulWidget {
  final String? catId;

  const MeowEditPage({super.key, this.catId});

  @override
  State<MeowEditPage> createState() => _MeowEditPageState();
}

class _MeowEditPageState extends State<MeowEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _avatarController;
  late TextEditingController _colorController;
  late TextEditingController _genderController;
  late TextEditingController _hauntController;
  late TextEditingController _roleController;
  late TextEditingController _birthYearController;
  late TextEditingController _descriptionController;
  Campus? _campus;
  final ImagePicker _imagePicker = ImagePicker();

  String _status = 'SCHOOL';
  bool _isNeutered = false;
  String _neuteredTypeDisplay = '剪耳';
  DateTime? _neuteredDate;
  DateTime? _admissionDate;
  String _healthStatusDisplay = '健康';

  double _friendliness = 9.0;
  double _gluttony = 9.5;
  double _fight = 1.0;
  double _appearance = 10.0;

  List<String> _selectedTags = [];
  List<String> _images = [];
  bool _loading = false;
  bool _uploading = false;

  static const _statusOptions = [
    'SCHOOL',
    'GRADUATED',
    'MEOW_STAR',
    'HOSPITAL'
  ];
  static const _campusOptions = <Campus?>[
    null,
    ...Campus.values,
  ];
  static const _genderDisplayOptions = ['公', '母', '未知'];
  static const _neuteredTypeDisplayOptions = ['剪耳', '未剪耳'];
  static const _healthStatusDisplayOptions = ['健康', '生病', '恢复中'];
  final List _tagOptions = [
    '亲人',
    '吃货',
    '话痨',
    '高冷',
    '霸主',
    '学霸',
    '安静',
    '粘人',
    '胆小'
  ];

  static const _genderDisplayToValue = {
    '公': 'MALE',
    '母': 'FEMALE',
    '未知': 'UNKNOWN',
  };
  static const _genderValueToDisplay = {
    'MALE': '公',
    'FEMALE': '母',
    'UNKNOWN': '未知',
  };
  static const _statusDisplayToValue = {
    '在校': 'SCHOOL',
    '已毕业': 'GRADUATED',
    '喵星': 'MEOW_STAR',
    '住院': 'HOSPITAL',
  };
  static const _neuteredTypeDisplayToValue = {
    '剪耳': 'EAR_CUT',
    '未剪耳': 'UNCUT',
  };
  static const _neuteredTypeValueToDisplay = {
    'EAR_CUT': '剪耳',
    'UNCUT': '未剪耳',
  };
  static const _healthStatusDisplayToValue = {
    '健康': 'HEALTHY',
    '生病': 'SICK',
    '恢复中': 'RECOVERING',
  };
  static const _healthStatusValueToDisplay = {
    'HEALTHY': '健康',
    'SICK': '生病',
    'RECOVERING': '恢复中',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _avatarController = TextEditingController();
    _colorController = TextEditingController();
    _genderController = TextEditingController();
    _hauntController = TextEditingController();
    _roleController = TextEditingController();
    _birthYearController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    _colorController.dispose();
    _genderController.dispose();
    _hauntController.dispose();
    _roleController.dispose();
    _birthYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    if (widget.catId == null) return;
    setState(() => _loading = true);
    try {
      final response = await CatService.fetchCatDetail(widget.catId!);
      final detail = response.data;
      if (detail == null) return;
      _tagOptions
          .addAll(detail.tags.where((tag) => !_tagOptions.contains(tag)));
      _applyDetail(detail);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDetail(CatDetail detail) {
    _nameController.text = detail.name;
    _avatarController.text = detail.avatar;
    _colorController.text = detail.basicInfo.color;
    _genderController.text = _genderDisplayFromApi(detail.basicInfo.gender);
    _hauntController.text = detail.basicInfo.hauntLocation;
    _roleController.text = detail.basicInfo.role;
    _descriptionController.text = detail.description;
    _campus = Campus.values.cast<Campus?>().firstWhere(
          (item) => item?.name == detail.basicInfo.campus,
          orElse: () => null,
        );
    _status = detail.basicInfo.status.isEmpty
        ? _statusOptions.first
        : _statusValueFromApi(detail.basicInfo.status);
    _isNeutered = detail.basicInfo.neutered.isNeutered;
    _neuteredTypeDisplay = detail.basicInfo.neutered.type.isEmpty
        ? _neuteredTypeDisplayOptions.first
        : _neuteredTypeDisplayFromApi(detail.basicInfo.neutered.type);
    _neuteredDate = detail.basicInfo.neutered.neuteredDate.isEmpty
        ? null
        : DateTime.tryParse(detail.basicInfo.neutered.neuteredDate);
    _friendliness = detail.attributes.friendliness;
    _gluttony = detail.attributes.gluttony;
    _fight = detail.attributes.fight;
    _appearance = detail.attributes.appearance;
    _selectedTags = detail.tags;
    _images = List<String>.from(detail.images);
    _birthYearController.text = detail.basicInfo.birthYear == 0
        ? ''
        : detail.basicInfo.birthYear.toString();
    _admissionDate = detail.basicInfo.admissionDate.isEmpty
        ? null
        : DateTime.tryParse(detail.basicInfo.admissionDate);
    _healthStatusDisplay = detail.basicInfo.healthStatus.isEmpty
        ? _healthStatusDisplayOptions.first
        : _healthStatusDisplayFromApi(detail.basicInfo.healthStatus);
    if (mounted) setState(() {});
  }

  bool get _isBusy => _loading || _uploading;

  String _genderDisplayFromApi(String value) {
    if (_genderValueToDisplay.containsKey(value)) {
      return _genderValueToDisplay[value]!;
    }
    if (_genderDisplayToValue.containsKey(value)) {
      return value;
    }
    return value;
  }

  String _genderValueFromDisplay(String display) {
    return _genderDisplayToValue[display] ?? display;
  }

  String _statusValueFromApi(String value) {
    if (_statusDisplayToValue.containsKey(value)) {
      return _statusDisplayToValue[value]!;
    }
    if (_statusOptions.contains(value)) {
      return value;
    }
    return value;
  }

  String _neuteredTypeDisplayFromApi(String value) {
    if (_neuteredTypeValueToDisplay.containsKey(value)) {
      return _neuteredTypeValueToDisplay[value]!;
    }
    if (_neuteredTypeDisplayToValue.containsKey(value)) {
      return value;
    }
    return value;
  }

  String _neuteredTypeValueFromDisplay(String display) {
    return _neuteredTypeDisplayToValue[display] ?? display;
  }

  String _healthStatusDisplayFromApi(String value) {
    if (_healthStatusValueToDisplay.containsKey(value)) {
      return _healthStatusValueToDisplay[value]!;
    }
    if (_healthStatusDisplayToValue.containsKey(value)) {
      return value;
    }
    return value;
  }

  String _healthStatusValueFromDisplay(String display) {
    return _healthStatusDisplayToValue[display] ?? display;
  }

  Future<void> _pickNeuteredDate() async {
    final initialDate = _neuteredDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _neuteredDate = picked);
  }

  Future<void> _pickAdmissionDate() async {
    final initialDate = _admissionDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _admissionDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final payload = {
      'name': _nameController.text.trim(),
      'aliases': <String>[],
      'color': _colorController.text.trim(),
      'avatar': _avatarController.text.trim(),
      'images': _images,
      'gender': _genderValueFromDisplay(_genderController.text.trim()),
      'campus': _campus?.name ?? '',
      'hauntLocation': _hauntController.text.trim(),
      'role': _roleController.text.trim(),
      'birthYear': int.tryParse(_birthYearController.text.trim()) ?? 0,
      'admissionDate': _admissionDate == null
          ? ''
          : _admissionDate!.toIso8601String().split('T').first,
      'status': _status,
      'healthStatus': _healthStatusValueFromDisplay(_healthStatusDisplay),
      'attributes': {
        'friendliness': _friendliness,
        'gluttony': _gluttony,
        'fight': _fight,
        'appearance': _appearance,
      },
      'isNeutered': _isNeutered,
      'neuteredDate': _neuteredDate?.toIso8601String().split('T').first,
      'neuteredType': _neuteredTypeValueFromDisplay(_neuteredTypeDisplay),
      'description': _descriptionController.text.trim(),
      'tags': _selectedTags,
    };
    debugPrint('$payload');
    try {
      var result = await CatService.upsertCat(id: widget.catId, payload: payload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存成功 ${result.data}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请稍后重试')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _uploading = true);
    try {
      final url = await Http().uploadImage(image);
      _avatarController.text = url;
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像上传失败，请稍后重试')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeAvatar() {
    _avatarController.text = '';
    setState(() {});
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(limit: 9);
    if (images.isEmpty) return;
    setState(() => _uploading = true);
    try {
      for (final image in images) {
        try {
          final url = await Http().uploadImage(image);
          if (!_images.contains(url)) {
            _images.add(url);
          }
        } catch (error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片上传失败，请稍后重试')),
          );
        }
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeImage(String url) {
    setState(() => _images.remove(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('编辑猫咪档案'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _AvatarCard(
                  avatarUrl: _avatarController.text,
                  onTap: _pickAvatar,
                  onRemove: _removeAvatar,
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '图片管理',
                  children: [
                    Text(
                      '支持上传猫咪展示图，可删除原来的图片',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _ImageGrid(
                      images: _images,
                      onAdd: _pickImages,
                      onRemove: _removeImage,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '基本信息',
                  children: [
                    _TextFieldTile(
                      label: '猫咪名字',
                      controller: _nameController,
                      requiredField: true,
                    ),
                    _TextFieldTile(
                      label: '花色/品种',
                      controller: _colorController,
                      requiredField: true,
                    ),
                    _DropdownTile(
                      label: '所在校区',
                      value: _campus?.name,
                      items: _campusOptions
                          .map((item) => item?.name ?? '未选择')
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _campus = Campus.values.cast<Campus?>().firstWhere(
                                (item) => item?.name == value,
                                orElse: () => null,
                              );
                        });
                      },
                    ),
                    _DropdownTile(
                      label: '性别',
                      value: _genderController.text.isEmpty
                          ? null
                          : _genderController.text,
                      items: _genderDisplayOptions,
                      onChanged: (value) {
                        _genderController.text = value ?? '';
                        setState(() {});
                      },
                    ),
                    _TextFieldTile(
                      label: '常驻地点',
                      controller: _hauntController,
                    ),
                    _TextFieldTile(
                      label: '学历/编制',
                      controller: _roleController,
                    ),
                    _TextFieldTile(
                      label: '出生年份',
                      controller: _birthYearController,
                      keyboardType: TextInputType.number,
                    ),
                    _ActionTile(
                      label: '入学时间',
                      value: _admissionDate == null
                          ? '请选择'
                          : _admissionDate!.toIso8601String().split('T').first,
                      onTap: _pickAdmissionDate,
                    ),
                    _DropdownTile(
                      label: '健康状态',
                      value: _healthStatusDisplay,
                      items: _healthStatusDisplayOptions,
                      onChanged: (value) {
                        setState(() => _healthStatusDisplay =
                            value ?? _healthStatusDisplay);
                      },
                    ),
                    _StatusPicker(
                      status: _status,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '猫格属性',
                  children: [
                    _SliderTile(
                      label: '亲人指数',
                      value: _friendliness,
                      color: const Color(0xFFF6C14D),
                      onChanged: (value) =>
                          setState(() => _friendliness = value),
                    ),
                    _SliderTile(
                      label: '贪吃指数',
                      value: _gluttony,
                      color: const Color(0xFFF6C14D),
                      onChanged: (value) => setState(() => _gluttony = value),
                    ),
                    _SliderTile(
                      label: '战斗力',
                      value: _fight,
                      color: const Color(0xFF7BC97F),
                      onChanged: (value) => setState(() => _fight = value),
                    ),
                    _SliderTile(
                      label: '颜值指数',
                      value: _appearance,
                      color: const Color(0xFFFF8EB2),
                      onChanged: (value) => setState(() => _appearance = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '特点标签',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagOptions.map((tag) {
                        final selected = _selectedTags.contains(tag);
                        return ChoiceChip(
                          label: Text(tag),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    IconButton(
                      onPressed: () {
                        TextEditingController _newTagController =
                            TextEditingController();
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: const Text('添加新标签'),
                                  content: TextField(
                                    controller: _newTagController,
                                    autofocus: true,
                                    onSubmitted: (value) {
                                      if (value.trim().isEmpty) return;
                                      if (!_tagOptions.contains(value.trim())) {
                                        setState(() =>
                                            _tagOptions.add(value.trim()));
                                      }
                                      Navigator.of(context).pop();
                                    },
                                    decoration: const InputDecoration(
                                      hintText: '输入标签名称',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final value = _newTagController.text;
                                        if (value.trim().isEmpty) return;
                                        if (!_tagOptions
                                            .contains(value.trim())) {
                                          setState(() =>
                                              _tagOptions.add(value.trim()));
                                        }
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('添加'),
                                    )
                                  ],
                                ));
                      },
                      icon: const Icon(Icons.add_box_outlined,
                          color: Color(0xFF7BC97F)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '其他信息',
                  children: [
                    _DropdownTile(
                      label: '绝育情况',
                      value: _isNeutered ? '已绝育' : '未绝育',
                      items: const ['未绝育', '已绝育'],
                      onChanged: (value) {
                        setState(() => _isNeutered = value == '已绝育');
                      },
                    ),
                    _DropdownTile(
                      label: '绝育类型',
                      value: _neuteredTypeDisplay,
                      items: _neuteredTypeDisplayOptions,
                      onChanged: (value) {
                        setState(() => _neuteredTypeDisplay =
                            value ?? _neuteredTypeDisplay);
                      },
                    ),
                    _ActionTile(
                      label: '绝育日期',
                      value: _neuteredDate == null
                          ? '请选择'
                          : _neuteredDate!.toIso8601String().split('T').first,
                      onTap: _pickNeuteredDate,
                    ),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: '备注信息',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          if (_isBusy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final String avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AvatarCard({
    required this.avatarUrl,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: onTap,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.pets,
                          size: 40,
                          color: Color(0xFFB0B4BA),
                        )
                      : null,
                ),
              ),
              if (avatarUrl.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, color: Color(0xFFE14B4B)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('点击图片更换头像', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _ImageGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = [
      _ImageAddTile(onTap: onAdd),
      ...images
          .map((url) => _ImageTile(url: url, onRemove: () => onRemove(url))),
    ];

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: tiles
          .map((child) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: child,
                ),
              ))
          .toList(),
    );
  }
}

class _ImageAddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ImageAddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: Color(0xFF7B8593)),
          const SizedBox(height: 6),
          Text('添加',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: const Color(0xFF7B8593))),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _ImageTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE6E7EB),
            alignment: Alignment.center,
            child: const Icon(Icons.pets, color: Colors.grey),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Material(
            color: Colors.white.withValues(alpha: 0.9),
            shape: const CircleBorder(),
            child: IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Color(0xFFE14B4B)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _TextFieldTile extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool requiredField;
  final TextInputType? keyboardType;

  const _TextFieldTile({
    required this.label,
    required this.controller,
    this.requiredField = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入$label';
                }
                return null;
              }
            : null,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;

  const _StatusPicker({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatusButton(
          label: '在校',
          value: 'SCHOOL',
          selected: status == 'SCHOOL',
          onTap: onChanged,
        ),
        _StatusButton(
          label: '已毕业',
          value: 'GRADUATED',
          selected: status == 'GRADUATED',
          onTap: onChanged,
        ),
        _StatusButton(
          label: '喵星',
          value: 'MEOW_STAR',
          selected: status == 'MEOW_STAR',
          onTap: onChanged,
        ),
        _StatusButton(
          label: '住院',
          value: 'HOSPITAL',
          selected: status == 'HOSPITAL',
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  const _StatusButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF7EE) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF39B56B) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF39B56B) : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 10,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
