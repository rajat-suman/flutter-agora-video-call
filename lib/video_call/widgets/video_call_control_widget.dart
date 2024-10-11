import 'package:flutter/material.dart';

import '../../custom_image_view.dart';

class VideoCallControlWidget extends StatelessWidget {
  const VideoCallControlWidget({
    super.key,
    required this.onTap,
    required this.image,
    this.size,
    this.padding,
    this.color,
    this.isSelected = true,
  });

  final Function(bool) onTap;
  final String image;
  final double? size;
  final double? padding;
  final Color? color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Color(0x24FFFFFF),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          size ?? 50,
        ),
      ),
      child: InkWell(
        onTap: () {
          onTap(!isSelected);
        },
        child: Container(
          width: (size ?? 50),
          height: (size ?? 50),
          padding: EdgeInsets.all(padding ?? 15),
          child: CustomImageView(
            imagePath: image,
          ),
        ),
      ),
    );
  }
}
