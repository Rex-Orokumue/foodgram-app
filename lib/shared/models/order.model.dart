class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String postId;
  final String status;
  final String deliveryAddress;
  final double totalAmount;
  final String? notes;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? caption;
  final String? cuisineTag;
  final String? sellerUsername;
  final String? sellerDisplayName;
  final String? sellerAvatarUrl;
  final String? buyerUsername;
  final String? buyerDisplayName;
  final String? buyerAvatarUrl;
  final List<Map<String, dynamic>> postMedia;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.postId,
    required this.status,
    required this.deliveryAddress,
    required this.totalAmount,
    this.notes,
    this.confirmedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.caption,
    this.cuisineTag,
    this.sellerUsername,
    this.sellerDisplayName,
    this.sellerAvatarUrl,
    this.buyerUsername,
    this.buyerDisplayName,
    this.buyerAvatarUrl,
    required this.postMedia,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'post_id': postId,
      'status': status,
      'delivery_address': deliveryAddress,
      'total_amount': totalAmount.toString(),
      'notes': notes,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'caption': caption,
      'cuisine_tag': cuisineTag,
      'seller_username': sellerUsername,
      'seller_display_name': sellerDisplayName,
      'seller_avatar_url': sellerAvatarUrl,
      'buyer_username': buyerUsername,
      'buyer_display_name': buyerDisplayName,
      'buyer_avatar_url': buyerAvatarUrl,
      'post_media': postMedia,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      postId: json['post_id'] as String,
      status: json['status'] as String,
      deliveryAddress: json['delivery_address'] as String,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      notes: json['notes'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      caption: json['caption'] as String?,
      cuisineTag: json['cuisine_tag'] as String?,
      sellerUsername: json['seller_username'] as String?,
      sellerDisplayName: json['seller_display_name'] as String?,
      sellerAvatarUrl: json['seller_avatar_url'] as String?,
      buyerUsername: json['buyer_username'] as String?,
      buyerDisplayName: json['buyer_display_name'] as String?,
      buyerAvatarUrl: json['buyer_avatar_url'] as String?,
      postMedia: (json['post_media'] as List<dynamic>? ?? [])
          .map((m) => m as Map<String, dynamic>)
          .toList(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => !isDelivered && !isCancelled;

  String get formattedAmount => '₦${totalAmount.toStringAsFixed(0)}';

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'ready': return 'Ready for pickup';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String get sellerName => sellerDisplayName ?? sellerUsername ?? 'Unknown';
  String get buyerName => buyerDisplayName ?? buyerUsername ?? 'Unknown';
}