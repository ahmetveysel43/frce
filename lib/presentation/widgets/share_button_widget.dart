import 'package:flutter/material.dart';
import '../../core/services/file_share_service.dart';
import '../../core/utils/app_logger.dart';
import '../theme/app_theme.dart';

/// Paylaşım butonu widget'ı
/// Herhangi bir dosya veya metin paylaşımı için kullanılabilir
class ShareButtonWidget extends StatelessWidget {
  final VoidCallback? onSharePDF;
  final VoidCallback? onShareText;
  final VoidCallback? onShareCSV;
  final VoidCallback? onShareJSON;
  final String? customLabel;
  final IconData? customIcon;
  final bool isLoading;
  final bool isEnabled;

  const ShareButtonWidget({
    super.key,
    this.onSharePDF,
    this.onShareText,
    this.onShareCSV,
    this.onShareJSON,
    this.customLabel,
    this.customIcon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Eğer sadece bir paylaşım türü varsa direkt buton göster
    if (_getSingleShareAction() != null) {
      return _buildSingleShareButton();
    }
    
    // Çoklu paylaşım seçenekleri varsa menü göster
    return _buildShareMenu();
  }

  VoidCallback? _getSingleShareAction() {
    final actions = [onSharePDF, onShareText, onShareCSV, onShareJSON];
    final nonNullActions = actions.where((action) => action != null).toList();
    
    if (nonNullActions.length == 1) {
      return nonNullActions.first;
    }
    
    return null;
  }

  Widget _buildSingleShareButton() {
    return ElevatedButton.icon(
      onPressed: isEnabled && !isLoading ? _getSingleShareAction() : null,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(customIcon ?? Icons.share),
      label: Text(customLabel ?? 'Paylaş'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.textHint,
      ),
    );
  }

  Widget _buildShareMenu() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuSelection,
      enabled: isEnabled && !isLoading,
      icon: Icon(
        customIcon ?? Icons.share,
        color: isEnabled ? AppTheme.primaryColor : AppTheme.textHint,
      ),
      tooltip: customLabel ?? 'Paylaş',
      color: AppTheme.darkCard,
      itemBuilder: (context) => [
        if (onSharePDF != null)
          const PopupMenuItem(
            value: 'pdf',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: AppTheme.errorColor),
                SizedBox(width: 8),
                Text('PDF Paylaş', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        if (onShareText != null)
          const PopupMenuItem(
            value: 'text',
            child: Row(
              children: [
                Icon(Icons.text_snippet, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Metin Paylaş', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        if (onShareCSV != null)
          const PopupMenuItem(
            value: 'csv',
            child: Row(
              children: [
                Icon(Icons.table_chart, color: AppTheme.successColor),
                SizedBox(width: 8),
                Text('CSV Paylaş', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        if (onShareJSON != null)
          const PopupMenuItem(
            value: 'json',
            child: Row(
              children: [
                Icon(Icons.code, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text('JSON Paylaş', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    try {
      switch (value) {
        case 'pdf':
          onSharePDF?.call();
          break;
        case 'text':
          onShareText?.call();
          break;
        case 'csv':
          onShareCSV?.call();
          break;
        case 'json':
          onShareJSON?.call();
          break;
      }
    } catch (e) {
      AppLogger.error('Paylaşım menü hatası', e);
    }
  }
}

/// Floating Action Button olarak paylaşım
class ShareFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? heroTag;
  final Color? backgroundColor;

  const ShareFloatingActionButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.heroTag,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag ?? 'share_fab',
      onPressed: isLoading ? null : onPressed,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.share, color: Colors.white),
    );
  }
}

/// Hızlı metin paylaşım butonu
class QuickTextShareButton extends StatelessWidget {
  final String text;
  final String? subject;
  final String? buttonLabel;
  final IconData? icon;
  final bool isOutlined;

  const QuickTextShareButton({
    super.key,
    required this.text,
    this.subject,
    this.buttonLabel,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = isOutlined
        ? OutlinedButton.icon(
            onPressed: () => _shareText(),
            icon: Icon(icon ?? Icons.share),
            label: Text(buttonLabel ?? 'Paylaş'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          )
        : ElevatedButton.icon(
            onPressed: () => _shareText(),
            icon: Icon(icon ?? Icons.share),
            label: Text(buttonLabel ?? 'Paylaş'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          );

    return button;
  }

  Future<void> _shareText() async {
    try {
      await FileShareService.shareText(
        text: text,
        subject: subject,
      );
    } catch (e) {
      AppLogger.error('Hızlı metin paylaşımı hatası', e);
    }
  }
}