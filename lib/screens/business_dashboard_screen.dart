import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'business/create_ad_screen.dart';
import 'ad_analytics_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({Key? key}) : super(key: key);
  
  @override
  _BusinessDashboardScreenState createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  List<Map<String, dynamic>> ads = [];
  bool isLoading = true;
  String selectedTab = 'active';
  String? businessId;
  String? businessName;
  String? token;
  
  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }
  
  Future<void> _loadBusinessData() async {
    final prefs = await SharedPreferences.getInstance();
    businessId = prefs.getString('businessId');
    businessName = prefs.getString('businessName');
    token = prefs.getString('businessToken');
    
    if (businessId != null) {
      _loadAds();
    }
  }
  
  Future<void> _loadAds() async {
    setState(() => isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://vibbeo-backend.onrender.com/api/business-ads/business/$businessId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ads = List<Map<String, dynamic>>.from(data['ads'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ads: $e');
      setState(() => isLoading = false);
    }
  }
  
  List<Map<String, dynamic>> get filteredAds {
    return ads.where((ad) => ad['status'] == selectedTab).toList();
  }
  
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('businessId');
    await prefs.remove('businessToken');
    await prefs.setBool('isBusinessAccount', false);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Dashboard', style: TextStyle(fontSize: 18)),
            if (businessName != null)
              Text(businessName!, style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats overview
          _buildStatsOverview(),
          
          // Tab bar
          _buildTabBar(),
          
          // Ads list
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredAds.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: filteredAds.length,
                        itemBuilder: (context, index) {
                          return _buildAdCard(filteredAds[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateAdScreen()),
          ).then((_) => _loadAds());
        },
        icon: Icon(Icons.add),
        label: Text('Create Ad'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  Widget _buildStatsOverview() {
    int totalImpressions = 0;
    int totalClicks = 0;
    double totalSpent = 0;
    
    for (var ad in ads) {
      if (ad['metrics'] != null) {
        totalImpressions += (ad['metrics']['impressions'] ?? 0) as int;
        totalClicks += (ad['metrics']['clicks'] ?? 0) as int;
      }
      if (ad['budget'] != null) {
        totalSpent += (ad['budget']['spent'] ?? 0) as double;
      }
    }
    
    double ctr = totalImpressions > 0 ? (totalClicks / totalImpressions * 100) : 0;
    
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Impressions',
              totalImpressions.toString(),
              Icons.visibility,
              Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Clicks',
              totalClicks.toString(),
              Icons.touch_app,
              Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'CTR',
              '${ctr.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Spent',
              '₹${totalSpent.toStringAsFixed(0)}',
              Icons.currency_rupee,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTab('active', 'Active'),
          SizedBox(width: 8),
          _buildTab('paused', 'Paused'),
          SizedBox(width: 8),
          _buildTab('completed', 'Completed'),
          SizedBox(width: 8),
          _buildTab('draft', 'Draft'),
        ],
      ),
    );
  }
  
  Widget _buildTab(String value, String label) {
    bool isSelected = selectedTab == value;
    int count = ads.where((ad) => ad['status'] == value).length;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAdCard(Map<String, dynamic> ad) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ad image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad['adImage'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.image),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                
                // Ad info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['adTitle'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        ad['adDescription'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMetricChip(
                            Icons.visibility,
                            ad['metrics']?['impressions']?.toString() ?? '0',
                          ),
                          SizedBox(width: 8),
                          _buildMetricChip(
                            Icons.touch_app,
                            ad['metrics']?['clicks']?.toString() ?? '0',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAnalytics(ad),
                    icon: Icon(Icons.analytics, size: 16),
                    label: Text('Analytics', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editAd(ad),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAdStatus(ad),
                    icon: Icon(
                      ad['status'] == 'active' ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      ad['status'] == 'active' ? 'Pause' : 'Resume',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ad['status'] == 'active' ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricChip(IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No ads found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first ad to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  void _viewAnalytics(Map<String, dynamic> ad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdAnalyticsScreen(
          adId: ad['_id'],
          adTitle: ad['adTitle'],
        ),
      ),
    );
  }
  
  void _editAd(Map<String, dynamic> ad) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit feature coming soon!')),
    );
  }
  
  Future<void> _toggleAdStatus(Map<String, dynamic> ad) async {
    try {
      final newStatus = ad['status'] == 'active' ? 'paused' : 'active';
      final endpoint = newStatus == 'active' ? 'resume' : 'pause';
      
      final response = await http.post(
        Uri.parse('https://vibbeo-backend.onrender.com/api/business-ads/${ad['_id']}/$endpoint'),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ad ${newStatus == 'active' ? 'resumed' : 'paused'} successfully')),
        );
        _loadAds();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ad status')),
      );
    }
  }
}
