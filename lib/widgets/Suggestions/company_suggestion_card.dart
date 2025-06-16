import 'package:flutter/material.dart';
import '../../models/Basic/company_model.dart'; // تأكدي من المسار الصحيح

class CompanySuggestionCard extends StatelessWidget {
  // تم تحويله إلى StatelessWidget
  final CompanyModel company;
  final bool isFavorite; // مطلوب
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const CompanySuggestionCard({
    super.key,
    required this.company,
    required this.isFavorite, // أصبح مطلوباً
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CompanySuggestionCardContent(
      company: company,
      isFavorite: isFavorite,
      onFavoriteToggle: onFavoriteToggle,
      onTap: onTap,
    );
  }
}

// تم فصل المحتوى إلى StatefulWidget داخلي للحفاظ على تأثيرات الـ hover
class _CompanySuggestionCardContent extends StatefulWidget {
  final CompanyModel company;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const _CompanySuggestionCardContent({
    required this.company,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<_CompanySuggestionCardContent> createState() =>
      _CompanySuggestionCardContentState();
}

class _CompanySuggestionCardContentState
    extends State<_CompanySuggestionCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isHovered ? 1.03 : 1.0;
    final double elevation = _isHovered ? 8.0 : 2.0;
    final Offset offset = _isHovered ? const Offset(0, -5) : Offset.zero;
    final Duration animationDuration = const Duration(milliseconds: 200);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: animationDuration,
        transformAlignment: Alignment.center,
        transform:
            Matrix4.identity()
              ..translate(offset.dx, offset.dy)
              ..scale(scale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                115,
                115,
                115,
              ).withOpacity(_isHovered ? 0.15 : 0.08),
              blurRadius: elevation * 2,
              spreadRadius: 0.5,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                        ),
                        child:
                            widget.company.profileImage != null &&
                                    widget.company.profileImage!.isNotEmpty
                                ? Image.network(
                                  widget
                                      .company
                                      .profileImage!, // افترض أن هذا URL كامل
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.domain_verification,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  loadingBuilder: (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 120,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.domain_verification,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                      ),
                      if (widget.onFavoriteToggle != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap:
                                  widget
                                      .onFavoriteToggle, // استدعاء الدالة الممررة مباشرة
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons
                                          .favorite_border, // استخدام widget.isFavorite
                                  color:
                                      widget.isFavorite
                                          ? Colors.redAccent
                                          : Colors.white,
                                  size: 26,
                                  shadows:
                                      _isHovered || !widget.isFavorite
                                          ? [
                                            const Shadow(
                                              blurRadius: 3.0,
                                              color: Colors.black54,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.company.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        if (widget.company.rating != null)
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16.0,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                widget.company.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12.0),
                              ),
                            ],
                          ),
                        // يمكنك إضافة company.companyType هنا إذا أردت
                        if (widget.company.companyType != null &&
                            widget.company.companyType!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              widget.company.companyType!,
                              style: TextStyle(
                                fontSize: 11.0,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
