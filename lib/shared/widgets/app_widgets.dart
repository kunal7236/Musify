import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'skeleton_loader.dart';

/// Reusable image widgets that eliminate code duplication
/// Provides consistent image loading patterns across the app
class AppImageWidgets {
  // Private constructor to prevent instantiation
  AppImageWidgets._();

  /// Optimized album art widget for large images (music player)
  static Widget albumArt({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? accentColor,
  }) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppConstants.borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width ?? AppConstants.albumArtSize,
          height: height ?? AppConstants.albumArtSize,
          fit: BoxFit.cover,
          memCacheWidth: AppConstants.imageCacheWidth,
          memCacheHeight: AppConstants.imageCacheHeight,
          maxWidthDiskCache: AppConstants.imageCacheWidth,
          maxHeightDiskCache: AppConstants.imageCacheHeight,
          filterQuality: FilterQuality.high,
          placeholder: (context, url) => ShimmerWidget(
            baseColor: Colors.black12,
            highlightColor: Colors.black26,
            child: Container(
              width: width ?? AppConstants.albumArtSize,
              height: height ?? AppConstants.albumArtSize,
              color: Colors.black12,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width ?? AppConstants.albumArtSize,
            height: height ?? AppConstants.albumArtSize,
            color: Colors.transparent, // Completely transparent
          ),
        ),
      ),
    );
  }

  /// Optimized thumbnail widget for small images (lists, mini-player)
  static Widget thumbnail({
    required String imageUrl,
    double? size,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    final imageSize = size ?? AppConstants.thumbnailSize;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppConstants.borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          memCacheWidth: AppConstants.thumbnailCacheSize,
          memCacheHeight: AppConstants.thumbnailCacheSize,
          maxWidthDiskCache: AppConstants.thumbnailCacheSize,
          maxHeightDiskCache: AppConstants.thumbnailCacheSize,
          filterQuality: FilterQuality.high,
          placeholder: (context, url) => ShimmerWidget(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Container(
              width: imageSize,
              height: imageSize,
              color: Colors.grey[800],
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: imageSize,
            height: imageSize,
            color: Colors.transparent, // Completely transparent
          ),
        ),
      ),
    );
  }
}

/// Reusable container widgets that eliminate gradient duplication
class AppContainerWidgets {
  // Private constructor to prevent instantiation
  AppContainerWidgets._();

  /// Primary gradient background container
  static Widget gradientBackground({
    required Widget child,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
      ),
      child: child,
    );
  }

  /// Gradient button container
  static Widget gradientButton({
    required Widget child,
    required VoidCallback onPressed,
    Gradient? gradient,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.buttonGradient,
        borderRadius: borderRadius ??
            BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ??
              BorderRadius.circular(AppConstants.buttonBorderRadius),
          child: Padding(
            padding:
                padding ?? const EdgeInsets.all(AppConstants.defaultPadding),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Card container with consistent styling
  static Widget appCard({
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
            vertical: AppConstants.smallPadding / 2,
          ),
      child: Card(
        color: color ?? AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ??
              BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppConstants.defaultPadding),
          child: child,
        ),
      ),
    );
  }
}
