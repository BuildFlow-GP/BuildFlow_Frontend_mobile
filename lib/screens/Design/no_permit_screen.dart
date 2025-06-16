import 'package:flutter/material.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'design_agreement_screen.dart';

class NoPermitScreen extends StatefulWidget {
  const NoPermitScreen({super.key, required int projectId})
    : _projectId = projectId;

  final int _projectId;

  @override
  State<NoPermitScreen> createState() => _NoPermitScreenState();
}

class _NoPermitScreenState extends State<NoPermitScreen> {
  bool step1 = false;
  bool step2 = false;
  bool step3 = false;
  bool step4 = false;

  void _navigateToNextPage(BuildContext context) {
    if (step1 && step2 && step3 && step4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DesignAgreementScreen(projectId: widget._projectId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all steps before proceeding.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allStepsDone = step1 && step2 && step3 && step4;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 28,
                    ),
                    color: AppColors.accent,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      "Pre-Submission Requirements",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // توازن المساحة بسبب زر الرجوع
                ],
              ),
            ),
            const SizedBox(height: 16),

            // == Steps ==
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    StepCard(
                      title: "Submit land ownership documents",
                      subtitle:
                          "Visit the local land registry office, provide property information, pay the required fees, and obtain your ownership documents.",
                      value: step1,
                      onChanged: (val) => setState(() => step1 = val!),
                      icon: Icons.description,
                    ),
                    StepCard(
                      title: "Get a land survey report",
                      subtitle:
                          "Hire a licensed surveyor to measure and map your property, then submit the survey data to the local land authority for validation.",
                      value: step2,
                      onChanged: (val) => setState(() => step2 = val!),
                      icon: Icons.map,
                    ),
                    StepCard(
                      title: "Obtain municipal approval",
                      subtitle:
                          "Submit your building plans to the municipal office and receive official approval.",
                      value: step3,
                      onChanged: (val) => setState(() => step3 = val!),
                      icon: Icons.account_balance,
                    ),
                    StepCard(
                      title: "Obtain archaeological authority approval",
                      subtitle:
                          "Coordinate with the Department of Antiquities to ensure the construction site is clear.",
                      value: step4,
                      onChanged: (val) => setState(() => step4 = val!),
                      icon: Icons.history_edu,
                    ),

                    const SizedBox(height: 24),

                    // == Message ==
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: allStepsDone ? 1 : 0.6,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "All steps must be completed to proceed to the agreement form.",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // == Submit Button ==
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (step1 && step2 && step3 && step4)
                                ? AppColors.accent
                                : AppColors.primary.withOpacity(0.5),
                        foregroundColor:
                            (step1 && step2 && step3 && step4)
                                ? Colors.white
                                : Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: (step1 && step2 && step3 && step4) ? 6 : 2,
                      ),
                      onPressed:
                          (step1 && step2 && step3 && step4)
                              ? () => _navigateToNextPage(context)
                              : null,
                      child: Text(
                        (step1 && step2 && step3 && step4)
                            ? 'All Steps Completed! Continue'
                            : 'Complete All Steps First',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // ← تم تحديد اللون هنا
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// == Custom Modern Step Card ==
class StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool?> onChanged;

  const StepCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: value ? AppColors.accent.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.accent : Colors.grey.shade300,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(icon, color: AppColors.accent),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: value ? TextDecoration.lineThrough : null,
            color: value ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value ? AppColors.accent : Colors.grey,
          ),
          onPressed: () => onChanged(!value),
        ),
        onTap: () => onChanged(!value),
      ),
    );
  }
}



//import 'package:buildflow_frontend/widgets/custom_bottom_nav.dart';

 /*bottomNavigationBar: CustomBottomNav(
    currentIndex: _selectedIndex,
    onTap: (index) {
      setState(() {
        _selectedIndex = index;
      });
    },
  ),*/