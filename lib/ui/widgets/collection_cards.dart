import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

enum CollectionCardType { landscapeCinematic, mediumSquare, tallVertical, wideEditorial }

class CollectionCard extends StatefulWidget {
  final Collections collection;
  final CollectionCardType type;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.collection,
    this.type = CollectionCardType.landscapeCinematic,
    required this.onTap,
  });

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final walls = widget.collection.walls ?? [];
    
    double borderRadius;
    double cardHeight;
    double? cardWidth;
    
    switch (widget.type) {
      case CollectionCardType.landscapeCinematic:
        cardHeight = 440;
        borderRadius = 40.0;
        break;
      case CollectionCardType.mediumSquare:
        cardHeight = 240;
        borderRadius = 32.0;
        break;
      case CollectionCardType.tallVertical:
        cardHeight = 380;
        borderRadius = 36.0;
        break;
      case CollectionCardType.wideEditorial:
        cardHeight = 180;
        borderRadius = 32.0;
        cardWidth = double.infinity;
        break;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.12),
              blurRadius: isDarkMode ? 40 : 30,
              spreadRadius: isDarkMode ? -10 : 0,
              offset: Offset(0, isDarkMode ? 20 : 10),
            ),
            // Ambient Glow Halo (Subtle in light mode)
            BoxShadow(
              color: const Color(0xFF37C3A3).withValues(alpha: isDarkMode ? 0.08 : 0.04),
              blurRadius: 60,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            height: cardHeight,
            width: cardWidth,
            child: Stack(
              children: [
                // Static Preview
                Positioned.fill(
                  child: walls.isNotEmpty
                      ? CNImage(imageUrl: walls[0].url)
                      : Container(color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200]),
                ),

                // Cinematic Reflections & Depth Gradients
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.3, 0.7, 1.0],
                        colors: [
                          Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.1),
                          Colors.transparent,
                          Colors.transparent,
                          isDarkMode ? Colors.black.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Info Layout (Combined Box)
                Positioned(
                  bottom: 20,
                  left: 12,
                  right: 12,
                  child: _buildCombinedInfoBox(isDarkMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedInfoBox(bool isDarkMode) {
    final bool isGrid = widget.type == CollectionCardType.mediumSquare || widget.type == CollectionCardType.tallVertical;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(isGrid ? 32 : 36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.all(isGrid ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(isGrid ? 32 : 36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Row(
            children: [
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.collection.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isGrid ? 13 : 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontFamily: 'POCOTech-cool-Bold',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.collection.walls?.length ?? 0} PREMIUM WALLPAPERS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: isGrid ? 8 : 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Integrated Action Button
              Container(
                width: isGrid ? 36 : 42,
                height: isGrid ? 36 : 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: isGrid ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
