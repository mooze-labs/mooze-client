import 'package:flutter/material.dart';

class KeypadWidget extends StatelessWidget {
  final String valorDigitado;
  final Function(String) onAdicionarNumero;
  final VoidCallback onApagarNumero;
  final VoidCallback onAdicionarAoTotal;
  final VoidCallback? onFinalizarVenda;
  final double? cartTotal;

  const KeypadWidget({
    super.key,
    required this.valorDigitado,
    required this.onAdicionarNumero,
    required this.onApagarNumero,
    required this.onAdicionarAoTotal,
    this.onFinalizarVenda,
    this.cartTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(top: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'R\$$valorDigitado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                children: [
                  for (int i = 1; i <= 9; i++)
                    _buildKeypadButton(
                      text: i.toString(),
                      onPressed: () => onAdicionarNumero(i.toString()),
                    ),
                  _buildKeypadButton(
                    icon: Icons.backspace_outlined,
                    onPressed: onApagarNumero,
                    color: Colors.pink,
                  ),
                  _buildKeypadButton(
                    text: '0',
                    onPressed: () => onAdicionarNumero('0'),
                  ),
                  _buildKeypadButton(
                    icon: Icons.add,
                    onPressed: onAdicionarAoTotal,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          if (onFinalizarVenda != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        (cartTotal != null && cartTotal! < 20.0)
                            ? [Colors.grey.shade600, Colors.grey.shade700]
                            : [Color(0xFFE91E63), Color(0xFFAD1457)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: ElevatedButton(
                  onPressed: onFinalizarVenda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Finalizar Venda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (cartTotal != null &&
                          cartTotal! > 0 &&
                          cartTotal! < 20.0)
                        Text(
                          'Mínimo R\$ 20,00',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      margin: EdgeInsets.all(4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            text != null
                ? Text(
                  text,
                  style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                )
                : Icon(icon, color: color ?? Colors.white, size: 24),
      ),
    );
  }
}
