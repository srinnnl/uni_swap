import 'enums.dart';
import 'json_utils.dart';

/// แถวในตาราง `bank_accounts`
///
/// ไม่เก็บ `account_number_enc` ไว้ใน model ฝั่งแอป เพราะเป็นข้อมูลที่เข้ารหัส
/// และไม่ควรถูกส่งกลับไปที่ client
class BankAccount {
  const BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountLast4,
    required this.accountName,
    this.status = BankAccountStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: jsonInt(json['bank_account_id'] ?? json['id']) ?? 0,
      userId: jsonInt(json['user_id']) ?? 0,
      bankName: jsonString(json['bank_name']) ?? '',
      accountLast4: jsonString(json['account_last4']) ?? '',
      accountName: jsonString(json['account_name']) ?? '',
      status: BankAccountStatus.fromApi(json['status']),
      verifiedBy: jsonInt(json['verified_by']),
      verifiedAt: jsonDateTime(json['verified_at']),
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
    );
  }

  final int id; // bank_accounts.bank_account_id
  final int userId; // bank_accounts.user_id
  final String bankName; // bank_accounts.bank_name
  final String accountLast4; // bank_accounts.account_last4
  final String accountName; // bank_accounts.account_name
  final BankAccountStatus status; // bank_accounts.status
  final int? verifiedBy; // bank_accounts.verified_by
  final DateTime? verifiedAt; // bank_accounts.verified_at
  final DateTime? createdAt; // bank_accounts.created_at
  final DateTime? updatedAt; // bank_accounts.updated_at

  /// เลขบัญชีแบบปิดบางส่วน เช่น "•••• 1234"
  String get maskedNumber => accountLast4.isEmpty ? '' : '•••• $accountLast4';

  Map<String, dynamic> toJson() {
    return {
      'bank_account_id': id,
      'user_id': userId,
      'bank_name': bankName,
      'account_last4': accountLast4,
      'account_name': accountName,
      'status': status.apiValue,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toUtc().toIso8601String(),
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
