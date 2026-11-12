import 'package:flutter/material.dart';

// ไฟล์กลางของที่พัก ใช้ร่วมกันทุกหน้า (register, profile, sell, search, ...)
// ตอนนี้วางที่ lib/view/user/campus_locations.dart (ทุกไฟล์ import จากที่นี่)
// ตรงกับ DB: zone เป็น enum on_campus / off_campus ส่วนตาราง locations ต้องรอเพื่อน ALTER (alter_request.sql)
// TODO: เปลี่ยน kCampusLocations เป็นข้อมูลจาก API (รายการ locations ที่ is_active)

const _ink = Color(0xFF2F2F2B);
const _border = Color(0xFFE6E4DD);

enum CampusZone {
  onCampus('on_campus', 'On-campus dorms'),
  offCampus('off_campus', 'Off-campus dorms');

  const CampusZone(this.code, this.label);
  final String code; // products.zone / users.residence_zone
  final String label; // ข้อความที่แสดงในแอป
}

class CampusLocation {
  const CampusLocation(this.id, this.zone, this.name);
  final int id; // locations.location_id (ตัวเลขในนี้เป็นค่าจำลอง)
  final CampusZone zone;
  final String name;

  /// ข้อความแสดงผล เช่น 'On-campus dorms · Lamduan 1 Dormitory'
  String get place => '${zone.label} · $name';
}

// ข้อมูลจำลองตาม seed ใน DB
const kCampusLocations = <CampusLocation>[
  CampusLocation(1, CampusZone.offCampus, 'S-Room Apartment'),
  CampusLocation(2, CampusZone.offCampus, 'Saen Fah Luang Dormitory'),
  CampusLocation(3, CampusZone.offCampus, 'PHUTARA APARTMENT MFU'),
  CampusLocation(4, CampusZone.offCampus, 'PapaMama@MFU'),
  CampusLocation(5, CampusZone.offCampus, 'MFU Home Stay'),
  CampusLocation(6, CampusZone.offCampus, 'SJD Mansion'),
  CampusLocation(7, CampusZone.offCampus, 'Kittiya Dormitory'),
  CampusLocation(8, CampusZone.offCampus, 'Weang Fah Luang "Bann Goo"'),
  CampusLocation(9, CampusZone.offCampus, 'Rattana Dormitory'),
  CampusLocation(10, CampusZone.offCampus, 'Tharnn Residence'),
  CampusLocation(11, CampusZone.offCampus, 'Regent Mansion MFU'),
  CampusLocation(12, CampusZone.onCampus, 'Lamduan 1 Dormitory'),
  CampusLocation(13, CampusZone.onCampus, 'Lamduan 2 Dormitory'),
  CampusLocation(14, CampusZone.onCampus, 'Lamduan 7 Dormitory'),
  CampusLocation(15, CampusZone.onCampus, 'Sakthong 2 Dormitory'),
  CampusLocation(16, CampusZone.onCampus, 'Sakthong 3 Dormitory'),
  CampusLocation(17, CampusZone.onCampus, 'F2 Female Dormitory'),
  CampusLocation(18, CampusZone.onCampus, 'F3 Female Dormitory'),
  CampusLocation(19, CampusZone.onCampus, 'F4 Female Dormitory'),
];

CampusLocation locationById(int id) =>
    kCampusLocations.firstWhere((l) => l.id == id);

List<CampusLocation> locationsIn(CampusZone z) => [
  for (final l in kCampusLocations)
    if (l.zone == z) l,
];

/// ผลที่เลือก: location เป็น null = เลือก "Other" (ที่พักที่ยังไม่มีในรายการ)
typedef LocationPick = ({CampusZone zone, CampusLocation? location});

/// bottom sheet เลือกที่พัก: เลือกโซนก่อน แล้วเลือกหอจากรายการ (เลื่อนได้)
/// ใส่ [otherLabel] ถ้าต้องการแถว "Other" ท้ายรายการ
Future<LocationPick?> showCampusLocationPicker(
  BuildContext context, {
  CampusZone? zone,
  CampusLocation? selected,
  String? otherLabel,
}) {
  var current = zone ?? selected?.zone ?? CampusZone.onCampus;
  return showModalBottomSheet<LocationPick>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    backgroundColor: Colors.white,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  for (final z in CampusZone.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text(z.label),
                          ),
                          selected: current == z,
                          onSelected: (_) => setSheet(() => current = z),
                          showCheckmark: false,
                          backgroundColor: Colors.white,
                          selectedColor: _ink,
                          side: const BorderSide(color: _border),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: current == z ? Colors.white : _ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final l in locationsIn(current))
                    ListTile(
                      title: Text(l.name),
                      trailing: l.id == selected?.id
                          ? const Icon(Icons.check, color: _ink)
                          : null,
                      onTap: () =>
                          Navigator.pop(ctx, (zone: current, location: l)),
                    ),
                  if (otherLabel != null)
                    ListTile(
                      leading: const Icon(
                        Icons.add_location_alt_outlined,
                        color: _ink,
                      ),
                      title: Text(otherLabel),
                      onTap: () =>
                          Navigator.pop(ctx, (zone: current, location: null)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
