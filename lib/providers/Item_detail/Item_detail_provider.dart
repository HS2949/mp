import 'package:flutter/material.dart';
import 'package:mp_db/models/custom_error.dart';

import 'ItemDetail_repository.dart';
import 'Item_detail_state.dart';

class ItemDetailProvider with ChangeNotifier {
  ItemDetailState _state = ItemDetailState.initial();
  ItemDetailState get state => _state;

  final ItemDetailRepository itemdetailRepository;

  ItemDetailProvider({
    required this.itemdetailRepository,
  });

  /// 🔹 특정 아이템 ID를 기반으로 Firestore에서 데이터 가져오기
  Future<void> getItemDetail({required String itemId}) async {
    _state = _state.copyWith(itemDetailStatus: ItemDetailStatus.loading);
    notifyListeners();

    try {
      // Firestore에서 아이템 가져오기
      final Map<String, dynamic>? itemDetails = await itemdetailRepository
          .getItem(collectionName: 'Items', id: itemId);

      if (itemDetails != null) {
        _state = _state.copyWith(
          itemDetailStatus: ItemDetailStatus.loaded,
          itemData: itemDetails, // 🔹 가져온 데이터 저장
        );
      } else {
        throw CustomError(
          code: 'NotFound',
          message: '아이템을 찾을 수 없습니다.',
          plugin: 'flutter_error/not_found',
        );
      }
    } on CustomError catch (e) {
      _state = _state.copyWith(
        itemDetailStatus: ItemDetailStatus.error,
        error: e,
      );
    } catch (e) {
      _state = _state.copyWith(
        itemDetailStatus: ItemDetailStatus.error,
        error: CustomError(
          code: 'Exception',
          message: e.toString(),
          plugin: 'flutter_error/server_error',
        ),
      );
    }

    notifyListeners();
  }
}
