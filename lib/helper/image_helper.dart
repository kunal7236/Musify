import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Helper class for optimized image loading with enhanced quality settings
class ImageHelper {
  /// Create an optimized CachedNetworkImage for album art (large images)
  static Widget buildAlbumArt({
    required String imageUrl,
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? accentColor,
  }) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          memCacheWidth: 500,
          memCacheHeight: 500,
          maxWidthDiskCache: 500,
          maxHeightDiskCache: 500,
          filterQuality: FilterQuality.high,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: backgroundColor ?? Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  accentColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            color: backgroundColor ?? Colors.grey[900],
            child: Center(
              child: Icon(
                Icons.music_note,
                size: width * 0.3,
                color: accentColor ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Create an optimized CachedNetworkImage for thumbnails (small images)
  static Widget buildThumbnail({
    required String imageUrl,
    required double size,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: 150,
          memCacheHeight: 150,
          maxWidthDiskCache: 150,
          maxHeightDiskCache: 150,
          filterQuality: FilterQuality.high,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: backgroundColor ?? Colors.grey[300],
            child: Icon(
              Icons.music_note,
              size: size * 0.5,
              color: Colors.grey[600],
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: backgroundColor ?? Colors.grey[300],
            child: Icon(
              Icons.music_note,
              size: size * 0.5,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// Enhance image URL quality by replacing size parameters
  static String enhanceImageQuality(String imageUrl) {
    if (imageUrl.isEmpty) return imageUrl;

    // Try different resolution patterns for maximum quality
    return imageUrl
        .replaceAll('150x150', '500x500')
        .replaceAll('50x50', '500x500')
        .replaceAll('200x200', '500x500')
        .replaceAll('250x250', '500x500')
        .replaceAll('300x300', '500x500');
  }
}
