import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/user.dart';

void main() {
  group('User Model Tests', () {
    
    test('fromJson: should parse valid JSON correctly', () {
      final json = {
        'user_id': 101,
        'student_id': '6731501234',
        'username': 'frontend_hero',
        'email': 'hero@student.ac.th',
        'display_name': 'Frontend Hero',
        'role': 'member',
        'status': 'active',
      };

      final user = User.fromJson(json);

      expect(user.id, 101);
      expect(user.studentId, '6731501151');
      expect(user.username, 'frontend_hero');
      expect(user.email, 'hero@student.ac.th');
      expect(user.displayName, 'Frontend Hero');
      expect(user.role, UserRole.member);
      expect(user.status, UserStatus.active);
    });

    test('isAdmin: should return true only for admin role', () {
      final memberJson = {'user_id': 1, 'role': 'member'};
      final adminJson = {'user_id': 2, 'role': 'admin'};

      final memberUser = User.fromJson(memberJson);
      final adminUser = User.fromJson(adminJson);

      expect(memberUser.isAdmin, isFalse);
      expect(adminUser.isAdmin, isTrue);
    });

    test('isActive: should return true only for active status', () {
      final activeJson = {'user_id': 1, 'status': 'active'};
      final pendingJson = {'user_id': 2, 'status': 'pending'};
      final suspendedJson = {'user_id': 3, 'status': 'suspended'};

      expect(User.fromJson(activeJson).isActive, isTrue);
      expect(User.fromJson(pendingJson).isActive, isFalse);
      expect(User.fromJson(suspendedJson).isActive, isFalse);
    });

    test('initials: should extract correct initials from display name', () {
      // เคสปกติ 2 คำ
      final user1 = User.fromJson({'display_name': 'Maya Demo'});
      expect(user1.initials, 'MD');

      // เคสมีช่องว่างเยอะๆ ระหว่างคำ
      final user2 = User.fromJson({'display_name': 'John    Doe'});
      expect(user2.initials, 'JD');

      // เคสมีชื่อคำเดียว
      final user3 = User.fromJson({'display_name': 'Cher'});
      expect(user3.initials, 'C');

      // เคสมี 3 คำ (ต้องเอาแค่ 2 คำแรก)
      final user4 = User.fromJson({'display_name': 'Anna Bella Cole'});
      expect(user4.initials, 'AB');
    });

    test('toJson: should serialize User object back to JSON correctly', () {
      final originalJson = {
        'user_id': 99,
        'student_id': '12345',
        'username': 'test_user',
        'email': 'test@test.com',
        'display_name': 'Test User',
        'residence_zone': null,
        'residence_location_id': null,
        'residence_name': null,
        'role': 'member',
        'status': 'pending',
        'verified_by': null,
        'verified_at': null,
        'created_at': null,
        'updated_at': null,
      };

      final user = User.fromJson(originalJson);
      final serializedJson = user.toJson();

      expect(serializedJson['user_id'], 99);
      expect(serializedJson['role'], 'member');
      expect(serializedJson['display_name'], 'Test User');
    });
  });
}