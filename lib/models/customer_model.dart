class CustomerModel {
  String? id;
  String name;
  String mobile;
  String address;
  String? permanentAddress;
  String? city;
  String? state;
  String? email;
  String? pinCode;
  String? whatsapp;
  String? gstNumber;
  String status;
  String country;
  String? imageUrl;
  DateTime? createdAt;

  CustomerModel({
    this.id,
    required this.name,
    required this.mobile,
    required this.address,
    this.permanentAddress,
    this.city,
    this.state,
    this.email,
    this.pinCode,
    this.whatsapp,
    this.gstNumber,
    this.status = 'Active',
    this.country = 'India',
    this.imageUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'permanentAddress': permanentAddress,
      'city': city,
      'state': state,
      'email': email,
      'pinCode': pinCode,
      'whatsapp': whatsapp,
      'gstNumber': gstNumber,
      'status': status,
      'country': country,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String docId) {
    return CustomerModel(
      id: docId,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      permanentAddress: map['permanentAddress'],
      city: map['city'],
      state: map['state'],
      email: map['email'],
      pinCode: map['pinCode'],
      whatsapp: map['whatsapp'],
      gstNumber: map['gstNumber'],
      status: map['status'] ?? 'Active',
      country: map['country'] ?? 'India',
      imageUrl: map['imageUrl'],
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
    String? permanentAddress,
    String? city,
    String? state,
    String? email,
    String? pinCode,
    String? whatsapp,
    String? gstNumber,
    String? status,
    String? country,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      email: email ?? this.email,
      pinCode: pinCode ?? this.pinCode,
      whatsapp: whatsapp ?? this.whatsapp,
      gstNumber: gstNumber ?? this.gstNumber,
      status: status ?? this.status,
      country: country ?? this.country,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
