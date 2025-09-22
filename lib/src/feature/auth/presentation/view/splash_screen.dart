import 'package:briqwear/src/common/bottons.dart';
import 'package:briqwear/src/common/font_type.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("briqWear", style: AppTextStyle.h1),
              // under details box //
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text: "Your style\nYour ",
                                style: AppTextStyle.h2),
                            const TextSpan(
                              text: "wardrobe",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 30,
                                fontFamily: "Montserrat",
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                            TextSpan(
                                text: "\nYour choice", style: AppTextStyle.h2),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox( 
                        width: double.infinity,
                        child: CustomButton(
                            color: Colors.black, text: "Sign up with Google")),
                    const SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          color: Color.fromARGB(255, 194, 194, 194),
                          text: "I have an account",
                          textColor: Color.fromARGB(255, 62, 62, 62),
                        )),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                          "The API class handles token storage. Would you like me to modify any specific endpoints or response formats to match your backend exactly",
                          style: AppTextStyle.h5),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
