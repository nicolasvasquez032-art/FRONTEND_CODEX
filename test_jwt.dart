
void main() {
  String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiMTk2ZTgxYS1hNGJiLTRjOTktYjQ3OS1lNGZiZTEwMDhhNmMiLCJlbWFpbCI6Im5pY29sYXN2YXNxdXVlejAzMkBnbWFpbC5jb20iLCJyb2xlIjoiY2FuZGlkYXRlIiwiaXNfcHJlbWl1bSI6ZmFsc2UsImV4cCI6MTc5MTE1MjQ2Nn0.iR0q2nVV66OOT1WdLuah6ysHWPnrwt2YGDt8PDag51w";
  
  final parts = token.split('.');
  String payload = parts[1];
  payload = payload.replaceAll('-', '+').replaceAll('_', '/');
  while (payload.length % 4 != 0) {
    payload += '=';
  }

  try {
    final decoded = String.fromCharCodes(
      Uri.parse(
        'data:application/octet-stream;base64,$payload',
      ).data!.contentAsBytes(),
    );
    print("Decoded: $decoded");
  } catch (e) {
    print("Error: $e");
  }
}
