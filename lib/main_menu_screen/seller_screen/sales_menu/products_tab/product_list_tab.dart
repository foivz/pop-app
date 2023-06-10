// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/packages_tab/package_data.dart';
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/products_tab/product_data.dart';
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/products_tab/product_card.dart';
import 'package:pop_app/api_requests.dart';
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/sales_menu.dart';

import 'package:pop_app/models/user.dart';
import 'package:flutter/material.dart';

class ProductsTab extends StatefulWidget {
  final User user;
  final GlobalKey<SalesMenuScreenState>? salesMenuKey;
  final Function(int index, VariableProductData product)? wrapper;
  const ProductsTab({super.key, required this.user, this.salesMenuKey, this.wrapper});

  static ProductsTabState? of(BuildContext context) {
    try {
      return context.findAncestorStateOfType<ProductsTabState>();
    } catch (err) {
      return null;
    }
  }

  @override
  State<ProductsTab> createState() => ProductsTabState();
}

class ProductsTabState extends State<ProductsTab> {
  List<ConstantProductData> products = List.empty(growable: true);
  void reload() => setState(() {});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          products = PackageDataApiInterface.productsFromApi(snapshot.data!.last["DATA"]);
          return ListView.separated(
            itemCount: products.length,
            shrinkWrap: true,
            clipBehavior: Clip.hardEdge,
            separatorBuilder: (_, __) => const Divider(indent: 3, endIndent: 3, thickness: 0),
            padding: const EdgeInsets.all(5),
            itemBuilder: (context, index) {
              if (widget.wrapper != null) {
                products[index] = VariableProductData.withProduct(products[index]);
                return widget.wrapper!(index, products[index] as VariableProductData);
              } else
                return ProductCard(
                  index: index,
                  product: products[index],
                  salesMenuKey: widget.salesMenuKey!,
                  user: widget.user,
                );
            },
          );
        } else
          return const Center(child: CircularProgressIndicator());
      },
      future: ApiRequestManager.getAllProducts(widget.user),
    );
  }
}