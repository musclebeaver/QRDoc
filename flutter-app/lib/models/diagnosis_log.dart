import 'dart:convert';

class DiagnosisLog {
  final String id;
  final String diseaseName;     // 병명 (예: 2형 당뇨병)
  final String diseaseCode;     // 질병 분류 코드 (예: E11)
  final String diagnosisDate;    // 진단 일자 (YYYY-MM-DD)
  final String hospitalName;     // 진단 의료 기관 (예: 서울대학교병원)
  final String doctorOpinion;    // 주치의 소견 및 특이사항
  final String inputMethod;      // GEMINI_AI_OCR or MANUAL
  final bool isActive;

  DiagnosisLog({
    required this.id,
    required this.diseaseName,
    required this.diseaseCode,
    required this.diagnosisDate,
    required this.hospitalName,
    required this.doctorOpinion,
    required this.inputMethod,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diseaseName': diseaseName,
      'diseaseCode': diseaseCode,
      'diagnosisDate': diagnosisDate,
      'hospitalName': hospitalName,
      'doctorOpinion': doctorOpinion,
      'inputMethod': inputMethod,
      'isActive': isActive,
    };
  }

  factory DiagnosisLog.fromMap(Map<String, dynamic> map) {
    return DiagnosisLog(
      id: map['id'] ?? '',
      diseaseName: map['diseaseName'] ?? '',
      diseaseCode: map['diseaseCode'] ?? '',
      diagnosisDate: map['diagnosisDate'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      doctorOpinion: map['doctorOpinion'] ?? '',
      inputMethod: map['inputMethod'] ?? 'MANUAL',
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory DiagnosisLog.fromJson(String source) => DiagnosisLog.fromMap(json.decode(source));
}
