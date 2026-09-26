import 'api/api_models.dart';

enum WorkerJobStatus {
  awaitingSelection,
  accepted,
  scheduled,
  active,
  evidenceSubmitted,
  paymentPending,
  completed,
  cancelled,
}

extension WorkerJobStatusLabel on WorkerJobStatus {
  String get label => switch (this) {
    WorkerJobStatus.awaitingSelection => 'Awaiting Selection',
    WorkerJobStatus.accepted => 'Accepted',
    WorkerJobStatus.scheduled => 'Scheduled',
    WorkerJobStatus.active => 'In Progress',
    WorkerJobStatus.evidenceSubmitted => 'Evidence Submitted',
    WorkerJobStatus.paymentPending => 'Payment Pending',
    WorkerJobStatus.completed => 'Completed',
    WorkerJobStatus.cancelled => 'Cancelled',
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
    this.status = 'PENDING',
    this.isEmergency = false,
    this.hasScheduleConflict = false,
    this.googleMapsLink,
    this.latitude,
    this.longitude,
    this.categoryId,
    this.gigType = 'STANDARD',
    this.scheduledDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.photos = const [],
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
  final String status;
  final bool isEmergency;
  final bool hasScheduleConflict;
  final String? googleMapsLink;
  final double? latitude;
  final double? longitude;
  final String? categoryId;
  final String gigType;
  final String? scheduledDate;
  final String? scheduledStartTime;
  final String? scheduledEndTime;
  final List<String> photos;

  static String formatDateTimeDisplay(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Today';
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
      if (timeStr.toUpperCase().contains('AM') || timeStr.toUpperCase().contains('PM')) {
        formattedTime = timeStr;
      } else {
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
      }
    } catch (_) {}

    return '$formattedDate at $formattedTime';
  }

  String get scheduleDisplay => formatDateTimeDisplay(scheduledDate, scheduledStartTime);

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
      when: formatDateTimeDisplay(gig.scheduledDate, gig.scheduledStartTime),
      distance: '2.5 km away',
      location: gig.address ?? 'Customer location',
      duration: gig.expectedDurationMinutes != null
          ? '${gig.expectedDurationMinutes} min'
          : '2 hours',
      materials: gig.materialProcurementMode == 'CUSTOMER_PURCHASES'
          ? 'Customer purchases'
          : 'Worker purchases',
      instructions: gig.instructions ?? '',
      status: dto.status,
      isEmergency: gig.isEmergency,
      hasScheduleConflict: false,
      googleMapsLink: gig.googleMapsLink,
      latitude: gig.latitude,
      longitude: gig.longitude,
      categoryId: gig.categoryId,
      gigType: gig.gigType,
      scheduledDate: gig.scheduledDate,
      scheduledStartTime: gig.scheduledStartTime,
      scheduledEndTime: gig.scheduledEndTime,
      photos: gig.photos,
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
    this.googleMapsLink,
    this.latitude,
    this.longitude,
    this.categoryId,
    this.gigType = 'STANDARD',
    this.customerPhone = '+91 98765 43211',
    this.photos = const [],
    this.scheduledDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
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
  final String customerPhone;
  final String materials;
  final String instructions;
  final bool isEmergency;
  final bool isRookieParticipation;
  final String? additionalWorkerName;
  final String? googleMapsLink;
  final double? latitude;
  final double? longitude;
  final String? categoryId;
  final String gigType;
  final List<String> photos;
  final String? scheduledDate;
  final String? scheduledStartTime;
  final String? scheduledEndTime;

  String get scheduleDisplay =>
      WorkerOpportunity.formatDateTimeDisplay(scheduledDate, scheduledStartTime);

  bool get workerBringsMaterials =>
      materials.toLowerCase().contains('worker') ||
      materials.toLowerCase().contains('procure');

  WorkerJob copyWith({
    String? id,
    String? gigId,
    String? customerId,
    String? title,
    String? category,
    String? description,
    String? wage,
    String? when,
    String? location,
    String? duration,
    WorkerJobStatus? status,
    String? customerName,
    String? customerPhone,
    String? materials,
    String? instructions,
    bool? isEmergency,
    bool? isRookieParticipation,
    String? additionalWorkerName,
    String? googleMapsLink,
    double? latitude,
    double? longitude,
    String? categoryId,
    String? gigType,
    List<String>? photos,
    String? scheduledDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  }) {
    return WorkerJob(
      id: id ?? this.id,
      gigId: gigId ?? this.gigId,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      wage: wage ?? this.wage,
      when: when ?? this.when,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      materials: materials ?? this.materials,
      instructions: instructions ?? this.instructions,
      isEmergency: isEmergency ?? this.isEmergency,
      isRookieParticipation: isRookieParticipation ?? this.isRookieParticipation,
      additionalWorkerName: additionalWorkerName ?? this.additionalWorkerName,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categoryId: categoryId ?? this.categoryId,
      gigType: gigType ?? this.gigType,
      photos: photos ?? this.photos,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
    );
  }

  factory WorkerJob.fromDto(WorkerGigListItemDto dto) {
    final status = switch (dto.status.toUpperCase()) {
      'WORKER_SELECTED' || 'SCHEDULED' => WorkerJobStatus.accepted,
      'IN_PROGRESS' => WorkerJobStatus.active,
      'COMPLETION_SUBMITTED' || 'WORKER_COMPLETED' => WorkerJobStatus.evidenceSubmitted,
      'CUSTOMER_CONFIRMED' ||
      'PAYMENT_PENDING' ||
      'PAYMENT_CUSTOMER_PAID' =>
        WorkerJobStatus.paymentPending,
      'PAYMENT_WORKER_CONFIRMED' || 'COMPLETED' => WorkerJobStatus.completed,
      'CANCELLED' => WorkerJobStatus.cancelled,
      _ => WorkerJobStatus.accepted,
    };

    final formattedWhen = WorkerOpportunity.formatDateTimeDisplay(
      dto.scheduledDate,
      dto.scheduledStartTime,
    );

    return WorkerJob(
      id: dto.id,
      gigId: dto.id,
      customerId: dto.customerId,
      title: dto.categoryName,
      category: dto.categoryName,
      description: 'Cooperative service gig',
      wage: '₹${dto.exactWage.toInt()}',
      when: formattedWhen,
      location: dto.address ?? 'Assigned location',
      duration: dto.expectedDurationMinutes != null
          ? '${dto.expectedDurationMinutes} min'
          : '2 hours',
      status: status,
      customerName: (dto.customerName != null && dto.customerName!.isNotEmpty)
          ? dto.customerName!
          : 'Customer',
      materials: dto.materialProcurementMode == 'WORKER_PURCHASES'
          ? 'Worker purchases'
          : 'Customer purchases',
      instructions: '',
      isEmergency: dto.isEmergency,
      googleMapsLink: dto.googleMapsLink,
      latitude: dto.latitude,
      longitude: dto.longitude,
      categoryId: dto.categoryId,
      gigType: dto.gigType,
      scheduledDate: dto.scheduledDate,
      scheduledStartTime: dto.scheduledStartTime,
    );
  }

  factory WorkerJob.fromOpportunity(
    WorkerOpportunity opp, {
    WorkerJobStatus status = WorkerJobStatus.awaitingSelection,
  }) {
    return WorkerJob(
      id: opp.gigId ?? opp.id,
      gigId: opp.gigId ?? opp.id,
      title: opp.title,
      category: opp.category,
      description: opp.description,
      wage: opp.wage,
      when: opp.when,
      location: opp.location,
      duration: opp.duration,
      status: status,
      customerName: 'Customer',
      materials: opp.materials,
      instructions: opp.instructions,
      isEmergency: opp.isEmergency,
      googleMapsLink: opp.googleMapsLink,
      latitude: opp.latitude,
      longitude: opp.longitude,
      categoryId: opp.categoryId,
      gigType: opp.gigType,
      photos: opp.photos,
      scheduledDate: opp.scheduledDate,
      scheduledStartTime: opp.scheduledStartTime,
      scheduledEndTime: opp.scheduledEndTime,
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
// Default Template Availability
// ----------------------------------------------------------------------

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
