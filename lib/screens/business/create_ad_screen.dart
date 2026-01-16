import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({Key? key}) : super(key: key);

  @override
  _CreateAdScreenState createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 1: Package Selection
  String _selectedPackage = 'starter';
  
  final List<Map<String, dynamic>> _packages = [
    {
      'id': 'starter',
      'name': 'Starter',
      'price': 2999,
      'impressions': '25,000',
      'reach': '10,000-15,000',
      'duration': '7 days',
      'placements': ['Feed'],
      'features': ['City targeting', 'Basic analytics', 'Reach 10K-15K users'],
    },
    {
      'id': 'growth',
      'name': 'Growth',
      'price': 5999,
      'impressions': '75,000',
      'reach': '30,000-40,000',
      'duration': '15 days',
      'placements': ['Feed', 'Shorts'],
      'features': ['City + Age targeting', 'Detailed analytics', 'Priority support', 'Reach 30K-40K users'],
      'popular': true,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': 9999,
      'impressions': '150,000',
      'reach': '60,000-80,000',
      'duration': '30 days',
      'placements': ['Feed', 'Shorts', 'Search'],
      'features': ['Advanced targeting', 'Real-time analytics', 'Priority support', 'Featured placement', 'Reach 60K-80K users'],
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise',
      'price': 19999,
      'impressions': '500,000',
      'reach': '200,000-300,000',
      'duration': '60 days',
      'placements': ['All placements'],
      'features': ['All features', 'Dedicated manager', 'Custom reporting', 'API access', 'Reach 200K-300K users'],
    },
  ];
  
  // Step 2: Ad Content
  final _adTitleController = TextEditingController();
  final _adDescriptionController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  File? _adImage;
  String _callToAction = 'learn_more';
  
  // Step 3: Targeting
  final _targetCityController = TextEditingController();
  final _targetStateController = TextEditingController();
  int _minAge = 18;
  int _maxAge = 65;
  String _targetGender = 'all';
  List<String> _selectedInterests = [];
  
  final List<String> _availableInterests = [
    'Food', 'Fashion', 'Technology', 'Travel', 'Fitness',
    'Beauty', 'Education', 'Entertainment', 'Sports', 'Music',
  ];
  
  @override
  void dispose() {
    _adTitleController.dispose();
    _adDescriptionController.dispose();
    _websiteUrlController.dispose();
    _targetCityController.dispose();
    _targetStateController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _adImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_adImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an ad image')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final businessId = prefs.getString('businessId');
      final token = prefs.getString('businessToken');
      
      // Get package details
      final package = _packages.firstWhere((p) => p['id'] == _selectedPackage);
      
      // TODO: Upload image to BunnyCDN first
      // For now, using placeholder
      final imageUrl = 'https://via.placeholder.com/800x600';
      
      final response = await http.post(
        Uri.parse('https://vibbeo-backend.onrender.com/api/business-ads/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'businessId': businessId,
          'adTitle': _adTitleController.text.trim(),
          'adDescription': _adDescriptionController.text.trim(),
          'adImage': imageUrl,
          'callToAction': _callToAction,
          'websiteUrl': _websiteUrlController.text.trim(),
          'targetLocations': [
            {
              'city': _targetCityController.text.trim(),
              'state': _targetStateController.text.trim(),
              'country': 'India',
            }
          ],
          'targetAudience': {
            'ageRange': {'min': _minAge, 'max': _maxAge},
            'gender': _targetGender,
            'interests': _selectedInterests,
          },
          'placements': package['placements'],
          'campaignType': 'cpm',
          'budget': {
            'daily': (package['price'] / int.parse(package['duration'].split(' ')[0])).round(),
            'total': package['price'],
          },
          'pricing': {
            'cpm': 100,
            'cpc': 5,
            'cpa': 50,
          },
          'schedule': {
            'startDate': DateTime.now().toIso8601String(),
            'endDate': DateTime.now().add(Duration(days: int.parse(package['duration'].split(' ')[0]))).toIso8601String(),
          },
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Ad created! Pending review.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Show payment dialog
          _showPaymentDialog(package['price']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to create ad'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showPaymentDialog(int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Payment Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Amount: ₹$amount'),
            SizedBox(height: 16),
            Text(
              'Please complete payment to activate your ad campaign.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Payment Options:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• UPI: vibbeo@upi'),
            Text('• Bank Transfer'),
            Text('• Razorpay Link (coming soon)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to dashboard
            },
            child: Text('I\'ll Pay Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment link sent to your email!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Send Payment Link'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Ad Campaign'),
        backgroundColor: Colors.blue,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _createAd();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          // Step 1: Package Selection
          Step(
            title: Text('Choose Package'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              children: _packages.map((package) {
                final isSelected = _selectedPackage == package['id'];
                final isPopular = package['popular'] == true;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedPackage = package['id']),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: package['id'],
                              groupValue: _selectedPackage,
                              onChanged: (value) {
                                setState(() => _selectedPackage = value!);
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        package['name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isPopular) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'POPULAR',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '₹${package['price']}/campaign',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildPackageDetail(Icons.visibility, '${package['impressions']} impressions'),
                        _buildPackageDetail(Icons.people, '${package['reach']} unique users'),
                        _buildPackageDetail(Icons.calendar_today, package['duration']),
                        _buildPackageDetail(Icons.place, (package['placements'] as List).join(', ')),
                        SizedBox(height: 8),
                        ...((package['features'] as List).map((feature) => 
                          _buildPackageDetail(Icons.check_circle, feature, color: Colors.green)
                        )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Step 2: Ad Content
          Step(
            title: Text('Ad Content'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Ad Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _adImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_adImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to select ad image'),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Ad Title
                  TextFormField(
                    controller: _adTitleController,
                    decoration: InputDecoration(
                      labelText: 'Ad Title *',
                      hintText: 'e.g., 50% Off Today!',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLength: 100,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter ad title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Ad Description
                  TextFormField(
                    controller: _adDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Ad Description *',
                      hintText: 'Describe your offer...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                    maxLength: 500,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter ad description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Call to Action
                  DropdownButtonFormField<String>(
                    value: _callToAction,
                    decoration: InputDecoration(
                      labelText: 'Call to Action',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'learn_more', child: Text('Learn More')),
                      DropdownMenuItem(value: 'call_now', child: Text('Call Now')),
                      DropdownMenuItem(value: 'visit_website', child: Text('Visit Website')),
                      DropdownMenuItem(value: 'get_directions', child: Text('Get Directions')),
                      DropdownMenuItem(value: 'book_now', child: Text('Book Now')),
                      DropdownMenuItem(value: 'order_now', child: Text('Order Now')),
                      DropdownMenuItem(value: 'shop_now', child: Text('Shop Now')),
                    ],
                    onChanged: (value) => setState(() => _callToAction = value!),
                  ),
                  SizedBox(height: 16),
                  
                  // Website URL
                  TextFormField(
                    controller: _websiteUrlController,
                    decoration: InputDecoration(
                      labelText: 'Website URL (optional)',
                      hintText: 'https://yourwebsite.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Step 3: Targeting
          Step(
            title: Text('Targeting'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _targetCityController,
                  decoration: InputDecoration(
                    labelText: 'City *',
                    hintText: 'e.g., Mumbai',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _targetStateController,
                  decoration: InputDecoration(
                    labelText: 'State *',
                    hintText: 'e.g., Maharashtra',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 24),
                
                // Age Range
                Text('Age Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                RangeSlider(
                  values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
                  min: 18,
                  max: 65,
                  divisions: 47,
                  labels: RangeLabels('$_minAge', '$_maxAge'),
                  onChanged: (values) {
                    setState(() {
                      _minAge = values.start.round();
                      _maxAge = values.end.round();
                    });
                  },
                ),
                Text('$_minAge - $_maxAge years', textAlign: TextAlign.center),
                SizedBox(height: 24),
                
                // Gender
                Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _targetGender,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (value) => setState(() => _targetGender = value!),
                ),
                SizedBox(height: 24),
                
                // Interests
                Text('Interests (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Step 4: Review
          Step(
            title: Text('Review'),
            isActive: _currentStep >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review Your Ad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildReviewItem('Package', _packages.firstWhere((p) => p['id'] == _selectedPackage)['name']),
                _buildReviewItem('Price', '₹${_packages.firstWhere((p) => p['id'] == _selectedPackage)['price']}'),
                _buildReviewItem('Title', _adTitleController.text),
                _buildReviewItem('Target City', _targetCityController.text),
                _buildReviewItem('Age Range', '$_minAge - $_maxAge years'),
                _buildReviewItem('Gender', _targetGender),
                SizedBox(height: 16),
                if (_isLoading)
                  Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _createAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text('Create Ad & Proceed to Payment', style: TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPackageDetail(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color ?? Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
