import "package:flutter/material.dart";
import "package:healthtrack/component/square_tile.dart";
import "package:healthtrack/screens/LoginPage/LoginForm_page.dart";
import "package:healthtrack/screens/SignUp Page/Sign_Up.dart";

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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    //google button
                    SquareTile(imagePath: "images/google Logo.png"),

                    //facebook button
                    SquareTile(imagePath: "images/Facebook Logo.png"),

                    //twitter button
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
}
