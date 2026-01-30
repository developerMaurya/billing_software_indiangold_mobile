class CustomerModel {
  String? id;
  String name;
  String mobile;
  String address;
  String? email;
  String? pinCode;
  String? whatsapp;
  String status;
  String country;
  DateTime? createdAt;

  CustomerModel({
    this.id,
    required this.name,
    required this.mobile,
    required this.address,
    this.email,
    this.pinCode,
    this.whatsapp,
    this.status = 'Active',
    this.country = 'India',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'email': email,
      'pinCode': pinCode,
      'whatsapp': whatsapp,
      'status': status,
      'country': country,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      email: map['email'],
      pinCode: map['pinCode'],
      whatsapp: map['whatsapp'],
      status: map['status'] ?? 'Active',
      country: map['country'] ?? 'India',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? address,
    String? email,
    String? pinCode,
    String? whatsapp,
    String? status,
    String? country,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      email: email ?? this.email,
      pinCode: pinCode ?? this.pinCode,
      whatsapp: whatsapp ?? this.whatsapp,
      status: status ?? this.status,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
