import 'package:flutter_test/flutter_test.dart';
import 'package:hanapbuhayapp/data/repositories/mock/mock_chat_repository.dart';
import 'package:hanapbuhayapp/providers/chat_provider.dart';

void main() {
  test('returns the persisted message from sendMessage', () async {
    final provider = ChatProvider(MockChatRepository());
    addTearDown(provider.dispose);

    final message = await provider.sendMessage(
      'c1',
      senderId: 'current_user',
      text: 'Sent from the thread',
    );

    expect(message.senderId, 'current_user');
    expect(message.text, 'Sent from the thread');
    expect((await provider.getMessages('c1')).last.id, message.id);
  });
}
