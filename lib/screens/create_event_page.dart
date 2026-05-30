import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startingPointController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceInCoinsController = TextEditingController();
  final TextEditingController _coinsToEarnController = TextEditingController();
  final TextEditingController _officialPageController = TextEditingController();
  
  String? _selectedCategory;
  String _selectedLevel = 'Rider';
  bool _isLoading = false;
  DateTime? _selectedDateTime;

  final List<String> _levels = ['Rider', 'Explorer', 'Elite', 'Pro'];

  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImagesToCloudinary() async {
    List<String> uploadedUrls = [];
    for (var imageFile in _selectedImages) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dopk2m742/image/upload'),
        );
        request.fields['upload_preset'] = 'hubike_shop';
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
        
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final jsonData = json.decode(responseData);
          uploadedUrls.add(jsonData['secure_url']);
        } else {
          throw Exception('Cloudinary upload failed with status ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Image upload failed: $e');
        throw Exception('Failed to upload image: $e');
      }
    }
    return uploadedUrls;
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

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('You must be logged in to create an event');
        return;
      }

      // Fetch the Group Leader's name
      String leaderName = 'HUBIKE Team';
      try {
        final leaderDoc = await _firestore.collection('leaders').doc(user.uid).get();
        if (leaderDoc.exists && leaderDoc.data() != null) {
           final data = leaderDoc.data()!;
           final fName = data['first_name'] ?? data['firstName'] ?? '';
           final lName = data['last_name'] ?? data['lastName'] ?? '';
           leaderName = data['groupName'] ?? '$fName $lName'.trim();
        } else {
           final userDoc = await _firestore.collection('users').doc(user.uid).get();
           if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data()!;
              final fName = data['first_name'] ?? data['firstName'] ?? '';
              final lName = data['last_name'] ?? data['lastName'] ?? '';
              leaderName = '$fName $lName'.trim();
           }
        }
        if (leaderName.isEmpty) leaderName = 'HUBIKE Team';
      } catch (e) {
        // Ignore error and use default
      }

      setState(() => _isUploading = true);
      List<String> finalImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        finalImageUrls = await _uploadImagesToCloudinary();
      }

      final eventData = {
        'eventName': _eventNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDateTime != null ? Timestamp.fromDate(_selectedDateTime!) : FieldValue.serverTimestamp(),
        'startingPoint': _startingPointController.text.trim(),
        'capacity': int.tryParse(_capacityController.text) ?? 0,
        'currentParticipants': 0,
        'price': int.tryParse(_priceController.text) ?? 0,
        'priceInCoins': int.tryParse(_priceInCoinsController.text) ?? 0,
        'coinsToEarn': int.tryParse(_coinsToEarnController.text) ?? 0,
        'categoryId': _selectedCategory,
        'level': _selectedLevel,
        'officialPageLink': _officialPageController.text.trim(),
        'creatorId': user.uid,
        'creatorName': leaderName,
        'imageUrls': finalImageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Available',
      };

      await _firestore.collection('events').add(eventData);

      _showSuccess('Event created successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to create event: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
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
          'Create Event',
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
                      Icons.add_circle,
                      color: const Color(0xFF39FF14),
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fill in the details to host your cycling event',
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
              
              // Image Picker Section
              _buildImagePicker(),
              
              const SizedBox(height: 16),
              
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
                  
                  // Ensure we have a valid selected category
                  final categoryIds = categories.map((doc) => doc.id).toList();
                  if (_selectedCategory == null || !categoryIds.contains(_selectedCategory)) {
                    // Use post-frame callback to avoid setState during build
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
                  onPressed: (_isLoading || _isUploading) ? null : _createEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: (_isLoading || _isUploading)
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'CREATE EVENT',
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
                    Container(
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
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF39FF14)),
                          onChanged: (year) {
                            if (year != null) {
                              setDialogState(() {
                                focusedDay = DateTime(year, focusedDay.month, 1);
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 320,
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
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
                    if (selectedDay != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Selected: ${selectedDay!.day}/${selectedDay!.month}/${selectedDay!.year}',
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(color: Colors.white54),
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Photos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.3)),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.red, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF121212).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF39FF14).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, color: const Color(0xFF39FF14)),
                const SizedBox(width: 8),
                Text(
                  _selectedImages.isEmpty ? 'Select Photos' : 'Add More Photos',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
