import 'package:flutter/material.dart';

import '../models/festival.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/festival_image.dart';
import '../widgets/gradient_tile.dart';
import '../widgets/primary_button.dart';
import 'preview_share_screen.dart';

class CustomizeScreen extends StatefulWidget {
  final Festival festival;

  const CustomizeScreen({super.key, required this.festival});

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  int _selectedFontIndex = 0;
  int _selectedBackgroundIndex = 0;

  static const _fontLabels = ['Aa', 'Aa', 'Aa', 'अ'];
  final _backgroundOptions = <List<Color>>[];

  @override
  void initState() {
    super.initState();
    _backgroundOptions.addAll([
      widget.festival.gradient,
      [AppColors.secondary, AppColors.primary],
      [AppColors.primaryDark, AppColors.secondary],
      [AppColors.success, AppColors.secondary],
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('अपना स्टेटस बनाएं')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.sectionGap,
          ),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _selectedBackgroundIndex == 0
                          ? FestivalImage(festival: widget.festival, iconSize: 56)
                          : GradientTile(
                              colors: _backgroundOptions[_selectedBackgroundIndex],
                              icon: widget.festival.icon,
                              iconSize: 56,
                            ),
                    ),
                    if (_nameController.text.isNotEmpty)
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Text(
                          _nameController.text,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.screenTitle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('अपना नाम लिखें', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'आपका नाम'),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('अपनी फ़ोटो जोड़ें', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('फ़ोटो चुनें (demo)')),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('फोटो बदलें'),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('फॉन्ट स्टाइल', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fontLabels.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final selected = i == _selectedFontIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFontIndex = i),
                    child: Container(
                      width: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _fontLabels[i],
                        style: AppTextStyles.cardTitle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('बैकग्राउंड', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _backgroundOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final selected = i == _selectedBackgroundIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBackgroundIndex = i),
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: i == 0
                          ? FestivalImage(
                              festival: widget.festival,
                              iconSize: 18,
                              borderRadius: BorderRadius.circular(11),
                            )
                          : GradientTile(
                              colors: _backgroundOptions[i],
                              icon: widget.festival.icon,
                              iconSize: 18,
                              borderRadius: BorderRadius.circular(11),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('अपना संदेश लिखें (Optional)', style: AppTextStyles.cardTitle()),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'यहाँ अपना संदेश लिखें'),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            PrimaryButton(
              label: 'Preview देखें',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PreviewShareScreen(
                    festival: widget.festival,
                    gradient: _backgroundOptions[_selectedBackgroundIndex],
                    useFestivalImage: _selectedBackgroundIndex == 0,
                    name: _nameController.text,
                    message: _messageController.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
