// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:pop_app/login_screen/company_data_container_widget.dart';

import 'package:flutter/material.dart';
import 'package:pop_app/role_selection/role_selection_screen.dart';
import 'package:pop_app/screentransitions.dart';

class CompanySelectionScreen extends StatefulWidget {
  final Function(String company) onCompanySelected;
  final bool showAppBar;
  final Map<int, String> companyNamesWithNoOfMembers;
  const CompanySelectionScreen(this.onCompanySelected, this.companyNamesWithNoOfMembers,
      {super.key, this.showAppBar = true});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  GlobalKey? selectedCompany;
  bool _lockSnackbar = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text("Company selection")) : null,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (selectedCompany == null) {
              if (!_lockSnackbar) {
                _lockSnackbar = true;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  dismissDirection: DismissDirection.down,
                  content: Text("You must select a company."),
                  duration: Duration(seconds: 1),
                ));
                Future.delayed(const Duration(seconds: 1), () => _lockSnackbar = false);
              }
            } else {
              var state = selectedCompany?.currentState;

              if (state != null) {
                widget.onCompanySelected((state as CompanyDataContainerState).widget.companyName);
              }
            }
          },
          child: const Icon(Icons.check),
        ),
        body: FutureBuilder(
          builder: (context, snapshot) {
            List<Widget> companies = [];
            if (snapshot.hasData) {
              (snapshot.data as Map).forEach((key, value) {
                GlobalKey companyKey = GlobalKey();
                companies.add(CompanyDataContainer(
                  key: companyKey,
                  companyName: value,
                  employeeCount: key,
                  onTapCallback: () {
                    state(o) => (((o.key as GlobalKey).currentState) as CompanyDataContainerState);
                    companies.where((company) => state(company).isSelected).forEach((company) {
                      state(company).select();
                    });
                    (companyKey.currentState as CompanyDataContainerState).select();
                    selectedCompany = companyKey;
                  },
                ));
              });
              return Scrollbar(
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.only(top: 15),
                    child: Column(children: companies),
                  ),
                ),
              );
            } else
              return const Center(child: CircularProgressIndicator());
          },
          initialData: widget.companyNamesWithNoOfMembers,
        ),
      ),
    );
  }
}
