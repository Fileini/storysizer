import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/providers.dart';
import 'package:storysizer/services/auth_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class GroupsView extends ConsumerStatefulWidget {
  const GroupsView({super.key});

  @override
  ConsumerState<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends ConsumerState<GroupsView> with RouteAware {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(groupsNotifierProvider.notifier).loadGroups());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    ref.read(groupsNotifierProvider.notifier).loadGroups();
  }

  Future<void> _showCreateGroupDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Group name'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        final group = await ref.read(dataRepositoryProvider).createGroup(controller.text.trim());
        await ref.read(groupsNotifierProvider.notifier).loadGroups();
        if (mounted) context.go('/groups/${group.id}');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating group: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Group Estimation')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.groups == null || state.groups!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.group_solid, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No groups yet.',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Create one or accept an invitation.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(groupsNotifierProvider.notifier).loadGroups(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: state.groups!.length,
                        itemBuilder: (context, index) {
                          final group = state.groups![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(CupertinoIcons.group_solid),
                              ),
                              title: Text(group.name,
                                  style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                  '${group.members.length} member${group.members.length != 1 ? 's' : ''}'),
                              trailing: group.iAmAdmin
                                  ? Chip(
                                      label: const Text('Admin'),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primaryContainer,
                                      labelStyle: const TextStyle(fontSize: 11),
                                    )
                                  : const Icon(CupertinoIcons.chevron_right),
                              onTap: () => context.go('/groups/${group.id}'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ─── Join Group Screen (handles /join-group?token=...) ───────────────────────

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String token;
  const JoinGroupScreen({super.key, required this.token});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  static const String _pendingTokenKey = 'pending_invite_token';
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final loginInfo = AuthService.instance.loginInfo;
    loginInfo.addListener(_maybeStart);
    _maybeStart();
  }

  @override
  void dispose() {
    AuthService.instance.loginInfo.removeListener(_maybeStart);
    super.dispose();
  }

  void _maybeStart() {
    if (_started || !mounted) return;
    final loginInfo = AuthService.instance.loginInfo;
    if (!loginInfo.isInitialized) return; // wait for Keycloak check-sso

    if (widget.token.isEmpty) {
      _started = true;
      context.go(loginInfo.isLoggedIn ? '/groups' : '/');
      return;
    }

    if (!loginInfo.isLoggedIn) {
      // Anonymous: stash the token so we can resume after login, then bounce
      // to the login screen WITHOUT triggering any API call (which would
      // otherwise force an immediate keycloak.login() with no IdP hint and
      // land the user on Keycloak's credentials page).
      _started = true;
      html.window.localStorage[_pendingTokenKey] = widget.token;
      context.go('/');
      return;
    }

    _started = true;
    Future.microtask(_acceptInvite);
  }

  Future<void> _acceptInvite() async {
    try {
      final group =
          await ref.read(dataRepositoryProvider).acceptGroupInvite(widget.token);
      if (mounted) context.go('/groups/${group.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept invite: $e')),
        );
        context.go('/groups');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Accepting invitation…'),
          ],
        ),
      ),
    );
  }
}
