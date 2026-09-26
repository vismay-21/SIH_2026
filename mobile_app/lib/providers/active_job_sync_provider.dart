import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api/api_models.dart';
import '../repositories/gig_repository.dart';

/// Auto-disposed stream provider that polls a specific gig's live status every 3.5 seconds.
/// Automatically cancels the timer and stream as soon as the user leaves the screen.
final activeGigSyncProvider =
    StreamProvider.autoDispose.family<GigDto?, String>((ref, gigId) {
  if (gigId.startsWith('job-') || gigId.startsWith('opp-')) {
    return const Stream.empty();
  }

  final gigRepo = GigRepository();
  String? lastStatus;
  final controller = StreamController<GigDto?>();

  // Immediate initial fetch
  gigRepo.getGig(gigId).then((gig) {
    if (!controller.isClosed) {
      lastStatus = gig.status;
      controller.add(gig);
    }
  }).catchError((_) {});

  // Periodic polling every 6s
  final timer = Timer.periodic(const Duration(seconds: 6), (_) async {
    try {
      final gig = await gigRepo.getGig(gigId);
      if (!controller.isClosed && gig.status != lastStatus) {
        lastStatus = gig.status;
        controller.add(gig);
      }
    } catch (_) {}
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
