import 'package:flutter/material.dart';
class MyTextField extends StatelessWidget
{
  final  controller;
  final String hintText;
  final bool obscureText;
  final prefixIcon;
  final Function(String)? onChanged;
  final max_length;
  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.prefixIcon,
    this.onChanged,
    this.max_length, TextInputType? keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              onChanged: onChanged,
              maxLength: max_length,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color:Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                fillColor: Colors.grey.shade200,
                filled:true,
                hintText: hintText,
                hintStyle: TextStyle(color:Colors.grey[500]),
                prefixIcon :prefixIcon,
                
              ),
            ),
          );
  }
}