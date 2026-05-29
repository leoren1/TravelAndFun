// lib/data/repositories/brand_repository.dart

import 'package:explore_index/data/models/brand.dart';

abstract class BrandRepository {
  /// All brands for a given country ID.
  List<Brand> getBrandsByCountry(String countryId);

  /// Distinct industry labels present for a country (sorted).
  List<String> getIndustriesForCountry(String countryId);
}
