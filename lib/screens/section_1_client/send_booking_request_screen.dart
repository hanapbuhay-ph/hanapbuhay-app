import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/worker_model.dart';
import '../../widgets/navigation/app_header.dart';
import '../../widgets/buttons/primary_button.dart';

class SendBookingRequestScreen extends StatefulWidget {
  final String workerId;

  const SendBookingRequestScreen({
    super.key,
    required this.workerId,
  });

  @override
  State<SendBookingRequestScreen> createState() => _SendBookingRequestScreenState();
}

class _SendBookingRequestScreenState extends State<SendBookingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  Worker? _worker;
  bool _isLoadingWorker = true;
  bool _isSubmitting = false;

  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();

  final List<String> _categories = [
    'Electrical',
    'Plumbing',
    'Tutoring',
    'Cleaning',
    'Laundry',
    'Gardening',
    'Carpentry'
  ];

  @override
  void initState() {
    super.initState();
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    final worker = await context.read<WorkerProvider>().getWorkerById(widget.workerId);
    if (mounted) {
      setState(() {
        _worker = worker;
        _isLoadingWorker = false;
        // Pre-select category if worker specialty matches
        if (worker != null) {
          final match = _categories.firstWhere(
            (c) => worker.specialty.contains(c),
            orElse: () => _categories.first,
          );
          _selectedCategory = match;
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    // In a real app, we'd get the actual barangay ID from the user object
    final clientBarangay = 'Poblacion'; 

    try {
      final result = await context.read<BookingProvider>().createBooking(
        workerId: widget.workerId,
        category: _selectedCategory!,
        date: _selectedDate!,
        time: _selectedTime!.format(context),
        notes: _notesController.text.trim(),
        barangay: clientBarangay,
      );

      if (!mounted) return;

      if (result.success) {
        // Success: Show confirmation and pop back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.primary,
          ),
        );
        // TODO: Eventually go to booking_detail_screen (1.6)
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoadingWorker) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_worker == null) {
      return const Scaffold(body: Center(child: Text('Worker not found')));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(title: 'Send Request'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildWorkerSummary(_worker!),
                    const SizedBox(height: 32),
                    
                    // Service Category
                    Text('Service Required', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _getInputDecoration('Category'),
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: AppTypography.bodyMedium),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 24),

                    // Date & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: _getBoxDecoration(),
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedDate == null 
                                          ? 'Select Date' 
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: _selectedDate == null ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.calendar_today, size: 18, color: colorScheme.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Time', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _selectTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: _getBoxDecoration(),
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: _selectedTime == null ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.access_time, size: 18, color: colorScheme.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Service Location (Architecture Correction: Read-only Barangay)
                    Text('Service Location', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Poblacion, Trinidad', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Workers will meet you at your registered barangay. Exact address can be shared via chat after booking is confirmed.',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Job Details
                    Text('Job Details', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      style: AppTypography.bodyMedium,
                      decoration: _getInputDecoration('Details').copyWith(
                        hintText: 'Describe the issue... e.g. leaking pipe under kitchen sink',
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please provide some details' : null,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bottom Bar
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: PrimaryButton(
              label: 'Send Request',
              showArrow: true,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSummary(Worker worker) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundImage: NetworkImage(worker.avatarUrl)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(worker.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(worker.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(' (${worker.reviewCount} reviews)', style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  BoxDecoration _getBoxDecoration() {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.outlineVariant),
    );
  }
}
