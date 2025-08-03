// import 'package:flutter/material.dart';
// import 'package:mooze_mobile/features/send_funds/data/asset_data_screen.dart';

// class AmountModal extends StatefulWidget {
//   final AssetDataScreen asset;
//   final Function(String) onAmountSet;

//   const AmountModal({super.key, required this.asset, required this.onAmountSet});

//   @override
//   State<AmountModal> createState() => _AmountModalState();
// }

// class _AmountModalState extends State<AmountModal> {
//   final TextEditingController _controller = TextEditingController();

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _handleConfirm() {
//     if (_controller.text.trim().isNotEmpty) {
//       widget.onAmountSet(_controller.text.trim());
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//       ),
//       child: Container(
//         decoration: const BoxDecoration(
//           color: Color(0xFF1F1F1F),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Definir Quantia',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),

//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Quantia em ${widget.asset.symbol}',
//                   style: const TextStyle(
//                     color: Color(0xFF9CA3AF),
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _controller,
//                   keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true,
//                   ),
//                   autofocus: true,
//                   style: const TextStyle(color: Colors.white, fontSize: 18),
//                   decoration: InputDecoration(
//                     hintText: '0.00',
//                     hintStyle: const TextStyle(
//                       color: Color(0xFF6B7280),
//                       fontSize: 18,
//                     ),
//                     filled: true,
//                     fillColor: const Color(0xFF111827),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: Color(0xFF374151)),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: Color(0xFFEC4899)),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(color: Color(0xFF374151)),
//                     ),
//                     contentPadding: const EdgeInsets.all(16),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),

//             Row(
//               children: [
//                 Expanded(
//                   child: TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: TextButton.styleFrom(
//                       backgroundColor: const Color(0xFF111827),
//                       foregroundColor: const Color(0xFF9CA3AF),
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Cancelar',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed:
//                         _controller.text.trim().isNotEmpty
//                             ? _handleConfirm
//                             : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFEC4899),
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       disabledBackgroundColor: const Color(0xFF374151),
//                     ),
//                     child: const Text(
//                       'OK',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // new

import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class AmountModal extends StatefulWidget {
  final Function(String) onAmountSet;

  const AmountModal({super.key, required this.onAmountSet});

  @override
  State<AmountModal> createState() => _AmountModalState();
}

class _AmountModalState extends State<AmountModal> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAmountSet(_controller.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Definir Quantia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quantia em BTC',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.pinBackground,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: 'OK',
                    onPressed: _handleConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
