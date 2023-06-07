// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:pop_app/main_menu_screen/seller_screen/sales_menu/products_tab/product_data.dart';
import 'package:pop_app/myconstants.dart';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final int index;
  final ProductData product;
  const ProductCard({super.key, required this.index, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animCont;

  bool isSelected = false;

  void select() {
    HapticFeedback.selectionClick();
    setState(() {
      isSelected = !isSelected;
      if (isSelected)
        _animCont.forward();
      else
        _animCont.reverse();
    });
  }

  @override
  void initState() {
    super.initState();
    _animCont = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _animCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double width = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        InkWell(
          onTap: select,
          splashColor: MyConstants.red,
          focusColor: MyConstants.red.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          highlightColor: MyConstants.red.withOpacity(0.4),
          child: _card(width),
        ),
        _selectionMarker(),
      ],
    );
  }

  Align _selectionMarker() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(padding: const EdgeInsets.all(12.0), child: _animatedSelectionMarker()),
    );
  }

  AnimatedWidget _animatedSelectionMarker() {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_animCont),
      child: ScaleTransition(
        scale: Tween(begin: 0.0, end: 1.0).animate(_animCont),
        child: _iconWithBorder(),
      ),
    );
  }

  Container _iconWithBorder() => Container(decoration: _circleBorderDecoration(), child: _icon());

  BoxDecoration _circleBorderDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: isSelected ? MyConstants.red : Colors.grey, width: 3),
    );
  }

  Icon _icon() {
    return Icon(color: isSelected ? MyConstants.red : Colors.grey, Icons.attach_money);
  }

  Image _image(double width) {
    return Image.network(
      widget.product.imagePath ?? "",
      height: 128,
      width: width * 0.2,
    );
  }

  Card _card(double width) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black,
      elevation: 10,
      borderOnForeground: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          _image(width),
          _productText(width),
          _price(),
        ]),
      ),
    );
  }

  Container _productText(double width) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
      width: width * 0.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(height: 1.75),
          ),
          Text(widget.product.description, overflow: TextOverflow.fade),
        ],
      ),
    );
  }

  Text _price() {
    return Text(
      widget.product.price.toString(),
      style: const TextStyle(color: MyConstants.accentColor),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
