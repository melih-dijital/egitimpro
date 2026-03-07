import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/duty_planner_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _completeWelcome(BuildContext context, String route) async {
    // İlk açılış tamamlandı olarak işaretle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_launched_before', true);

    if (context.mounted) {
      // Yığını temizlemeden git ki geri gelindiğinde tekrar burası görünsün
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutunu al
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Veya temanıza uygun bir renk
      body: Stack(
        children: [
          // Üst kısım boş bırakıldı (İstek üzerine)
          // İsteğe bağlı olarak logo vs eklenebilir ama "içerik gösterilmeyecek" denildi.

          // Alt kısım - Yarım Daire Tasarımı
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.4, // Ekranın alt %40'ı
            child: Container(
              decoration: BoxDecoration(
                color: DutyPlannerColors.primary, // Ana renk
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(screenWidth * 1.5, screenHeight * 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Giriş Yap Butonu
                  SizedBox(
                    width: screenWidth * 0.7,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _completeWelcome(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: DutyPlannerColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kayıt Ol Butonu
                  SizedBox(
                    width: screenWidth * 0.7,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => _completeWelcome(context, '/register'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
    );
  }
}
