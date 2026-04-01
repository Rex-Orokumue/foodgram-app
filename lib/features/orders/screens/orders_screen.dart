import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../providers/order.provider.dart';
import '../../../shared/models/order.model.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(ordersProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'My Orders (${state.buyerOrders.length})'),
            Tab(text: 'Incoming (${state.sellerOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyerOrders(state),
          _buildSellerOrders(state),
        ],
      ),
    );
  }

  Widget _buildBuyerOrders(OrdersState state) {
    if (state.isLoadingBuyer) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.buyerOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🛍️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Order food from posts in your feed',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadBuyerOrders(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.buyerOrders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(state.buyerOrders[index], isBuyer: true),
      ),
    );
  }

  Widget _buildSellerOrders(OrdersState state) {
    if (state.isLoadingSeller) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.sellerOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🍽️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No incoming orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Upgrade to a business account to receive orders',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersProvider.notifier).loadSellerOrders(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.sellerOrders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(state.sellerOrders[index], isBuyer: false),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isBuyer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBuyer
                            ? 'From ${order.sellerName}'
                            : 'From ${order.buyerName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.caption ?? 'Food order',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      order.formattedAmount,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (order.notes != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Seller actions
          if (!isBuyer && order.isActive) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  if (order.isPending)
                    _buildActionButton(
                      'Confirm',
                      AppColors.success,
                      () => ref
                          .read(ordersProvider.notifier)
                          .updateOrderStatus(order.id, 'confirmed'),
                    ),
                  if (order.isConfirmed)
                    _buildActionButton(
                      'Start Preparing',
                      AppColors.primary,
                      () => ref
                          .read(ordersProvider.notifier)
                          .updateOrderStatus(order.id, 'preparing'),
                    ),
                  if (order.isPreparing)
                    _buildActionButton(
                      'Mark Ready',
                      AppColors.primary,
                      () => ref
                          .read(ordersProvider.notifier)
                          .updateOrderStatus(order.id, 'ready'),
                    ),
                  if (order.isReady)
                    _buildActionButton(
                      'Mark Delivered',
                      AppColors.success,
                      () => ref
                          .read(ordersProvider.notifier)
                          .updateOrderStatus(order.id, 'delivered'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref
                        .read(ordersProvider.notifier)
                        .cancelOrder(order.id),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case 'confirmed':
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        break;
      case 'preparing':
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        break;
      case 'ready':
        color = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      case 'delivered':
        color = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      case 'cancelled':
        color = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        break;
      default:
        color = AppColors.textSecondary;
        bgColor = AppColors.surfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'ready': return 'Ready';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}