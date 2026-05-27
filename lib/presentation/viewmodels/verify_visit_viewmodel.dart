// lib/presentation/viewmodels/verify_visit_viewmodel.dart

import 'package:explore_index/data/models/place.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/domain/usecases/verify_visit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Step enum
// ---------------------------------------------------------------------------

enum VerifyVisitStep { photo, rating, note, date }

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class VerifyVisitState {
  /// The current step in the 4-step flow.
  final VerifyVisitStep currentStep;

  /// Path to the photo selected/captured in step 1.
  final String? photoPath;

  /// Star rating (1–5) chosen in step 2.
  final int rating;

  /// Optional note written in step 3.
  final String? note;

  /// Visit date selected in step 4.
  final DateTime visitDate;

  /// True while the submit operation is in progress.
  final bool isSubmitting;

  /// Non-null when a submission or verification error has occurred.
  final String? errorMessage;

  /// Non-null when submission succeeded; contains the result.
  final VerifyVisitResult? result;

  const VerifyVisitState({
    this.currentStep = VerifyVisitStep.photo,
    this.photoPath,
    this.rating = 3,
    this.note,
    required this.visitDate,
    this.isSubmitting = false,
    this.errorMessage,
    this.result,
  });

  bool get canAdvanceFromPhoto => photoPath != null && photoPath!.isNotEmpty;
  bool get canAdvanceFromRating => rating >= 1 && rating <= 5;
  bool get isComplete => result != null && (result!.success);

  VerifyVisitState copyWith({
    VerifyVisitStep? currentStep,
    String? photoPath,
    int? rating,
    String? note,
    DateTime? visitDate,
    bool? isSubmitting,
    String? errorMessage,
    VerifyVisitResult? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return VerifyVisitState(
      currentStep: currentStep ?? this.currentStep,
      photoPath: photoPath ?? this.photoPath,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      visitDate: visitDate ?? this.visitDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class VerifyVisitViewModel extends Notifier<VerifyVisitState> {
  @override
  VerifyVisitState build() => VerifyVisitState(visitDate: DateTime.now());

  // ── Step navigation ────────────────────────────────────────────────────────

  void setPhoto(String path) {
    state = state.copyWith(
      photoPath: path,
      clearError: true,
    );
  }

  void setRating(int rating) {
    if (rating < 1 || rating > 5) return;
    state = state.copyWith(rating: rating);
  }

  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  void setVisitDate(DateTime date) {
    state = state.copyWith(visitDate: date);
  }

  void nextStep() {
    final nextIndex = state.currentStep.index + 1;
    if (nextIndex < VerifyVisitStep.values.length) {
      state = state.copyWith(
        currentStep: VerifyVisitStep.values[nextIndex],
        clearError: true,
      );
    }
  }

  void previousStep() {
    final prevIndex = state.currentStep.index - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(
        currentStep: VerifyVisitStep.values[prevIndex],
        clearError: true,
      );
    }
  }

  void goToStep(VerifyVisitStep step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  /// Submits the verified visit for [place] on behalf of [userId].
  ///
  /// Calls [VerifyVisitUseCase.execute] which runs photo verification and
  /// persists the visit if it passes.
  Future<void> submit({
    required Place place,
    required String userId,
  }) async {
    final path = state.photoPath;
    if (path == null || path.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select a photo first.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final useCase = VerifyVisitUseCase(
        verificationService: ref.read(photoVerificationServiceProvider),
        exifService: ref.read(exifServiceProvider),
        visitRepository: ref.read(visitRepositoryProvider),
      );

      final result = await useCase.execute(
        photoPath: path,
        place: place,
        rating: state.rating,
        note: state.note,
        visitDate: state.visitDate,
        userId: userId,
      );

      if (result.success) {
        state = state.copyWith(isSubmitting: false, result: result);
      } else {
        final msg = _failMessage(result.reason);
        state = state.copyWith(isSubmitting: false, errorMessage: msg);
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  void reset() {
    state = VerifyVisitState(visitDate: DateTime.now());
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String _failMessage(VerificationFailReason? reason) {
    return switch (reason) {
      VerificationFailReason.locationMismatch =>
        'The photo was not taken at this location. Please use a photo taken at the place.',
      VerificationFailReason.noExifData =>
        'The photo does not contain GPS data. Please enable location for your camera and retake the photo.',
      VerificationFailReason.fileError =>
        'Could not read the photo file. Please choose a different photo.',
      VerificationFailReason.deviceLocationUnavailable =>
        'Device location is unavailable. Please enable location services.',
      VerificationFailReason.deviceTooFar =>
        'You appear to be too far from this location. Please verify on-site.',
      null => 'Verification failed. Please try again.',
    };
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final verifyVisitViewModelProvider =
    NotifierProvider<VerifyVisitViewModel, VerifyVisitState>(
  VerifyVisitViewModel.new,
);
