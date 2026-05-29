// lib/core/map/country_borders.dart
//
// Loads the Natural Earth 110m country borders GeoJSON from assets and
// converts them into flutter_map Polygon objects.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class CountryPolygons {
  final String iso;  // lowercase ISO-3166-1 alpha-2
  final String name; // display name from GeoJSON
  final List<List<LatLng>> rings; // outer ring + holes

  const CountryPolygons({
    required this.iso,
    required this.name,
    required this.rings,
  });
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

class CountryBordersService {
  CountryBordersService._();

  static List<CountryPolygons>? _cache;

  /// Loads and parses the GeoJSON once; subsequent calls return the cache.
  static Future<List<CountryPolygons>> load() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle
        .loadString('assets/geo/countries_110m.geojson');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;

    final result = <CountryPolygons>[];

    for (final feat in features) {
      final props = feat['properties'] as Map<String, dynamic>;
      final iso  = (props['iso']  as String? ?? 'xx').toLowerCase();
      final name = (props['name'] as String? ?? '');
      final geom = feat['geometry'] as Map<String, dynamic>;
      final type = geom['type'] as String;
      final coords = geom['coordinates'] as List<dynamic>;

      if (type == 'Polygon') {
        final rings = _parsePolygon(coords);
        if (rings.isNotEmpty) result.add(CountryPolygons(iso: iso, name: name, rings: rings));
      } else if (type == 'MultiPolygon') {
        for (final poly in coords) {
          final rings = _parsePolygon(poly as List<dynamic>);
          if (rings.isNotEmpty) result.add(CountryPolygons(iso: iso, name: name, rings: rings));
        }
      }
    }

    _cache = result;
    return result;
  }

  static List<List<LatLng>> _parsePolygon(List<dynamic> rings) {
    return rings.map((ring) {
      final pts = ring as List<dynamic>;
      return pts.map((pt) {
        final c = pt as List<dynamic>;
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Build flutter_map Polygon list
  // ---------------------------------------------------------------------------

  /// Returns a typed [Polygon<String>] list for use with [PolygonLayer].
  ///
  /// [visitedIsos]  — set of lowercase ISO codes the user has visited.
  /// [showLabels]   — whether to render the country name label inside each polygon.
  static List<Polygon<String>> buildPolygons({
    required List<CountryPolygons> countries,
    required Set<String> visitedIsos,
    bool showLabels = false,
  }) {
    const visitedFill     = Color(0xAA22C55E); // green, 67 % opacity
    const unvisitedFill   = Color(0x22888888); // grey, 13 % opacity
    const visitedBorder   = Color(0xFF16A34A); // darker green border
    const unvisitedBorder = Color(0xFF555555); // subtle grey border

    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
    );

    // Track which ISOs have already received a label so multi-polygon countries
    // only get labelled once (on their largest / first polygon).
    final labelledIsos = <String>{};
    final polygons = <Polygon<String>>[];

    for (final cp in countries) {
      final visited = visitedIsos.contains(cp.iso);
      final fill    = visited ? visitedFill   : unvisitedFill;
      final border  = visited ? visitedBorder : unvisitedBorder;

      final outer = cp.rings.isNotEmpty ? cp.rings[0] : const <LatLng>[];
      final holes = cp.rings.length > 1 ? cp.rings.sublist(1) : null;

      if (outer.isEmpty) continue;

      // Give each ISO a label on its first polygon only.
      final wantLabel = showLabels && cp.name.isNotEmpty && !labelledIsos.contains(cp.iso);
      if (wantLabel) labelledIsos.add(cp.iso);

      polygons.add(Polygon<String>(
        points: outer,
        holePointsList: holes,
        color: fill,
        borderColor: border,
        borderStrokeWidth: visited ? 1.5 : 0.8,
        label: wantLabel ? cp.name : null,
        labelStyle: labelStyle,
        labelPlacement: PolygonLabelPlacement.polylabel,
        hitValue: cp.iso,
      ));
    }

    // Draw visited countries on top so their borders are always visible.
    polygons.sort((a, b) {
      final aV = a.color == visitedFill ? 1 : 0;
      final bV = b.color == visitedFill ? 1 : 0;
      return aV.compareTo(bV);
    });

    return polygons;
  }
}
