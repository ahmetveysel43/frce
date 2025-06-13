import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Animasyonlu drawer menu item widget'ı
/// Hover efektleri ve geçiş animasyonları içerir
class AnimatedDrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? badge;
  final bool isSelected;
  final Duration animationDuration;

  const AnimatedDrawerItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.badge,
    this.isSelected = false,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedDrawerItem> createState() => _AnimatedDrawerItemState();
}

class _AnimatedDrawerItemState extends State<AnimatedDrawerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0.02, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedDrawerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildMenuItem(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isSelected 
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : _isHovered 
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: widget.isSelected 
            ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
            : null,
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Haptic feedback
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onHover: (hovering) {
            setState(() {
              _isHovered = hovering;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildAnimatedIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextContent(),
                ),
                if (widget.badge != null) widget.badge!,
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      duration: widget.animationDuration,
      tween: Tween(
        begin: 0.0,
        end: widget.isSelected || _isHovered ? 1.0 : 0.0,
      ),
      builder: (context, value, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppTheme.darkCard,
              AppTheme.primaryColor.withValues(alpha: 0.2),
              value,
            ),
            borderRadius: BorderRadius.circular(10),
            border: value > 0.5
                ? Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: value * 0.3),
                  )
                : null,
          ),
          child: Icon(
            widget.icon,
            color: Color.lerp(
              AppTheme.textSecondary,
              AppTheme.primaryColor,
              value,
            ),
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<Color?>(
          duration: widget.animationDuration,
          tween: ColorTween(
            begin: Colors.white,
            end: widget.isSelected 
                ? AppTheme.primaryColor 
                : Colors.white,
          ),
          builder: (context, color, child) {
            return Text(
              widget.title,
              style: TextStyle(
                color: color,
                fontWeight: widget.isSelected 
                    ? FontWeight.w600 
                    : FontWeight.w500,
                fontSize: 14,
              ),
            );
          },
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitle!,
            style: TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Animasyonlu badge widget'ı
class AnimatedBadge extends StatefulWidget {
  final String text;
  final Color color;
  final Duration animationDuration;

  const AnimatedBadge({
    Key? key,
    required this.text,
    required this.color,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start pulsing animation
    _startPulsing();
  }

  void _startPulsing() {
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pulse efektli bağlantı göstergesi
class AnimatedConnectionIndicator extends StatefulWidget {
  final bool isConnected;
  final double size;

  const AnimatedConnectionIndicator({
    Key? key,
    required this.isConnected,
    this.size = 8.0,
  }) : super(key: key);

  @override
  State<AnimatedConnectionIndicator> createState() => _AnimatedConnectionIndicatorState();
}

class _AnimatedConnectionIndicatorState extends State<AnimatedConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isConnected) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size * (widget.isConnected ? _pulseAnimation.value : 1.0),
          height: widget.size * (widget.isConnected ? _pulseAnimation.value : 1.0),
          decoration: BoxDecoration(
            color: widget.isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
            boxShadow: widget.isConnected
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}