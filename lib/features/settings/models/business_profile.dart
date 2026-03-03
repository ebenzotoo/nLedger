class BusinessProfile {
  final String id;
  final String companyName;
  final String address;
  final String email;
  final String phone;
  final String website;
  final String logoUrl; // To store the Firebase Storage link for the logo

  // Payment Instructions
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String mobileMoneyNumber;
  final String paymentTerms;

  BusinessProfile({
    required this.id,
    required this.companyName,
    required this.address,
    required this.email,
    required this.phone,
    required this.website,
    this.logoUrl = '',
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.mobileMoneyNumber,
    required this.paymentTerms,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'address': address,
      'email': email,
      'phone': phone,
      'website': website,
      'logoUrl': logoUrl,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'mobileMoneyNumber': mobileMoneyNumber,
      'paymentTerms': paymentTerms,
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      id: map['id'] ?? '',
      companyName: map['companyName'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      website: map['website'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      bankName: map['bankName'] ?? '',
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      mobileMoneyNumber: map['mobileMoneyNumber'] ?? '',
      paymentTerms: map['paymentTerms'] ?? '',
    );
  }
}
