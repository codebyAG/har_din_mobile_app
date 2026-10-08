import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'auth_widgets.dart';
import 'primary_button.dart';

/// The first-run "आपका नाम?" popup. Returns the name the user typed, or
/// null if they dismissed it — in which case the profile stays incomplete
/// and the app asks again later (Profile) instead of losing the name.
///
/// [onSave] does the real work and returns an error message to show, or
/// null on success; the sheet stays open and shows the error otherwise.
Future<String?> showNamePrompt(
  BuildContext context, {
  required Future<String?> Function(String name) onSave,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _NameSheet(onSave: onSave),
  );
}

class _NameSheet extends StatefulWidget {
  final Future<String?> Function(String name) onSave;

  const _NameSheet({required this.onSave});

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'अपना नाम लिखें।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSave(name);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(name);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'आपका नाम क्या है?',
                style: AppTextStyles.screenTitle().copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'आपका नाम आपके स्टेटस पर दिखेगा।',
                style: AppTextStyles.secondary(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthField(
                controller: _controller,
                hint: 'अपना नाम लिखें',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.secondary(color: AppColors.like),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _busy ? 'कृपया रुकें…' : 'आगे बढ़ें',
                icon: _busy ? null : Icons.arrow_forward,
                onPressed: _busy ? null : _save,
              ),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                  child: Text('बाद में', style: AppTextStyles.secondary()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
