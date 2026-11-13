import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/auth_controller.dart';

import 'test_helpers.dart';

void main() {
  late List<RecordedCall> calls;

  setUp(() => calls = []);

  Map<String, Object?> loginResponse() => {
    'success': true,
    'token': 'session-token',
    'user': {'user_id': 3, 'role': 'member'},
  };

  group('สถานะเริ่มต้น', () {
    test('ยังไม่ล็อกอิน ไม่มี token และไม่มี user', () {
      final auth = AuthController(fakeApi(calls));
      expect(auth.isAuthenticated, false);
      expect(auth.token, isNull);
      expect(auth.user, isNull);
      expect(auth.isBusy, false);
    });
  });

  group('login', () {
    test('ตัดช่องว่างของอีเมลก่อนส่ง แต่ไม่แตะรหัสผ่าน', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));

      await auth.login(email: '  a@b.com  ', password: ' pass ');

      expect(calls.single.label, 'POST /api/login');
      expect(calls.single.body, {'email': 'a@b.com', 'password': ' pass '});
    });

    test('เก็บ token และ user หลังล็อกอินสำเร็จ', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));

      await auth.login(email: 'a@b.com', password: 'secret123');

      expect(auth.isAuthenticated, true);
      expect(auth.token, 'session-token');
      expect(auth.user?['user_id'], 3);
    });

    test(
      'response ไม่มี token → โยน ApiException และไม่ถือว่าล็อกอิน',
      () async {
        final auth = AuthController(
          fakeApi(
            calls,
            response: {
              'success': true,
              'user': {'user_id': 3},
            },
          ),
        );

        await expectLater(
          auth.login(email: 'a@b.com', password: 'x'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('did not contain a token'),
            ),
          ),
        );
        expect(auth.isAuthenticated, false);
        expect(auth.isBusy, false);
      },
    );

    test(
      'รหัสผ่านผิด (401) → โยน ApiException และ isBusy กลับเป็น false',
      () async {
        final auth = AuthController(
          fakeApi(
            calls,
            status: 401,
            response: {'success': false, 'message': 'Invalid credentials'},
          ),
        );

        await expectLater(
          auth.login(email: 'a@b.com', password: 'wrong'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.message, 'message', 'Invalid credentials'),
          ),
        );
        expect(auth.isAuthenticated, false);
        expect(auth.isBusy, false);
      },
    );

    test('แจ้ง listener และ isBusy เป็น true ระหว่างทำงาน', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));
      final busyStates = <bool>[];
      auth.addListener(() => busyStates.add(auth.isBusy));

      await auth.login(email: 'a@b.com', password: 'secret123');

      expect(busyStates.first, true);
      expect(busyStates.last, false);
      expect(auth.isBusy, false);
    });
  });

  group('register', () {
    test('ส่งข้อมูลไป /api/register และไม่ล็อกอินให้อัตโนมัติ', () async {
      final auth = AuthController(
        fakeApi(calls, response: {'success': true, 'user_id': 9}),
      );

      final result = await auth.register({
        'username': 'maya',
        'email': 'maya@example.com',
      });

      expect(calls.single.label, 'POST /api/register');
      expect(calls.single.body!['username'], 'maya');
      expect(result['user_id'], 9);
      expect(auth.isAuthenticated, false);
      expect(auth.isBusy, false);
    });

    test(
      'สมัครไม่สำเร็จ (409) → โยน ApiException และ isBusy เป็น false',
      () async {
        final auth = AuthController(
          fakeApi(
            calls,
            status: 409,
            response: {
              'success': false,
              'message': 'This record already exists',
            },
          ),
        );

        await expectLater(
          auth.register({'username': 'maya'}),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409),
          ),
        );
        expect(auth.isBusy, false);
      },
    );
  });

  group('profile', () {
    test('loadProfile เก็บ user จาก data และแจ้ง listener', () async {
      final auth = AuthController(
        fakeApi(
          calls,
          response: {
            'success': true,
            'data': {'user_id': 3, 'display_name': 'Maya'},
          },
        ),
      );
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.loadProfile();

      expect(calls.single.label, 'GET /api/profile');
      expect(auth.user?['display_name'], 'Maya');
      expect(notified, 1);
    });

    test('loadProfile ที่ data ไม่ใช่ object → user เป็น null', () async {
      final auth = AuthController(
        fakeApi(calls, response: {'success': true, 'data': 'oops'}),
      );

      await auth.loadProfile();

      expect(auth.user, isNull);
    });

    test('updateProfile ส่ง PUT แล้วโหลดโปรไฟล์ใหม่', () async {
      final auth = AuthController(
        fakeApi(
          calls,
          response: {
            'success': true,
            'data': {'user_id': 3, 'display_name': 'New Name'},
          },
        ),
      );

      await auth.updateProfile({'display_name': 'New Name'});

      expect(calls.map((c) => c.label), [
        'PUT /api/profile',
        'GET /api/profile',
      ]);
      expect(calls.first.body, {'display_name': 'New Name'});
      expect(auth.user?['display_name'], 'New Name');
    });

    test('updateProfile ส่ง residence ที่เลือกไปยัง API', () async {
      final auth = AuthController(
        fakeApi(
          calls,
          response: {
            'success': true,
            'data': {
              'user_id': 3,
              'residence_zone': 'on_campus',
              'residence_location_id': 12,
            },
          },
        ),
      );

      await auth.updateProfile({
        'residence_zone': 'on_campus',
        'residence_location_id': 12,
      });

      expect(calls.first.label, 'PUT /api/profile');
      expect(calls.first.body, {
        'residence_zone': 'on_campus',
        'residence_location_id': 12,
      });
      expect(auth.user?['residence_location_id'], 12);
    });

    test('user ที่ดึงออกมาแก้ไขไม่ได้ (unmodifiable)', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));
      await auth.login(email: 'a@b.com', password: 'secret123');

      expect(() => auth.user!['role'] = 'admin', throwsUnsupportedError);
    });
  });

  group('signOut', () {
    test('ล้าง token และ user แล้วแจ้ง listener', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));
      await auth.login(email: 'a@b.com', password: 'secret123');
      var notified = 0;
      auth.addListener(() => notified++);

      auth.signOut();

      expect(auth.isAuthenticated, false);
      expect(auth.token, isNull);
      expect(auth.user, isNull);
      expect(notified, 1);
    });
  });
}
