// Strongly typed DTOs strictly aligned with backend FastAPI / OpenAPI schemas.

// ============================================================================
// AUTH & USERS
// ============================================================================

class UserDto {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? fullName;
  final String role; // 'customer' or 'worker'
  final bool isActive;
  final DateTime? createdAt;

  const UserDto({
    required this.id,
    this.email,
    this.phoneNumber,
    this.fullName,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      fullName: json['full_name'] as String?,
      role: (json['role'] as String?)?.toLowerCase() ?? 'customer',
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone_number': phoneNumber,
    'full_name': fullName,
    'role': role,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
  };
}

class DevLoginRequest {
  final String email;
  final String password;
  final String? role;

  const DevLoginRequest({
    required this.email,
    required this.password,
    this.role,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (role != null) 'role': role!.toUpperCase(),
  };
}

class DevLoginResponse {
  final String token;
  final String tokenType;
  final UserDto user;

  const DevLoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory DevLoginResponse.fromJson(Map<String, dynamic> json) {
    return DevLoginResponse(
      token: (json['token'] as String?) ?? (json['access_token'] as String),
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class DemoUserItem {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  const DemoUserItem({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory DemoUserItem.fromJson(Map<String, dynamic> json) {
    return DemoUserItem(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

// ============================================================================
// CATALOGUE & PRICING
// ============================================================================

class ServiceCategoryDto {
  final String id;
  final String name;
  final String? description;
  final double baseRatePerMinute;
  final int minimumBillableMinutes;
  final bool isActive;

  const ServiceCategoryDto({
    required this.id,
    required this.name,
    this.description,
    required this.baseRatePerMinute,
    required this.minimumBillableMinutes,
    this.isActive = true,
  });

  factory ServiceCategoryDto.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      baseRatePerMinute: (json['base_rate_per_minute'] as num?)?.toDouble() ?? 0.0,
      minimumBillableMinutes: (json['minimum_billable_minutes'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class ServiceTaskDto {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final int standardDurationMinutes;
  final double basePrice;
  final double complexityScore;
  final String complexityBucket;
  final bool isActive;

  const ServiceTaskDto({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.standardDurationMinutes,
    required this.basePrice,
    required this.complexityScore,
    required this.complexityBucket,
    this.isActive = true,
  });

  factory ServiceTaskDto.fromJson(Map<String, dynamic> json) {
    return ServiceTaskDto(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      standardDurationMinutes: (json['standard_duration_minutes'] as num?)?.toInt() ?? 0,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      complexityScore: (json['complexity_score'] as num?)?.toDouble() ?? 1.0,
      complexityBucket: (json['complexity_bucket'] as String?) ?? 'LOW',
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class PricePreviewTaskItemDto {
  final String id;
  final String name;
  final int standardDurationMinutes;
  final double basePrice;
  final double complexityScore;

  const PricePreviewTaskItemDto({
    required this.id,
    required this.name,
    required this.standardDurationMinutes,
    required this.basePrice,
    required this.complexityScore,
  });

  factory PricePreviewTaskItemDto.fromJson(Map<String, dynamic> json) {
    return PricePreviewTaskItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      standardDurationMinutes: (json['standard_duration_minutes'] as num?)?.toInt() ?? 0,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      complexityScore: (json['complexity_score'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class EstimatedWageRangeDto {
  final double minWage;
  final double rookieWage;
  final double maxWage;

  const EstimatedWageRangeDto({
    required this.minWage,
    required this.rookieWage,
    required this.maxWage,
  });

  factory EstimatedWageRangeDto.fromJson(Map<String, dynamic> json) {
    return EstimatedWageRangeDto(
      minWage: (json['min_wage'] as num?)?.toDouble() ?? 0.0,
      rookieWage: (json['rookie_wage'] as num?)?.toDouble() ?? 0.0,
      maxWage: (json['max_wage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PricePreviewDto {
  final String categoryId;
  final String categoryName;
  final double baseRatePerMinute;
  final int minimumBillableMinutes;
  final int totalStandardDurationMinutes;
  final int billableDurationMinutes;
  final double basePrice;
  final List<PricePreviewTaskItemDto> tasks;
  final EstimatedWageRangeDto estimatedWageRange;

  const PricePreviewDto({
    required this.categoryId,
    required this.categoryName,
    required this.baseRatePerMinute,
    required this.minimumBillableMinutes,
    required this.totalStandardDurationMinutes,
    required this.billableDurationMinutes,
    required this.basePrice,
    required this.tasks,
    required this.estimatedWageRange,
  });

  factory PricePreviewDto.fromJson(Map<String, dynamic> json) {
    return PricePreviewDto(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      baseRatePerMinute: (json['base_rate_per_minute'] as num?)?.toDouble() ?? 0.0,
      minimumBillableMinutes: (json['minimum_billable_minutes'] as num?)?.toInt() ?? 0,
      totalStandardDurationMinutes: (json['total_standard_duration_minutes'] as num?)?.toInt() ?? 0,
      billableDurationMinutes: (json['billable_duration_minutes'] as num?)?.toInt() ?? 0,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((item) => PricePreviewTaskItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      estimatedWageRange: EstimatedWageRangeDto.fromJson(
        json['estimated_wage_range'] as Map<String, dynamic>,
      ),
    );
  }
}

// ============================================================================
// GIGS & WORKFLOW
// ============================================================================

class GigTaskItemDto {
  final String id;
  final String taskId;
  final String taskName;
  final int standardDurationMinutesSnapshot;
  final double basePriceSnapshot;

  const GigTaskItemDto({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.standardDurationMinutesSnapshot,
    required this.basePriceSnapshot,
  });

  factory GigTaskItemDto.fromJson(Map<String, dynamic> json) {
    return GigTaskItemDto(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskName: json['task_name'] as String,
      standardDurationMinutesSnapshot:
          (json['standard_duration_minutes_snapshot'] as num?)?.toInt() ?? 0,
      basePriceSnapshot: (json['base_price_snapshot'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GigCreateRequestDto {
  final String categoryId;
  final List<String> taskIds;
  final String gigType; // 'NORMAL' or 'EMERGENCY'
  final String? description;
  final String? instructions;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? googleMapsLink;
  final String? scheduledDate; // 'YYYY-MM-DD'
  final String? scheduledStartTime; // 'HH:MM:SS'
  final String? scheduledEndTime; // 'HH:MM:SS'
  final int? expectedDurationMinutes;
  final bool isEmergency;
  final String materialProcurementMode; // 'CUSTOMER_PURCHASES' or 'WORKER_PURCHASES'

  const GigCreateRequestDto({
    required this.categoryId,
    required this.taskIds,
    this.gigType = 'NORMAL',
    this.description,
    this.instructions,
    this.address,
    this.latitude,
    this.longitude,
    this.googleMapsLink,
    this.scheduledDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.expectedDurationMinutes,
    this.isEmergency = false,
    this.materialProcurementMode = 'CUSTOMER_PURCHASES',
  });

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'task_ids': taskIds,
    'gig_type': gigType,
    if (description != null) 'description': description,
    if (instructions != null) 'instructions': instructions,
    if (address != null) 'address': address,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (googleMapsLink != null) 'google_maps_link': googleMapsLink,
    if (scheduledDate != null) 'scheduled_date': scheduledDate,
    if (scheduledStartTime != null) 'scheduled_start_time': scheduledStartTime,
    if (scheduledEndTime != null) 'scheduled_end_time': scheduledEndTime,
    if (expectedDurationMinutes != null)
      'expected_duration_minutes': expectedDurationMinutes,
    'is_emergency': isEmergency,
    'material_procurement_mode': materialProcurementMode,
  };
}

class GigDto {
  final String id;
  final String customerId;
  final String cooperativeId;
  final String categoryId;
  final String categoryName;
  final String gigType;
  final String status;
  final String? description;
  final String? instructions;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? googleMapsLink;
  final String? scheduledDate;
  final String? scheduledStartTime;
  final String? scheduledEndTime;
  final int? expectedDurationMinutes;
  final bool isEmergency;
  final String? acceptanceDeadline;
  final String materialProcurementMode;
  final double basePrice;
  final int? minimumBillableMinutesSnapshot;
  final double? baseRatePerMinuteSnapshot;
  final String? selectedWorkerId;
  final List<GigTaskItemDto> tasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GigDto({
    required this.id,
    required this.customerId,
    required this.cooperativeId,
    required this.categoryId,
    required this.categoryName,
    required this.gigType,
    required this.status,
    this.description,
    this.instructions,
    this.address,
    this.latitude,
    this.longitude,
    this.googleMapsLink,
    this.scheduledDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.expectedDurationMinutes,
    required this.isEmergency,
    this.acceptanceDeadline,
    required this.materialProcurementMode,
    required this.basePrice,
    this.minimumBillableMinutesSnapshot,
    this.baseRatePerMinuteSnapshot,
    this.selectedWorkerId,
    required this.tasks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GigDto.fromJson(Map<String, dynamic> json) {
    return GigDto(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      gigType: json['gig_type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googleMapsLink: json['google_maps_link'] as String?,
      scheduledDate: json['scheduled_date'] as String?,
      scheduledStartTime: json['scheduled_start_time'] as String?,
      scheduledEndTime: json['scheduled_end_time'] as String?,
      expectedDurationMinutes:
          (json['expected_duration_minutes'] as num?)?.toInt(),
      isEmergency: (json['is_emergency'] as bool?) ?? false,
      acceptanceDeadline: json['acceptance_deadline'] as String?,
      materialProcurementMode:
          (json['material_procurement_mode'] as String?) ?? 'CUSTOMER_PURCHASES',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      minimumBillableMinutesSnapshot:
          (json['minimum_billable_minutes_snapshot'] as num?)?.toInt(),
      baseRatePerMinuteSnapshot:
          (json['base_rate_per_minute_snapshot'] as num?)?.toDouble(),
      selectedWorkerId: json['selected_worker_id'] as String?,
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((item) => GigTaskItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ============================================================================
// CANDIDATES & WORKER SELECTION
// ============================================================================

class GigCandidateDto {
  final String workerId;
  final String name;
  final double exactWage;
  final int completedJobsCount;
  final double ratingAverage;
  final int ratingCount;
  final double finalScore;
  final String? profilePhotoUrl;

  const GigCandidateDto({
    required this.workerId,
    required this.name,
    required this.exactWage,
    required this.completedJobsCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.finalScore,
    this.profilePhotoUrl,
  });

  factory GigCandidateDto.fromJson(Map<String, dynamic> json) {
    return GigCandidateDto(
      workerId: json['worker_id'] as String,
      name: json['name'] as String,
      exactWage: (json['exact_wage'] as num?)?.toDouble() ?? 0.0,
      completedJobsCount: (json['completed_jobs_count'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0.0,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}

class SelectWorkerRequestDto {
  final String workerId;

  const SelectWorkerRequestDto({required this.workerId});

  Map<String, dynamic> toJson() => {'worker_id': workerId};
}

class SelectWorkerResponseDto {
  final String gigId;
  final String selectedWorkerId;
  final String status;
  final String message;

  const SelectWorkerResponseDto({
    required this.gigId,
    required this.selectedWorkerId,
    required this.status,
    required this.message,
  });

  factory SelectWorkerResponseDto.fromJson(Map<String, dynamic> json) {
    return SelectWorkerResponseDto(
      gigId: json['gig_id'] as String,
      selectedWorkerId: json['selected_worker_id'] as String,
      status: json['status'] as String,
      message: (json['message'] as String?) ?? 'Worker selected successfully.',
    );
  }
}

// ============================================================================
// WORKER OPPORTUNITIES & GIG LIST
// ============================================================================

class OpportunityGigDto {
  final String id;
  final String categoryId;
  final String categoryName;
  final String gigType;
  final String? description;
  final String? instructions;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? scheduledDate;
  final String? scheduledStartTime;
  final String? scheduledEndTime;
  final int? expectedDurationMinutes;
  final bool isEmergency;
  final String materialProcurementMode;
  final String? acceptanceDeadline;
  final List<GigTaskItemDto> tasks;

  const OpportunityGigDto({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.gigType,
    this.description,
    this.instructions,
    this.address,
    this.latitude,
    this.longitude,
    this.scheduledDate,
    this.scheduledStartTime,
    this.scheduledEndTime,
    this.expectedDurationMinutes,
    this.isEmergency = false,
    required this.materialProcurementMode,
    this.acceptanceDeadline,
    required this.tasks,
  });

  factory OpportunityGigDto.fromJson(Map<String, dynamic> json) {
    return OpportunityGigDto(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      gigType: json['gig_type'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      scheduledDate: json['scheduled_date'] as String?,
      scheduledStartTime: json['scheduled_start_time'] as String?,
      scheduledEndTime: json['scheduled_end_time'] as String?,
      expectedDurationMinutes:
          (json['expected_duration_minutes'] as num?)?.toInt(),
      isEmergency: (json['is_emergency'] as bool?) ?? false,
      materialProcurementMode:
          (json['material_procurement_mode'] as String?) ?? 'CUSTOMER_PURCHASES',
      acceptanceDeadline: json['acceptance_deadline'] as String?,
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((item) => GigTaskItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OpportunityDto {
  final String id;
  final String gigId;
  final String workerId;
  final String status;
  final double basePrice;
  final double basePriceSnapshot;
  final double finalScoreSnapshot;
  final double premiumPercentage;
  final double exactWage;
  final DateTime offeredAt;
  final DateTime? respondedAt;
  final OpportunityGigDto gig;

  const OpportunityDto({
    required this.id,
    required this.gigId,
    required this.workerId,
    required this.status,
    required this.basePrice,
    required this.basePriceSnapshot,
    required this.finalScoreSnapshot,
    required this.premiumPercentage,
    required this.exactWage,
    required this.offeredAt,
    this.respondedAt,
    required this.gig,
  });

  factory OpportunityDto.fromJson(Map<String, dynamic> json) {
    return OpportunityDto(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      workerId: json['worker_id'] as String,
      status: json['status'] as String,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      basePriceSnapshot: (json['base_price_snapshot'] as num?)?.toDouble() ?? 0.0,
      finalScoreSnapshot: (json['final_score_snapshot'] as num?)?.toDouble() ?? 0.0,
      premiumPercentage: (json['premium_percentage'] as num?)?.toDouble() ?? 0.0,
      exactWage: (json['exact_wage'] as num?)?.toDouble() ?? 0.0,
      offeredAt: DateTime.tryParse(json['offered_at'] as String? ?? '') ??
          DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
      gig: OpportunityGigDto.fromJson(json['gig'] as Map<String, dynamic>),
    );
  }
}

class WorkerGigListItemDto {
  final String id;
  final String customerId;
  final String categoryId;
  final String categoryName;
  final String gigType;
  final String status;
  final String? address;
  final String? customerName;
  final String? scheduledDate;
  final String? scheduledStartTime;
  final int? expectedDurationMinutes;
  final bool isEmergency;
  final double exactWage;
  final bool canStart;
  final bool canComplete;

  const WorkerGigListItemDto({
    required this.id,
    required this.customerId,
    required this.categoryId,
    required this.categoryName,
    required this.gigType,
    required this.status,
    this.address,
    this.customerName,
    this.scheduledDate,
    this.scheduledStartTime,
    this.expectedDurationMinutes,
    this.isEmergency = false,
    required this.exactWage,
    this.canStart = false,
    this.canComplete = false,
  });

  factory WorkerGigListItemDto.fromJson(Map<String, dynamic> json) {
    return WorkerGigListItemDto(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      gigType: json['gig_type'] as String? ?? 'STANDARD',
      status: json['status'] as String? ?? 'POSTED',
      address: (json['address_line'] ?? json['address']) as String?,
      customerName: json['customer_name'] as String?,
      scheduledDate: json['scheduled_date']?.toString(),
      scheduledStartTime: json['scheduled_start_time']?.toString(),
      expectedDurationMinutes:
          (json['expected_duration_minutes'] as num?)?.toInt(),
      isEmergency: (json['emergency'] ?? json['is_emergency']) as bool? ?? false,
      exactWage: (json['exact_wage'] as num?)?.toDouble() ?? 0.0,
      canStart: (json['can_start'] as bool?) ?? false,
      canComplete: (json['can_complete'] as bool?) ?? false,
    );
  }
}

// ============================================================================
// COMPLETION & EVIDENCE
// ============================================================================

class CompletionEvidenceCreateDto {
  final String fileUrl;
  final String fileType;

  const CompletionEvidenceCreateDto({
    required this.fileUrl,
    this.fileType = 'image/jpeg',
  });

  Map<String, dynamic> toJson() => {
    'file_url': fileUrl,
    'file_type': fileType,
  };
}

class CompletionEvidenceResponseDto {
  final String id;
  final String submissionId;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;

  const CompletionEvidenceResponseDto({
    required this.id,
    required this.submissionId,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
  });

  factory CompletionEvidenceResponseDto.fromJson(Map<String, dynamic> json) {
    return CompletionEvidenceResponseDto(
      id: json['id'] as String,
      submissionId: json['submission_id'] as String,
      fileUrl: json['file_url'] as String,
      fileType: (json['file_type'] as String?) ?? 'image/jpeg',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class CompletionSubmissionRequestDto {
  final String? description;
  final List<CompletionEvidenceCreateDto> evidenceItems;

  const CompletionSubmissionRequestDto({
    this.description,
    required this.evidenceItems,
  });

  Map<String, dynamic> toJson() => {
    if (description != null) 'description': description,
    'evidence_items': evidenceItems.map((e) => e.toJson()).toList(),
  };
}

class CompletionSubmissionResponseDto {
  final String id;
  final String gigId;
  final String workerId;
  final String? description;
  final DateTime submittedAt;
  final List<CompletionEvidenceResponseDto> evidenceFiles;

  const CompletionSubmissionResponseDto({
    required this.id,
    required this.gigId,
    required this.workerId,
    this.description,
    required this.submittedAt,
    required this.evidenceFiles,
  });

  factory CompletionSubmissionResponseDto.fromJson(Map<String, dynamic> json) {
    return CompletionSubmissionResponseDto(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      workerId: json['worker_id'] as String,
      description: json['description'] as String?,
      submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? '') ??
          DateTime.now(),
      evidenceFiles: (json['evidence_files'] as List<dynamic>? ?? [])
          .map((e) =>
              CompletionEvidenceResponseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CompletionConfirmationRequestDto {
  final bool confirmed;
  final String? responseNote;

  const CompletionConfirmationRequestDto({
    required this.confirmed,
    this.responseNote,
  });

  Map<String, dynamic> toJson() => {
    'confirmed': confirmed,
    if (responseNote != null) 'response_note': responseNote,
  };
}

class CompletionConfirmationResponseDto {
  final String id;
  final String gigId;
  final String customerId;
  final bool confirmed;
  final String? responseNote;
  final DateTime createdAt;

  const CompletionConfirmationResponseDto({
    required this.id,
    required this.gigId,
    required this.customerId,
    required this.confirmed,
    this.responseNote,
    required this.createdAt,
  });

  factory CompletionConfirmationResponseDto.fromJson(Map<String, dynamic> json) {
    return CompletionConfirmationResponseDto(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      customerId: json['customer_id'] as String,
      confirmed: json['confirmed'] as bool,
      responseNote: json['response_note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class StartWorkResponseDto {
  final String gigId;
  final String status;
  final String message;

  const StartWorkResponseDto({
    required this.gigId,
    required this.status,
    required this.message,
  });

  factory StartWorkResponseDto.fromJson(Map<String, dynamic> json) {
    return StartWorkResponseDto(
      gigId: json['gig_id'] as String,
      status: json['status'] as String,
      message: (json['message'] as String?) ?? 'Work started successfully.',
    );
  }
}

class GigCompletionDetailDto {
  final String gigId;
  final String status;
  final CompletionSubmissionResponseDto? submission;
  final CompletionConfirmationResponseDto? confirmation;

  const GigCompletionDetailDto({
    required this.gigId,
    required this.status,
    this.submission,
    this.confirmation,
  });

  factory GigCompletionDetailDto.fromJson(Map<String, dynamic> json) {
    return GigCompletionDetailDto(
      gigId: json['gig_id'] as String,
      status: json['status'] as String,
      submission: json['submission'] != null
          ? CompletionSubmissionResponseDto.fromJson(
              json['submission'] as Map<String, dynamic>)
          : null,
      confirmation: json['confirmation'] != null
          ? CompletionConfirmationResponseDto.fromJson(
              json['confirmation'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ============================================================================
// PAYMENTS
// ============================================================================

class PaymentCreateRequestDto {
  final String paymentMethod; // 'CASH' or 'UPI'

  const PaymentCreateRequestDto({required this.paymentMethod});

  Map<String, dynamic> toJson() => {'payment_method': paymentMethod};
}

class PaymentReceiptConfirmRequestDto {
  final bool confirmed;

  const PaymentReceiptConfirmRequestDto({this.confirmed = true});

  Map<String, dynamic> toJson() => {'confirmed': confirmed};
}

class PaymentDto {
  final String id;
  final String gigId;
  final String customerId;
  final String workerId;
  final double amount;
  final String? paymentMethod;
  final String paymentType;
  final String status;
  final String? upiDeeplink;
  final DateTime? paidAt;
  final DateTime? workerConfirmedAt;
  final bool canPay;
  final bool canConfirm;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentDto({
    required this.id,
    required this.gigId,
    required this.customerId,
    required this.workerId,
    required this.amount,
    this.paymentMethod,
    required this.paymentType,
    required this.status,
    this.upiDeeplink,
    this.paidAt,
    this.workerConfirmedAt,
    this.canPay = false,
    this.canConfirm = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      customerId: json['customer_id'] as String,
      workerId: json['worker_id'] as String,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      paymentMethod: json['payment_method'] as String?,
      paymentType: (json['payment_type'] as String?) ?? 'LABOUR',
      status: json['status'] as String,
      upiDeeplink: json['upi_deeplink'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      workerConfirmedAt: json['worker_confirmed_at'] != null
          ? DateTime.tryParse(json['worker_confirmed_at'] as String)
          : null,
      canPay: (json['can_pay'] as bool?) ?? false,
      canConfirm: (json['can_confirm'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

// ============================================================================
// REVIEWS & METRICS
// ============================================================================

class ReviewQuestionDto {
  final String id;
  final String targetRole; // 'CUSTOMER' or 'WORKER'
  final String questionText;
  final int displayOrder;
  final bool isActive;

  const ReviewQuestionDto({
    required this.id,
    required this.targetRole,
    required this.questionText,
    required this.displayOrder,
    this.isActive = true,
  });

  factory ReviewQuestionDto.fromJson(Map<String, dynamic> json) {
    return ReviewQuestionDto(
      id: json['id'] as String,
      targetRole: json['target_role'] as String,
      questionText: json['question_text'] as String,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}

class ReviewAnswerItemDto {
  final String questionId;
  final int answerValue; // 1-5

  const ReviewAnswerItemDto({
    required this.questionId,
    required this.answerValue,
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer_value': answerValue,
  };
}

class ReviewCreateRequestDto {
  final String revieweeId;
  final double? overallRating;
  final List<ReviewAnswerItemDto> answers;

  const ReviewCreateRequestDto({
    required this.revieweeId,
    this.overallRating,
    required this.answers,
  });

  Map<String, dynamic> toJson() => {
    'reviewee_id': revieweeId,
    if (overallRating != null) 'overall_rating': overallRating,
    'answers': answers.map((a) => a.toJson()).toList(),
  };
}

class ReviewAnswerResponseDto {
  final String id;
  final String questionId;
  final String questionText;
  final int answerValue;

  const ReviewAnswerResponseDto({
    required this.id,
    required this.questionId,
    required this.questionText,
    required this.answerValue,
  });

  factory ReviewAnswerResponseDto.fromJson(Map<String, dynamic> json) {
    return ReviewAnswerResponseDto(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      questionText: json['question_text'] as String,
      answerValue: (json['answer_value'] as num?)?.toInt() ?? 1,
    );
  }
}

class ReviewDto {
  final String id;
  final String gigId;
  final String reviewerId;
  final String revieweeId;
  final String reviewerRole;
  final double overallRating;
  final List<ReviewAnswerResponseDto> answers;
  final DateTime createdAt;

  const ReviewDto({
    required this.id,
    required this.gigId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewerRole,
    required this.overallRating,
    required this.answers,
    required this.createdAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      reviewerRole: json['reviewer_role'] as String,
      overallRating: (json['overall_rating'] as num?)?.toDouble() ?? 0.0,
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((a) => ReviewAnswerResponseDto.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class WorkerPublicMetricsDto {
  final String workerId;
  final int completedJobsCount;
  final double ratingAverage;
  final int ratingCount;
  final double finalScore;

  const WorkerPublicMetricsDto({
    required this.workerId,
    required this.completedJobsCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.finalScore,
  });

  factory WorkerPublicMetricsDto.fromJson(Map<String, dynamic> json) {
    return WorkerPublicMetricsDto(
      workerId: json['worker_id'] as String,
      completedJobsCount: (json['completed_jobs_count'] as num?)?.toInt() ?? 0,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ============================================================================
// CHAT & NOTIFICATIONS
// ============================================================================

class MessageCreateRequestDto {
  final String messageText;

  const MessageCreateRequestDto({required this.messageText});

  Map<String, dynamic> toJson() => {'message_text': messageText};
}

class MessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderRole;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderRole,
    required this.messageText,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      senderRole: json['sender_role'] as String?,
      messageText: json['message_text'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ConversationDto {
  final String id;
  final String gigId;
  final String customerId;
  final String workerId;
  final String? customerName;
  final String? workerName;
  final int unreadCount;
  final MessageDto? lastMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConversationDto({
    required this.id,
    required this.gigId,
    required this.customerId,
    required this.workerId,
    this.customerName,
    this.workerName,
    this.unreadCount = 0,
    this.lastMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: json['id'] as String,
      gigId: json['gig_id'] as String,
      customerId: json['customer_id'] as String,
      workerId: json['worker_id'] as String,
      customerName: json['customer_name'] as String?,
      workerName: json['worker_name'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessage: json['last_message'] != null
          ? MessageDto.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}

class ConversationMessagesDto {
  final String conversationId;
  final List<MessageDto> messages;
  final int total;
  final bool hasMore;

  const ConversationMessagesDto({
    required this.conversationId,
    required this.messages,
    required this.total,
    this.hasMore = false,
  });

  factory ConversationMessagesDto.fromJson(Map<String, dynamic> json) {
    return ConversationMessagesDto(
      conversationId: json['conversation_id'] as String,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => MessageDto.fromJson(m as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: (json['has_more'] as bool?) ?? false,
    );
  }
}

class NotificationDto {
  final String id;
  final String recipientId;
  final String? gigId;
  final String type;
  final String title;
  final String body;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationDto({
    required this.id,
    required this.recipientId,
    this.gigId,
    required this.type,
    required this.title,
    required this.body,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      gigId: json['gig_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      actionUrl: json['action_url'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
    );
  }
}

class NotificationListDto {
  final List<NotificationDto> items;
  final int total;
  final int unreadCount;
  final int limit;
  final int offset;

  const NotificationListDto({
    required this.items,
    required this.total,
    required this.unreadCount,
    required this.limit,
    required this.offset,
  });

  factory NotificationListDto.fromJson(Map<String, dynamic> json) {
    return NotificationListDto(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => NotificationDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}

class NotificationReadAllDto {
  final int markedReadCount;

  const NotificationReadAllDto({required this.markedReadCount});

  factory NotificationReadAllDto.fromJson(Map<String, dynamic> json) {
    return NotificationReadAllDto(
      markedReadCount: (json['marked_read_count'] as num?)?.toInt() ?? 0,
    );
  }
}
