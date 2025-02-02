import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData getTheme() {
  return ThemeData(
    listTileTheme: ListTileThemeData(titleTextStyle:const TextTheme(headlineMedium: TextStyle( color: Colors.black,),).headlineMedium,),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Colors.black,
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      displayMedium: TextStyle(
        color: Colors.black,
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      displaySmall: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color:Colors.black),
      headlineLarge: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      headlineMedium: TextStyle(
        color: Colors.black,
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      headlineSmall: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      titleLarge: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      labelSmall: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      bodyLarge: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      labelLarge: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      bodyMedium: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      labelMedium: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
      bodySmall: TextStyle(fontFamily: GoogleFonts.montserrat().fontFamily,color: Colors.black),
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    appBarTheme: AppBarTheme(
      iconTheme: const IconThemeData(color: Colors.black),
      color: Colors.white,
      elevation: 0.0,
      centerTitle: true, toolbarTextStyle: const TextTheme(
        headlineMedium: TextStyle(color: Colors.black,),).bodyMedium, 
        titleTextStyle: const TextTheme(headlineMedium: TextStyle( color: Colors.black,),).headlineMedium,
    ),
  );
}
