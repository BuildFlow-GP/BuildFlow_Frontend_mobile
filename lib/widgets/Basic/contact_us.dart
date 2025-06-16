import 'package:flutter/material.dart';
import 'package:buildflow_frontend/themes/app_colors.dart'; // تأكد من المسار الصحيح
import 'package:get/get.dart'; // لاستخدام GetUtils للتحقق من البريد الإلكتروني
import 'package:logger/logger.dart'; // لاستخدام logger

final logger = Logger(); // تعريف logger هنا ليكون متاحاً في هذا الملف

class ContactUsSection extends StatefulWidget {
  const ContactUsSection({super.key});

  @override
  State<ContactUsSection> createState() => _ContactUsSectionState();
}

class _ContactUsSectionState extends State<ContactUsSection> {
  final _formKey = GlobalKey<FormState>(); // مفتاح للتحكم في حالة النموذج
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose(); // التخلص من المتحكمات لمنع تسرب الذاكرة
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // دالة لمعالجة إرسال النموذج
  void _sendContactMessage() {
    if (_formKey.currentState!.validate()) {
      // إذا كان النموذج صالحاً، يمكنك هنا إرسال البيانات
      // إلى الباك إيند أو خدمة البريد الإلكتروني.
      logger.i('Sending contact message:');
      logger.i('Name: ${_nameController.text}');
      logger.i('Email: ${_emailController.text}');
      logger.i('Message: ${_messageController.text}');

      // إظهار رسالة نجاح للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message sent successfully! We will get back to you soon.',
            style: TextStyle(
              color: AppColors.textPrimary,
            ), // لون نص فاتح على اللون الأساسي
          ),
          backgroundColor: AppColors.success, // لون خلفية النجاح
          duration: const Duration(seconds: 3),
        ),
      );

      // مسح حقول النموذج بعد الإرسال
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  // دالة مساعدة لبناء Input Decoration بشكل متناسق
  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(
        icon,
        color: AppColors.accent,
      ), // استخدام AppColors.accent
      labelStyle: TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
      filled: true,
      fillColor: AppColors.background, // لون تعبئة الحقل من AppColors
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // إزالة الحدود الافتراضية
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2.0,
        ), // حدود عند التركيز
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withOpacity(0.3),
          width: 1.0,
        ), // حدود عند التفعيل
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2.0,
        ), // حدود للخطأ
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ), // يمكن تعديل هذا لتصغير الارتفاع
    );
  }

  // دالة مساعدة لبناء صف معلومات الاتصال
  Widget _buildContactInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.accent,
          size: 20,
        ), // استخدام AppColors.accent
        const SizedBox(width: 12),
        Expanded(
          // استخدام Expanded لضمان أن النص لا يتجاوز الحدود على الشاشات الصغيرة
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary, // استخدام AppColors
            ),
          ),
        ),
      ],
    );
  }

  // دالة لبناء جزء نموذج الاتصال (تم تعديلها لتقبل isWideScreen)
  Widget _buildContactForm(bool isWideScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // لمحاذاة العناصر إلى اليسار
        children: [
          if (isWideScreen) // الاسم والايميل جنب بعض على الشاشات العريضة
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                      'Your Name',
                      Icons.person,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 16), // مسافة بين حقلي الاسم والايميل
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      'Your Email',
                      Icons.email,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            )
          else // الاسم والايميل فوق بعض على الشاشات الصغيرة
            Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Your Name', Icons.person),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Your Email', Icons.email),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          const SizedBox(
            height: 16,
          ), // مسافة بعد الاسم والايميل (سواء كانوا بجانب بعض أو فوق بعض)
          TextFormField(
            controller: _messageController,
            maxLines: 2, // السماح بعدة أسطر للرسالة
            decoration: _buildInputDecoration('Your Message', Icons.message),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your message';
              }
              return null;
            },
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, // لجعل الزر يمتد على عرض العمود
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sendContactMessage, // ربط الزر بدالة الإرسال
              icon: Icon(Icons.send, color: Colors.white),
              label: Text(
                'Send Message',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, // لون الزر الأساسي
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة لبناء جزء معلومات الاتصال
  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // لمحاذاة العناصر إلى اليسار
      children: [
        Divider(
          color: AppColors.textSecondary.withOpacity(0.3),
        ), // خط فاصل أنيق
        const SizedBox(height: 24),
        _buildContactInfoRow(Icons.phone, '+972 568051019'),
        const SizedBox(height: 12),
        _buildContactInfoRow(Icons.email, 'support@buildflow.com'),
        const SizedBox(height: 12),
        _buildContactInfoRow(Icons.location_on, 'Nablus, Palestine'),
        const SizedBox(height: 12),
        _buildContactInfoRow(
          Icons.access_time,
          'Business Hours: Sat-Thu, 9 AM - 5 PM',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 600;
    // شرط جديد لـ "شاشات أكبر من 1000"
    final bool isExtraWideScreen = MediaQuery.of(context).size.width > 1000;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          // لتحديد أقصى عرض للبطاقة على الشاشات العريضة
          // هنا تم تعديل أقصى عرض ليتناسب مع الشاشات الأكبر من 1000 بكسل
          constraints: BoxConstraints(
            maxWidth:
                isExtraWideScreen
                    ? 1300
                    : (isWideScreen ? 700 : double.infinity),
          ),
          child: Card(
            elevation: 8, // ظل مشابه لبطاقات المقترحات
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // زوايا دائرية
            ),
            color: AppColors.card, // لون خلفية البطاقة
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 28.0, // حجم خط أكبر قليلاً
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Have a question or need assistance? Send us a message!',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // هنا يتم التبديل بين التصميم الأفقي والعمودي
                  if (isWideScreen) // للشاشات العريضة (أكبر من 600 بكسل)
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start, // لمحاذاة العناصر إلى الأعلى
                      children: [
                        Expanded(
                          flex: 3, // النموذج يأخذ 3 أجزاء من المساحة
                          child: _buildContactForm(
                            true,
                          ), // تمرير true لأنها شاشة عريضة
                        ),
                        const SizedBox(width: 48), // مسافة أكبر بين العمودين
                        Expanded(
                          flex: 2, // معلومات الاتصال تأخذ جزئين من المساحة
                          child: _buildContactInfo(),
                        ),
                      ],
                    )
                  else // تصميم الشاشات الصغيرة (أقل من 600 بكسل)
                    Column(
                      children: [
                        _buildContactForm(
                          false,
                        ), // تمرير false لأنها شاشة صغيرة
                        const SizedBox(
                          height: 32,
                        ), // مسافة بين النموذج ومعلومات الاتصال
                        _buildContactInfo(),
                      ],
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
