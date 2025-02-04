import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ItemDetail_repository.dart';
import 'Item_detail_state.dart';

class ItemDetailProvider with ChangeNotifier {
  ItemDetailState _state = ItemDetailState.initial();
  ItemDetailState get state => _state;

  final ItemDetailRepository itemDetailRepository;
  StreamSubscription<Item?>? _itemSubscription;

  Item? itemData; // 🔹 실시간으로 가져온 아이템 데이터

  ItemDetailProvider({required this.itemDetailRepository});

  /// 🔹 Firestore 실시간 데이터 감지 시작
  void listenToItemDetail({required String itemId}) {
    _state = _state.copyWith(itemDetailStatus: ItemDetailStatus.loading);
    notifyListeners();

    try {
      _itemSubscription = itemDetailRepository
          .streamItemWithSubItems(
            collectionName: 'Items',
            subcollectionName: 'Sub_Items',
            itemId: itemId,
          )
          .listen((Item? item) {
        if (item != null) {
          itemData = item;
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

  /// 🔹 Firestore 스트림 해제
  void cancelSubscriptions() {
    _itemSubscription?.cancel();
  }
}
