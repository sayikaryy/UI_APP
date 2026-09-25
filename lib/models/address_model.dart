class AddressModel {
  final int id;
  final int userId;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String city;
  final String label; // 'Home', 'Office'
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    this.city = 'Phnom Penh',
    this.label = 'Home',
    this.isDefault = false,
  });

  String get fullAddress => '$addressLine, $city';

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? 'Phnom Penh',
      label: json['label'] ?? 'Home',
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipient_name': recipientName,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      'label': label,
      'is_default': isDefault,
    };
  }
}
