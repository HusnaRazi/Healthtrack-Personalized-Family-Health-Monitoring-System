import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:healthtrack/screens/SignUp Page/ForgotPass_page.dart";
import 'package:healthtrack/screens/WelcomePage/navigation_menu.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool rememberMe = false;
  bool _obscureText = true;
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  final _formfield = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formfield,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              controller: email,
              validator: (value) {
                bool emailValid = RegExp(
                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(value!);
                if (value == null || value.isEmpty) {
                  return "Email is required";
                }
                else if(!emailValid){
                  return "Valid Email is required";
                }
                return null;
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.person_outline_outlined,
                  color: Colors.pinkAccent,
                ),
                labelText: "E-mail",
                hintText: "Enter E-mail",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: password,
              obscureText: _obscureText,
              validator: (value) {
                if (value!.isEmpty) {
                  return "Password is required";
                }
                else if(password.text.length<6) {
                  return "Password Length Should not be less than 6";
                }
                return null;
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.pinkAccent,
                ),
                labelText: "Password",
                hintText: "Enter Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _obscureText? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  }
                ),
              ),
            ),

            const SizedBox(height: 3),

            //Remember Me and Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text("Remember Me"),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (e) => const ForgotPassword(),
                      ),
                    );
                  },
                  child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),

            //Sign In Button
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                onPressed: () async {
                  if(_formfield.currentState!.validate()){
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email.text,
                        password: password.text,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NavigationMenu()),
                      );
                    } on FirebaseAuthException catch (e) {
                      String errorMessage = "Incorrect username or password";
                      if (e.code == 'user-not-found') {
                        errorMessage = 'No user found for that email.';
                      } else if (e.code == 'wrong-password') {
                        errorMessage = 'Wrong password provided.';
                    }
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Login Error"),
                          titleTextStyle: const TextStyle(
                              fontFamily: 'SansSerif',
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 22,),

                          content: Text(errorMessage),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("Back"),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


