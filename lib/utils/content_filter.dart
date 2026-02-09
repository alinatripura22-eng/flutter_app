/// Content filtering to block inappropriate videos
/// Prevents adult content, violence, hate speech without AI
class ContentFilter {
  // Banned keywords for titles and descriptions
  static final List<String> bannedKeywords = [
    // Adult content
    'sex', 'porn', 'xxx', 'nude', 'naked', 'nsfw', 'adult', 'erotic',
    'sexy', 'hot girl', 'hot boy', 'onlyfans', 'webcam', 'cam girl',
    'strip', 'bikini', 'underwear', 'lingerie', 'boobs', 'ass', 'dick',
    'pussy', 'cock', 'fuck', 'fucking', 'bitch', 'slut', 'whore',
    
    // Violence
    'kill', 'murder', 'death', 'suicide', 'rape', 'torture', 'abuse',
    'violence', 'blood', 'gore', 'weapon', 'gun', 'knife', 'bomb',
    
    // Hate speech
    'hate', 'racist', 'terrorism', 'terrorist', 'nazi', 'hitler',
    
    // Drugs
    'drug', 'cocaine', 'heroin', 'meth', 'weed', 'marijuana', 'cannabis',
    
    // Gambling
    'casino', 'gambling', 'poker', 'betting', 'lottery',
    
    // Scams
    'free money', 'get rich', 'make money fast', 'click here', 'download now',
  ];
  
  // Suspicious patterns
  static final List<RegExp> suspiciousPatterns = [
    RegExp(r'\b(18\+|21\+|adults? only)\b', caseSensitive: false),
    RegExp(r'\b(click|download|install)\s+(here|now|free)\b', caseSensitive: false),
    RegExp(r'\b(free\s+money|easy\s+money|fast\s+cash)\b', caseSensitive: false),
    RegExp(r'\b(sex|porn|xxx)\b', caseSensitive: false),
  ];
  
  /// Check if content is appropriate
  /// Returns null if OK, error message if blocked
  static String? checkContent({
    required String title,
    required String description,
  }) {
    final combinedText = '$title $description'.toLowerCase();
    
    // Check banned keywords
    for (final keyword in bannedKeywords) {
      if (combinedText.contains(keyword.toLowerCase())) {
        return 'Content contains prohibited keyword: "$keyword"';
      }
    }
    
    // Check suspicious patterns
    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(combinedText)) {
        return 'Content contains suspicious pattern';
      }
    }
    
    // Check for excessive caps (spam indicator)
    final capsCount = title.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (title.length > 10 && capsCount > title.length * 0.7) {
      return 'Title contains excessive capital letters';
    }
    
    // Check for excessive special characters (spam indicator)
    final specialChars = title.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    if (specialChars > title.length * 0.3) {
      return 'Title contains excessive special characters';
    }
    
    return null; // Content is OK
  }
  
  /// Check if video duration is acceptable
  static String? checkDuration(Duration duration) {
    const maxDuration = Duration(minutes: 5);
    
    if (duration > maxDuration) {
      return 'Video too long. Maximum: 5 minutes';
    }
    
    if (duration < Duration(seconds: 3)) {
      return 'Video too short. Minimum: 3 seconds';
    }
    
    return null; // Duration is OK
  }
  
  /// Check file size (prevent huge uploads)
  static String? checkFileSize(int bytes) {
    const maxSize = 500 * 1024 * 1024; // 500 MB
    
    if (bytes > maxSize) {
      return 'File too large. Maximum: 500 MB';
    }
    
    return null; // Size is OK
  }
  
  /// Get content guidelines for users
  static String getGuidelines() {
    return '''
CONTENT GUIDELINES

✅ ALLOWED:
- Educational content
- Entertainment
- Music and dance
- Comedy and memes
- Gaming
- Tutorials
- Vlogs
- Sports
- News

❌ NOT ALLOWED:
- Adult/sexual content
- Violence or gore
- Hate speech or discrimination
- Illegal activities
- Drug use or promotion
- Scams or spam
- Copyright violations
- Misleading content

VIDEO LIMITS:
- Maximum length: 5 minutes
- Maximum size: 500 MB
- Minimum length: 3 seconds

VIOLATIONS:
- First offense: Warning
- Second offense: 7-day ban
- Third offense: Permanent ban

Report inappropriate content using the flag button.
''';
  }
}
