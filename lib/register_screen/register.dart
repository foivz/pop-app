import 'package:flutter/material.dart';
import 'package:pop_app/models/user.dart';
import 'package:pop_app/register_screen/register_screen_1.dart';
import 'package:pop_app/register_screen/register_screen_2.dart';
import 'package:pop_app/register_screen/register_screen_3.dart';
import 'package:pop_app/screentransitions.dart';

class RegisterScreen extends StatefulWidget {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatedPasswordController =
      TextEditingController();
  final User user = User.empty();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  static RegisterScreenState? of(BuildContext context) {
    try {
      return context.findAncestorStateOfType<RegisterScreenState>();
    } catch (err) {
      return null;
    }
  }

  RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  int _previousCurrentStep = 0;
  int _currentStep = 0;
  final roleSelectionWidgetKey = GlobalKey();
  final List<Widget> _registerScreens = [];

  void showNextRegisterScreen() {
    setState(() {
      if (_currentStep < _registerScreens.length - 1) {
        _previousCurrentStep = _currentStep;
        _currentStep++;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _registerScreens.add(FirstRegisterScreen(widget));
    _registerScreens.add(SecondRegisterScreen(widget));
    _registerScreens.add(ThirdRegisterScreen(widget));
  }

  _animatedSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder:
          ScreenTransitions.navAnimH(_currentStep > _previousCurrentStep),
      reverseDuration: const Duration(milliseconds: 0),
      child: _registerScreens[_currentStep],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          bool tryingToExitRegister = _currentStep == 0;
          setState(() {
            if (_currentStep > 0) {
              _previousCurrentStep = _currentStep;
              _currentStep--;
            }
          });
          return tryingToExitRegister;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Register yourself'),
            ),
            body: Center(child: _animatedSwitcher())));
  }
}
