import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://api.opcw032522.uk/items/habits?filter[user_id][_eq]=013003');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final data = await response.transform(utf8.decoder).join();
  
  File('habit_data.txt').writeAsStringSync(data);

  final url2 = Uri.parse('https://api.opcw032522.uk/items/todos?filter[user_id][_eq]=013003');
  final request2 = await HttpClient().getUrl(url2);
  final response2 = await request2.close();
  final data2 = await response2.transform(utf8.decoder).join();
  
  File('todo_data.txt').writeAsStringSync(data2);
}
