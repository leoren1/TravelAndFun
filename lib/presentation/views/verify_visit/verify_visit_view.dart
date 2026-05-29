// lib/presentation/views/verify_visit/verify_visit_view.dart

import 'dart:io';

import 'package:explore_index/core/constants/app_colors.dart';
import 'package:explore_index/core/constants/app_spacing.dart';
import 'package:explore_index/core/constants/app_text_styles.dart';
import 'package:explore_index/data/providers.dart';
import 'package:explore_index/presentation/viewmodels/verify_visit_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:explore_index/core/utils/theme_extensions.dart';

class VerifyVisitView extends ConsumerStatefulWidget {
  final String placeId;
  const VerifyVisitView({super.key, required this.placeId});

  @override
  ConsumerState<VerifyVisitView> createState() => _VerifyVisitViewState();
}

class _VerifyVisitViewState extends ConsumerState<VerifyVisitView> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile != null) {
      ref.read(verifyVisitViewModelProvider.notifier).setPhoto(xFile.path);
    }
  }

  Future<void> _pickDate() async {
    final vm = ref.read(verifyVisitViewModelProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.visitDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: context.appColors.surfaceElevated,
          ),
          dialogBackgroundColor: context.appColors.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(verifyVisitViewModelProvider.notifier).setVisitDate(picked);
    }
  }

  Future<void> _submit() async {
    final placeRepo = ref.read(placeRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final place = await placeRepo.getPlaceById(widget.placeId);
    if (!mounted) return;
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place not found.')),
      );
      return;
    }

    final profile = await userRepo.getUserProfile();
    final notifier = ref.read(verifyVisitViewModelProvider.notifier);

    notifier.setNote(_noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim());

    await notifier.submit(place: place, userId: profile.id);

    final vmState = ref.read(verifyVisitViewModelProvider);
    if (!mounted) return;

    if (vmState.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Visit verified! Discovery updated.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(verifyVisitViewModelProvider);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verify Visit', style: AppTextStyles.titleSmall),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step indicators ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: _StepIndicator(currentStep: vmState.currentStep),
            ),

            // ── Step content ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: _stepContent(vmState),
              ),
            ),

            // ── Error message ─────────────────────────────────────────────
            if (vmState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: Text(
                    vmState.errorMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),

            // ── Footer info ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Your visit will increase the city discovery score.',
                style: AppTextStyles.captionMuted,
                textAlign: TextAlign.center,
              ),
            ),

            // ── Bottom buttons ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: _BottomActions(
                vmState: vmState,
                onBack: () =>
                    ref.read(verifyVisitViewModelProvider.notifier).previousStep(),
                onNext: () =>
                    ref.read(verifyVisitViewModelProvider.notifier).nextStep(),
                onSubmit: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent(VerifyVisitState state) {
    return switch (state.currentStep) {
      VerifyVisitStep.photo => _PhotoStep(
          photoPath: state.photoPath,
          onPickGallery: () => _pickImage(ImageSource.gallery),
          onPickCamera: () => _pickImage(ImageSource.camera),
        ),
      VerifyVisitStep.rating => _RatingStep(
          rating: state.rating,
          onRatingChanged: (r) =>
              ref.read(verifyVisitViewModelProvider.notifier).setRating(r),
        ),
      VerifyVisitStep.note => _NoteStep(controller: _noteController),
      VerifyVisitStep.date => _DateStep(
          date: state.visitDate,
          onPickDate: _pickDate,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Step Indicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  final VerifyVisitStep currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Photo', 'Rating', 'Note', 'Date'];
    final currentIndex = currentStep.index;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIndex < currentIndex ? AppColors.primary : context.appColors.divider,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex < currentIndex;
        final isCurrent = stepIndex == currentIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary
                    : isCurrent
                        ? AppColors.primary.withOpacity(0.2)
                        : context.appColors.surfaceElevated,
                border: Border.all(
                  color: isCurrent || isCompleted
                      ? AppColors.primary
                      : context.appColors.divider,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? Icon(Icons.check, color: context.appColors.textPrimary, size: 16)
                  : Text(
                      '${stepIndex + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: isCurrent
                            ? AppColors.primary
                            : context.appColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              steps[stepIndex],
              style: AppTextStyles.overline.copyWith(
                color: isCurrent ? AppColors.primary : context.appColors.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Photo
// ---------------------------------------------------------------------------

class _PhotoStep extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  const _PhotoStep({
    required this.photoPath,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload a photo', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Take a photo at the location to verify your visit.',
          style: AppTextStyles.captionMuted,
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (photoPath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            child: Image.file(
              File(photoPath!),
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appColors.divider),
                    foregroundColor: context.appColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appColors.divider),
                    foregroundColor: context.appColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
        ] else
          GestureDetector(
            onTap: onPickCamera,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(
                  color: context.appColors.divider,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: context.appColors.textMuted, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text('Tap to take a photo', style: AppTextStyles.captionMuted),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: onPickGallery,
                    child: Text(
                      'or choose from gallery',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Rating
// ---------------------------------------------------------------------------

class _RatingStep extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  const _RatingStep({required this.rating, required this.onRatingChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rate your experience', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'How would you rate this place?',
          style: AppTextStyles.captionMuted,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final starValue = i + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 150),
                    child: Icon(
                      starValue <= rating ? Icons.star : Icons.star_border,
                      key: ValueKey('star_${starValue}_${starValue <= rating}'),
                      color: starValue <= rating
                          ? AppColors.warning
                          : context.appColors.textMuted,
                      size: 48,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Center(
          child: Text(
            _ratingLabel(rating),
            style: AppTextStyles.titleSmall.copyWith(color: context.appColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Very Good',
        5 => 'Excellent',
        _ => '',
      };
}

// ---------------------------------------------------------------------------
// Step 3: Note
// ---------------------------------------------------------------------------

class _NoteStep extends StatelessWidget {
  final TextEditingController controller;
  const _NoteStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a note', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Optional: share your thoughts about this place.',
          style: AppTextStyles.captionMuted,
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 300,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'e.g. The sunset view was incredible...',
            hintStyle: AppTextStyles.captionMuted,
            filled: true,
            fillColor: context.appColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: BorderSide(color: context.appColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: BorderSide(color: context.appColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            counterStyle: AppTextStyles.captionMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Date
// ---------------------------------------------------------------------------

class _DateStep extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPickDate;
  const _DateStep({required this.date, required this.onPickDate});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When did you visit?', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Select the date of your visit.',
          style: AppTextStyles.captionMuted,
        ),
        const SizedBox(height: AppSpacing.xxl),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.appColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: context.appColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.md),
                Text(formatted, style: AppTextStyles.bodyMedium),
                const Spacer(),
                Text(
                  'Change',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Action Buttons
// ---------------------------------------------------------------------------

class _BottomActions extends StatelessWidget {
  final VerifyVisitState vmState;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  const _BottomActions({
    required this.vmState,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = vmState.currentStep == VerifyVisitStep.date;
    final isFirstStep = vmState.currentStep == VerifyVisitStep.photo;

    return Row(
      children: [
        if (!isFirstStep)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.appColors.divider),
                foregroundColor: context.appColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
              ),
              onPressed: vmState.isSubmitting ? null : onBack,
              child: const Text('Back'),
            ),
          ),
        if (!isFirstStep) const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
            ),
            onPressed: vmState.isSubmitting
                ? null
                : isLastStep
                    ? onSubmit
                    : (vmState.currentStep == VerifyVisitStep.photo &&
                            !vmState.canAdvanceFromPhoto)
                        ? null
                        : onNext,
            child: vmState.isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: context.appColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isLastStep ? 'Complete Visit' : 'Next',
                    style: AppTextStyles.bodyMedium,
                  ),
          ),
        ),
      ],
    );
  }
}


