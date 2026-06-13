import '../../../../core/database/app_database.dart';
import '../../../../core/utils/search_text.dart';

class ProductSectionData {
  const ProductSectionData({required this.subcategory, required this.products});

  final Subcategory? subcategory;
  final List<Product> products;
}

List<ProductSectionData> buildProductSections(
  List<Subcategory> subcategories,
  List<Product> products,
) {
  return buildProductSectionsWithOptions(
    subcategories,
    products,
    includeEmptySubcategories: true,
  );
}

List<ProductSectionData> buildProductSectionsWithOptions(
  List<Subcategory> subcategories,
  List<Product> products, {
  required bool includeEmptySubcategories,
}) {
  final sections = [
    for (final subcategory in subcategories)
      if (includeEmptySubcategories ||
          products.any((product) => product.subcategoryId == subcategory.id))
        ProductSectionData(
          subcategory: subcategory,
          products: sortProductsForDisplay(
            products
                .where((product) => product.subcategoryId == subcategory.id)
                .toList(),
          ),
        ),
  ];

  sections.sort((a, b) {
    final countComparison = b.products.length.compareTo(a.products.length);
    if (countComparison != 0) {
      return countComparison;
    }

    return a.subcategory!.name.toLowerCase().compareTo(
      b.subcategory!.name.toLowerCase(),
    );
  });

  final uncategorizedProducts = products
      .where((product) => product.subcategoryId == null)
      .toList();

  if (uncategorizedProducts.isNotEmpty) {
    sections.add(
      ProductSectionData(
        subcategory: null,
        products: sortProductsForDisplay(uncategorizedProducts),
      ),
    );
  }

  return sections;
}

int totalProducts(List<ProductSectionData> sections) {
  return sections.fold(0, (total, section) => total + section.products.length);
}

List<Product> sortProductsForDisplay(List<Product> products) {
  if (products.length < 2) {
    return products;
  }

  final productsByBrand = <String, List<Product>>{};

  for (final product in products) {
    final brandKey = _productBrandKey(product);
    productsByBrand.putIfAbsent(brandKey, () => []).add(product);
  }

  final brandGroups = productsByBrand.values.toList()
    ..sort((a, b) {
      final priceComparison = _minPrice(a).compareTo(_minPrice(b));
      if (priceComparison != 0) {
        return priceComparison;
      }

      return _productBrandKey(a.first).compareTo(_productBrandKey(b.first));
    });

  return [for (final group in brandGroups) ..._sortBrandGroup(group)];
}

List<Product> filterProductsByQuery(List<Product> products, String query) {
  final cleanQuery = normalizeSearchText(query);
  if (cleanQuery.isEmpty) {
    return products;
  }

  return products.where((product) {
    return normalizeSearchText(product.name).contains(cleanQuery) ||
        (product.brand != null &&
            normalizeSearchText(product.brand!).contains(cleanQuery)) ||
        (product.description != null &&
            normalizeSearchText(product.description!).contains(cleanQuery));
  }).toList();
}

List<Product> _sortBrandGroup(List<Product> products) {
  return [...products]..sort((a, b) {
    final priceComparison = a.price.compareTo(b.price);
    if (priceComparison != 0) {
      return priceComparison;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}

double _minPrice(List<Product> products) {
  return products
      .map((product) => product.price)
      .reduce((value, element) => value < element ? value : element);
}

String _productBrandKey(Product product) {
  final brand = product.brand?.trim().toLowerCase();
  if (brand != null && brand.isNotEmpty) {
    return brand;
  }

  final words = product.name.trim().toLowerCase().split(RegExp(r'\s+'));
  return words.isEmpty ? product.name.toLowerCase() : words.first;
}
