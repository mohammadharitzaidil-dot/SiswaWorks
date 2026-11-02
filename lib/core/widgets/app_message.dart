import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'app_primary_button.dart';

/// Localized empty/error content; callers supply complete messages and labels.
class AppMessage extends StatelessWidget {
  const AppMessage({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(liveRegion: true, child: Text(message)),
      if (onAction != null) ...[
        const SizedBox(height: AppSpacing.medium),
        AppPrimaryButton(label: actionLabel!, onPressed: onAction),
      ],
    ],
  );
}
