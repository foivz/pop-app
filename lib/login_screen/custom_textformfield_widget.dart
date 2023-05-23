// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:pop_app/myconstants.dart';

import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final String inputLabel;
  final TextEditingController textEditingController;
  final bool obscureText;
  final EdgeInsets padding;
  final bool autoFocus;
  final Function(String value)? submitCallback;
  final TextInputAction textInputAction;

  const CustomTextFormField({
    super.key,
    this.obscureText = false,
    required this.inputLabel,
    required this.textEditingController,
    this.padding = const EdgeInsets.fromLTRB(10, 0, 10, 10),
    this.autoFocus = false,
    this.submitCallback,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool isFocused = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      color: MyConstants.textfieldBackground,
      width: MyConstants.textFieldWidth,
      padding: widget.padding,
      child: Stack(children: [
        TextFormField(
          autofocus: widget.autoFocus,
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            labelText: widget.inputLabel,
            floatingLabelStyle: MaterialStateTextStyle.resolveWith(
              (states) => const TextStyle(color: MyConstants.accentColor),
            ),
            labelStyle: MaterialStateTextStyle.resolveWith(
              (states) => TextStyle(
                color: MyConstants.red,
                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: MyConstants.accentColor),
            ),
            contentPadding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
            suffixIcon: widget.textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () => setState(() {
                      widget.textEditingController.clear();
                    }),
                  )
                : null,
          ),
          textInputAction: widget.textInputAction,
          controller: widget.textEditingController,
          validator: (value) {
            return value == null || value.isEmpty
                ? 'Please enter a valid ${widget.inputLabel.toLowerCase()}'
                : null;
          },
          onTap: () => setState(() => isFocused = true),
          onChanged: (_) => setState(() => isFocused = true),
        ),
      ]),
    );
  }
}