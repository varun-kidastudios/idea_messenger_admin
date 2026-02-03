import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/admin_user.dart';
import '../providers/chats_provider.dart';
import '../theme_constants.dart';
import 'chat_detail_screen.dart';

class ChatsListScreen extends ConsumerStatefulWidget {
  final AdminUser user;

  const ChatsListScreen({super.key, required this.user});

  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> {
  final List<String> _categories = [
    'all', 'youtube', 'finance', 'diy', 'tech', 'music', 'business',
    'health', 'education', 'fashion', 'travel', 'creation', 'art', 'others',
  ];

  String _getCategoryDisplayName(String category) {
    if (category == 'all') return 'All';
    return category[0].toUpperCase() + category.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = ref.watch(filteredChatsProvider(widget.user.uid));
    final chatsAsync = ref.watch(userChatsStreamProvider(widget.user.uid));
    final selectedCategory = ref.watch(categoryFilterProvider);

    return CupertinoPageScaffold(
      backgroundColor: AdminTheme.surfaceGrey,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AdminTheme.surfaceWhite,
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCategoryFilter(selectedCategory),
            Expanded(
              child: chatsAsync.when(
                data: (chats) {
                  if (filteredChats.isEmpty) {
                    return _buildEmptyState();
                  }

                  return CustomScrollView(
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(AdminTheme.paddingMedium),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final chat = filteredChats[index];
                              return _buildChatCard(chat);
                            },
                            childCount: filteredChats.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(String? selectedCategory) {
    return Container(
      color: AdminTheme.surfaceWhite,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = (selectedCategory == null && category == 'all') || selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  ref.read(categoryFilterProvider.notifier).state = category == 'all' ? null : category;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AdminTheme.primaryBlue : AdminTheme.surfaceGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _getCategoryDisplayName(category),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? CupertinoColors.white : AdminTheme.textGrey,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatCard(chat) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
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
          ref.read(selectedChatProvider.notifier).state = chat;
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => ChatDetailScreen(userId: widget.user.uid, chat: chat),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(chat.categoryColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.chat_bubble_text_fill,
                  color: Color(chat.categoryColor),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title,
                      style: AdminTheme.body.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(chat.categoryColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            chat.categoryName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(chat.categoryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(chat.updatedAt),
                          style: AdminTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${chat.messageCount}',
                    style: AdminTheme.heading2.copyWith(fontSize: 18, color: AdminTheme.primaryBlue),
                  ),
                  const Text('msgs', style: AdminTheme.caption),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right, size: 14, color: AdminTheme.textLightGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.chat_bubble_2, size: 64, color: AdminTheme.textLightGrey),
          const SizedBox(height: 16),
          Text('No chats found', style: AdminTheme.subHeading),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(error.toString(), style: AdminTheme.caption, textAlign: TextAlign.center),
      ),
    );
  }
}
