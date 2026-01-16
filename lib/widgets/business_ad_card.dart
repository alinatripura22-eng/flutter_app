import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/business_ads_service.dart';

class BusinessAdCard extends StatelessWidget {
  final Map<String, dynamic> adData;
  final bool isShorts;
  
  const BusinessAdCard({
    Key? key,
    required this.adData,
    this.isShorts = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isShorts ? 0 : 12,
        vertical: isShorts ? 0 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isShorts ? 0 : 12),
        boxShadow: isShorts ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isShorts ? _buildShortsAd(context) : _buildFeedAd(context),
    );
  }
  
  // Feed ad (Instagram style)
  Widget _buildFeedAd(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sponsored label
        Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.campaign, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'Sponsored',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Ad image/video
        GestureDetector(
          onTap: () => _handleAdClick(context),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: adData['adVideo'] != null
                ? _buildVideoPlayer(adData['adVideo'])
                : Image.network(
                    adData['adImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      );
                    },
                  ),
          ),
        ),
        
        // Ad content
        Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business name
              Text(
                adData['businessName'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              
              // Ad title
              Text(
                adData['adTitle'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              
              // Ad description
              Text(
                adData['adDescription'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              
              // Call to action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleAdClick(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _getCallToActionText(adData['callToAction']),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Shorts ad (TikTok style - full screen)
  Widget _buildShortsAd(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: Stack(
        children: [
          // Background image/video
          Positioned.fill(
            child: adData['adVideo'] != null
                ? _buildVideoPlayer(adData['adVideo'])
                : Image.network(
                    adData['adImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: Icon(Icons.image, size: 100, color: Colors.grey),
                      );
                    },
                  ),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Sponsored label (top)
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Ad content (bottom)
          Positioned(
            bottom: 100,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business name
                Text(
                  adData['businessName'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                
                // Ad title
                Text(
                  adData['adTitle'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                
                // Ad description
                Text(
                  adData['adDescription'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                
                // Call to action button
                ElevatedButton(
                  onPressed: () => _handleAdClick(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _getCallToActionText(adData['callToAction']),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPlayer(String videoUrl) {
    // TODO: Implement video player
    // For now, show placeholder
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
      ),
    );
  }
  
  String _getCallToActionText(String action) {
    switch (action) {
      case 'visit_website':
        return 'Visit Website';
      case 'call_now':
        return 'Call Now';
      case 'get_directions':
        return 'Get Directions';
      case 'book_now':
        return 'Book Now';
      case 'order_now':
        return 'Order Now';
      case 'shop_now':
        return 'Shop Now';
      case 'sign_up':
        return 'Sign Up';
      case 'download':
        return 'Download';
      default:
        return 'Learn More';
    }
  }
  
  Future<void> _handleAdClick(BuildContext context) async {
    // Record click
    await BusinessAdsService.recordClick(adData['_id']);
    
    // Open URL
    if (adData['websiteUrl'] != null && adData['websiteUrl'].isNotEmpty) {
      final url = Uri.parse(adData['websiteUrl']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Record conversion after opening URL
        await BusinessAdsService.recordConversion(adData['_id']);
      }
    } else {
      // Show contact info
      _showContactDialog(context);
    }
  }
  
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(adData['businessName']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (adData['contactPhone'] != null) ...[
              Row(
                children: [
                  Icon(Icons.phone, size: 20),
                  SizedBox(width: 8),
                  Text(adData['contactPhone']),
                ],
              ),
              SizedBox(height: 8),
            ],
            if (adData['contactEmail'] != null) ...[
              Row(
                children: [
                  Icon(Icons.email, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text(adData['contactEmail'])),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (adData['contactPhone'] != null)
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse('tel:${adData['contactPhone']}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                  await BusinessAdsService.recordConversion(adData['_id']);
                }
                Navigator.pop(context);
              },
              child: Text('Call Now'),
            ),
        ],
      ),
    );
  }
}
