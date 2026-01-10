// lib/services/gemini_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:libyan_banking_hub/models/models.dart';

class GeminiService {
  // يفضل وضع المفتاح في ملف آمن وليس هنا مباشرة
  final String _apiKey = 'YOUR_API_KEY_HERE';

  Future<String> analyzeLiquidity(List<Branch> branches) async {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);

    // تجهيز البيانات للنص (Prompt Engineering)
    final prompt = "حلل حالة السيولة لهذه الفروع وقدم نصيحة: ${branches.map((b) => '${b.name}: ${b.status}').join(', ')}";

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    return response.text ?? "لم أتمكن من التحليل حالياً.";
  }
}