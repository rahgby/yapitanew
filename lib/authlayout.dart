import 'package:flutter/material.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:nuevoyapita/view/appnavigationlayout.dart';
import 'package:nuevoyapita/view/loginview.dart';
import 'package:nuevoyapita/view/welcomepage.dart';
import 'package:nuevoyapita/view/widgets/apploadingpage.dart';

class AuthLayout extends StatelessWidget{
  const AuthLayout({
    super.key,
    this.pageIfNotConnected,
});
  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
 return ValueListenableBuilder(
   valueListenable: authService,
   builder: (context, authService, child){
    return StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot){
      Widget widget;
      if (snapshot.connectionState==ConnectionState.waiting){
        widget=AppLoadingPage();
      }
      else if(snapshot.hasData){
        widget = const AppNavigationLayout();
      }
      else {
        widget = pageIfNotConnected ?? LoginView();
      }
      return widget;

    },
    );
   },
 );
  }
}