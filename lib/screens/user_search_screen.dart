import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/user_search_controller.dart';
import '../widgets/user_search_bar.dart';
import '../widgets/search_empty_state.dart';
import '../widgets/search_error_state.dart';
import '../widgets/search_loading_indicator.dart';
import '../widgets/user_tile.dart';

class UserSearchScreen extends StatelessWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = Provider.of<UserSearchController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pretraga korisnika'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: UserSearchBar(
                  controller: controller.searchController,
                  onChanged: controller.onQueryChanged,
                  onClear: controller.clearSearch,
                ),
              ),
            ),
            if (controller.isLoading)
              const SliverToBoxAdapter(
                child: SearchLoadingIndicator(),
              ),
            if (controller.errorMessage.isNotEmpty)
              SliverToBoxAdapter(
                child: SearchErrorState(
                  message: controller.errorMessage,
                  onRetry: controller.retrySearch,
                ),
              ),
            if (controller.searchResults.isEmpty &&
                !controller.isLoading &&
                controller.searchController.text.isNotEmpty &&
                controller.errorMessage.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: SearchEmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = controller.searchResults[index];
                    return UserTile(user: user);
                  },
                  childCount: controller.searchResults.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
