import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAnimation extends StatefulWidget {
  const LottieAnimation({
    super.key,
    required this.size,
    required this.type,
    this.onCompleted,
  });

  final Size size;
  final String type;
  final VoidCallback? onCompleted;

  @override
  State<LottieAnimation> createState() => _LottieAnimationState();
}

class _LottieAnimationState extends State<LottieAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this);

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        debugPrint("🎉 Animation completed");
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lotties/${widget.type}.json',
      controller: controller,
      onLoaded: (composition) {
        controller.duration = composition.duration;

        if (widget.type == "like" ||
            widget.type == "welcome" ||
            widget.type == "Home") {
          // Chạy lặp đi lặp lại với reverse
          controller.repeat(reverse: true);
        } else {
          // Chạy một lần
          controller.forward();
        }

        debugPrint("⏱️ Lottie Duration: ${composition.duration}");
      },
      height: widget.size.height,
      width: widget.size.width,
    );
  }
}
