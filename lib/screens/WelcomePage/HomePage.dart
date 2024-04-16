import 'package:flutter/material.dart';
import 'package:healthtrack/component/HomePage_header.dart';
import 'package:healthtrack/component/curved_edges.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/HealthPage.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/SymptomPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  Widget? currentContent = const HealthPage();

  final List<String> categories = ['Health', 'Symptoms', 'Medication', 'Medical Profile'];
  final List<String> images = [
    'images/Health Logo.png',
    'images/Symptoms Icon.png',
    'images/Medicine Icon.png',
    'images/Medical Profile Icon.png'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: CustomCurvedEdges(),
              child: Container(
                color: Colors.lightBlue,
                padding: const EdgeInsets.all(0),
                child: Stack(
                  children: [
                    // Title Widget
                    const Positioned(
                      top: 50,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome!',
                            style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            ),
                          ),
                        Text(
                          'Your Health informations are saved here.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Positioned(
                      top: 130, // Adjust the position as needed
                      left: 20,
                      right: 20,
                      child: TextField(
                        controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            prefixIcon: const Icon(Icons.search_outlined),
                          ),
                          style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    const Positioned(
                      top: 200, // Adjusted top position
                      left: 30,
                      child: Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                Positioned(
                  top: 240,
                  left: 30,
                  right: 20,
                  child: SizedBox(
                    height: 100,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, index) {
                        String titleWithLineBreak = categories[index] == 'Medical Profile' ? 'Medical\nProfile' : categories[index];
                        return VerticalImageText(
                          title: titleWithLineBreak,
                          images: images[index],
                            onTap: () => _handleIconTap(categories[index]),
                        );
                      },
                    ),
                  ),
                ),

                    // Curved Background
                    SizedBox(
                      height: 380,
                      child: Stack(
                        children: [
                          Positioned(
                            top: -150,
                            right: -250,
                            child: Header(backgroundColor: Colors.white.withOpacity(0.1)),
                          ),
                          Positioned(
                            top: 100,
                            right: -300,
                            child: Header(backgroundColor: Colors.white.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: currentContent ?? Container(),
            ),
          ],
        ),
      ),
    );
  }

void _handleIconTap(String category) {
  setState(() {
    // Decide which content to load based on the tapped icon
    switch (category) {
      case 'Health':
        currentContent = const HealthPage();
        break;
      case 'Symptoms':
        currentContent = const SymptomsPage();
      default:
        currentContent = null;
    }
  });
}
}

class VerticalImageText extends StatelessWidget {
  const VerticalImageText({
    Key? key,
    required this.images,
    required this.title,
    this.textColor = Colors.black, // Changed default color to black for better visibility
    this.backgroundColor = Colors.white, // Set a default background color
    required this.onTap,
  }) : super(key: key);

  final String images, title;
  final Color textColor, backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    images,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
                title,
                style: TextStyle(color: textColor),
                maxLines: 2, // Allow up to two lines
                overflow: TextOverflow.ellipsis, // Handle overflow with an ellipsis
                textAlign: TextAlign.center, // Center align the text for aesthetics
              ),
          ],
        ),
      ),
    );
  }
}
