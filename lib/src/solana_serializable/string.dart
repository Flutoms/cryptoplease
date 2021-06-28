import 'dart:convert';

import 'package:solana/src/solana_serializable/solana_serializable.dart';

class SerializableString extends Serializable {
  SerializableString(String string) : _value = utf8.encode(string);

  final List<int> _value;

  int get size => _value.length;

  @override
  List<int> serialize() => _value;
}