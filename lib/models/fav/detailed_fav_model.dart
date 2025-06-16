import '../Basic/project_model.dart';
import 'userfav_model.dart';

import '../Basic/office_model.dart';
import '../Basic/company_model.dart';
import '../userprojects/project_readonly_model.dart';

class DetailedFavoriteItem {
  final FavoriteItemModel favoriteInfo;
  final dynamic itemDetail;

  DetailedFavoriteItem({required this.favoriteInfo, required this.itemDetail});

  String get itemName {
    if (itemDetail is OfficeModel) {
      return (itemDetail as OfficeModel).name;
    } else if (itemDetail is CompanyModel) {
      return (itemDetail as CompanyModel).name;
    } else if (itemDetail is ProjectreadonlyModel) {
      return (itemDetail as ProjectreadonlyModel).name;
    } else if (itemDetail is ProjectModel) {
      return (itemDetail as ProjectModel).name;
    }
    return 'Unknown Item';
  }

  String? get itemImage {
    if (itemDetail is OfficeModel) {
      return (itemDetail as OfficeModel).profileImage;
    }
    if (itemDetail is CompanyModel) {
      return (itemDetail as CompanyModel).profileImage;
    }

    return null;
  }

  String get itemType {
    return favoriteInfo.itemType;
  }
}
