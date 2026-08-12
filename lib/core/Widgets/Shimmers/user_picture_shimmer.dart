import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class UserPictureShimmer extends StatelessWidget {
  const UserPictureShimmer({super.key, this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade200,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade400,
        highlightColor: Colors.grey.shade100,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Head
              Positioned(
                top: size * 0.15,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.35,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Body / shoulders
              Positioned(
                bottom: size * 0.12,
                child: Container(
                  width: size * 0.65,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
