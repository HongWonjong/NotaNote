import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/note_model.dart';
import 'package:nota_note/viewmodels/notes_list_viewmodel.dart';

class NoteListPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const NoteListPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  ConsumerState<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends ConsumerState<NoteListPage> {
  String? _newNoteName;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(notesListViewModelProvider(widget.groupId)).fetchNotes());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새 노트 추가'),
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(hintText: '노트 이름을 입력하세요'),
          onChanged: (value) {
            _newNoteName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (_newNoteName != null && _newNoteName!.isNotEmpty) {
                ref
                    .read(notesListViewModelProvider(widget.groupId))
                    .createNote(_newNoteName!);
                _textController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 노트 목록 가져오기
    final notesViewModel =
        ref.watch(notesListViewModelProvider(widget.groupId));
    final notes = notesViewModel.notes;
    final isLoading = notesViewModel.isLoading;
    final error = notesViewModel.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error))
              : notes.isEmpty
                  ? Center(child: Text('노트가 없습니다'))
                  : _buildNoteList(notes),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: Color(0xFFEFEFEF),
        shape: CircleBorder(),
        elevation: 0,
        child: Icon(
          Icons.add,
          size: 24,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildNoteList(List<Note> notes) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: notes.length,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteItem(note);
      },
    );
  }

  Widget _buildNoteItem(Note note) {
    return GestureDetector(
      onTap: () {
        // 노트 상세 페이지로 이동
        // Navigator.push(context, MaterialPageRoute(builder: (context) => NotePage(...)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // 옵션 메뉴 표시
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => _buildOptionsSheet(note),
                    );
                  },
                  icon: Icon(Icons.more_horiz),
                  constraints: BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '페이지 ${note.pages.length}개',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (note.tags.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: note.tags
                    .map((tag) => Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 12),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSheet(Note note) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 59,
            height: 6,
            decoration: BoxDecoration(
              color: Color(0xff494949),
              borderRadius: BorderRadius.circular(2),
            ),
            margin: EdgeInsets.symmetric(vertical: 12),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // 공유 기능 구현
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '공유',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // 이름 변경 기능 구현
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '이름 변경',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // 노트 삭제 확인 다이얼로그
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('노트 삭제'),
                        content: Text('정말로 "${note.title}" 노트를 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ref
                                  .read(notesListViewModelProvider(
                                      widget.groupId))
                                  .deleteNote(note.noteId);
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: Text('삭제'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '삭제',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
