import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:untitled/Pages/signUp.dart';

import 'Forgot_password.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});


  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email="",password="";
  var EmailController=TextEditingController();
  var PasswordController=TextEditingController();
  final _formkey = GlobalKey<FormState>();
  userLogin() async {


  }
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Colors.white,
      body:Container(
        child:SingleChildScrollView(

        child: Column(
          children: [
            SizedBox(height: 30,),
            Container(

              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                  'assets/logo.jpg'
              ),

            ),
            SizedBox(height: 30,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0,right: 20),
              child:Form(
                key: _formkey,

              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 2.0,horizontal: 30.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFedf0f8),
                      borderRadius: BorderRadius.circular(30),

                    ),
                    child: TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter E-mail';
                        }
                        return null;
                      },
                      controller: EmailController,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Email",
                          hintStyle: TextStyle(
                              color: Color(0xFFb2b7bf), fontSize: 18.0)),
                    ),

                  ),
                  SizedBox(
                    height: 40.0,
                  ),
                  Container(
                    padding:
                    EdgeInsets.symmetric(vertical: 2.0, horizontal: 30.0),

                    decoration: BoxDecoration(
                        color: Color(0xFFedf0f8
                        ),
                        borderRadius: BorderRadius.circular(30)
                    ),
                  child:TextFormField(
                    controller: PasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Password",
                        hintStyle: TextStyle(
                            color: Color(0xFFb2b7bf), fontSize: 18.0),


                    ),
                    obscureText: true,

                  ) ,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  GestureDetector(
                    onTap: (){
                      if(_formkey.currentState!.validate()){
                        setState(() {
                          email= EmailController.text;
                          password=PasswordController.text;
                        });
                      }
                      userLogin();

                    },
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(
                            vertical: 13.0, horizontal: 30.0),
                        decoration: BoxDecoration(
                            color: Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(30)),
                        child: Center(
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w500),
                            ))),


                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> ForgotPassword()));
                    },
                    child: Text("Forgot Password?",
                        style: TextStyle(
                            color: Color(0xFF8c8e98),
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(
                    height: 40.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                            fontSize: 18.0, color: Colors.black),
                      ),
                      SizedBox(
                        width: 5.0,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUp()));
                        },
                        child: Text(
                          "Create",
                          style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500),
                        ),
                      )
                    ],
                  )
                ],


              ),
              )
            )
          ],
        ),
      ),
      )

    );
  }
}
