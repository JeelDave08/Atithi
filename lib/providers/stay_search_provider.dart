import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stay_search.dart';

class StaySearchNotifier extends Notifier<StaySearch?> {
  @override
  StaySearch? build() => null;
  void save(StaySearch search) => state = search;
  void clear() => state = null;
}

final staySearchProvider = NotifierProvider<StaySearchNotifier, StaySearch?>(
  StaySearchNotifier.new,
);
