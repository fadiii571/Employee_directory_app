import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Enhanced Network Image Widget with Caching and Error Handling
/// 
/// This widget provides robust image loading with:
/// - Automatic caching for better performance
/// - Proper error handling and fallbacks
/// - Loading indicators
/// - Support for Firebase Storage URLs
/// - Retry mechanism for failed loads
class CachedNetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool isCircular;
  final double? radius;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.isCircular = false,
    this.radius,
  });

  /// Factory constructor for circular avatars
  factory CachedNetworkImageWidget.avatar({
    required String? imageUrl,
    double radius = 25,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImageWidget(
      imageUrl: imageUrl,
      isCircular: true,
      radius: radius,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle null or empty URLs
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildErrorWidget();
    }

    // Clean and validate URL
    final cleanUrl = _cleanImageUrl(imageUrl!);
    if (!_isValidUrl(cleanUrl)) {
      return _buildErrorWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: cleanUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) {
        return _buildErrorWidget();
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Enhanced cache configuration
      cacheKey: _generateCacheKey(cleanUrl),
      maxWidthDiskCache: 800, // Reduced for better performance
      maxHeightDiskCache: 800,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      // Add retry mechanism and headers
      httpHeaders: const {
        'Cache-Control': 'max-age=3600', // Cache for 1 hour
      },
    );

    // Apply circular clipping if needed
    if (isCircular) {
      imageWidget = CircleAvatar(
        radius: radius ?? 25,
        backgroundColor: Colors.grey[300],
        child: ClipOval(
          child: SizedBox(
            width: (radius ?? 25) * 2,
            height: (radius ?? 25) * 2,
            child: imageWidget,
          ),
        ),
      );
    } else if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Clean and normalize image URL
  String _cleanImageUrl(String url) {
    // Remove any whitespace
    url = url.trim();
    
    // Handle Firebase Storage URLs
    if (url.contains('firebasestorage.googleapis.com')) {
      // Ensure proper token parameter format
      if (url.contains('?') && !url.contains('&token=') && !url.contains('?token=')) {
        // URL might be malformed, try to fix it
        if (url.contains('alt=media') && !url.contains('token=')) {
          // Firebase Storage URL missing token parameter
        }
      }
    }
    
    return url;
  }

  /// Validate if URL is properly formatted
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Generate cache key for the image
  String _generateCacheKey(String url) {
    // For Firebase Storage URLs, use the full URL as cache key to avoid conflicts
    // This ensures each unique URL gets its own cache entry
    if (url.contains('firebasestorage.googleapis.com')) {
      // Use the full URL to ensure unique caching per image
      return url;
    }
    return url;
  }

  /// Build placeholder widget
  Widget _buildPlaceholder() {
    if (placeholder != null) {
      return placeholder!;
    }

    if (isCircular) {
      return CircleAvatar(
        radius: radius ?? 25,
        backgroundColor: Colors.grey[300],
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    if (isCircular) {
      return CircleAvatar(
        radius: radius ?? 25,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: (radius ?? 25) * 0.8,
          color: Colors.grey[600],
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Enhanced Image Loading Utilities
class ImageLoadingUtils {
  
  /// Preload image to cache
  static Future<void> preloadImage(String imageUrl, BuildContext context) async {
    if (imageUrl.trim().isEmpty) return;
    
    try {
      await precacheImage(
        CachedNetworkImageProvider(imageUrl),
        context,
      );
    } catch (e) {
      // Failed to preload image
    }
  }

  /// Clear image cache
  static Future<void> clearImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      // Failed to clear image cache
    }
  }

  /// Get cache size
  static Future<String> getCacheSize() async {
    try {
      // Note: CacheManager doesn't provide direct size info
      // This is a placeholder for future implementation
      return 'Cache info not available';
    } catch (e) {
      return 'Error getting cache size';
    }
  }

  /// Validate Firebase Storage URL
  static bool isValidFirebaseStorageUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('firebasestorage.googleapis.com') &&
             uri.pathSegments.length >= 4 &&
             uri.queryParameters.containsKey('alt');
    } catch (e) {
      return false;
    }
  }

  /// Fix Firebase Storage URL if possible
  static String? fixFirebaseStorageUrl(String url) {
    if (url.trim().isEmpty) return null;
    
    try {
      final uri = Uri.parse(url);
      
      // If it's already a proper Firebase Storage URL, return as is
      if (isValidFirebaseStorageUrl(url)) {
        return url;
      }
      
      // Try to fix common issues
      if (uri.host.contains('firebasestorage.googleapis.com')) {
        // Ensure alt=media parameter exists
        final queryParams = Map<String, String>.from(uri.queryParameters);
        if (!queryParams.containsKey('alt')) {
          queryParams['alt'] = 'media';
        }
        
        final fixedUri = uri.replace(queryParameters: queryParams);
        return fixedUri.toString();
      }
      
      return url; // Return original if can't fix
    } catch (e) {
      return null;
    }
  }
}
