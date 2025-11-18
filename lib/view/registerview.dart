import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:nuevoyapita/view/widgets/buttonglobal.dart';
import 'package:nuevoyapita/view/widgets/textformglobal.dart';
import '../utils/globalcolors.dart';
import 'appnavigationlayout.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController dniController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  DateTime? fechaNacimiento;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null && picked != fechaNacimiento) {
      setState(() {
        fechaNacimiento = picked;
      });
    }
  }

  Future<void> _signUp(BuildContext context) async {
    try {
      // Validaciones
      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          nombreController.text.isEmpty ||
          dniController.text.isEmpty ||
          telefonoController.text.isEmpty ||
          fechaNacimiento == null) {
        Get.snackbar(
          'Error',
          'Por favor completa todos los campos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        Get.snackbar(
          'Error',
          'Las contraseñas no coinciden',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (passwordController.text.length < 6) {
        Get.snackbar(
          'Error',
          'La contraseña debe tener al menos 6 caracteres',
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

      // Registrar usuario
      await authService.value.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        nombre: nombreController.text.trim(),
        dni: dniController.text.trim(),
        telefono: telefonoController.text.trim(),
        fechaNacimiento: fechaNacimiento!,
      );

      Get.back(); // Cierra el loading

      // Navega al home
      Get.offAll(() => const AppNavigationLayout());

    } on FirebaseAuthException catch (e) {
      Get.back(); // Cierra el loading

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este email';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Operación no permitida';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil';
          break;
        default:
          errorMessage = 'Error en el registro: ${e.message}';
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
        'Ocurrió un error inesperado: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: GlobalColors.mainColor,
        foregroundColor: Colors.white,
      ),
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
                  child: Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      color: GlobalColors.mainColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Campo de nombre completo
                TextFormGlobal(
                  controller: nombreController,
                  text: 'Nombre Completo',
                  obscure: false,
                  textInputType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                // Campo de DNI
                TextFormGlobal(
                  controller: dniController,
                  text: 'DNI',
                  obscure: false,
                  textInputType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                // Campo de teléfono
                TextFormGlobal(
                  controller: telefonoController,
                  text: 'Número de Teléfono',
                  obscure: false,
                  textInputType: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                // Selector de fecha de nacimiento
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: GlobalColors.mainColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          fechaNacimiento == null
                              ? 'Fecha de Nacimiento'
                              : '${fechaNacimiento!.day}/${fechaNacimiento!.month}/${fechaNacimiento!.year}',
                          style: TextStyle(
                            color: fechaNacimiento == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Campo de email
                TextFormGlobal(
                  controller: emailController,
                  text: 'Email',
                  obscure: false,
                  textInputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                // Campo de contraseña
                TextFormGlobal(
                  controller: passwordController,
                  text: 'Contraseña',
                  obscure: true,
                  textInputType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                // Campo de confirmar contraseña
                TextFormGlobal(
                  controller: confirmPasswordController,
                  text: 'Confirmar Contraseña',
                  obscure: true,
                  textInputType: TextInputType.text,
                ),
                const SizedBox(height: 25),
                InkWell(
                  onTap: () => _signUp(context),
                  child: const ButtonGlobal(text: 'Registrarse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}