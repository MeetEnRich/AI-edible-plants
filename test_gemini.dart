import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = 'AIzaSyCTUO64-SBMlSYqO6lS-s0sm93R8VPMvxE';
  
  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
  );

  try {
    print('Calling Gemini...');
    final response = await model.generateContent([Content.text('Hello')]);
    print('Response: ' + (response.text ?? ''));
  } catch (e) {
    print('Error caught: ' + e.toString());
  }
}
