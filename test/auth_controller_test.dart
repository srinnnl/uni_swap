// นำเข้าแพ็กเกจหลักสำหรับการเขียน Unit Test ใน Flutter
import 'package:flutter_test/flutter_test.dart';
// นำเข้าคลาสจัดการ Error และ AuthController ที่ต้องการนำมาทดสอบ
import 'package:uni_swap/controller/api_client.dart';
import 'package:uni_swap/controller/auth_controller.dart';

// นำเข้าตัวช่วยจำลอง API (Fake API) สำหรับการทดสอบ
import 'test_helpers.dart';

void main() {
  // ประกาศตัวแปรเก็บประวัติการเรียก API ที่เกิดขึ้นในแต่ละเทสต์
  late List<RecordedCall> calls;

  // ล้างข้อมูลประวัติการเรียก API ให้ว่างเปล่าก่อนเริ่มรันแต่ละเทสต์ย่อย
  setUp(() => calls = []);

  // ฟังก์ชันช่วยสร้างข้อมูลจำลอง (Mock Response) เมื่อล็อกอินสำเร็จ
  Map<String, Object?> loginResponse() => {
    'success': true,
    'token': 'session-token',
    'user': {'user_id': 3, 'role': 'member'},
  };

  // =========================================================================
  // กลุ่มทดสอบที่ 1: สถานะเริ่มต้นของ AuthController ก่อนมีการล็อกอิน
  // =========================================================================
  group('สถานะเริ่มต้น', () {
    test('ยังไม่ล็อกอิน ไม่มี token และไม่มี user', () {
      final auth = AuthController(fakeApi(calls));
      // ตรวจสอบว่าค่าเริ่มต้นทั้งหมดต้องเป็นสถานะยังไม่ได้ยืนยันตัวตนและไม่กำลังโหลด (isBusy = false)
      expect(auth.isAuthenticated, false);
      expect(auth.token, isNull);
      expect(auth.user, isNull);
      expect(auth.isBusy, false);
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 2: การเข้าสู่ระบบ (Login) และจัดการสถานะ Loading (isBusy)
  // =========================================================================
  group('login', () {
    test('ตัดช่องว่างของอีเมลก่อนส่ง แต่ไม่แตะรหัสผ่าน', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));

      // ทดสอบส่งอีเมลและรหัสผ่านที่มีช่องว่างหน้า-หลัง
      await auth.login(email: '  a@b.com  ', password: ' pass ');

      // ตรวจสอบว่าอีเมลถูก trim ช่องว่างออก แต่รหัสผ่านต้องคงช่องว่างไว้ตามเดิมเผื่อผู้ใช้ตั้งรหัสผ่านที่มีเว้นวรรค
      expect(calls.single.label, 'POST /api/login');
      expect(calls.single.body, {'email': 'a@b.com', 'password': ' pass '});
    });

    test('เก็บ token และ user หลังล็อกอินสำเร็จ', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));

      await auth.login(email: 'a@b.com', password: 'secret123');

      // ตรวจสอบว่าสถานะเปลี่ยนเป็นล็อกอินแล้ว และมีการเก็บ token กับข้อมูล user ไว้อย่างถูกต้อง
      expect(auth.isAuthenticated, true);
      expect(auth.token, 'session-token');
      expect(auth.user?['user_id'], 3);
    });

    test('response ไม่มี token → โยน ApiException และไม่ถือว่าล็อกอิน', () async {
      // จำลองกรณี Server ตอบกลับมาว่าสำเร็จ แต่ลืมส่ง token แนบมาด้วย
      final auth = AuthController(
        fakeApi(
          calls,
          response: {
            'success': true,
            'user': {'user_id': 3},
          },
        ),
      );

      // ตรวจสอบว่าต้องโยน ApiException และสถานะการล็อกอินต้องยังคงเป็น false รวมถึงรีเซ็ต isBusy
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
    });

    test(
      'รหัสผ่านผิด (401) → โยน ApiException และ isBusy กลับเป็น false',
      () async {
        // จำลองกรณีกรอกรหัสผ่านผิด (HTTP 401 Unauthorized)
        final auth = AuthController(
          fakeApi(
            calls,
            status: 401,
            response: {'success': false, 'message': 'Invalid credentials'},
          ),
        );

        // ตรวจสอบว่าโยน ApiException พร้อมรหัส 401 และปิดสถานะกำลังโหลด (isBusy = false)
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
      // ดักฟังการเปลี่ยนแปลงสถานะ (ChangeNotifier) เพื่อเก็บค่า isBusy ทุกครั้งที่มีการแจ้งเตือน UI
      auth.addListener(() => busyStates.add(auth.isBusy));

      await auth.login(email: 'a@b.com', password: 'secret123');

      // ตรวจสอบลำดับสถานะ: ตอนเริ่มทำงาน isBusy ต้องเป็น true (แสดงตัวหมุนโหลด) และตอนเสร็จต้องเป็น false
      expect(busyStates.first, true);
      expect(busyStates.last, false);
      expect(auth.isBusy, false);
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 3: การสมัครสมาชิก (Register)
  // =========================================================================
  group('register', () {
    test('ส่งข้อมูลไป /api/register และไม่ล็อกอินให้อัตโนมัติ', () async {
      final auth = AuthController(
        fakeApi(calls, response: {'success': true, 'user_id': 9}),
      );

      final result = await auth.register({
        'username': 'maya',
        'email': 'maya@example.com',
      });

      // ตรวจสอบว่ายิงไปที่ endpoint สมัครสมาชิกถูกต้อง และหลังสมัครเสร็จจะยังไม่ล็อกอินให้อัตโนมัติ
      expect(calls.single.label, 'POST /api/register');
      expect(calls.single.body!['username'], 'maya');
      expect(result['user_id'], 9);
      expect(auth.isAuthenticated, false);
      expect(auth.isBusy, false);
    });

    test(
      'สมัครไม่สำเร็จ (409) → โยน ApiException และ isBusy เป็น false',
      () async {
        // จำลองกรณีข้อมูลซ้ำ เช่น อีเมลหรือชื่อผู้ใช้ถูกใช้ไปแล้ว (HTTP 409 Conflict)
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

        // ตรวจสอบว่าโยน ApiException 409 และรีเซ็ต isBusy กลับเป็น false
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

  // =========================================================================
  // กลุ่มทดสอบที่ 4: การดึงข้อมูลและอัปเดตโปรไฟล์ผู้ใช้ (Profile)
  // =========================================================================
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
      auth.addListener(() => notified++); // นับจำนวนครั้งที่แจ้งเตือนไปยัง UI

      await auth.loadProfile();

      // ตรวจสอบว่าดึงข้อมูลโปรไฟล์มาเก็บในตัวแปร user และแจ้งเตือน listener 1 ครั้ง
      expect(calls.single.label, 'GET /api/profile');
      expect(auth.user?['display_name'], 'Maya');
      expect(notified, 1);
    });

    test('loadProfile ที่ data ไม่ใช่ object → user เป็น null', () async {
      // จำลองกรณีที่ Server ส่งฟิลด์ data กลับมาผิดรูปแบบ (เช่น เป็น String แทนที่จะเป็น Map/Object)
      final auth = AuthController(
        fakeApi(calls, response: {'success': true, 'data': 'oops'}),
      );

      await auth.loadProfile();

      // ตรวจสอบว่าระบบป้องกันไม่ให้แอปพัง โดยกำหนดค่า user เป็น null
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

      // ตรวจสอบลำดับการเรียก API: ต้องส่ง PUT เพื่ออัปเดตก่อน แล้วตามด้วย GET เพื่อโหลดข้อมูลล่าสุดทันที
      expect(calls.map((c) => c.label), [
        'PUT /api/profile',
        'GET /api/profile',
      ]);
      expect(calls.first.body, {'display_name': 'New Name'});
      expect(auth.user?['display_name'], 'New Name');
    });

    test('user ที่ดึงออกมาแก้ไขไม่ได้ (unmodifiable)', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));
      await auth.login(email: 'a@b.com', password: 'secret123');

      // ตรวจสอบความปลอดภัยของข้อมูล: ป้องกันไม่ให้โค้ดส่วนอื่นแอบแก้ไข Map ของ user โดยตรง
      expect(() => auth.user!['role'] = 'admin', throwsUnsupportedError);
    });
  });

  // =========================================================================
  // กลุ่มทดสอบที่ 5: การออกจากระบบ (Sign Out)
  // =========================================================================
  group('signOut', () {
    test('ล้าง token และ user แล้วแจ้ง listener', () async {
      final auth = AuthController(fakeApi(calls, response: loginResponse()));
      await auth.login(email: 'a@b.com', password: 'secret123');
      var notified = 0;
      auth.addListener(() => notified++);

      auth.signOut();

      // ตรวจสอบว่าเมื่อออกจากระบบ ข้อมูล token และ user ถูกล้างจนหมด และแจ้งเตือน UI
      expect(auth.isAuthenticated, false);
      expect(auth.token, isNull);
      expect(auth.user, isNull);
      expect(notified, 1);
    });
  });
}
