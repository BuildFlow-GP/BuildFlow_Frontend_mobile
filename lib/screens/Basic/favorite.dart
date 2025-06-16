// screens/favorites_screen.dart
import 'package:buildflow_frontend/models/Basic/company_model.dart';
import 'package:buildflow_frontend/models/Basic/office_model.dart';
import 'package:buildflow_frontend/models/Basic/project_model.dart';
import 'package:buildflow_frontend/models/fav/detailed_fav_model.dart';
import 'package:buildflow_frontend/models/fav/userfav_model.dart';
import 'package:buildflow_frontend/screens/ReadonlyProfiles/company_readonly_profile.dart';
import 'package:buildflow_frontend/screens/ReadonlyProfiles/office_readonly_profile.dart';
import 'package:buildflow_frontend/screens/ReadonlyProfiles/project_readonly_profile.dart';
import 'package:buildflow_frontend/services/Basic/favorite_service.dart';
import 'package:flutter/material.dart';
import 'package:buildflow_frontend/themes/app_colors.dart'; // هذا موجود بالفعل
import 'package:logger/logger.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

final Logger logger = Logger();

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  List<DetailedFavoriteItem> _detailedFavorites = [];
  bool _isLoading = true;
  String? _error;
  static const String baseUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final favoriteItems = await _favoriteService.getFavorites();
      if (favoriteItems.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final List<DetailedFavoriteItem?> fetchedDetails = await Future.wait(
        favoriteItems.map((favInfo) async {
          try {
            final detail = await _favoriteService.getFavoriteItemDetail(
              favInfo.itemId,
              favInfo.itemType,
            );
            return DetailedFavoriteItem(
              favoriteInfo: favInfo,
              itemDetail: detail,
            );
          } catch (e) {
            logger.i(
              "Error fetching detail for ${favInfo.itemType} ${favInfo.itemId}: $e",
            );
            return null;
          }
        }).toList(),
      );

      if (mounted) {
        setState(() {
          _detailedFavorites =
              fetchedDetails
                  .where((item) => item != null)
                  .cast<DetailedFavoriteItem>()
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load favorites: ${e.toString()}";
          _isLoading = false;
        });
      }
      logger.e("Error in _loadFavorites: $e");
    }
  }

  Future<void> _removeFromFavorites(FavoriteItemModel favoriteItem) async {
    try {
      await _favoriteService.removeFavorite(
        favoriteItem.itemId,
        favoriteItem.itemType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${favoriteItem.itemType} removed from favorites.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success, // استخدام AppColors
          ),
        );
        _loadFavorites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove from favorites: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error, // استخدام AppColors
          ),
        );
      }
      logger.e("Error removing favorite: $e");
    }
  }

  void _navigateToDetail(DetailedFavoriteItem detailedItem) {
    if (detailedItem.itemDetail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item details not available.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error, // استخدام AppColors
        ),
      );
      return;
    }

    if (detailedItem.itemDetail is OfficeModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => OfficerProfileScreen(
                officeId: detailedItem.favoriteInfo.itemId,
              ),
        ),
      );
    } else if (detailedItem.itemDetail is CompanyModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CompanyrProfileScreen(
                companyId: detailedItem.favoriteInfo.itemId,
              ),
        ),
      );
    } else if (detailedItem.itemDetail is ProjectModel) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ProjectreadDetailsScreen(
                projectId: detailedItem.favoriteInfo.itemId,
              ),
        ),
      );
      logger.i(
        "Navigate to project details: ${detailedItem.favoriteInfo.itemId}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ضبط عرض المحتوى بناءً على حجم الشاشة (متجاوب)
    double screenWidth = MediaQuery.of(context).size.width;
    double contentMaxWidth = screenWidth > 800 ? 800 : screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'My Favorites',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // لا يوجد زر تحديث في هذه الشاشة (يمكن إضافته إذا لزم الأمر)
              const SizedBox(width: 48), // مسافة فارغة لتوازن زر الرجوع
            ],
          ),
        ),
      ),
      body: Center(
        // توسيط المحتوى أفقياً
        child: ConstrainedBox(
          // تحديد عرض أقصى للمحتوى ليكون متجاوباً (Responsive)
          constraints: BoxConstraints(
            maxWidth: contentMaxWidth,
          ), // استخدام العرض المتجاوب
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadFavorites,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.background,
                ),
                label: const Text(
                  'Try Again',
                  style: TextStyle(color: AppColors.background),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_detailedFavorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded, // أيقونة جديدة
                color: AppColors.textSecondary,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'You have no favorite items yet.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add items to your favorites to see them here!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isWeb = MediaQuery.of(context).size.width > 600;

    return isWeb
        ? GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 350,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 1,
          ),
          itemCount: _detailedFavorites.length,
          itemBuilder: (context, index) {
            return _buildFavoriteItemCard(_detailedFavorites[index]);
          },
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _detailedFavorites.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildFavoriteItemCard(_detailedFavorites[index]),
            );
          },
        );
  }

  Widget _buildFavoriteItemCard(DetailedFavoriteItem detailedItem) {
    String title;
    String subtitle;
    // لم نعد بحاجة لـ imageProvider أو defaultIcon بما أننا لن نعرض CircleAvatar
    // ignore: unused_local_variable
    ImageProvider? imageProvider;
    dynamic actualItem = detailedItem.itemDetail;

    if (actualItem == null) {
      title = 'Unavailable Item';
      subtitle =
          'ID: ${detailedItem.favoriteInfo.itemId} (Type: ${detailedItem.favoriteInfo.itemType})';
    } else if (actualItem is OfficeModel) {
      title = actualItem.name;
      subtitle = 'Office Location: ${actualItem.location ?? 'N/A'}';
      if (actualItem.profileImage != null &&
          actualItem.profileImage!.isNotEmpty) {
        imageProvider = NetworkImage(
          actualItem.profileImage!.startsWith('http')
              ? actualItem.profileImage!
              : '$baseUrl/${actualItem.profileImage}',
        );
      }
    } else if (actualItem is CompanyModel) {
      title = actualItem.name;
      subtitle = 'Company Type: ${actualItem.companyType ?? 'N/A'}';
      if (actualItem.profileImage != null &&
          actualItem.profileImage!.isNotEmpty) {
        imageProvider = NetworkImage(
          actualItem.profileImage!.startsWith('http')
              ? actualItem.profileImage!
              : '$baseUrl/${actualItem.profileImage}',
        );
      }
    } else if (actualItem is ProjectModel) {
      title = actualItem.name;
      subtitle = 'Status: ${actualItem.status ?? 'N/A'}';
    } else {
      title = 'Favorite Project';
      subtitle = 'Type: ${detailedItem.favoriteInfo.itemType}';
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(detailedItem),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card, // استخدام AppColors
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.05), // استخدام AppColors
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // يمكنك إضافة CircleAvatar هنا إذا أردت عرض صورة العنصر
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary, // استخدام AppColors
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary, // استخدام AppColors
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                    ), // أيقونة جديدة + استخدام AppColors
                    tooltip: 'Remove from favorites',
                    onPressed:
                        () => _removeFromFavorites(detailedItem.favoriteInfo),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
