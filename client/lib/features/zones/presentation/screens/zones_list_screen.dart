import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/error_handler.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/zone_api.dart';
import '../../models/zone_model.dart';
import 'add_edit_zone_screen.dart';

class ZonesListScreen extends StatefulWidget {
  const ZonesListScreen({super.key});

  @override
  State<ZonesListScreen> createState() => _ZonesListScreenState();
}

class _ZonesListScreenState extends State<ZonesListScreen> {
  bool _loading = true;
  List<ZoneModel> _zones = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final zones = await ZoneApi.list(limit: 100);
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ErrorHandler.show(context, e);
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditZoneScreen()),
    );
    await _load();
  }

  Future<void> _openEdit(ZoneModel zone) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditZoneScreen(zone: zone)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openCreate,
        label: const Text('Add zone'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _zones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No zones yet'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _openCreate,
                        child: const Text('Create first zone'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.dashboard),
                        child: const Text('Back to dashboard'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _zones.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final z = _zones[i];
                    return ListTile(
                      title: Text(z.name),
                      subtitle: z.description.isEmpty ? null : Text(z.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!z.isActive)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text('Inactive'),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _openEdit(z),
                    );
                  },
                ),
    );
  }
}

