import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.length,
    required this.onChanged,
    this.onComplete,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onComplete;
  final bool enabled;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final List<FocusNode> _focusNodes = [];
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.length; i++) {
      _focusNodes.add(FocusNode());
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final n in _focusNodes) n.dispose();
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    final value = _controllers.map((c) => c.text).join();
    widget.onChanged(value);
    if (value.length == widget.length) widget.onComplete?.call();
  }

  void _distributePaste(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '').split('').take(widget.length).toList();
    if (digits.isEmpty) return;
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    if (digits.length >= widget.length) {
      FocusScope.of(context).requestFocus(_focusNodes[widget.length - 1]);
      _focusNodes[widget.length - 1].unfocus();
    } else {
      FocusScope.of(context).requestFocus(_focusNodes[digits.length]);
    }
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        final isFirst = index == 0;
        return SizedBox(
          width: 46,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.6,
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: isFirst ? widget.length : 1,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (!isFirst) LengthLimitingTextInputFormatter(1),
              if (isFirst)
                TextInputFormatter.withFunction((old, next) {
                  if (next.text.length > 1) {
                    _distributePaste(next.text);
                    final first = next.text.replaceAll(RegExp(r'\D'), '').isNotEmpty
                        ? next.text.replaceAll(RegExp(r'\D'), '')[0]
                        : '';
                    return TextEditingValue(
                      text: first,
                      selection: TextSelection.collapsed(offset: first.length),
                    );
                  }
                  return next;
                }),
            ],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
            onChanged: (v) {
              if (isFirst && v.length > 1) return;
              if (v.isNotEmpty) {
                if (index < widget.length - 1) {
                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                } else {
                  _focusNodes[index].unfocus();
                }
              }
              _notifyChanged();
            },
            onTap: () {
              if (_controllers[index].text.isNotEmpty) {
                _controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[index].text.length,
                );
              }
            },
            ),
          ),
        );
      }),
    );
  }
}
