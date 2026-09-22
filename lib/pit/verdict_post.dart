import 'dart:convert';

import 'cloak.dart';
import 'mark.dart';
import 'packed.dart';
import 'reply.dart';
import 'seal_box.dart';
import 'stash.dart';

class VerdictPost {
  VerdictPost(this._stash);

  final Stash _stash;

  static const Duration _limit = Duration(seconds: 22);

  Future<PitReply> ask(Map<String, dynamic> body) async {
    final String endpoint = Mark.gateEndpoint;
    final String secret = openRelaySecret();
    if (endpoint.isEmpty || secret.isEmpty) {
      return PitReply.fault('endpoint-unset');
    }

    try {
      final response = await cloak
          .post(
            Uri.parse(endpoint),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(SealBox.seal(body, secret)),
          )
          .timeout(_limit);

      if (response.statusCode == 404) {
        return const PitReply(admitted: false);
      }
      if (response.statusCode != 200) {
        return PitReply.fault('status-${response.statusCode}');
      }

      final Map<String, dynamic> raw =
          jsonDecode(response.body) as Map<String, dynamic>;
      final PitReply reply = PitReply.parse(raw);
      if (reply.admitted && reply.hasTarget) {
        await _stash.writeTarget(reply.target!);
        if (reply.expiresAt != null) {
          await _stash.writeUntil(reply.expiresAt!);
        }
      }
      return reply;
    } catch (error) {
      return PitReply.fault(error.toString());
    }
  }
}
