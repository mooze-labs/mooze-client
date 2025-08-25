import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MerchantModeScreen extends StatefulWidget {
  @override
  MerchantModeScreenState createState() => MerchantModeScreenState();
}

class MerchantModeScreenState extends State<MerchantModeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double valorReais = 0;
  double valorBitcoin = 0;
  String valorDigitado = '0.00';
  List<Item> produtos = [
    Item(nome: 'Produto 01', preco: 3.00, quantidade: 0),
    Item(nome: 'Produto 02', preco: 40.00, quantidade: 1),
    Item(nome: 'Produto 03', preco: 2.50, quantidade: 4),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _adicionarNumero(String numero) {
    setState(() {
      if (valorDigitado == '0.00') {
        valorDigitado = numero;
      } else {
        String valorLimpo = valorDigitado
            .replaceAll('.', '')
            .replaceAll(',', '');
        valorLimpo += numero;
        double valor = double.parse(valorLimpo) / 100;
        valorDigitado = valor.toStringAsFixed(2);
      }
    });
  }

  void _apagarNumero() {
    setState(() {
      if (valorDigitado.length > 1) {
        String valorLimpo = valorDigitado
            .replaceAll('.', '')
            .replaceAll(',', '');
        if (valorLimpo.length > 1) {
          valorLimpo = valorLimpo.substring(0, valorLimpo.length - 1);
          double valor = double.parse(valorLimpo) / 100;
          valorDigitado = valor.toStringAsFixed(2);
        } else {
          valorDigitado = '0.00';
        }
      } else {
        valorDigitado = '0.00';
      }
    });
  }

  void _mostrarBottomSheet() {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Adicionar Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: nomeController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome do produto',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: precoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Preço (R\$)',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nomeController.text.isNotEmpty &&
                              precoController.text.isNotEmpty) {
                            setState(() {
                              produtos.add(
                                Item(
                                  nome: nomeController.text,
                                  preco:
                                      double.tryParse(precoController.text) ??
                                      0.0,
                                  quantidade: 0,
                                ),
                              );
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Adicionar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEA1E63), Color(0xFF841138)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            context.pop();
                          },
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Text(
                          'Modo comerciante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.download, color: Colors.white, size: 24),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'R\$${valorReais.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${valorBitcoin.toStringAsFixed(6)} BTC',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 16),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.pink,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.grid_3x3), Text('Keypad')],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [Icon(Icons.grid_3x3), Text('Itens')],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildKeypadTab(), _buildItensTab()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadTab() {
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
          SizedBox(
            width: 320,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              children: [
                for (int i = 1; i <= 9; i++)
                  _buildKeypadButton(
                    text: i.toString(),
                    onPressed: () => _adicionarNumero(i.toString()),
                  ),
                _buildKeypadButton(
                  icon: Icons.backspace_outlined,
                  onPressed: _apagarNumero,
                  color: Colors.pink,
                ),
                _buildKeypadButton(
                  text: '0',
                  onPressed: () => _adicionarNumero('0'),
                ),
                _buildKeypadButton(
                  icon: Icons.add,
                  onPressed: () {
                    setState(() {
                      valorReais += 2;
                    });
                  },
                  color: Colors.green,
                ),
              ],
            ),
          ),
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

  Widget _buildItensTab() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView.separated(
          itemCount: produtos.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final produto = produtos[index];
            return Slidable(
              key: Key(produto.nome + index.toString()),
              endActionPane: ActionPane(
                motion: ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => _editarItem(index),
                    backgroundColor: AppColors.editColor.withValues(alpha: 0.3),
                    foregroundColor: AppColors.editColor,
                    icon: Icons.edit,
                  ),
                  SlidableAction(
                    onPressed: (context) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text(
                                'Deletar item',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Deseja realmente deletar "${produto.nome}"?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Deletar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirm ?? false) {
                        setState(() {
                          produtos.removeAt(index);
                        });
                      }
                    },
                    backgroundColor: AppColors.errorColor.withValues(
                      alpha: 0.3,
                    ),
                    foregroundColor: AppColors.errorColor,
                    icon: Icons.delete,
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produto.nome,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'R\$ ${produto.preco.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (produto.quantidade > 0) {
                              setState(() {
                                produto.quantidade--;
                              });
                            }
                          },
                          icon: Icon(
                            Icons.remove,
                            color:
                                produto.quantidade < 1
                                    ? AppColors.errorColor.withValues(
                                      alpha: 0.3,
                                    )
                                    : AppColors.errorColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          produto.quantidade.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              produto.quantidade++;
                            });
                          },
                          icon: Icon(
                            Icons.add,
                            color: AppColors.positiveColor,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _mostrarBottomSheet,
          backgroundColor: Color(0xFFE91E63),
          elevation: 8,
          child: Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  void _editarItem(int index) {
    final produto = produtos[index];
    final nomeController = TextEditingController(text: produto.nome);
    final precoController = TextEditingController(
      text: produto.preco.toString(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editar Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: nomeController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome do produto',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: precoController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Preço (R\$)',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nomeController.text.isNotEmpty &&
                              precoController.text.isNotEmpty) {
                            setState(() {
                              produto.nome = nomeController.text;
                              produto.preco =
                                  double.tryParse(precoController.text) ?? 0.0;
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Salvar'),
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

class Item {
  String nome;
  double preco;
  int quantidade;

  Item({required this.nome, required this.preco, required this.quantidade});
}
