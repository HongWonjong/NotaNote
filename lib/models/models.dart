import 'package:nota_note/models/comment_model.dart';
import 'package:nota_note/models/note_model.dart';
import 'package:nota_note/models/page_model.dart';
import 'package:nota_note/models/widget_model.dart';

Future<void> models() async {
  await noteModel();
  await pageModel();
  await widgetModel();
  await commentModel();

  print('전체 임시 데이터');
}
