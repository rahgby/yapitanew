import 'package:flutter/material.dart';

class TextFormGlobal extends StatelessWidget {
  TextFormGlobal ({Key? key,required this.controller, required this.text, required this.textInputType, required this.obscure}): super(key:key);
  final TextEditingController controller;
  final String text;
  final TextInputType textInputType;
  final bool obscure;

  @override
  Widget build(BuildContext context){
    return Container(
      height: 50,
      padding: const EdgeInsets.only(top:3,left:15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,

          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType,
        obscureText: obscure,
        validator: (value) {
          if (text.toLowerCase().contains('email') && value != null && value.isNotEmpty) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Por favor ingresa un email válido';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: text,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(0),
          hintStyle: const TextStyle(
            height: 1,
          ),
        ),
      ),
   );
  }
}