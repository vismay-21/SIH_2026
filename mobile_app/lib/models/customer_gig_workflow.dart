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
  cancelled,
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
    GigStage.cancelled => 'Cancelled',
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
    this.phoneNumber = '+91 98765 43210',
    this.upiId = 'artisan.coop@oksbi',
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
  final String phoneNumber;
  final String upiId;

  factory GigCandidate.fromDto(GigCandidateDto dto, {String? categoryName}) {
    final skillTitle = categoryName != null && categoryName.isNotEmpty
        ? '$categoryName Specialist'
        : 'Guild Certified Artisan';
    final reliabilityPercent = (dto.finalScore * 100).toInt();
    final reviewCount = dto.ratingCount;
    final ratingStr = dto.ratingAverage > 0 ? dto.ratingAverage.toStringAsFixed(1) : 'New';

    final safeId = dto.workerId.replaceAll('-', '');
    final suffix = (safeId.hashCode.abs() % 90000 + 10000).toString();
    final phone = '+91 98765 $suffix';
    final cleanName = dto.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final upi = '${cleanName.isNotEmpty ? cleanName : "artisan"}@oksbi';

    return GigCandidate(
      workerId: dto.workerId,
      name: dto.name,
      initials: dto.name.isNotEmpty ? dto.name[0].toUpperCase() : 'W',
      skill: skillTitle,
      wage: '₹${dto.exactWage.toInt()}',
      experience: '${dto.completedJobsCount} completed jobs in trade guild',
      rating: ratingStr,
      jobs: '${dto.completedJobsCount} gigs',
      summary: 'Tier 2 Guild Verified · Reliability: $reliabilityPercent% (Algorithmic Quality: $ratingStr)',
      factors: [
        'Guaranteed tariff wage: ₹${dto.exactWage.toInt()}',
        'Customer rating: $ratingStr ($reviewCount reviews)',
        'Tier 1: Identity & Police Antecedents Cleared',
        'Cooperative Shareholder Member',
      ],
      isRecommended: dto.finalScore >= 0.7,
      phoneNumber: phone,
      upiId: upi,
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
    this.price,
    this.gigType,
    this.rawStatus,
    this.workerWage,
    this.estimatedMinPrice,
    this.estimatedMaxPrice,
    this.googleMapsLink,
    this.latitude,
    this.longitude,
    this.scheduledDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
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
  final double? price;
  final String? gigType;
  final String? rawStatus;
  final double? workerWage;
  final double? estimatedMinPrice;
  final double? estimatedMaxPrice;
  final String? googleMapsLink;
  final double? latitude;
  final double? longitude;
  final String? scheduledDate;
  final String? scheduledStartTime;
  final String? scheduledEndTime;

  static String formatDateTimeDisplay(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'As arranged';
    }

    String formattedDate = dateStr;
    try {
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        final now = DateTime.now();
        final isToday = parsedDate.year == now.year &&
            parsedDate.month == now.month &&
            parsedDate.day == now.day;
        final tomorrow = now.add(const Duration(days: 1));
        final isTomorrow = parsedDate.year == tomorrow.year &&
            parsedDate.month == tomorrow.month &&
            parsedDate.day == tomorrow.day;

        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthName = months[parsedDate.month - 1];

        if (isToday) {
          formattedDate = 'Today, ${parsedDate.day} $monthName';
        } else if (isTomorrow) {
          formattedDate = 'Tomorrow, ${parsedDate.day} $monthName';
        } else {
          formattedDate = '${parsedDate.day} $monthName ${parsedDate.year}';
        }
      }
    } catch (_) {}

    if (timeStr == null || timeStr.isEmpty) {
      return formattedDate;
    }

    String formattedTime = timeStr;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1].padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) {
          hour = 12;
        } else if (hour > 12) {
          hour -= 12;
        }
        formattedTime = '$hour:$minute $ampm';
      }
    } catch (_) {}

    return '$formattedDate at $formattedTime';
  }

  String get scheduleDisplay => formatDateTimeDisplay(scheduledDate, scheduledStartTime);

  bool get chatEnabled => selectedWorker != null && stage != GigStage.completed;

  /// Dynamic price display:
  /// - Before worker selection: shows price range (e.g. ₹550 – ₹800 or ₹min – ₹max)
  /// - After worker selection: shows exact fixed price agreed with worker (e.g. ₹680)
  String get priceDisplay {
    final isWorkerSelected = selectedWorker != null ||
        stage == GigStage.selected ||
        stage == GigStage.scheduled ||
        stage == GigStage.active ||
        stage == GigStage.completionRequested ||
        stage == GigStage.payment ||
        stage == GigStage.completed;

    if (isWorkerSelected) {
      if (workerWage != null && workerWage! > 0) {
        return '₹${workerWage!.toInt()}';
      }
      if (selectedWorker != null && selectedWorker!.wage.isNotEmpty) {
        final digitsOnly = selectedWorker!.wage.replaceAll(RegExp(r'[^0-9.]'), '');
        final parsed = double.tryParse(digitsOnly);
        if (parsed != null && parsed > 0) {
          return '₹${parsed.toInt()}';
        }
      }
      if (price != null && price! > 0) {
        return '₹${price!.toInt()}';
      }
      return '₹680';
    }

    // Before worker is selected: show price range!
    if (candidates.isNotEmpty) {
      final wages = candidates
          .map((c) => double.tryParse(c.wage.replaceAll(RegExp(r'[^0-9.]'), '')))
          .whereType<double>()
          .toList();
      if (wages.isNotEmpty) {
        wages.sort();
        final minW = wages.first.toInt();
        final maxW = wages.last.toInt();
        if (minW != maxW) {
          return '₹$minW – ₹$maxW';
        } else {
          return '₹$minW';
        }
      }
    }

    if (estimatedMinPrice != null && estimatedMaxPrice != null && estimatedMinPrice! > 0) {
      final minP = estimatedMinPrice!.toInt();
      final maxP = estimatedMaxPrice!.toInt();
      if (minP != maxP) {
        return '₹$minP – ₹$maxP';
      }
      return '₹$minP';
    }

    if (price != null && price! > 0) {
      final minP = price!.toInt();
      final maxP = (price! * 1.30).round();
      if (minP != maxP) {
        return '₹$minP – ₹$maxP';
      }
      return '₹$minP';
    }

    return '₹550 – ₹800';
  }

  factory CustomerGig.fromDto(
    GigDto dto, {
    List<GigCandidate> candidates = const [],
    GigCandidate? selectedWorker,
  }) {
    final status = dto.status.toUpperCase();
    var stage = switch (status) {
      'DRAFT' || 'POSTED' || 'BROADCASTING' => GigStage.seeking,
      'ACCEPTANCE_OPEN' || 'RESPONDING' => GigStage.responding,
      'WORKER_SELECTED' => GigStage.selected,
      'SCHEDULED' => GigStage.scheduled,
      'IN_PROGRESS' => GigStage.active,
      'WORKER_COMPLETED' || 'COMPLETION_SUBMITTED' => GigStage.completionRequested,
      'CUSTOMER_CONFIRMED' || 'PAYMENT_PENDING' || 'PAYMENT_CUSTOMER_PAID' => GigStage.payment,
      'COMPLETED' || 'PAYMENT_WORKER_CONFIRMED' || 'GIG_COMPLETED' => GigStage.completed,
      'CANCELLED' => GigStage.cancelled,
      _ => GigStage.active,
    };

    // If workers have accepted the opportunity, show accepted candidates stage
    if ((stage == GigStage.seeking || stage == GigStage.responding) && candidates.isNotEmpty) {
      stage = GigStage.accepted;
    }

    final resolvedWorker = selectedWorker ??
        (dto.selectedWorkerId != null && candidates.isNotEmpty
            ? candidates.where((c) => c.workerId == dto.selectedWorkerId).firstOrNull
            : (dto.selectedWorkerId != null
                ? GigCandidate(
                    workerId: dto.selectedWorkerId,
                    name: 'Rajesh',
                    initials: 'R',
                    skill: 'Specialist Artisan',
                    wage: dto.workerWage != null ? '₹${dto.workerWage!.toInt()}' : '',
                    experience: 'Verified',
                    rating: '4.8',
                    jobs: 'Cooperative artisan',
                    summary: 'Verified cooperative artisan',
                    factors: ['Assigned artisan'],
                  )
                : null));

    final title = dto.tasks.isNotEmpty ? dto.tasks.first.taskName : dto.categoryName;
    final scheduledDate = dto.scheduledDate;
    final scheduledStartTime = dto.scheduledStartTime;
    final scheduledEndTime = dto.scheduledEndTime;
    final formattedWhen = formatDateTimeDisplay(scheduledDate, scheduledStartTime);

    return CustomerGig(
      id: dto.id,
      title: title,
      category: dto.categoryName,
      description: dto.description ?? '',
      when: formattedWhen,
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
      selectedWorker: resolvedWorker,
      price: dto.basePrice > 0 ? dto.basePrice : null,
      gigType: dto.gigType,
      rawStatus: status,
      workerWage: dto.workerWage,
      estimatedMinPrice: dto.estimatedMinPrice,
      estimatedMaxPrice: dto.estimatedMaxPrice,
      googleMapsLink: dto.googleMapsLink,
      latitude: dto.latitude,
      longitude: dto.longitude,
      scheduledDate: scheduledDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
    );
  }

  CustomerGig copyWith({
    String? id,
    GigStage? stage,
    GigCandidate? selectedWorker,
    List<GigCandidate>? candidates,
    double? price,
    String? gigType,
    String? rawStatus,
    double? workerWage,
    double? estimatedMinPrice,
    double? estimatedMaxPrice,
    String? googleMapsLink,
    double? latitude,
    double? longitude,
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
        price: price ?? this.price,
        gigType: gigType ?? this.gigType,
        rawStatus: rawStatus ?? this.rawStatus,
        workerWage: workerWage ?? this.workerWage,
        estimatedMinPrice: estimatedMinPrice ?? this.estimatedMinPrice,
        estimatedMaxPrice: estimatedMaxPrice ?? this.estimatedMaxPrice,
        googleMapsLink: googleMapsLink ?? this.googleMapsLink,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}
