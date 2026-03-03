import 'package:flutter/material.dart';

typedef ItemBuilder = Widget Function(BuildContext, int);

class RefreshableList extends StatelessWidget {
  final List<dynamic>? items;
  final bool? loading;
  final bool? hasMore;
  final Object? error;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final ItemBuilder? itemBuilder;
  final ScrollController? controller;

  const RefreshableList({
    super.key,
    this.items,
    this.loading,
    this.hasMore,
    this.error,
    this.onRefresh,
    this.onLoadMore,
    this.itemBuilder,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (items != null && itemBuilder != null) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView.builder(
          controller: controller,
          itemCount: items!.length + (hasMore == true ? 1 : 0),
          itemBuilder: (ctx, index) {
            if (index >= items!.length) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: loading == true ? const CircularProgressIndicator() : const SizedBox.shrink()),
              );
            }
            return itemBuilder!(ctx, index);
          },
        ),
      );
    }

    // Fallback: empty list
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(children: const [SizedBox.shrink()]),
    );
  }
}
