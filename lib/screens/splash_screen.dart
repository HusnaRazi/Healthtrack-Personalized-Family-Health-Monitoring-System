import "dart:async";
import "package:flutter/material.dart";
import "package:healthtrack/screens/LoginPage/Login_page.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin{

  @override
  void initState() {
    //TODO: implement initState
    super.initState();

    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..forward();
  late final Animation<Offset> _leftToRightAnim = Tween<Offset>(
    begin: const Offset(-1.5, 0.0),

    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  ));
  late final Animation<Offset>_rightToLeftAnim = Tween<Offset>(
    begin: const Offset(1.5, 0.0),

    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  ));

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                "images/Splash Screen Logo.png"
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(position: _leftToRightAnim, child: const Text("True Happiness Comes "),),
                SlideTransition(position: _rightToLeftAnim, child: const Text("From Good Health"),),
              ],
            )
          ],
        ),
      ),
    );
  }
}
