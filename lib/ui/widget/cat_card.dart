import 'package:flutter/material.dart';
import 'package:meow/model/cat.dart';

class CatCard extends StatelessWidget {
  final Cat cat;
  final VoidCallback? onTap;
  final VoidCallback? onImageLongPress;
  final VoidCallback? onDelete;

  const CatCard({
    super.key,
    required this.cat,
    this.onTap,
    this.onImageLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0B0B0F),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onLongPress: onImageLongPress,
                        child: Image.network(
                          cat.avatar,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF1F2F4),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.pets,
                                color: Color(0xFFB0B4BA),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (onDelete != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Material(
                          color: Colors.white.withAlpha(230),
                          shape: const CircleBorder(),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFE14B4B),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cat.campus} · ${cat.locationName.isEmpty ? '' : cat.locationName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -4,
                    children: cat.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF6A4BC3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
