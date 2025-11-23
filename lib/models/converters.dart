import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Offset offset) {
    return {
      'dx': offset.dx,
      'dy': offset.dy,
    };
  }
}

class SizeConverter implements JsonConverter<Size, Map<String, dynamic>> {
  const SizeConverter();

  @override
  Size fromJson(Map<String, dynamic> json) {
    return Size(
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Size size) {
    return {
      'width': size.width,
      'height': size.height,
    };
  }
}

class OffsetListConverter implements JsonConverter<List<Offset>, List<dynamic>> {
  const OffsetListConverter();

  @override
  List<Offset> fromJson(List<dynamic> json) {
    return json.map((item) {
      final map = item as Map<String, dynamic>;
      return Offset(
        (map['dx'] as num).toDouble(),
        (map['dy'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  List<dynamic> toJson(List<Offset> offsets) {
    return offsets.map((offset) => {
      'dx': offset.dx,
      'dy': offset.dy,
    }).toList();
  }
}
