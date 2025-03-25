import 'package:equatable/equatable.dart';
import '../../models/custom_error.dart';

enum ItemDetailStatus {
  initial,
  loading,
  loaded,
  error,
}

class ItemDetailState extends Equatable {
  final ItemDetailStatus itemDetailStatus;
  late final Map<String, dynamic>? itemData; // 🔹 Firestore에서 가져온 데이터를 저장할 필드 추가
  final CustomError error;

  ItemDetailState({
    required this.itemDetailStatus,
    this.itemData, // 🔹 Nullable로 설정
    required this.error,
  });

  factory ItemDetailState.initial() {
    return ItemDetailState(
      itemDetailStatus: ItemDetailStatus.initial,
      itemData: null, // 🔹 초기값을 null로 설정
      error: CustomError(),
    );
  }

  @override
  List<Object?> get props => [itemDetailStatus, itemData, error]; // 🔹 itemData 추가

  @override
  bool get stringify => true;

  ItemDetailState copyWith({
    ItemDetailStatus? itemDetailStatus,
    Map<String, dynamic>? itemData,
    CustomError? error,
  }) {
    return ItemDetailState(
      itemDetailStatus: itemDetailStatus ?? this.itemDetailStatus,
      itemData: itemData ?? this.itemData, // 🔹 itemData도 업데이트 가능하도록 설정
      error: error ?? this.error,
    );
  }
}
