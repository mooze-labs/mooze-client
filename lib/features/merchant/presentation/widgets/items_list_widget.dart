import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mooze_mobile/features/merchant/models/item.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class ItemsListWidget extends StatelessWidget {
  final List<Item> produtos;
  final Function(int) onEditarItem;
  final Function(int) onRemoverItem;
  final Function(int, bool) onAtualizarQuantidade;
  final VoidCallback onAdicionarItem;
  final GlobalKey? addButtonKey;
  final GlobalKey? firstProductKey;

  const ItemsListWidget({
    super.key,
    required this.produtos,
    required this.onEditarItem,
    required this.onRemoverItem,
    required this.onAtualizarQuantidade,
    required this.onAdicionarItem,
    this.addButtonKey,
    this.firstProductKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: produtos.isEmpty ? _buildEmptyState() : _buildProductsList(),
      floatingActionButton: SizedBox(
        key: addButtonKey,
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: onAdicionarItem,
          backgroundColor: Color(0xFFE91E63),
          elevation: 8,
          child: Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[600]),
            SizedBox(height: 20),
            Text(
              'Nenhum produto cadastrado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Comece adicionando seu primeiro produto\nclicando no botão + abaixo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.separated(
      padding: EdgeInsets.all(20).copyWith(bottom: 100),
      itemCount: produtos.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final produto = produtos[index];
        final isFirstProduct = index == 0 && firstProductKey != null;

        return Slidable(
          key:
              isFirstProduct
                  ? firstProductKey
                  : Key(produto.nome + index.toString()),
          endActionPane: ActionPane(
            motion: ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => onEditarItem(index),
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
                              onPressed: () => Navigator.pop(context, false),
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
                    onRemoverItem(index);
                  }
                },
                backgroundColor: AppColors.errorColor.withValues(alpha: 0.3),
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
                          onAtualizarQuantidade(index, false);
                        }
                      },
                      icon: Icon(
                        Icons.remove,
                        color:
                            produto.quantidade < 1
                                ? AppColors.errorColor.withValues(alpha: 0.3)
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
                        onAtualizarQuantidade(index, true);
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
    );
  }
}
