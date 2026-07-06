import 'package:flutter/material.dart';
import 'package:wallrio/provider/export.dart';
import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class PlusSubscription extends StatelessWidget {
  const PlusSubscription({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          _headerUI(context),
          _featureUI(context),
          _productList(),
          _buildQueryUI(context),
          // _buildBuyBtnUI(context),
          // _buildRestoreBtn(context)
        ],
      ),
    );
  }

  Padding _buildQueryUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Please contact us for any payment related queries.",
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () =>
                LaunchUrlWidget.launchEmail("teamshadowsupp@gmail.com"),
            child: Text("teamshadowsupp@gmail.com",
                style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }

  Widget _productList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      child: Ink(
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFE376), Color(0xFFF7B540)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(20)),
        child: Consumer<SubscriptionProvider>(builder: (context, provider, _) {
          return Theme(
            data: WallRioThemeData.getLightThemeData(
                isDarkTheme: false, context: context),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: provider.products
                    .where((product) => !product.id.contains('collection'))
                    .map((product) => _buildSubscriptonTile(context,
                        product: product,
                        activeSubscription: provider.subscriptionDaysLeft))
                    .toList(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _featureUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
      child: Column(
        children: [
          _buildPlusFeature(context: context, feature: "Ad-free experience."),
          _buildPlusFeature(
              context: context, feature: "Unlock Plus collections."),
          _buildPlusFeature(
              context: context, feature: "Maximum Quality Upto 8k.")
        ],
      ),
    );
  }

  Container _headerUI(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Theme.of(context).navigationBarTheme.indicatorColor,
      ),
      child: Stack(
        children: [
          Image.asset("assets/watermark.png"),
          Column(
            children: [
              Image.asset("assets/app_icon/icon-foreground.png", height: 90),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Consumer<DarkThemeProvider>(builder: (context, provider, _) {
                    return GradientText(
                      " WallRio ",
                      style: Theme.of(context).textTheme.displayLarge,
                      colors: gradientColorMap[provider.gradType]!,
                    );
                  }),
                  Text(
                    "Plus",
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(color: whiteColor),
                  ),
                  const SizedBox(width: 12),
                  _buildPlusIcon(size: 24)
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(right: 10, top: 10),
                child: CloseButton(color: whiteColor),
              ))
        ],
      ),
    );
  }

  RadioListTile<String> _buildSubscriptonTile(BuildContext context,
      {required ProductDetails product, required String activeSubscription}) {
    return RadioListTile(
      value: product.id,
      groupValue: activeSubscription,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      onChanged: (val) =>
          Provider.of<SubscriptionProvider>(context, listen: false)
              .buyProduct(product),
      title: Row(
        children: [
          Expanded(child: Text(product.title)),
          Text(product.price),
        ],
      ),
      isThreeLine: true,
      subtitle: Text(
        product.description,
        style:
            Theme.of(context).textTheme.labelSmall!.copyWith(color: blackColor),
      ),
    );
  }

  Row _buildPlusFeature(
      {required BuildContext context, required String feature}) {
    return Row(
      children: [
        _buildPlusIcon(size: 16),
        const SizedBox(width: 10),
        Text(
          feature,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  Padding _buildPlusIcon({required double size}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Image.asset("assets/plus_icon.png", height: size),
    );
  }
}
