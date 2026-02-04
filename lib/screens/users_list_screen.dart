import 'package:flutter/cupertino.dart';
import '../services/firebase_service.dart';
import '../services/widget_service.dart';
import '../theme_constants.dart';
import '../providers/stats_provider.dart';
import '../providers/users_provider.dart';
import 'chat_detail_screen.dart';
import 'chats_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Refresh is handled automatically by the stream provider
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = ref.watch(filteredUsersProvider);
    final usersAsync = ref.watch(usersFutureProvider);
    final statsAsync = ref.watch(statsProvider);

    // Sync stats with iOS Home Widget whenever they are loaded or refreshed
    ref.listen(statsProvider, (previous, next) {
      if (next is AsyncData<Map<String, int>>) {
        WidgetService.updateWidgetData(next.value);
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: AdminTheme.surfaceGrey,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Control Center'),
        backgroundColor: AdminTheme.surfaceWhite,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh, size: 22),
          onPressed: () async {
            await ref.refresh(usersFutureProvider.future);
            await ref.refresh(statsProvider.future);
          },
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await ref.refresh(usersFutureProvider.future);
                await ref.refresh(statsProvider.future);
              },
            ),
            
            // Stats Section
            SliverToBoxAdapter(
              child: statsAsync.when(
                data: (stats) => _buildStatsHeader(stats, usersAsync.value?.length ?? 0),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoSearchTextField(
                  placeholder: 'Search by UID or Email',
                  onChanged: (value) {
                    ref.read(userSearchQueryProvider.notifier).state = value;
                  },
                ),
              ),
            ),
            
            // Users List
            usersAsync.when(
              data: (users) {
                if (users.isEmpty && filteredUsers.isEmpty) {
                  return SliverToBoxAdapter(child: _buildEmptyStateNonSliver());
                }
                if (filteredUsers.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No results found')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildUserCard(filteredUsers[index]),
                      childCount: filteredUsers.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(child: _buildErrorStateNonSliver(error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateNonSliver() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.person_2, size: 64, color: AdminTheme.textLightGrey),
          const SizedBox(height: 16),
          Text('No users found', style: AdminTheme.subHeading),
        ],
      ),
    );
  }

  Widget _buildErrorStateNonSliver(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: CupertinoColors.systemIndigo),
            const SizedBox(height: 16),
            const Text('Sync Error', style: AdminTheme.heading2),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center, style: AdminTheme.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverNavigationBar(BuildContext context) {
    return const CupertinoSliverNavigationBar(
      largeTitle: Text('Control Center'),
      border: null,
      backgroundColor: AdminTheme.surfaceGrey,
    );
  }

  Widget _buildStatsHeader(Map<String, int> stats, int actualUserCount) {
    final formatter = NumberFormat.compact();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _buildStatCard(
            'Users', 
            formatter.format(actualUserCount > 0 ? actualUserCount : (stats['totalUsers'] ?? 0)), 
            CupertinoIcons.person_3_fill,
            'Total registered users and discovered guest accounts who have initiated conversations on the platform.',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Chats', 
            formatter.format(stats['totalChats'] ?? 0), 
            CupertinoIcons.chat_bubble_2_fill,
            'The total number of unique conversation threads created by all users across all categories.',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Msgs', 
            formatter.format(stats['totalMessages'] ?? 0), 
            CupertinoIcons.bolt_fill,
            'Total volume of messages exchanged within all chats, representing the cumulative engagement level.',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, String description) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AdminTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: AdminTheme.primaryBlue),
                GestureDetector(
                  onTap: () => _showStatInfo(label, description),
                  child: const Icon(CupertinoIcons.info_circle, size: 16, color: AdminTheme.textLightGrey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AdminTheme.heading2),
            Text(label, style: AdminTheme.caption),
          ],
        ),
      ),
    );
  }

  void _showStatInfo(String title, String description) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: const BoxDecoration(
          color: AdminTheme.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AdminTheme.heading2),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.clear_circled_solid, color: AdminTheme.textLightGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: AdminTheme.body.copyWith(height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AdminTheme.primaryBlue,
                borderRadius: BorderRadius.circular(16),
                child: const Text(
                  'Got it',
                  style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdminTheme.cardShadow,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          ref.read(selectedUserProvider.notifier).state = user;
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => ChatsListScreen(user: user),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: user.isAnonymous ? null : AdminTheme.blueGradient,
                  color: user.isAnonymous ? CupertinoColors.systemGrey5 : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.isAnonymous ? CupertinoIcons.person : CupertinoIcons.person_fill,
                  color: user.isAnonymous ? CupertinoColors.systemGrey : CupertinoColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.uid,
                      style: AdminTheme.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminTheme.surfaceGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.totalChats} chats',
                      style: AdminTheme.caption.copyWith(fontWeight: FontWeight.bold, color: AdminTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: AdminTheme.textLightGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_2, size: 64, color: AdminTheme.textLightGrey),
            const SizedBox(height: 16),
            Text('No users found', style: AdminTheme.subHeading),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AdminTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: CupertinoColors.systemRed),
              const SizedBox(height: 16),
              const Text('Sync Error', style: AdminTheme.heading2),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center, style: AdminTheme.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchDelegate extends SliverPersistentHeaderDelegate {
  final ValueChanged<String> onSearchChanged;

  _SearchDelegate({required this.onSearchChanged});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AdminTheme.surfaceGrey.withOpacity(overlapsContent ? 0.9 : 1.0),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: CupertinoSearchTextField(
        placeholder: 'Search by UID or Email',
        onChanged: onSearchChanged,
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant _SearchDelegate oldDelegate) => false;
}
