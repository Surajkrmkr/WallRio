import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallrio/provider/personalization_provider.dart';

class PremiumAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const PremiumAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalizationProvider>(
      builder: (context, personalization, _) {
        final frameKey = personalization.personalization?.activeProfileFrame ?? 'none';
        final bool hasFrame = frameKey != 'none' && frameKey != 'frame_none';
        
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Base Avatar
                CircleAvatar(
                  radius: hasFrame ? radius * 0.70 : radius,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty ? const Icon(Icons.person_rounded) : null,
                ),
                
                // Frame Overlay (allowed to overflow the SizedBox visually)
                if (hasFrame)
                  _buildFrame(frameKey, radius),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrame(String frameKey, double avatarRadius) {
    String? assetPath;
    
    switch (frameKey) {
      case 'frame_gold_vip':
        assetPath = 'assets/frame_gold_vip.png';
        break;
      case 'frame_neon_v2':
        assetPath = 'assets/frame_neon_v2.png';
        break;
      case 'frame_aurora':
        assetPath = 'assets/frame_aurora.png';
        break;
      case 'frame_galaxy':
        assetPath = 'assets/frame_galaxy.png';
        break;
      case 'frame_glossy':
        assetPath = 'assets/frame_glossy.png';
        break;
      case 'frame_metal_fire':
        assetPath = 'assets/frame_metal_fire.png';
        break;
      case 'frame_fifa':
        assetPath = 'assets/frame_fifa.png';
        break;
      default:
        return const SizedBox.shrink();
    }

    // Adaptive frame size: 
    // For radius 18, offset is ~6px. For radius 30, offset is ~10px.
    final double frameOffset = avatarRadius / 3;
    final double frameSize = (avatarRadius * 2) + frameOffset;

    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AnimatedFrame extends StatefulWidget {
  final double size;
  final Color color;

  const _AnimatedFrame({required this.size, required this.color});

  @override
  State<_AnimatedFrame> createState() => _AnimatedFrameState();
}

class _AnimatedFrameState extends State<_AnimatedFrame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.5 + (0.5 * _controller.value)), 
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: 4 + (4 * _controller.value),
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
