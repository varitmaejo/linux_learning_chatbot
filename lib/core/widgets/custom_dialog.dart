import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../constants/strings.dart';

class CustomDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final Widget? contentWidget;
  final List<Widget>? actions;
  final bool barrierDismissible;
  final EdgeInsets? contentPadding;

  const CustomDialog({
    Key? key,
    this.title,
    this.content,
    this.contentWidget,
    this.actions,
    this.barrierDismissible = true,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title != null
          ? Text(
        title!,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      )
          : null,
      content: contentWidget ??
          (content != null
              ? Text(
            content!,
            style: Theme.of(context).textTheme.bodyMedium,
          )
              : null),
      contentPadding: contentPadding,
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static Future<T?> show<T>(
      BuildContext context, {
        String? title,
        String? content,
        Widget? contentWidget,
        List<Widget>? actions,
        bool barrierDismissible = true,
      }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: confirmColor ?? AppColors.errorColor,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? Strings.cancel),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.errorColor,
          ),
          child: Text(confirmText ?? Strings.confirm),
        ),
      ],
    );
  }

  static Future<bool> show(
      BuildContext context, {
        required String title,
        required String content,
        String? confirmText,
        String? cancelText,
        Color? confirmColor,
        IconData? icon,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
    return result ?? false;
  }
}

class LoadingDialog extends StatelessWidget {
  final String? message;
  final bool canDismiss;

  const LoadingDialog({
    Key? key,
    this.message,
    this.canDismiss = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => canDismiss,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void show(
      BuildContext context, {
        String? message,
        bool canDismiss = false,
      }) {
    showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => LoadingDialog(
        message: message,
        canDismiss: canDismiss,
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color? iconColor;

  const InfoDialog({
    Key? key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? AppColors.infoColor,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Strings.ok),
        ),
      ],
    );
  }

  static Future<void> show(
      BuildContext context, {
        required String title,
        required String content,
        IconData? icon,
        Color? iconColor,
      }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}