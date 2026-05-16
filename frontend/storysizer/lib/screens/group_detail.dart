import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/models/group.dart';
import 'package:storysizer/models/group_estimation.dart';
import 'package:storysizer/providers.dart';

class GroupDetailView extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailView({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends ConsumerState<GroupDetailView> {
  void _reload() {
    ref.invalidate(groupDetailProvider(widget.groupId));
    ref.read(groupEstimationsNotifierProvider(widget.groupId).notifier).load();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(groupEstimationsNotifierProvider(widget.groupId).notifier).load());
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  Future<void> _inviteDialog(String groupId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Email address'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send Invite')),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await ref.read(dataRepositoryProvider).inviteToGroup(groupId, controller.text.trim());
        _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation sent!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _renameGroupDialog(String groupId, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rename')),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await ref.read(dataRepositoryProvider).renameGroup(groupId, controller.text.trim());
        _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteGroupDialog(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure? This will delete all estimations in this group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(dataRepositoryProvider).deleteGroup(groupId);
        if (mounted) context.go('/groups');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _createEstimationDialog(String groupId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Group Estimation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Story / feature title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        final estimation = await ref
            .read(dataRepositoryProvider)
            .createGroupEstimation(groupId, controller.text.trim());
        _reload();
        if (mounted) {
          context.go('/groups/$groupId/estimation/${estimation.id}/vote');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _estimationOptionsDialog(
      String groupId, GroupEstimationItemModel item, bool isAdmin) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.chart_bar_fill),
              title: const Text('View Dashboard'),
              enabled: isAdmin,
              onTap: isAdmin ? () => Navigator.pop(ctx, 'dashboard') : null,
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.pencil),
              title: Text(item.isPending ? 'Vote' : 'View my vote'),
              onTap: () => Navigator.pop(ctx, 'vote'),
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(CupertinoIcons.refresh),
                title: const Text('Restart voting'),
                onTap: () => Navigator.pop(ctx, 'restart'),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.pencil_outline),
                title: const Text('Rename'),
                onTap: () => Navigator.pop(ctx, 'rename'),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ],
        ),
      ),
    );

    if (action == null) return;
    switch (action) {
      case 'vote':
        if (mounted) context.go('/groups/$groupId/estimation/${item.id}/vote');
        break;
      case 'dashboard':
        if (mounted) context.go('/groups/$groupId/estimation/${item.id}/dashboard');
        break;
      case 'restart':
        try {
          await ref.read(dataRepositoryProvider).restartGroupEstimation(item.id);
          _reload();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        break;
      case 'rename':
        if (!mounted) return;
        final controller = TextEditingController(text: item.title);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rename Estimation'),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rename')),
            ],
          ),
        );
        if (ok == true && controller.text.trim().isNotEmpty) {
          try {
            await ref
                .read(dataRepositoryProvider)
                .renameGroupEstimation(item.id, controller.text.trim());
            _reload();
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
        break;
      case 'delete':
        try {
          await ref.read(dataRepositoryProvider).deleteGroupEstimation(item.id);
          _reload();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        break;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final estimationsState = ref.watch(groupEstimationsNotifierProvider(widget.groupId));

    return groupAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (group) => Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/groups'),
          ),
          actions: [
            if (group.iAmAdmin)
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'rename') _renameGroupDialog(group.id, group.name);
                  if (val == 'delete') _deleteGroupDialog(group.id);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename Group')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Group', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
        floatingActionButton: group.iAmAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _createEstimationDialog(group.id),
                icon: const Icon(Icons.add),
                label: const Text('New Estimation'),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // ── Estimations ──────────────────────────────────────────────
              _SectionHeader(title: 'Estimations'),
              if (estimationsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (estimationsState.items?.isEmpty ?? true)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No estimations yet.', textAlign: TextAlign.center),
                )
              else
                ...estimationsState.items!.map((item) => _EstimationTile(
                      item: item,
                      isAdmin: group.iAmAdmin,
                      onTap: () => (group.iAmAdmin && !item.isPending)
                          ? context.go('/groups/${group.id}/estimation/${item.id}/dashboard')
                          : context.go('/groups/${group.id}/estimation/${item.id}/vote'),
                      onLongPress: () =>
                          _estimationOptionsDialog(group.id, item, group.iAmAdmin),
                    )),
              const Divider(height: 24),

              // ── Members ──────────────────────────────────────────────────
              _SectionHeader(
                title: 'Members (${group.members.length})',
                trailing: group.iAmAdmin
                    ? TextButton.icon(
                        onPressed: () => _inviteDialog(group.id),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Invite'),
                      )
                    : null,
              ),
              ...group.members.map((m) => _MemberTile(
                    member: m,
                    isAdmin: group.iAmAdmin,
                    onPromote: () async {
                      await ref
                          .read(dataRepositoryProvider)
                          .promoteGroupMember(group.id, m.userId);
                      _reload();
                    },
                    onRemove: () async {
                      await ref
                          .read(dataRepositoryProvider)
                          .removeGroupMember(group.id, m.userId);
                      _reload();
                    },
                  )),

              // ── Pending invitations (admin only) ─────────────────────────
              if (group.iAmAdmin && group.pendingInvitations.isNotEmpty) ...[
                const Divider(height: 24),
                _SectionHeader(title: 'Pending Invitations'),
                ...group.pendingInvitations.map((inv) => ListTile(
                      leading: const Icon(CupertinoIcons.mail, size: 20),
                      title: Text(inv.invitedEmail,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle, color: Colors.red),
                        onPressed: () async {
                          await ref
                              .read(dataRepositoryProvider)
                              .cancelGroupInvite(group.id, inv.id);
                          _reload();
                        },
                      ),
                    )),
              ],
              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EstimationTile extends StatelessWidget {
  final GroupEstimationItemModel item;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EstimationTile(
      {required this.item,
      required this.isAdmin,
      required this.onTap,
      required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isPending = item.isPending;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        onLongPress: isAdmin ? onLongPress : null,
        leading: CircleAvatar(
          backgroundColor: isPending ? Colors.amber.shade600 : Colors.green.shade600,
          child: Icon(
            isPending ? CupertinoIcons.exclamationmark : CupertinoIcons.checkmark,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(item.title),
        trailing: isAdmin
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onLongPress,
              )
            : const Icon(CupertinoIcons.chevron_right),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GroupMemberModel member;
  final bool isAdmin;
  final VoidCallback onPromote;
  final VoidCallback onRemove;

  const _MemberTile(
      {required this.member,
      required this.isAdmin,
      required this.onPromote,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(member.displayName[0].toUpperCase())),
      title: Text(member.displayName),
      subtitle: Text(member.email, style: Theme.of(context).textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(member.isAdmin ? 'Admin' : 'Member'),
            backgroundColor: member.isAdmin
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            labelStyle: const TextStyle(fontSize: 11),
          ),
          if (isAdmin) ...[
            if (!member.isAdmin)
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: 'Promote to Admin',
                onPressed: onPromote,
              ),
            IconButton(
              icon: const Icon(Icons.person_remove, size: 18, color: Colors.red),
              tooltip: 'Remove',
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
