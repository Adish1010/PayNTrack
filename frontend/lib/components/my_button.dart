import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final bool enabled;
  final String text;
  const MyButton({super.key, required this.onTap,required this.text,this.enabled=true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled?onTap:null,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: enabled?Colors.black:Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}