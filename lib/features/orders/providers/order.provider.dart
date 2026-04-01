import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/order.model.dart';

class OrdersState {
  final List<OrderModel> buyerOrders;
  final List<OrderModel> sellerOrders;
  final bool isLoadingBuyer;
  final bool isLoadingSeller;
  final String? error;

  const OrdersState({
    this.buyerOrders = const [],
    this.sellerOrders = const [],
    this.isLoadingBuyer = false,
    this.isLoadingSeller = false,
    this.error,
  });

  OrdersState copyWith({
    List<OrderModel>? buyerOrders,
    List<OrderModel>? sellerOrders,
    bool? isLoadingBuyer,
    bool? isLoadingSeller,
    String? error,
  }) {
    return OrdersState(
      buyerOrders: buyerOrders ?? this.buyerOrders,
      sellerOrders: sellerOrders ?? this.sellerOrders,
      isLoadingBuyer: isLoadingBuyer ?? this.isLoadingBuyer,
      isLoadingSeller: isLoadingSeller ?? this.isLoadingSeller,
      error: error ?? this.error,
    );
  }
}

class OrdersNotifier extends Notifier<OrdersState> {
  @override
  OrdersState build() {
    return const OrdersState();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadBuyerOrders(),
      loadSellerOrders(),
    ]);
  }

  Future<void> loadBuyerOrders() async {
    state = state.copyWith(isLoadingBuyer: true);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/orders/my-orders');
      final ordersJson = response.data['data']['orders'] as List<dynamic>;
      final orders = ordersJson
          .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        buyerOrders: orders,
        isLoadingBuyer: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingBuyer: false);
    }
  }

  Future<void> loadSellerOrders() async {
    state = state.copyWith(isLoadingSeller: true);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/orders/incoming');
      final ordersJson = response.data['data']['orders'] as List<dynamic>;
      final orders = ordersJson
          .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        sellerOrders: orders,
        isLoadingSeller: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingSeller: false);
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final dio = ApiClient.instance;
      await dio.patch(
        '/orders/$orderId/status',
        data: {'status': status},
      );

      // Update seller orders list
      final updatedOrders = state.sellerOrders.map((o) {
        if (o.id == orderId) {
          return OrderModel.fromJson({
            ...o.toJson(),
            'status': status,
          });
        }
        return o;
      }).toList();

      state = state.copyWith(sellerOrders: updatedOrders);
    } catch (e) {
      // Failed silently
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      final dio = ApiClient.instance;
      await dio.patch(
        '/orders/$orderId/cancel',
        data: {'cancellation_reason': reason},
      );

      await loadAll();
    } catch (e) {
      // Failed silently
    }
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, OrdersState>(() {
  return OrdersNotifier();
});