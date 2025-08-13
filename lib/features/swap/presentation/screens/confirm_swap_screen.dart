import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class ConfirmSwapBottomSheet extends StatefulWidget {
  const ConfirmSwapBottomSheet({super.key});

  @override
  State<ConfirmSwapBottomSheet> createState() => _ConfirmSwapBottomSheetState();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConfirmSwapBottomSheet(),
    );
  }
}

class _ConfirmSwapBottomSheetState extends State<ConfirmSwapBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'Confirmar Swap',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Spacer(),
                from(),
                const Spacer(),
                SlideToConfirmButton(
                  text: 'Confirmar Swap (5s)',
                  onSlideComplete: () {
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget from() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF2D2E2A), AppColors.primaryColor],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Você envia'),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/new_ui_wallet/assets/icons/asset/bitcoin.svg',
                            width: 15,
                            height: 15,
                          ),
                        ],
                      ),
                      Text('0.0001', style: Theme.of(context).textTheme.headlineSmall,),
                      Text('bitcoin'),
                    ],
                  ),
                  Expanded(
                    flex: 1,
                    child: SvgPicture.asset(
                      'assets/new_ui_wallet/assets/icons/menu/arrow.svg',
                      width: 25,
                      height: 25,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Você recebe'),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/new_ui_wallet/assets/icons/asset/depix.svg',
                            width: 15,
                            height: 15,
                          ),
                        ],
                      ),
                      Text('0.00015', style: Theme.of(context).textTheme.headlineSmall),
                      Text('drex'),
                    ],
                  ),
                ],
              ),
              const Divider(),
              const InfoRow(label: 'Taxa do servidor', value: '31 SATS'),
              const InfoRow(label: 'Taxa fixa', value: '80 SATS'),
              const InfoRow(label: 'Total de taxas', value: '111 SATS'),
            ],
          ),
        ),
      ),
    );
  }
}
