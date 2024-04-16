import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:get/get_core/src/get_main.dart";
import "package:healthtrack/screens/LoginPage/Login_page.dart";
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  bool _obscureText = true;
  String firstName="", lastName = "", username="", email = "", phonenum ="", password="";
  TextEditingController fNamecontroller = new TextEditingController();
  TextEditingController lNamecontroller = new TextEditingController();
  TextEditingController usernamecontroller = new TextEditingController();
  TextEditingController emailcontroller = new TextEditingController();
  TextEditingController phonenumbercontroller = new TextEditingController();
  TextEditingController passwordcontroller = new TextEditingController();

  final _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:24.0),
          child: Column(
            children: [
              //Title
               Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.lightBlue[800],
                  fontFamily: 'PatuaOne',
                  fontSize: 60,
                ),
              ),
              const Text(
                "Create An Account",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Lora',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              Form(
                key: _formkey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: fNamecontroller,
                              expands: false,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                return "First Name is required";
                              }
                              return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.person_outline_outlined,
                                  color: Colors.blue[800],
                                ),
                                labelText: "First Name",
                                hintText: "First Name",
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: lNamecontroller,
                              expands: false,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Last Name is required";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.person_outline_outlined,
                                  color: Colors.blue[800],
                                ),
                                labelText: "Last Name",
                                hintText: "Last Name",
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: usernamecontroller,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Username is required";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person_outline_outlined,
                            color: Colors.blue[800],
                          ),
                          labelText: "Username",
                          hintText: "Enter Username",
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: emailcontroller,
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
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.blue[800],
                          ),
                          labelText: "E-mail",
                          hintText: "Enter E-mail",
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: phonenumbercontroller,
                        validator: (value) {
                          final phoneRegExp = RegExp(r'^\d{10}$');
                          if (value == null || value.isEmpty) {
                            return "Phone Number is required";
                          }
                          else if(!phoneRegExp.hasMatch(value)) {
                            return 'Invalid phone number format';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.contact_phone_outlined,
                            color: Colors.blue[800],
                          ),
                          labelText: "Phone Number",
                          hintText: "Enter Phone Number",
                          border: const OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: passwordcontroller ,
                        obscureText: _obscureText,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter Password";
                          }
                          else if(!value.contains(RegExp(r'[A-Z]'))) {
                            return "Password must contain at least one uppercase letter";
                          }
                          else if(value.length<6) {
                            return "Password must contain at least 6 characters";
                          }
                          else if(!value.contains(RegExp(r'[0-9]'))) {
                            return "Password must contain at least one number";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.password_outlined,
                            color: Colors.blue[800],
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
                      ],
                  ),
                  ),
              const SizedBox(height: 30),

              //Sign In Button
              SizedBox(
                width: double.infinity,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: () async{
                    if (_formkey.currentState!.validate()) {
                      try {
                        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailcontroller.text,
                        password: passwordcontroller.text,
                    );
                        // Save user details to Firestore
                        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                          'firstName': fNamecontroller.text,
                          'lastName': lNamecontroller.text,
                          'username': usernamecontroller.text,
                          'email': emailcontroller.text,
                          'phoneNumber': phonenumbercontroller.text,
                          'password': passwordcontroller.text,
                        });

                        _showRegistrationSuccessDialog(context);
                      }catch (e) {
                        print("Failed to create user: $e");
                        // Handle any errors that occur during sign-up
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
                      "Create Account",
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

                  //Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an Account?",
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
      )
    );
  }
}

void _showRegistrationSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Registration Successful!",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        )),
        content: Text("Your account has been successfully created. Please Login to continue."),
        actions: <Widget>[
          TextButton(
            child: Text("OK"),
            onPressed: () {
              // Navigate to the home screen or any other screen you want
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
