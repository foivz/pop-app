// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/add_store_content/package_creation_form/package_creation_1.dart';
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/add_store_content/package_creation_form/package_creation_2.dart';
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/sales_menu.dart';
import 'package:pop_app/models/user.dart';

import 'package:flutter/material.dart';

class PackageCreationTab extends StatefulWidget {
  final GlobalKey<SalesMenuScreenState> salesMenuKey;

  final User user;
  final GlobalKey productListKey;

  const PackageCreationTab({
    super.key,
    required this.salesMenuKey,
    required this.productListKey,
    required this.user,
  });

  static PackageCreationTabState? of(BuildContext context) {
    try {
      return context.findAncestorStateOfType<PackageCreationTabState>();
    } catch (err) {
      return null;
    }
  }

  @override
  State<PackageCreationTab> createState() => PackageCreationTabState();
}

class PackageCreationTabState extends State<PackageCreationTab> with AutomaticKeepAliveClientMixin {
  late PackageCreation2 packageCreation;
  @override
  void initState() {
    super.initState();
    packageCreation = PackageCreation2(productListKey: widget.productListKey, user: widget.user);
  }

  bool showBottomSheet = false;

  void showProductSelectionScreen() => setState(() => showBottomSheet = true);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (showBottomSheet)
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          showModalBottomSheet(
            context: context,
            builder: (_) => packageCreation,
            isScrollControlled: true,
            useSafeArea: true,
          ).then((value) {
            Navigator.pop(context, true);
          });
        },
      );
    GlobalKey<PackageCreationTabState> key = GlobalKey<PackageCreationTabState>();
    return Scaffold(
      key: key,
      backgroundColor: Colors.white,
      body: const PackageCreation1(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}