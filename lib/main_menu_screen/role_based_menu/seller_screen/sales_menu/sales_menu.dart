import 'package:pop_app/main_menu_screen/role_based_menu/seller_screen/sales_menu/products_tab/products_tab.dart';
import 'package:pop_app/main_menu_screen/role_based_menu/seller_screen/sales_menu/packages_tab/packages_tab.dart';
import 'package:pop_app/main_menu_screen/role_based_menu/seller_screen/sales_menu/add_store_content/store_content_creation_menu.dart';

import 'package:flutter/material.dart';
import 'package:pop_app/main_menu_screen/role_based_menu/seller_screen/sales_menu/sell_items_screen.dart';
import 'package:pop_app/models/item.dart';
import 'package:pop_app/models/items_selected_for_selling.dart';
import 'package:pop_app/reusable_components/message.dart';
import 'package:pop_app/utils/seller_logic.dart';
import 'package:provider/provider.dart';

class SalesMenuScreen extends StatefulWidget {
  static late void Function(int selectedTab)? refreshTab;
  const SalesMenuScreen({super.key});

  @override
  State<SalesMenuScreen> createState() => SalesMenuScreenState();
}

class SalesMenuScreenState extends State<SalesMenuScreen> with TickerProviderStateMixin {
  late TabController tabController;
  late final GlobalKey _sellIconKey = GlobalKey();
  late AnimationController _animCont;
  int _selectedItemsCount = 0;

  void onSelectionStateChange(bool isSelected) {
    setState(() {
      isSelected ? _selectedItemsCount++ : _selectedItemsCount--;
    });
    if (_selectedItemsCount > 0) {
      _animCont.forward();
    } else {
      _animCont.reverse();
    }
  }

  late ProductsTab productsTab;
  late PackagesTab packagesTab;

  void generateNewProductsTabAndPackagesTabObjects() {
    productsTab = ProductsTab(onSelectionStateChange: onSelectionStateChange);
    packagesTab = PackagesTab(onSelectionStateChange: onSelectionStateChange);
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _animCont = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));

    SalesMenuScreen.refreshTab = (selectedTabIndex) {
      refreshAllProducts(context);
      loadTabContents();
      tabController.index = selectedTabIndex;
    };

    loadTabContents();
  }

  @override
  void dispose() {
    tabController.dispose();
    _animCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store content"),
        actions: [_salesButtonWithAnimations(), _createStoreContentButton()],
      ),
      body: tabs(),
    );
  }

  Widget _salesButtonWithAnimations() {
    Tween<double> tween = Tween(begin: 0.0, end: 1.0);
    return RotationTransition(
      turns: tween.animate(_animCont),
      child: ScaleTransition(
        scale: tween.animate(_animCont),
        // actual button
        child: _makeSaleButton(),
      ),
    );
  }

  Widget _makeSaleButton() {
    return IconButton(
      key: _sellIconKey,
      style: ButtonStyle(iconSize: MaterialStateProperty.resolveWith((states) => 24)),
      onPressed: _makeSaleMenu,
      icon: const Icon(Icons.attach_money),
    );
  }

  void _makeSaleMenu() {
    // if products are selected, open the sell items screen
    List<Item> selectedItems = List.from(productsTab.selectedItems);
    selectedItems.addAll(packagesTab.selectedItems);
    if (selectedItems.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return ChangeNotifierProvider<ItemsSelectedForSelling>(
          create: (context) => ItemsSelectedForSelling(selectedItems),
          child: const SellItemsScreen(),
        );
      }));
    } else {
      Message.error(context).show(
        "You can't sell products until you select them. Select products to sell them.",
      );
    }
  }

  Widget _createStoreContentButton() {
    return IconButton(onPressed: _createContentMenu, icon: const Icon(Icons.add));
  }

  void _createContentMenu() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      showModalBottomSheet(
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Scaffold(
              body: StoreContentCreation(selectedIndex: tabController.index),
            ),
          );
        },
      ).then((value) {
        if (value is bool) loadTabContents();
      });
    });
  }

  List<Widget> tabContents = List.empty(growable: true);
  bool loadTabContents() {
    generateNewProductsTabAndPackagesTabObjects();
    setState(() {
      tabContents = [Container()];
      tabContents = [productsTab, packagesTab];
    });
    return true;
  }

  Widget tabs() {
    return Column(
      children: [
        TabBar(controller: tabController, tabs: const <Tab>[
          Tab(text: "PRODUCTS"),
          Tab(text: "PACKAGES"),
        ]),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: tabContents,
          ),
        )
      ],
    );
  }
}
