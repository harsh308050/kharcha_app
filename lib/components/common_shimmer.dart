import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CommonShimmer extends StatelessWidget {
  final Widget child;

  const CommonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE4E7EA),
      highlightColor: const Color(0xFFF5F7F9),
      child: child,
    );
  }
}

class CommonShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const CommonShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return CommonShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE4E7EA),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class CommonShimmerCircle extends StatelessWidget {
  final double size;

  const CommonShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CommonShimmer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE4E7EA),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class CommonShimmerTransactionTile extends StatelessWidget {
  const CommonShimmerTransactionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
        child: Row(
          children: [
            const CommonShimmerCircle(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CommonShimmerBlock(
                    width: double.infinity,
                    height: 18,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      CommonShimmerBlock(
                        width: 72,
                        height: 18,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      SizedBox(width: 8),
                      CommonShimmerBlock(
                        width: 54,
                        height: 12,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                CommonShimmerBlock(
                  width: 74,
                  height: 18,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                SizedBox(height: 8),
                CommonShimmerBlock(
                  width: 42,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommonShimmerList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const CommonShimmerList({
    super.key,
    required this.count,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List<Widget>.generate(count, (int index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 10),
            child: const CommonShimmerTransactionTile(),
          );
        }),
      ),
    );
  }
}