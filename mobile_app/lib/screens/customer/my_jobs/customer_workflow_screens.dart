import 'package:flutter/material.dart';

import '../../../models/customer_gig_workflow.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/shared_widgets.dart';
import '../profile/customer_account_screens.dart';

class AcceptedCandidatesScreen extends StatelessWidget {
  const AcceptedCandidatesScreen({super.key, required this.gig});
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Accepted candidates',
    subtitle: 'Compare workers who accepted this gig before choosing one.',
    child: Column(
      children: [
        ...gig.candidates.map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CandidateTile(candidate: candidate, gig: gig),
          ),
        ),
        const SizedBox(height: 4),
        _ActionCard(
          icon: Icons.history_rounded,
          title: 'Request a previous worker',
          subtitle: 'A previous worker must accept before they are selected.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PreviousWorkerRequestScreen(),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate, required this.gig});
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Text(candidate.initials),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${candidate.skill} · ${candidate.experience}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (candidate.isRecommended) const StatusPill('Recommended'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          candidate.summary,
          style: const TextStyle(color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 10),
        Text(
          '${candidate.wage} labour · ★ ${candidate.rating} · ${candidate.jobs}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkerComparisonScreen(gig: gig),
                  ),
                ),
                child: const Text('Compare'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      WorkerProfileScreen(candidate: candidate, gig: gig),
                ),
              ),
              child: const Text('Profile'),
            ),
          ],
        ),
      ],
    ),
  );
}

class WorkerComparisonScreen extends StatelessWidget {
  const WorkerComparisonScreen({super.key, required this.gig});
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Compare workers',
    subtitle: 'The recommendation is guidance, not automatic assignment.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Cooperative recommendation',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Amit is recommended for the strongest skill match, availability, and reliability signals.',
                style: TextStyle(color: AppColors.muted, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...gig.candidates.map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ComparisonRow(candidate: candidate, gig: gig),
          ),
        ),
      ],
    ),
  );
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.candidate, required this.gig});
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                candidate.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              candidate.wage,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '${candidate.experience} · ★ ${candidate.rating} · ${candidate.jobs}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: candidate.factors
              .map((factor) => StatusPill(factor))
              .toList(),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    WorkerProfileScreen(candidate: candidate, gig: gig),
              ),
            ),
            child: const Text('View profile'),
          ),
        ),
      ],
    ),
  );
}

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({
    super.key,
    required this.candidate,
    required this.gig,
  });
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Worker profile',
    subtitle: 'Review profile information before making your choice.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Text(
                  candidate.initials,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                candidate.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                candidate.skill,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Text(
                '★ ${candidate.rating} · ${candidate.jobs}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'Experience',
          body: '${candidate.experience} of comparable household work.',
        ),
        _InfoCard(title: 'Review summary', body: candidate.summary),
        _InfoCard(
          title: 'Relevant factors',
          body: candidate.factors.join(' · '),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: 'Select this worker',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    FinalWorkerSelectedScreen(candidate: candidate, gig: gig),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class FinalWorkerSelectedScreen extends StatelessWidget {
  const FinalWorkerSelectedScreen({
    super.key,
    required this.candidate,
    required this.gig,
  });
  final GigCandidate candidate;
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) {
    final selectedGig = gig.copyWith(
      stage: GigStage.selected,
      selectedWorker: candidate,
    );

    return _WorkflowScaffold(
      title: 'Worker selected',
      subtitle: 'You have made the final choice for this gig.',
      child: Column(
        children: [
          SurfaceCard(
            child: Column(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
                const SizedBox(height: 10),
                Text(
                  candidate.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${candidate.skill} · ${candidate.wage} labour',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Job chat is now available after worker selection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: PrimaryAction(
              label: 'Open active job',
              icon: Icons.work_history_outlined,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => ActiveJobScreen(gig: selectedGig),
                ),
                (route) => route.isFirst,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreviousWorkerRequestScreen extends StatelessWidget {
  const PreviousWorkerRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Request previous worker',
    subtitle: 'Amit Sharma is not selected until he accepts this request.',
    child: Column(
      children: [
        SurfaceCard(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Text('AS'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amit Sharma',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Plumber · ★ 4.8 · 23 jobs',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const StatusPill('Available'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'What happens next',
          body:
              'Amit can accept, reject, or propose another time. If unavailable, you can return to open matching.',
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: 'Send request',
            icon: Icons.send_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request sent to Amit Sharma.')),
              );
              Navigator.of(context).pop();
            },
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Open matching instead'),
        ),
      ],
    ),
  );
}

class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key, required this.gig});
  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Active job',
    subtitle: 'Keep the job information and next action in one place.',
    child: Column(
      children: [
        _InfoCard(
          title: gig.title,
          body:
              '${gig.location}\n${gig.when}\n${gig.duration}\n${gig.instructions}',
        ),
        _InfoCard(
          title: 'Selected worker',
          body: gig.selectedWorker?.name ?? 'Amit Sharma · Plumber',
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerChatThreadScreen(
                      workerName: gig.selectedWorker?.name ?? 'Amit Sharma',
                      jobTitle: gig.title,
                      enabled: gig.chatEnabled,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(
                  gig.chatEnabled ? 'Open chat' : 'View chat history',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompletionEvidenceReviewScreen(gig: gig),
                  ),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review evidence'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const StatusPill('Scheduled · Active next'),
      ],
    ),
  );
}

class CompletionEvidenceReviewScreen extends StatelessWidget {
  const CompletionEvidenceReviewScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Completion evidence',
    subtitle: 'Review the worker evidence before confirming the work.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
                size: 38,
              ),
              const SizedBox(height: 10),
              const Text(
                '2 completion photos uploaded',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Before and after photos from the selected worker are ready to review.',
                style: TextStyle(color: AppColors.muted, height: 1.3),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evidence viewer opened.')),
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('View evidence'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: 'Confirm completion',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CompletionConfirmationScreen(gig: gig),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can contact the worker before confirming.'),
            ),
          ),
          child: const Text('Contact worker about the work'),
        ),
      ],
    ),
  );
}

class CompletionConfirmationScreen extends StatelessWidget {
  const CompletionConfirmationScreen({super.key, required this.gig});

  final CustomerGig gig;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Confirm completion',
    subtitle: 'Confirm only after checking that the work is complete.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(height: 10),
              const Text(
                'Is the work complete?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              const Text(
                'This moves the gig to payment. Evidence alone does not complete a gig.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: 'Yes, confirm completion',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PaymentScreen(gig: gig)),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not yet'),
        ),
      ],
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.gig});

  final CustomerGig gig;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'UPI';
  bool _paid = false;

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Payment',
    subtitle: 'Pay the confirmed labour amount. Materials stay separate.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amount due',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 5),
              const Text(
                '₹680',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Labour/service cost only',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'UPI',
              label: Text('UPI'),
              icon: Icon(Icons.account_balance_wallet_outlined),
            ),
            ButtonSegment(
              value: 'Cash',
              label: Text('Cash'),
              icon: Icon(Icons.payments_outlined),
            ),
          ],
          selected: {_method},
          onSelectionChanged: (selection) =>
              setState(() => _method = selection.first),
        ),
        const SizedBox(height: 8),
        Text(
          _method == 'UPI'
              ? 'Pay using a UPI app.'
              : 'Mark cash payment after handing it over.',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: PrimaryAction(
            label: _paid ? 'Payment marked' : 'Pay with $_method',
            icon: _paid ? Icons.check_rounded : Icons.lock_outline_rounded,
            onPressed: _paid
                ? null
                : () {
                    setState(() => _paid = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payment recorded. Worker confirmation is pending.',
                        ),
                      ),
                    );
                  },
          ),
        ),
        if (_paid)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                const StatusPill('Payment complete · Chat closed'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => ActiveJobScreen(
                          gig: widget.gig.copyWith(stage: GigStage.completed),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.work_outline_rounded),
                    label: const Text('View completed job'),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class MaterialBillViewerScreen extends StatelessWidget {
  const MaterialBillViewerScreen({super.key});

  @override
  Widget build(BuildContext context) => _WorkflowScaffold(
    title: 'Material bill / proof',
    subtitle: 'Review the worker-purchased material evidence.',
    child: Column(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Material purchase proof',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'PVC trap and sealant',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Uploaded by Amit Sharma · Today, 6:12 PM',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Container(
                height: 180,
                width: double.infinity,
                color: AppColors.background,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 58,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Total material amount',
                style: TextStyle(color: AppColors.muted),
              ),
              const Text(
                '₹420',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Legitimate material bills are expected to be honoured. Material disputes are outside the MVP.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
      ],
    ),
  );
}

class _WorkflowScaffold extends StatelessWidget {
  const _WorkflowScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SurfaceCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    ),
  );
}
