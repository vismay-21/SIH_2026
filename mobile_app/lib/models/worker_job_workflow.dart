import 'api/api_models.dart';

enum WorkerJobStatus {
  accepted,
  scheduled,
  active,
  evidenceSubmitted,
  paymentPending,
  completed,
}

extension WorkerJobStatusLabel on WorkerJobStatus {
  String get label => switch (this) {
    WorkerJobStatus.accepted => 'Accepted',
    WorkerJobStatus.scheduled => 'Scheduled',
    WorkerJobStatus.active => 'In Progress',
    WorkerJobStatus.evidenceSubmitted => 'Evidence Submitted',
    WorkerJobStatus.paymentPending => 'Payment Pending',
    WorkerJobStatus.completed => 'Completed',
  };
}

enum JoinRoleType { rookie, equalSharing }

extension JoinRoleTypeLabel on JoinRoleType {
  String get label => switch (this) {
    JoinRoleType.rookie => 'Rookie (Learning Progression)',
    JoinRoleType.equalSharing => 'Equal Sharing Worker',
  };
}

class WorkerOpportunity {
  const WorkerOpportunity({
    required this.id,
    this.gigId,
    required this.title,
    required this.category,
    required this.description,
    required this.wage,
    required this.when,
    required this.distance,
    required this.location,
    required this.duration,
    required this.materials,
    required this.instructions,
    this.isEmergency = false,
    this.hasScheduleConflict = false,
  });

  final String id;
  final String? gigId;
  final String title;
  final String category;
  final String description;
  final String wage;
  final String when;
  final String distance;
  final String location;
  final String duration;
  final String materials;
  final String instructions;
  final bool isEmergency;
  final bool hasScheduleConflict;

  factory WorkerOpportunity.fromDto(OpportunityDto dto) {
    final gig = dto.gig;
    final taskName =
        gig.tasks.isNotEmpty ? gig.tasks.first.taskName : gig.categoryName;
    return WorkerOpportunity(
      id: dto.id,
      gigId: dto.gigId,
      title: taskName,
      category: gig.categoryName,
      description: gig.description ?? '',
      wage: '₹${dto.exactWage.toInt()}',
      when: gig.scheduledDate ?? 'Today',
      distance: '2.5 km away',
      location: gig.address ?? 'Customer location',
      duration: gig.expectedDurationMinutes != null
          ? '${gig.expectedDurationMinutes} min'
          : '2 hours',
      materials: gig.materialProcurementMode == 'CUSTOMER_PURCHASES'
          ? 'Customer purchases'
          : 'Worker purchases',
      instructions: gig.instructions ?? '',
      isEmergency: gig.isEmergency,
      hasScheduleConflict: false,
    );
  }
}

class WorkerJob {
  const WorkerJob({
    required this.id,
    this.gigId,
    this.customerId,
    required this.title,
    required this.category,
    required this.description,
    required this.wage,
    required this.when,
    required this.location,
    required this.duration,
    required this.status,
    required this.customerName,
    required this.materials,
    required this.instructions,
    this.isEmergency = false,
    this.isRookieParticipation = false,
    this.additionalWorkerName,
  });

  final String id;
  final String? gigId;
  final String? customerId;
  final String title;
  final String category;
  final String description;
  final String wage;
  final String when;
  final String location;
  final String duration;
  final WorkerJobStatus status;
  final String customerName;
  final String materials;
  final String instructions;
  final bool isEmergency;
  final bool isRookieParticipation;
  final String? additionalWorkerName;

  factory WorkerJob.fromDto(WorkerGigListItemDto dto) {
    final status = switch (dto.status.toUpperCase()) {
      'SCHEDULED' => WorkerJobStatus.scheduled,
      'IN_PROGRESS' => WorkerJobStatus.active,
      'WORKER_COMPLETED' => WorkerJobStatus.evidenceSubmitted,
      'CUSTOMER_CONFIRMED' => WorkerJobStatus.paymentPending,
      'COMPLETED' => WorkerJobStatus.completed,
      _ => WorkerJobStatus.accepted,
    };

    return WorkerJob(
      id: dto.id,
      gigId: dto.id,
      customerId: dto.customerId,
      title: dto.categoryName,
      category: dto.categoryName,
      description: 'Cooperative service gig',
      wage: '₹${dto.exactWage.toInt()}',
      when: dto.scheduledDate ?? 'Today',
      location: dto.address ?? 'Assigned location',
      duration: dto.expectedDurationMinutes != null
          ? '${dto.expectedDurationMinutes} min'
          : '2 hours',
      status: status,
      customerName: 'Customer',
      materials: 'Cooperative verified',
      instructions: '',
      isEmergency: dto.isEmergency,
    );
  }
}

class WorkerJoinRequest {
  const WorkerJoinRequest({
    required this.id,
    required this.jobTitle,
    required this.category,
    required this.invitingWorkerName,
    required this.invitingWorkerInitials,
    required this.roleType,
    required this.when,
    required this.location,
    required this.notes,
  });

  final String id;
  final String jobTitle;
  final String category;
  final String invitingWorkerName;
  final String invitingWorkerInitials;
  final JoinRoleType roleType;
  final String when;
  final String location;
  final String notes;
}

class DayAvailability {
  const DayAvailability({
    required this.day,
    required this.isAvailable,
    required this.startTime,
    required this.endTime,
  });

  final String day;
  final bool isAvailable;
  final String startTime;
  final String endTime;

  DayAvailability copyWith({
    String? day,
    bool? isAvailable,
    String? startTime,
    String? endTime,
  }) {
    return DayAvailability(
      day: day ?? this.day,
      isAvailable: isAvailable ?? this.isAvailable,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

// ----------------------------------------------------------------------
// Mock Data Baseline
// ----------------------------------------------------------------------

final demoOpportunities = [
  const WorkerOpportunity(
    id: 'opp-1',
    title: 'Kitchen sink leak repair',
    category: 'Plumbing repair',
    description:
        'Drain pipe leak under kitchen sink. Replace seal and check faucet connections.',
    wage: '₹680',
    when: 'Today · 5:00 PM',
    distance: '3.2 km away',
    location: 'Indiranagar 100ft Road, Bengaluru',
    duration: 'Estimated · 2 hrs',
    materials: 'Customer purchases materials',
    instructions: 'Please call security gate before entering.',
  ),
  const WorkerOpportunity(
    id: 'opp-2',
    title: 'Emergency bathroom clog',
    category: 'Emergency plumbing',
    description:
        'Urgent main drain clog in ground floor flat. Immediate clearing needed.',
    wage: '₹760',
    when: 'Immediate · Within 30 min',
    distance: '2.1 km away',
    location: 'Ulsoor Main Road, Bengaluru',
    duration: 'Estimated · 60–90 min',
    materials: 'Worker purchases materials',
    instructions: 'Ring bell 2B directly. Bring drain auger.',
    isEmergency: true,
  ),
  const WorkerOpportunity(
    id: 'opp-3',
    title: 'Balcony tap installation',
    category: 'Plumbing',
    description:
        'Install new brass bib tap for washing machine in utility balcony.',
    wage: '₹520',
    when: 'Tomorrow · 10:00 AM',
    distance: '4.5 km away',
    location: 'Domlur Layout, Bengaluru',
    duration: 'Estimated · 1 hr',
    materials: 'Customer purchases materials',
    instructions: 'Tap and teflon tape already bought.',
    hasScheduleConflict: true,
  ),
  const WorkerOpportunity(
    id: 'opp-4',
    title: 'Bathroom pipe joint sealing',
    category: 'Plumbing repair',
    description:
        'Water seepage near overhead shower joint. Seal threads and test pressure.',
    wage: '₹590',
    when: 'Tomorrow · 3:30 PM',
    distance: '1.8 km away',
    location: 'Koramangala 4th Block, Bengaluru',
    duration: 'Estimated · 90 min',
    materials: 'Customer purchases materials',
    instructions: 'Water supply cutoff valve is inside the bathroom.',
  ),
];

final demoWorkerJobs = [
  const WorkerJob(
    id: 'job-1',
    title: 'Ceiling fan installation',
    category: 'Electrical work',
    description:
        'Install high-speed ceiling fan in master bedroom and wire the wall regulator.',
    wage: '₹520',
    when: 'Today · In Progress',
    location: 'Koramangala 5th Block, Bengaluru',
    duration: 'Estimated · 1 hr',
    status: WorkerJobStatus.active,
    customerName: 'Bhagya Rao',
    materials: 'Customer purchases materials',
    instructions: 'Fan box is in the hall. Ladder available.',
  ),
  const WorkerJob(
    id: 'job-2',
    title: 'Main pipeline valve replacement',
    category: 'Plumbing',
    description:
        'Replace rusted 1-inch gate valve with quarter-turn ball valve.',
    wage: '₹750',
    when: 'Tomorrow · 11:00 AM',
    location: 'Jayanagar 4th Block, Bengaluru',
    duration: 'Estimated · 2 hrs',
    status: WorkerJobStatus.scheduled,
    customerName: 'Karthik Nair',
    materials: 'Worker purchases materials',
    instructions: 'Please call 15 min before reaching.',
    additionalWorkerName: 'Suresh Kumar (Rookie)',
  ),
  const WorkerJob(
    id: 'job-3',
    title: 'Living room deep clean',
    category: 'Cleaning',
    description:
        'Complete deep cleaning of living room tiles, windows, and upholstery vacuuming.',
    wage: '₹950',
    when: 'Completed · 18 Aug',
    location: 'Jayanagar, Bengaluru',
    duration: 'Estimated · 3 hrs',
    status: WorkerJobStatus.completed,
    customerName: 'Ananya Sharma',
    materials: 'Customer purchases materials',
    instructions: 'Use the cleaning supplies in the utility room.',
  ),
];

final demoJoinRequests = [
  const WorkerJoinRequest(
    id: 'req-1',
    jobTitle: 'Commercial kitchen drainage overhaul',
    category: 'Plumbing',
    invitingWorkerName: 'Amit Sharma',
    invitingWorkerInitials: 'AS',
    roleType: JoinRoleType.rookie,
    when: 'This Saturday · 9:00 AM',
    location: 'Indiranagar 12th Main, Bengaluru',
    notes:
        'Heavy drainage task. Great learning opportunity for commercial pipe fittings. 0.5 job experience credited on completion.',
  ),
  const WorkerJoinRequest(
    id: 'req-2',
    jobTitle: 'Apartment dual-motor wiring',
    category: 'Electrical',
    invitingWorkerName: 'Rekha Patel',
    invitingWorkerInitials: 'RP',
    roleType: JoinRoleType.equalSharing,
    when: 'Tomorrow · 2:00 PM',
    location: 'HSR Layout Sector 2, Bengaluru',
    notes:
        'Dual motor control panel setup. Equal division of labour compensation.',
  ),
];

final demoWeekAvailability = [
  const DayAvailability(
    day: 'Monday',
    isAvailable: true,
    startTime: '09:00 AM',
    endTime: '06:00 PM',
  ),
  const DayAvailability(
    day: 'Tuesday',
    isAvailable: true,
    startTime: '09:00 AM',
    endTime: '06:00 PM',
  ),
  const DayAvailability(
    day: 'Wednesday',
    isAvailable: false,
    startTime: '09:00 AM',
    endTime: '06:00 PM',
  ),
  const DayAvailability(
    day: 'Thursday',
    isAvailable: true,
    startTime: '09:00 AM',
    endTime: '06:00 PM',
  ),
  const DayAvailability(
    day: 'Friday',
    isAvailable: true,
    startTime: '09:00 AM',
    endTime: '06:00 PM',
  ),
  const DayAvailability(
    day: 'Saturday',
    isAvailable: true,
    startTime: '10:00 AM',
    endTime: '04:00 PM',
  ),
  const DayAvailability(
    day: 'Sunday',
    isAvailable: false,
    startTime: '10:00 AM',
    endTime: '02:00 PM',
  ),
];
