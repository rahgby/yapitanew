import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/globalcolors.dart';
import 'loginview.dart';
import 'package:get/get.dart';



class SplashView extends StatelessWidget{
  const SplashView({Key? key}) : super(key:key);
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 2), () {
      Get.off(() => LoginView());
    });


    return Scaffold(
      backgroundColor:  GlobalColors.mainColor,
      body: const Center(
        child: Text(
          'Logo',
          style:TextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

    );
  }
}