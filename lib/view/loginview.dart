import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:nuevoyapita/view/registerview.dart';
import 'package:nuevoyapita/view/widgets/buttonglobal.dart';
import 'package:nuevoyapita/view/widgets/sociallogin.dart';
import 'package:nuevoyapita/view/widgets/textformglobal.dart';
import '../utils/globalcolors.dart';
import 'appnavigationlayout.dart'; // Importa el AppNavigationLayout

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _signIn(BuildContext context) async {
    try {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        Get.snackbar(
          'Error',
          'Por favor completa todos los campos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      await authService.value.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.back(); // Cierra el loading

      // Navega al AppNavigationLayout en lugar de mostrar solo un Snackbar
      Get.offAll(() => const AppNavigationLayout());

    } on FirebaseAuthException catch (e) {
      Get.back(); // Cierra el loading

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        default:
          errorMessage = 'Error en el inicio de sesión: ${e.message}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Cierra el loading

      Get.snackbar(
        'Error',
        'Ocurrió un error inesperado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logo222.png',
                    width: 200, // Ajusta el tamaño según necesites
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  'Ingresa tu cuenta',
                  style: TextStyle(
                    color: GlobalColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 15),
                // Campo de email
                TextFormGlobal(
                  controller: emailController,
                  text: 'Correo',
                  obscure: false,
                  textInputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextFormGlobal(
                  controller: passwordController,
                  text: 'Contraseña',
                  obscure: true,
                  textInputType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () => _signIn(context),
                  child: const ButtonGlobal(),
                ),
                const SizedBox(height: 25),
                const SocialLogin(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 150,
        color: Colors.white,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Don\'t have an account?'),
            InkWell(
              onTap: () {
                Get.to(() => const RegisterView()); // Navegación al registro
              },
              child: Text(
                ' Sign Up',
                style: TextStyle(
                  color: GlobalColors.mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
