import 'package:flutter/material.dart';
import 'package:healthtrack/component/HomePage_header.dart';
import 'package:healthtrack/component/curved_edges.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/HealthPage.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medical%20Profile/MedicalProfile_page.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medications/Medicine%20Page.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/SymptomPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  Widget? currentContent = const HealthPage();
  String currentCategory = 'Health';

  final List<String> categories = [
    'Health',
    'Symptoms',
    'Medication',
    'Medical Profile'
  ];
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
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          prefixIcon: const Icon(Icons.search_outlined),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    Positioned(
                      top: 200, // Adjusted top position
                      left: 30,
                      child: Text(
                        '${currentCategory} Categories',
                        // Dynamically display current category
                        style: const TextStyle(
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
                            return VerticalImageText(
                              title: categories[index],
                              images: images[index],
                              onTap: () => _handleIconTap(index),
                              isExpanded: _expandedIndex == index, // Pass the expanded state
                            );
                          },
                        ),
                      ),
                    ), // Curved Background
                    SizedBox(
                      height: 380,
                      child: Stack(
                        children: [
                          Positioned(
                            top: -150,
                            right: -250,
                            child: Header(
                                backgroundColor: Colors.white.withOpacity(0.1)),
                          ),
                          Positioned(
                            top: 100,
                            right: -300,
                            child: Header(
                                backgroundColor: Colors.white.withOpacity(0.1)),
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

  int? _expandedIndex;

  void _handleIconTap(int index) {
    print("Category tapped: ${categories[index]}");
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? null : index;
      currentCategory = categories[index];

      switch (categories[index]) {
        case 'Health':
          currentContent = const HealthPage();
          break;
        case 'Symptoms':
          currentContent = const SymptomsPage();
          break;
        case 'Medication':
          currentContent = const MedicationPage(); // Make sure this widget is correctly defined
          break;
        case 'Medical Profile':
          currentContent = MedicalProfilePage(); // Make sure this widget is correctly defined
          break;
        default:
          currentContent = const Text('Page not found');
      }
      print("Current content set to: $currentContent");
    });
  }
}

  class VerticalImageText extends StatefulWidget {
  const VerticalImageText({
    Key? key,
    required this.images,
    required this.title,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    required this.onTap,
    this.isExpanded = false, // New property to determine expansion
  }) : super(key: key);

  final String images, title;
  final Color textColor, backgroundColor;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  _VerticalImageTextState createState() => _VerticalImageTextState();
}

class _VerticalImageTextState extends State<VerticalImageText> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_animationController);
    _colorAnimation = ColorTween(begin: widget.backgroundColor, end: Colors.blueAccent).animate(_animationController);

    // Sync animation state with expansion changes
    if (widget.isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant VerticalImageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (_, __) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _colorAnimation.value,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          widget.images,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
