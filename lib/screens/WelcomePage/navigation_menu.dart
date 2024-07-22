import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthtrack/screens/Dashboard%20Page/Dashboard_page.dart';
import 'package:healthtrack/screens/Family%20Account/FamilyAccount_page.dart';
import 'package:healthtrack/screens/File%20Page/FileUploadPage.dart';
import 'package:healthtrack/screens/Setting%20Page/SettingProfile.dart';
import 'package:healthtrack/screens/WelcomePage/HomePage.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      body: Obx(() => Center(
        child: controller.screens[controller.selectedIndex.value],
        ),
      ),
      bottomNavigationBar:Obx(
        () => NavigationBar(
          height: 60,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) {
            controller.selectedIndex.value = index;
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.drive_folder_upload), label: 'File'),
            NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Family'),
            NavigationDestination(icon: Icon(Icons.auto_graph_outlined), label: 'Summary'),
            NavigationDestination(icon: Icon(Icons.account_circle_outlined), label: 'Profile'),
            ],
        ),
      ),
    );
  }
}

class NavigationController extends GetxController{
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
  const HomePage(),
  const FilePage(),
  AddFamilyMemberPage(),
  const DashboardPage(),
  const ProfilePage(),
  ];
}





