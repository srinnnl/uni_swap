import 'package:flutter/material.dart';
import 'package:uni_swap/model/enums.dart';
import 'package:uni_swap/model/location.dart';

typedef LocationSelection = ({ResidenceZone zone, Location? location});

Future<LocationSelection?> showLocationPicker(
  BuildContext context, {
  required List<Location> locations,
  ResidenceZone? zone,
  int? selectedLocationId,
  String? otherLabel,
}) {
  final selected = locations.cast<Location?>().firstWhere(
    (location) => location!.id == selectedLocationId,
    orElse: () => null,
  );
  var currentZone = zone ?? selected?.zone ?? ResidenceZone.onCampus;

  return showModalBottomSheet<LocationSelection>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    backgroundColor: Colors.white,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    for (final option in ResidenceZone.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                _zoneLabel(option),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: currentZone == option,
                            onSelected: (_) =>
                                setSheet(() => currentZone = option),
                            showCheckmark: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final location in locations.where(
                      (location) => location.zone == currentZone,
                    ))
                      ListTile(
                        title: Text(location.name),
                        trailing: location.id == selectedLocationId
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, (
                          zone: currentZone,
                          location: location,
                        )),
                      ),
                    if (otherLabel != null)
                      ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: Text(otherLabel),
                        onTap: () => Navigator.pop(sheetContext, (
                          zone: currentZone,
                          location: null,
                        )),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String locationZoneLabel(ResidenceZone zone) =>
    zone == ResidenceZone.onCampus ? 'On-campus dorms' : 'Off-campus dorms';

String _zoneLabel(ResidenceZone zone) =>
    zone == ResidenceZone.onCampus ? 'On-campus' : 'Off-campus';
