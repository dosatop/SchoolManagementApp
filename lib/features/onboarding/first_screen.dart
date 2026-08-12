import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: size.height / 4,
            width: double.infinity,
            child: Stack(
              children: [
                ClipPath(
                  clipper: WaveClipperTwo(),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    color: const Color.fromARGB(255, 9, 25, 147),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 70, top: 70, right: 20),
                  child: Column(children: [Row()]),
                ),
              ],
            ),
          ),
          Image.asset(
            "assets/svgs/team.png",
            height: size.height / 3,
            width: size.width / 1.5,
          ),
          Text(
            "SCHOOL",
            style: GoogleFonts.michroma(
              letterSpacing: 2,
              fontSize: 45,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 112, 120, 184),
            ),
          ),
          Text(
            "School Management App",
            style: GoogleFonts.exo(
              letterSpacing: 1.5,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: const Color.fromARGB(255, 47, 49, 61),
            ),
          ),

          Container(
            padding: EdgeInsets.all(30),
            margin: EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color.fromARGB(255, 9, 25, 147)),
            ),
            child: Column(
              children: [
                Text(
                  "Enjoy your Education at your fingertips !",
                  style: GoogleFonts.exo(fontSize: 14, letterSpacing: 1.3),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/loginOrSignup'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 9, 25, 147),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                    ),
                    child: Text("Get Started"),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      "/loginOrSignUp",
                      arguments: false,
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account ?",
                          style: TextStyle(fontSize: 16),
                        ),
                        TextButton(
                           onPressed: () => context.push('/loginOrSignup'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            // tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 9, 25, 147),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
