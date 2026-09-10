import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../repositories/gig_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../../common/splash_screen.dart';
import '../my_jobs/gig_details_screen.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final _gigRepo = GigRepository();
  List<CustomerGig> _activeGigs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _gigRepo.getCustomerGigs(pageSize: 50);
      final list = resp.data
          .where((dto) =>
              dto.selectedWorkerId != null &&
              dto.status != 'COMPLETED' &&
              dto.status != 'CANCELLED')
          .map((dto) => CustomerGig.fromDto(dto))
          .toList();
      if (!mounted) return;
      setState(() {
        _activeGigs = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat')),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _activeGigs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No active conversations',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Direct chat with workers opens once you confirm an artisan for your gig.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _activeGigs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final gig = _activeGigs[index];
                  final workerName =
                      gig.selectedWorker?.name ?? 'Assigned Worker';
                  return _ConversationTile(
                    name: workerName,
                    initials: workerName.isNotEmpty
                        ? workerName[0].toUpperCase()
                        : 'W',
                    preview: 'Active discussion for ${gig.title}',
                    time: gig.when,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CustomerChatThreadScreen(
                          workerName: workerName,
                          jobTitle: gig.title,
                        ),
                      ),
                    ),
                  );
                },
              ),
  );
}

class CustomerChatThreadScreen extends StatefulWidget {
  const CustomerChatThreadScreen({
    super.key,
    required this.workerName,
    required this.jobTitle,
    this.enabled = true,
  });

  final String workerName;
  final String jobTitle;
  final bool enabled;

  @override
  State<CustomerChatThreadScreen> createState() =>
      _CustomerChatThreadScreenState();
}

class _CustomerChatThreadScreenState extends State<CustomerChatThreadScreen> {
  final _messageController = TextEditingController();
  final _messages = <String>[
    'I can reach by 5:00 PM. I will bring the sealant.',
    'Thanks, I will be ready.',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _messages.add(message);
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.workerName),
          Text(
            widget.jobTitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GigDetailsScreen(gig: demoGigs[0]),
            ),
          ),
          icon: const Icon(Icons.work_outline_rounded),
          tooltip: 'Open job',
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, index) => Align(
              alignment: index.isEven
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: index.isEven ? AppColors.surface : AppColors.primary,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _messages[index],
                  style: TextStyle(
                    color: index.isEven ? AppColors.text : Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: widget.enabled,
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: widget.enabled
                          ? 'Write a message'
                          : 'Chat history · messaging closed',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: widget.enabled ? _sendMessage : null,
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class CustomerJobHistoryScreen extends StatefulWidget {
  const CustomerJobHistoryScreen({super.key});

  @override
  State<CustomerJobHistoryScreen> createState() =>
      _CustomerJobHistoryScreenState();
}

class _CustomerJobHistoryScreenState extends State<CustomerJobHistoryScreen> {
  final _gigRepo = GigRepository();
  List<CustomerGig> _completedGigs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _gigRepo.getCustomerGigs(status: 'COMPLETED');
      final mapped = resp.data.map(CustomerGig.fromDto).toList();
      if (!mounted) return;
      setState(() {
        _completedGigs = mapped;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Job history')),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _completedGigs.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No completed jobs yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Completed household gigs and digital service receipts will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _completedGigs.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final gig = _completedGigs[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GigDetailsScreen(gig: gig),
                      ),
                    ),
                    child: SurfaceCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gig.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${gig.stage.label} · ${gig.when}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
  );
}

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  bool _jobAlerts = true;
  bool _workerMessages = true;
  bool _locationSharing = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile.adaptive(
                title: const Text('Job updates'),
                subtitle: const Text('Status and worker responses'),
                value: _jobAlerts,
                onChanged: (value) => setState(() => _jobAlerts = value),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                title: const Text('Worker messages'),
                subtitle: const Text('New chat messages'),
                value: _workerMessages,
                onChanged: (value) => setState(() => _workerMessages = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Privacy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile.adaptive(
            title: const Text('Share location for matching'),
            subtitle: const Text('Used only for practical worker matching'),
            value: _locationSharing,
            onChanged: (value) => setState(() => _locationSharing = value),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Account',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account details are managed by your cooperative.'),
            ),
          ),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Manage account'),
        ),
      ],
    ),
  );
}

class CustomerHelpSupportScreen extends StatelessWidget {
  const CustomerHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help and support')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'How can we help?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Find answers about gigs, workers, payments, and materials.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 18),
        _HelpTile(
          title: 'How does worker selection work?',
          body:
              'Workers accept opportunities first. You compare accepted candidates and choose the final worker.',
        ),
        _HelpTile(
          title: 'When do I pay?',
          body:
              'Payment follows your completion confirmation. Labour and materials are shown separately.',
        ),
        _HelpTile(
          title: 'How do material bills work?',
          body:
              'If the worker purchases materials, they upload a bill or proof for you to view.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: 'Contact cooperative support',
            icon: Icons.support_agent_rounded,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Support request started. Your cooperative team will respond soon.',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.initials,
    required this.preview,
    required this.time,
    required this.onTap,
  });
  final String name;
  final String initials;
  final String preview;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Text(initials),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        time,
        style: const TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    ),
  );
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    children: [
      Text(body, style: const TextStyle(color: AppColors.muted, height: 1.35)),
    ],
  );
}

Future<void> showCustomerSignOutDialog(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        'You can sign back in whenever you need to manage your gigs.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (shouldSignOut == true && context.mounted) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }
}
