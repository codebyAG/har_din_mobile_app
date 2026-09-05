import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const int _maxLength = 500;

  final _textController = TextEditingController();
  String _selectedCategory = 'religious';
  bool _visibleToAll = true;

  static const _categories = [
    (id: 'religious', label: 'धार्मिक', icon: AppIcons.religious),
    (id: 'gifts', label: 'उपहार', icon: AppIcons.gifts),
    (id: 'festivals', label: 'त्योहार', icon: AppIcons.celebration),
    (id: 'quotes', label: 'कोट्स', icon: AppIcons.quote),
    (id: 'other', label: 'अन्य', icon: AppIcons.more),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('पोस्ट किया गया')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('अपना स्टेटस बनाएं'),
        actions: [
          TextButton(
            onPressed: _textController.text.trim().isEmpty ? null : _submit,
            child: Text(
              'पोस्ट करें',
              style: AppTextStyles.body(color: AppColors.primary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _textController,
                    maxLength: _maxLength,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'यहाँ अपने विचार लिखें...',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Text(
                    '${_textController.text.length}/$_maxLength',
                    style: AppTextStyles.secondary(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('श्रेणी चुनें', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) {
                  final category = _categories[i];
                  final selected = category.id == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category.id),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Image.asset(
                            'assets/categories/${category.id}.png',
                            fit: BoxFit.contain,
                            color: selected ? Colors.white : null,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              category.icon,
                              color: selected ? Colors.white : AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(category.label, style: AppTextStyles.secondary()),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('मीडिया जोड़ें', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MediaChip(
                  icon: AppIcons.camera,
                  label: 'फोटो/वीडियो',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('जल्द आ रहा है')),
                  ),
                ),
                _MediaChip(
                  icon: AppIcons.gif,
                  label: 'GIF',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('जल्द आ रहा है')),
                  ),
                ),
                _MediaChip(
                  icon: AppIcons.music,
                  label: 'ऑडियो',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('जल्द आ रहा है')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('पोस्ट सेटिंग', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => setState(() => _visibleToAll = !_visibleToAll),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _visibleToAll ? AppIcons.globe : AppIcons.lock,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _visibleToAll ? 'सभी को दिखाएं' : 'केवल मुझे दिखाएं',
                      style: AppTextStyles.secondary(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lightAccent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.secondary()),
          ],
        ),
      ),
    );
  }
}
