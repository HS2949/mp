import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/item_model.dart';
import '../../repositories/Item_detail_repository.dart';
import 'Item_detail_state.dart';

class ItemDetailProvider with ChangeNotifier {
  final ItemDetailRepository itemDetailRepository;

  final Map<String, StreamSubscription<Item?>> _subscriptions =
      {}; // 🔹 itemId별 Stream 관리
  final Map<String, Item?> _items = {}; // 🔹 itemId별 데이터 저장
  final Map<String, ItemDetailState> _states = {}; // 🔹 itemId별 상태 관리

  ItemDetailProvider({required this.itemDetailRepository});

  /// 🔹 특정 itemId의 상태 가져오기
  ItemDetailState getState(String itemId) {
    return _states[itemId] ?? ItemDetailState.initial();
  }

  bool _isToggleAllGroup = false;
  bool get isToggleAllGroup => _isToggleAllGroup;

  bool _isToggleAllItem = false;
  bool get isToggleAllItem => _isToggleAllItem;

  void toggleAllGroup() {
    _isToggleAllGroup = !_isToggleAllGroup;
    notifyListeners();
  }

  void setToggleAllGroup(bool value) {
    _isToggleAllGroup = value;
    notifyListeners();
  }

  void toggleAllItem() {
    _isToggleAllItem = !_isToggleAllItem;
    notifyListeners();
  }

  /// 🔹 특정 itemId의 데이터 가져오기
  Item? getItemData(String itemId) {
    return _items[itemId];
  }

  /// 🔹 Firestore 실시간 데이터 감지 (탭마다 고유한 Stream 유지)
  void listenToItemDetail({required String itemId}) {
    if (_subscriptions.containsKey(itemId)) return; // 이미 구독 중이면 재구독 방지

    _states[itemId] = ItemDetailState.initial()
        .copyWith(itemDetailStatus: ItemDetailStatus.loading);
    notifyListeners();

    try {
      // 🔹 Firestore 아이템 + subItems 함께 구독
      _subscriptions[itemId] = itemDetailRepository
          .streamItemWithSubItems(
        collectionName: 'Items',
        subcollectionName: 'Sub_Items',
        itemId: itemId,
      )
          .listen((Item? item) {
        if (item != null) {
          _items[itemId] = item;
          _states[itemId] = _states[itemId]!
              .copyWith(itemDetailStatus: ItemDetailStatus.loaded);
        } else {
          _states[itemId] = _states[itemId]!.copyWith(
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
        _states[itemId] = _states[itemId]!.copyWith(
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
      _states[itemId] = _states[itemId]!.copyWith(
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

  /// 🔹 특정 itemId의 Stream 해제 (탭이 닫힐 때)
  void cancelSubscription(String itemId) {
    _subscriptions[itemId]?.cancel();
    _subscriptions.remove(itemId);
    _items.remove(itemId);
    _states.remove(itemId);
    notifyListeners();
  }

  /// 🔹 모든 구독 해제 (전체 탭 닫을 때)
  void cancelAllSubscriptions() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _items.clear();
    _states.clear();
    notifyListeners();
  }
}
