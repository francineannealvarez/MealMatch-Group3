// lib/widgets/avatar_picker.dart

import 'package:flutter/material.dart';

class AvatarPicker extends StatelessWidget {
  final String? selectedAvatar;
  final Function(String?) onAvatarSelected;
  final bool showSkipOption;
  final bool isGridView; // true for Get Started, false for Settings modal

  const AvatarPicker({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
    this.showSkipOption = true,
    this.isGridView = true,
  });

  static final List<String> avatarOptions = [
    'assets/images/avatar_avocado.png',
    'assets/images/avatar_burger.png',
    'assets/images/avatar_donut.png',
    'assets/images/avatar_pizza.png',
    'assets/images/avatar_ramen.png',
    'assets/images/avatar_strawberry.png',
    'assets/images/avatar_sushi.png',
    'assets/images/avatar_taco.png',
  ];

  @override
  Widget build(BuildContext context) {
    // Add "Skip" option at the beginning if enabled
    final List<String?> options = [
      if (showSkipOption) null,
      ...avatarOptions,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isGridView ? 3 : 4, // 3 for Get Started, 4 for Edit Profile
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final avatarPath = options[index];
        final isSelected = selectedAvatar == avatarPath;

        return GestureDetector(
          onTap: () => onAvatarSelected(avatarPath),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF67B14D)
                    : Colors.grey.shade300,
                width: 4,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF67B14D).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipOval(
              child: avatarPath == null
                  ? _buildSkipOption()
                  : Image.asset(
                      avatarPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorIcon();
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkipOption() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 40,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            'Skip',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }
}

// ✅ BONUS: Avatar Display Widget (for showing selected avatar)
class AvatarDisplay extends StatelessWidget {
  final String? avatarPath;
  final double size;
  final bool showEditButton;
  final VoidCallback? onEditPressed;

  const AvatarDisplay({
    super.key,
    required this.avatarPath,
    this.size = 120,
    this.showEditButton = false,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4CAF50),
              width: 3,
            ),
            color: Colors.grey[300],
          ),
          child: ClipOval(
            child: avatarPath != null
                ? Image.asset(
                    avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: size * 0.5,
                        color: Colors.grey[600],
                      );
                    },
                  )
                : Icon(
                    Icons.person,
                    size: size * 0.5,
                    color: Colors.grey[600],
                  ),
          ),
        ),
        if (showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditPressed,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}