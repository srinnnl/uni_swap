import 'package:flutter/material.dart';
import 'package:uni_swap/controller/app_controllers.dart';
import 'package:uni_swap/view/login.dart';

void main() {
  setupControllers();
  // debugShowCheckedModeBanner
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage()));
}
