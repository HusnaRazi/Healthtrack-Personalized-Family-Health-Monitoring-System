import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:healthtrack/screens/LoginPage/Login_page.dart";
import "package:healthtrack/screens/SignUp Page/Sign_Up.dart";

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> passwordReset() async {
    final email = _emailController.text.trim();
    if (!_isEmailValid(email)) {
      showCustomDialog(context, "Invalid Email", "Please enter a valid email address.", false);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showCustomDialog(context, "Reset Successful",
          "A password reset link has been sent to your email. Please check your inbox and follow the instructions to reset your password.", true);
    } on FirebaseAuthException catch (_) {
      showCustomDialog(context, "Error", "Your Email does not exist. Please try again!", false);
    }
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b');
    return emailRegex.hasMatch(email);
  }

  void showCustomDialog(BuildContext context, String title, String content, bool isSuccess) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                )),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  if (isSuccess) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 140, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "images/Forgot Password.png",
                width: 240,
              ),

              const SizedBox(height: 10),

              const Text(
                "Reset Password",
                style: TextStyle(
                  fontFamily: 'PatuaOne',
                  fontSize: 24,
                ),
              ),

              const SizedBox(height: 5),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                  Text(
                    "Please enter your email address to receive password reset link.",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.blue,
                  ),
                  labelText: "E-mail",
                  hintText: "Enter E-mail Address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: passwordReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Send",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

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

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Remember Password?",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 5.0),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (e) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                        "Sign In",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      ),
    );
  }
}

