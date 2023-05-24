import 'package:pop_app/role_selection/role_selection_widget.dart';

import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _lockSnackbar = false;
  @override
  Widget build(BuildContext context) {
    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    GlobalKey roleSelectWidgetKey = GlobalKey();
    return Scaffold(
      appBar: AppBar(title: const Text("Role selection")),
      body: Container(
        margin: EdgeInsets.only(bottom: isPortrait ? 60 : 0),
        child: RoleSelectWidget(key: roleSelectWidgetKey),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var roleSelect = roleSelectWidgetKey.currentState as RoleSelectWidgetState;
          String selectedOption = roleSelect.selectedOption;
          if (selectedOption == '') {
            if (!_lockSnackbar) {
              _lockSnackbar = true;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                dismissDirection: DismissDirection.down,
                content: Text("You must select a role."),
                duration: Duration(seconds: 1),
              ));
              Future.delayed(const Duration(seconds: 1), () => _lockSnackbar = false);
            }
          } else {
            showAboutDialog(context: context);
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
