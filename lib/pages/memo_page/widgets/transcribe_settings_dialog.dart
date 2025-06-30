import 'package:flutter/material.dart';

class TranscribeSettingsDialog extends StatefulWidget {
  final String initialLanguage;
  final String initialMode;

  const TranscribeSettingsDialog({
    this.initialLanguage = 'ko',
    this.initialMode = 'origin',
    super.key,
  });

  @override
  State<TranscribeSettingsDialog> createState() => _TranscribeSettingsDialogState();
}

class _TranscribeSettingsDialogState extends State<TranscribeSettingsDialog> {
  late String _selectedLanguage;
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('변환 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text('언어', style: TextStyle(fontWeight: FontWeight.bold))),
          Row(
            children: [
              Radio<String>(
                value: 'ko',
                groupValue: _selectedLanguage,
                onChanged: (value) => setState(() => _selectedLanguage = value!),
              ),
              Text('한국어'),
              Radio<String>(
                value: 'en',
                groupValue: _selectedLanguage,
                onChanged: (value) => setState(() => _selectedLanguage = value!),
              ),
              Text('영어'),
            ],
          ),
          SizedBox(height: 8),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('보기 방식', style: TextStyle(fontWeight: FontWeight.bold))),
          Row(
            children: [
              Radio<String>(
                value: 'origin',
                groupValue: _selectedMode,
                onChanged: (value) => setState(() => _selectedMode = value!),
              ),
              Text('원문으로 보기'),
              Radio<String>(
                value: 'summary',
                groupValue: _selectedMode,
                onChanged: (value) => setState(() => _selectedMode = value!),
              ),
              Text('요약해서 보기'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, null), child: Text('취소')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'language': _selectedLanguage,
            'mode': _selectedMode,
          }),
          child: Text('변환하기'),
        ),
      ],
    );
  }
}
