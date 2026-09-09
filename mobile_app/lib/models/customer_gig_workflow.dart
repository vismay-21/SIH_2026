import 'api/api_models.dart';

enum GigStage {
  seeking,
  responding,
  accepted,
  selected,
  scheduled,
  active,
  completionRequested,
  payment,
  completed,
}

extension GigStageLabel on GigStage {
  String get label => switch (this) {
    GigStage.seeking => 'Seeking workers',
    GigStage.responding => 'Workers responding',
    GigStage.accepted => 'Accepted candidates',
    GigStage.selected => 'Worker selected',
    GigStage.scheduled => 'Scheduled',
    GigStage.active => 'Active',
    GigStage.completionRequested => 'Completion requested',
    GigStage.payment => 'Payment',
    GigStage.completed => 'Completed',
  };
}

class GigCandidate {
  const GigCandidate({
    this.workerId,
    required this.name,
    required this.initials,
    required this.skill,
    required this.wage,
    required this.experience,
    required this.rating,
    required this.jobs,
    required this.summary,
    required this.factors,
    this.isRecommended = false,
  });

  final String? workerId;
  final String name;
  final String initials;
  final String skill;
  final String wage;
  final String experience;
  final String rating;
  final String jobs;
  final String summary;
  final List<String> factors;
  final bool isRecommended;

  factory GigCandidate.fromDto(GigCandidateDto dto) {
    return GigCandidate(
      workerId: dto.workerId,
      name: dto.name,
      initials: dto.name.isNotEmpty ? dto.name[0].toUpperCase() : 'W',
      skill: 'Verified Specialist',
      wage: '₹${dto.exactWage.toInt()}',
      experience: '${dto.completedJobsCount} completed jobs',
      rating: dto.ratingAverage > 0 ? dto.ratingAverage.toStringAsFixed(1) : 'New',
      jobs: '${dto.completedJobsCount} gigs',
      summary: 'Reliability: ${(dto.finalScore * 100).toInt()}%',
      factors: [
        'Guaranteed wage: ₹${dto.exactWage.toInt()}',
        'Rating: ${dto.ratingAverage.toStringAsFixed(1)} (${dto.ratingCount} reviews)',
      ],
      isRecommended: dto.finalScore >= 0.7,
    );
  }
}

class CustomerGig {
  const CustomerGig({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.when,
    required this.location,
    required this.duration,
    required this.stage,
    required this.materials,
    required this.instructions,
    required this.candidates,
    this.isEmergency = false,
    this.selectedWorker,
  });

  final String? id;
  final String title;
  final String category;
  final String description;
  final String when;
  final String location;
  final String duration;
  final GigStage stage;
  final String materials;
  final String instructions;
  final List<GigCandidate> candidates;
  final bool isEmergency;
  final GigCandidate? selectedWorker;

  bool get chatEnabled => selectedWorker != null && stage != GigStage.completed;

  factory CustomerGig.fromDto(
    GigDto dto, {
    List<GigCandidate> candidates = const [],
    GigCandidate? selectedWorker,
  }) {
    final status = dto.status.toUpperCase();
    final stage = switch (status) {
      'DRAFT' || 'POSTED' || 'BROADCASTING' => GigStage.seeking,
      'RESPONDING' => GigStage.responding,
      'WORKER_SELECTED' => GigStage.selected,
      'SCHEDULED' => GigStage.scheduled,
      'IN_PROGRESS' => GigStage.active,
      'WORKER_COMPLETED' => GigStage.completionRequested,
      'CUSTOMER_CONFIRMED' => GigStage.payment,
      'COMPLETED' => GigStage.completed,
      _ => GigStage.active,
    };

    final title = dto.tasks.isNotEmpty ? dto.tasks.first.taskName : dto.categoryName;
    return CustomerGig(
      id: dto.id,
      title: title,
      category: dto.categoryName,
      description: dto.description ?? '',
      when: dto.scheduledDate ?? 'As arranged',
      location: dto.address ?? 'Customer address',
      duration: dto.expectedDurationMinutes != null
          ? '${dto.expectedDurationMinutes} min'
          : 'Flexible',
      stage: stage,
      materials: dto.materialProcurementMode == 'CUSTOMER_PURCHASES'
          ? 'Customer purchases'
          : 'Worker purchases',
      instructions: dto.instructions ?? '',
      candidates: candidates,
      isEmergency: dto.isEmergency,
      selectedWorker: selectedWorker,
    );
  }

  CustomerGig copyWith({
    String? id,
    GigStage? stage,
    GigCandidate? selectedWorker,
    List<GigCandidate>? candidates,
  }) =>
      CustomerGig(
        id: id ?? this.id,
        title: title,
        category: category,
        description: description,
        when: when,
        location: location,
        duration: duration,
        stage: stage ?? this.stage,
        materials: materials,
        instructions: instructions,
        candidates: candidates ?? this.candidates,
        isEmergency: isEmergency,
        selectedWorker: selectedWorker ?? this.selectedWorker,
      );
}

const demoCandidates = [
  GigCandidate(
    name: 'Amit Sharma',
    initials: 'AS',
    skill: 'Plumber',
    wage: '₹680',
    experience: '6 years',
    rating: '4.8',
    jobs: '23 comparable jobs',
    summary: 'Reliable plumbing work with strong repeat-customer reviews.',
    factors: ['Strong skill match', 'Available today', 'High reliability'],
    isRecommended: true,
  ),
  GigCandidate(
    name: 'Suresh Kumar',
    initials: 'SK',
    skill: 'Plumber',
    wage: '₹550',
    experience: '2 years',
    rating: '4.6',
    jobs: '11 completed jobs',
    summary: 'Good value and verified for household plumbing repairs.',
    factors: ['Lowest labour wage', 'Verified worker', 'Available today'],
  ),
  GigCandidate(
    name: 'Meena Das',
    initials: 'MD',
    skill: 'Plumbing specialist',
    wage: '₹800',
    experience: '9 years',
    rating: '4.9',
    jobs: '41 comparable jobs',
    summary: 'Experienced specialist with excellent quality feedback.',
    factors: ['Highest experience', 'Best review quality', 'Busy until 6 PM'],
  ),
];

final demoGigs = [
  CustomerGig(
    title: 'Kitchen sink leak repair',
    category: 'Plumbing repair',
    description: 'Leak under sink. Same-day repair required.',
    when: 'Today · 5:00 PM',
    location: 'Indiranagar, Bengaluru',
    duration: 'Estimated · 2 hrs',
    stage: GigStage.accepted,
    materials: 'Customer purchases materials',
    instructions: 'Please call at the gate before entering.',
    candidates: demoCandidates,
  ),
  CustomerGig(
    title: 'Emergency bathroom clog',
    category: 'Emergency plumbing',
    description: 'Urgent clog. Nearby worker matching enabled.',
    when: 'Today · Immediate',
    location: 'Ulsoor, Bengaluru',
    duration: 'Estimated · 60–90 min',
    stage: GigStage.responding,
    materials: 'Worker purchases materials',
    instructions: 'The bathroom is next to the kitchen.',
    candidates: [demoCandidates[1]],
    isEmergency: true,
  ),
  CustomerGig(
    title: 'Bedroom fan replacement',
    category: 'Electrical work',
    description: 'Replace the ceiling fan and check the regulator.',
    when: 'Tomorrow · 10:00 AM',
    location: 'Koramangala, Bengaluru',
    duration: 'Estimated · 1 hr',
    stage: GigStage.scheduled,
    materials: 'Customer purchases materials',
    instructions: 'New fan is already at home.',
    candidates: [demoCandidates[2]],
    selectedWorker: demoCandidates[2],
  ),
  CustomerGig(
    title: 'Living room deep clean',
    category: 'Cleaning',
    description: 'Deep clean after a small family event.',
    when: 'Completed · 18 Aug',
    location: 'Jayanagar, Bengaluru',
    duration: 'Estimated · 3 hrs',
    stage: GigStage.completed,
    materials: 'Customer purchases materials',
    instructions: 'Use the supplies in the utility room.',
    candidates: [demoCandidates[0]],
    selectedWorker: demoCandidates[0],
  ),
  CustomerGig(
    title: 'Water heater installation',
    category: 'Plumbing & Appliance',
    description: 'Installing a new 15L water heater in the master bathroom.',
    when: 'Today · 6:30 PM',
    location: 'Indiranagar, Bengaluru',
    duration: 'Estimated · 2 hrs',
    stage: GigStage.seeking,
    materials: 'Customer purchases materials',
    instructions: 'Heater is unboxed. Bring mounting tools.',
    candidates: [],
  ),
  CustomerGig(
    title: 'Main power fuse tripping',
    category: 'Emergency Electrical',
    description: 'Frequent tripping of main breaker box in 2BHK.',
    when: 'Today · Immediate',
    location: 'HSR Layout, Bengaluru',
    duration: 'Estimated · 45 min',
    stage: GigStage.seeking,
    materials: 'Worker purchases materials',
    instructions: 'Power currently off in bedrooms.',
    candidates: [],
    isEmergency: true,
  ),
];
