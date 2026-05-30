import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _eventNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _startingPointController;
  late final TextEditingController _capacityController;
  late final TextEditingController _priceController;
  late final TextEditingController _priceInCoinsController;
  late final TextEditingController _coinsToEarnController;
  late final TextEditingController _officialPageController;
  
  String? _selectedCategory;
  late String _selectedLevel;
  bool _isLoading = false;
  DateTime? _selectedDateTime;

  final List<String> _levels = ['Rider', 'Explorer', 'Elite', 'Pro'];

  String _formatDateHelper(dynamic dateData) {
    if (dateData == null) return '';
    if (dateData is Timestamp) {
      final date = dateData.toDate();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return dateData.toString();
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _eventNameController = TextEditingController(text: widget.eventData['eventName'] ?? '');
    _descriptionController = TextEditingController(text: widget.eventData['description'] ?? '');
    _dateController = TextEditingController(text: _formatDateHelper(widget.eventData['date']));
    _startingPointController = TextEditingController(text: widget.eventData['startingPoint'] ?? '');
    _capacityController = TextEditingController(text: widget.eventData['capacity']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.eventData['price']?.toString() ?? '');
    _priceInCoinsController = TextEditingController(text: widget.eventData['priceInCoins']?.toString() ?? '');
    _coinsToEarnController = TextEditingController(text: widget.eventData['coinsToEarn']?.toString() ?? '');
    _officialPageController = TextEditingController(text: widget.eventData['officialPageLink'] ?? '');
    
    _selectedCategory = widget.eventData['categoryId'];
    _selectedLevel = widget.eventData['level'] ?? 'Rider';
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _startingPointController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _priceInCoinsController.dispose();
    _coinsToEarnController.dispose();
    _officialPageController.dispose();
    super.dispose();
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Stream<QuerySnapshot> get _categoriesStream => _firestore.collection('categories').snapshots();

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('You must be logged in to update an event');
        return;
      }

      final eventData = {
        'eventName': _eventNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDateTime != null ? Timestamp.fromDate(_selectedDateTime!) : widget.eventData['date'],
        'startingPoint': _startingPointController.text.trim(),
        'capacity': int.tryParse(_capacityController.text) ?? 0,
        'price': int.tryParse(_priceController.text) ?? 0,
        'priceInCoins': int.tryParse(_priceInCoinsController.text) ?? 0,
        'coinsToEarn': int.tryParse(_coinsToEarnController.text) ?? 0,
        'categoryId': _selectedCategory,
        'level': _selectedLevel,
        'officialPageLink': _officialPageController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('events').doc(widget.eventId).update(eventData);

      _showSuccess('Event updated successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to update event: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF39FF14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Event',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: Border(
          bottom: BorderSide(color: Colors.white24, width: 0.2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF39FF14).withOpacity(0.2),
                      const Color(0xFF39FF14).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF39FF14).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: const Color(0xFF39FF14),
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modify Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Update your cycling event details',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Event Name
              _buildTextField(
                controller: _eventNameController,
                label: 'Event Name',
                icon: Icons.event,
                validator: (value) => value?.isEmpty ?? true ? 'Event name is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Date Picker with Calendar Table
              _buildDatePickerField(),
              
              const SizedBox(height: 16),
              
              // Starting Point
              _buildTextField(
                controller: _startingPointController,
                label: 'Starting Point',
                icon: Icons.location_on,
                validator: (value) => value?.isEmpty ?? true ? 'Starting point is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Category Dropdown (from Firestore)
              StreamBuilder<QuerySnapshot>(
                stream: _categoriesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingField('Loading categories...');
                  }
                  if (snapshot.hasError) {
                    return _buildErrorField('Failed to load categories');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildErrorField('No categories found');
                  }

                  final categories = snapshot.data!.docs;
                  
                  final categoryIds = categories.map((doc) => doc.id).toList();
                  if (_selectedCategory == null || !categoryIds.contains(_selectedCategory)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedCategory = categories.first.id;
                        });
                      }
                    });
                  }

                  return _buildFirestoreDropdown(
                    label: 'Category',
                    icon: Icons.category,
                    value: _selectedCategory ?? categories.first.id,
                    items: categories,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Level Dropdown
              _buildDropdown(
                label: 'Difficulty Level',
                icon: Icons.trending_up,
                value: _selectedLevel,
                items: _levels,
                onChanged: (value) => setState(() => _selectedLevel = value!),
              ),
              
              const SizedBox(height: 16),
              
              // Capacity
              _buildTextField(
                controller: _capacityController,
                label: 'Capacity (Max Riders)',
                icon: Icons.people,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value?.isEmpty ?? true ? 'Capacity is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Price Section
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (DZD)',
                      icon: Icons.money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _priceInCoinsController,
                      label: 'Price in Coins',
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Coins to Earn
              _buildTextField(
                controller: _coinsToEarnController,
                label: 'Coins to Earn (for attendance)',
                icon: Icons.redeem,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value?.isEmpty ?? true ? 'Coins reward is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Official Page Link
              _buildTextField(
                controller: _officialPageController,
                label: 'Official Page Link (optional)',
                icon: Icons.link,
              ),
              
              const SizedBox(height: 32),
              
              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          errorStyle: TextStyle(
            color: Colors.red.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item.substring(0, 1).toUpperCase() + item.substring(1),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF39FF14)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorField(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<QueryDocumentSnapshot> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items: items.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final name = data?['name'] as String? ?? doc.id;
          return DropdownMenuItem<String>(
            value: doc.id,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () => _showCalendarPicker(),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF39FF14).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextFormField(
          controller: _dateController,
          enabled: false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Select Date',
            hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
            prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFF39FF14)),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            disabledBorder: InputBorder.none,
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Date is required' : null,
        ),
      ),
    );
  }

  void _showCalendarPicker() {
    DateTime? selectedDay;
    DateTime focusedDay = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentYear = DateTime.now().year;
          final years = [currentYear, currentYear + 1];

          return Dialog(
            backgroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF39FF14).withOpacity(0.3),
                width: 1,
              ),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Event Date',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF39FF14),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF39FF14).withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: focusedDay.year,
                                dropdownColor: const Color(0xFF1A1A1A),
                                style: const TextStyle(color: Colors.white),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                onChanged: (year) {
                                  if (year != null) {
                                    setDialogState(() {
                                      focusedDay = DateTime(year, focusedDay.month);
                                    });
                                  }
                                },
                                items: years.map((year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(
                                      year.toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 320,
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime(currentYear + 1, 12, 31),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                        onDaySelected: (selected, focused) {
                          setDialogState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) {
                          setDialogState(() {
                            focusedDay = focused;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: const TextStyle(color: Colors.white),
                          weekendTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(color: Colors.white),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF39FF14),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          formatButtonVisible: false,
                          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: const Color(0xFF39FF14).withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF39FF14).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Selected: ${_formatDate(selectedDay!)}',
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white54,
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedDay != null
                                ? () async {
                                    Navigator.pop(context);
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _selectedDateTime = DateTime(
                                          selectedDay!.year,
                                          selectedDay!.month,
                                          selectedDay!.day,
                                          time.hour,
                                          time.minute,
                                        );
                                        _dateController.text = _formatFullDateTime(_selectedDateTime!);
                                      });
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF39FF14),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatFullDateTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[date.month - 1];
    final dayStr = date.day.toString();
    final yearStr = date.year.toString();
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    return '$monthStr $dayStr, $yearStr - $hourStr:$minuteStr';
  }
}
