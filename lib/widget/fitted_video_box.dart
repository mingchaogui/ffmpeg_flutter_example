import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class FittedVideoBox extends StatefulWidget {
  const FittedVideoBox({
    super.key,
    this.fit = BoxFit.contain,
    required this.player,
    required this.child,
  });

  final BoxFit fit;
  final ValueNotifier<VideoPlayerValue> player;
  final Widget? child;

  @override
  State<FittedVideoBox> createState() => _FittedVideoBoxState();
}

class _FittedVideoBoxState extends State<FittedVideoBox> {
  @override
  void initState() {
    super.initState();

    widget.player.addListener(_didPlayerValueChanged);
  }

  @override
  void didUpdateWidget(covariant FittedVideoBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.player != widget.player) {
      oldWidget.player.removeListener(_didPlayerValueChanged);
      widget.player.addListener(_didPlayerValueChanged);
    }
  }

  @override
  void dispose() {
    widget.player.removeListener(_didPlayerValueChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerValue playerValue = widget.player.value;
    final Size size = playerValue.isInitialized ? playerValue.size : Size.zero;

    return ClipRect(
      child: FittedBox(
        fit: widget.fit,
        child: SizedBox.fromSize(
          size: size,
          child: widget.child,
        ),
      ),
    );
  }

  void _didPlayerValueChanged() {
    setState(() {});
  }
}
