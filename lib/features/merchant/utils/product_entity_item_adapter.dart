import 'package:mooze_mobile/features/merchant/models/item.dart';
import 'package:mooze_mobile/features/merchant/models/product.dart';

class ProductEntityItemAdapter {
  static ProductEntity fromItem(Item item) {
    return ProductEntity(
      name: item.nome,
      price: item.preco,
      createdAt: DateTime.now(),
    );
  }

  static Item toItem(ProductEntity product) {
    return Item(nome: product.name, preco: product.price, quantidade: 0);
  }

  static List<Item> toItemList(List<ProductEntity> products) {
    return products.map((product) => toItem(product)).toList();
  }

  static List<ProductEntity> fromItemList(List<Item> items) {
    return items.map((item) => fromItem(item)).toList();
  }
}
