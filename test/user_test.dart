import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/user.dart';

void main() {
  group('User model', () {
    group('fromJson', () {
      test('parses valid JSON correctly', () {
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
        expect(user.studentId, '6731501234');
        expect(user.username, 'frontend_hero');
        expect(user.email, 'hero@student.ac.th');
        expect(user.displayName, 'Frontend Hero');
        expect(user.role, UserRole.member);
        expect(user.status, UserStatus.active);
      });

      test('accepts "id" as a fallback for "user_id"', () {
        expect(User.fromJson({'id': 7}).id, 7);
      });

      test('uses default values when fields are missing', () {
        final user = User.fromJson({});

        expect(user.id, 0);
        expect(user.studentId, '');
        expect(user.username, '');
        expect(user.email, '');
        expect(user.displayName, '');
        expect(user.residenceZone, isNull);
        expect(user.role, UserRole.member);
        expect(user.status, UserStatus.pending);
      });

      test('falls back to defaults for unknown role and status', () {
        final user = User.fromJson({'role': 'god', 'status': 'xyz'});

        expect(user.role, UserRole.member);
        expect(user.status, UserStatus.pending);
      });
    });

    group('isAdmin', () {
      test('returns true only for the admin role', () {
        final memberUser = User.fromJson({'user_id': 1, 'role': 'member'});
        final adminUser = User.fromJson({'user_id': 2, 'role': 'admin'});

        expect(memberUser.isAdmin, isFalse);
        expect(adminUser.isAdmin, isTrue);
      });
    });

    group('isActive', () {
      test('returns true only for the active status', () {
        final activeUser = User.fromJson({'user_id': 1, 'status': 'active'});
        final pendingUser = User.fromJson({'user_id': 2, 'status': 'pending'});
        final suspendedUser = User.fromJson({
          'user_id': 3,
          'status': 'suspended',
        });

        expect(activeUser.isActive, isTrue);
        expect(pendingUser.isActive, isFalse);
        expect(suspendedUser.isActive, isFalse);
      });
    });

    group('initials', () {
      test('uses the first letter of two words', () {
        final user = User.fromJson({'display_name': 'Maya Demo'});
        expect(user.initials, 'MD');
      });

      test('handles multiple spaces between words', () {
        final user = User.fromJson({'display_name': 'John    Doe'});
        expect(user.initials, 'JD');
      });

      test('handles a single-word name', () {
        final user = User.fromJson({'display_name': 'Cher'});
        expect(user.initials, 'C');
      });

      test('uses only the first two words of a longer name', () {
        final user = User.fromJson({'display_name': 'Anna Bella Cole'});
        expect(user.initials, 'AB');
      });

      test('returns an empty string for an empty display name', () {
        final user = User.fromJson({'display_name': ''});
        expect(user.initials, '');
      });
    });

    group('toJson', () {
      test('serializes basic fields correctly', () {
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

        final json = User.fromJson(originalJson).toJson();

        expect(json['user_id'], 99);
        expect(json['student_id'], '12345');
        expect(json['username'], 'test_user');
        expect(json['email'], 'test@test.com');
        expect(json['role'], 'member');
        expect(json['status'], 'pending');
        expect(json['display_name'], 'Test User');
      });

      test('serializes enums, ids and UTC dates correctly', () {
        final user = User.fromJson({
          'user_id': 5,
          'residence_zone': 'on_campus',
          'residence_location_id': 3,
          'residence_name': 'Dorm A',
          'role': 'admin',
          'status': 'active',
          'verified_by': 1,
          'verified_at': '2026-01-02T03:04:05Z',
        });

        final json = user.toJson();

        expect(json['residence_zone'], 'on_campus');
        expect(json['residence_location_id'], 3);
        expect(json['residence_name'], 'Dorm A');
        expect(json['role'], 'admin');
        expect(json['status'], 'active');
        expect(json['verified_by'], 1);
        expect(json['verified_at'], '2026-01-02T03:04:05.000Z');
      });

      test('outputs null for optional fields that were not provided', () {
        final json = User.fromJson({'user_id': 1}).toJson();

        expect(json['residence_zone'], isNull);
        expect(json['verified_at'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
      });
    });
  });
}
