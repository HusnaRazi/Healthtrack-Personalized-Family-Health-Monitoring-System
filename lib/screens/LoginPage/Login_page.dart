import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:healthtrack/component/square_tile.dart";
import "package:healthtrack/screens/LoginPage/LoginForm_page.dart";
import "package:healthtrack/screens/SignUp Page/Sign_Up.dart";
import "package:healthtrack/screens/WelcomePage/navigation_menu.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical:24.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 15.0),
                Image.asset(
                    "images/Red Minimalist Heart Beat Logo.png"
                ),
                const SizedBox(height: 15),

                //username textfield
                const LoginForm(),

                const SizedBox(height: 25),

                //or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(child:
                      Divider(
                        thickness: 0.8,
                        color: Colors.grey[400],
                      ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          "Or Continue With",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(child:
                      Divider(
                        thickness: 0.8,
                        color: Colors.grey[400],
                      ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                //google + apple sign in buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,  // Transparent background
                    shadowColor: Colors.transparent,  // No shadow
                    padding: EdgeInsets.zero,  // Remove padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),  // Match your SquareTile's border radius if it has one
                    ),
                  ),
                  onPressed: () {
                    signInWithGoogle();
                  },
                  child: SquareTile(imagePath: "images/google Logo.png"),
                ),
              ],
            ),

            const SizedBox(height: 30),

                //Not a member? Register Now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an Account?",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 5.0),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (e) => const SignUpPage(),
                            ),
                        );
                      },
                        child: const Text(
                          "Register now",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ]),
        ),
      ),
    );
  }

  signInWithGoogle() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.signOut(); // Sign out before signing in to ensure account selection

      GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {  // Check that user didn't cancel the login
        GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken
        );

        UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {  // Check that the user is logged in
          print(userCredential.user?.displayName);
          // Navigate to the Home Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationMenu()),  // Navigate to the navigation menu
          );
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }
}
