import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

class AvatarSelector extends StatelessWidget{
  final String? selectedAvatar;
  final ValueChanged<String> onAvatarSelected;
  
  const AvatarSelector({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
  });

  static const List<String> _avatars = [
    'anonimo',
    'caballero',
    'dracula',
    'fantasma',
    'frankenstein',
    'hada',
    'indio',
    'mago_joven',
    'mago_mayor',
    'troglodita'
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: _avatars.map((avatar){
        final isSelected = avatar == selectedAvatar;
        return _AvatarItem(
          avatarName: avatar,
          isSelected: isSelected,
          onTap: () => onAvatarSelected(avatar),
        );
      }).toList(),
    );
  }
}

class _AvatarItem extends StatelessWidget{
  final String avatarName;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarItem({
    required this.avatarName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: AppColors.purplePrimary,width: 3) : Border.all(color: Colors.transparent,width: 3),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.asset(
            'assets/avatars/$avatarName.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}