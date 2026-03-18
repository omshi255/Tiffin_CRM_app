import 'package:flutter/material.dart';

import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/zone_api.dart';
import '../../models/zone_model.dart';

class AddEditZoneScreen extends StatefulWidget {
  const AddEditZoneScreen({super.key, this.zone});

  final ZoneModel? zone;

  @override
  State<AddEditZoneScreen> createState() => _AddEditZoneScreenState();
}

class _AddEditZoneScreenState extends State<AddEditZoneScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _color;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.zone?.name ?? '');
    _description =
        TextEditingController(text: widget.zone?.description ?? '');
    _color = TextEditingController(text: widget.zone?.color ?? '');
    _isActive = widget.zone?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      AppSnackbar.error(context, 'Zone name is required');
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.zone == null) {
        await ZoneApi.create(
          ZoneModel(
            id: '',
            name: name,
            description: _description.text.trim(),
            color: _color.text.trim(),
            isActive: _isActive,
          ).toCreateJson(),
        );
      } else {
        await ZoneApi.update(
          widget.zone!.id,
          ZoneModel(
            id: widget.zone!.id,
            name: name,
            description: _description.text.trim(),
            color: _color.text.trim(),
            isActive: _isActive,
          ).toUpdateJson(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    final id = widget.zone?.id;
    if (id == null || id.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ZoneApi.deactivate(id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.zone != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit zone' : 'Create zone'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _saving ? null : _deactivate,
              icon: const Icon(Icons.block),
              tooltip: 'Deactivate',
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Zone name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _color,
              decoration: const InputDecoration(
                labelText: 'Color (optional)',
                hintText: '#FF0000 or "red"',
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Save changes' : 'Create zone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

