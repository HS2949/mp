import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/Item_detail_repository.dart';
import 'Item_detail_state.dart';

class ItemDetailProvider with ChangeNotifier {
  ItemDetailState _state = ItemDetailState.initial();
  ItemDetailState get state => _state;

  final ItemDetailRepository itemDetailRepository;
  StreamSubscription<Item?>? _itemSubscription;

  Item? _itemData; // 🔹 Firestore에서 가져온 데이터 저장 (전역)
  Item? get itemData => _itemData; // 🔹 getter

  String? _currentItemId; // 현재 구독 중인 itemId

  ItemDetailProvider({required this.itemDetailRepository});

  /// 🔹 Firestore 실시간 데이터 감지 (한 번만 실행)
  void listenToItemDetail({required String itemId}) {
    // 🔹 동일한 ID로 요청하면 불필요한 Firestore 호출 방지
    if (_currentItemId == itemId) return;

    _currentItemId = itemId;
    _state = _state.copyWith(itemDetailStatus: ItemDetailStatus.loading);
    notifyListeners();

    try {
      // 🔹 기존 스트림 해제 (ID가 변경될 경우)
      _itemSubscription?.cancel();

      _itemSubscription = itemDetailRepository
          .streamItemWithSubItems(
            collectionName: 'Items',
            subcollectionName: 'Sub_Items',
            itemId: itemId,
          )
          .listen((Item? item) {
        if (item != null) {
          _itemData = item;
          _state = _state.copyWith(itemDetailStatus: ItemDetailStatus.loaded);
        } else {
          _state = _state.copyWith(
            itemDetailStatus: ItemDetailStatus.error,
            error: CustomError(
              code: 'NotFound',
              message: '아이템을 찾을 수 없습니다.',
              plugin: 'flutter_error/not_found',
            ),
          );
        }
        notifyListeners();
      }, onError: (error) {
        _state = _state.copyWith(
          itemDetailStatus: ItemDetailStatus.error,
          error: CustomError(
            code: 'StreamError',
            message: error.toString(),
            plugin: 'flutter_error/firestore_error',
          ),
        );
        notifyListeners();
      });
    } catch (e) {
      _state = _state.copyWith(
        itemDetailStatus: ItemDetailStatus.error,
        error: CustomError(
          code: 'Exception',
          message: e.toString(),
          plugin: 'flutter_error/server_error',
        ),
      );
      notifyListeners();
    }
  }

  /// 🔹 Firestore 스트림 해제 (필요할 때 호출)
  void cancelSubscriptions() {
    _itemSubscription?.cancel();
  }
}
