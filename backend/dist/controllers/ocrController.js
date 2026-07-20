"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processPrescriptionOCR = void 0;
const gemini_1 = require("../config/gemini");
// Structured Output Schema for Gemini 3.5 Flash API supporting Prescriptions and Medical Certificates
const prescriptionSchema = {
    type: 'OBJECT',
    properties: {
        documentType: {
            type: 'STRING',
            description: 'The type of the medical document. Use "PRESCRIPTION" for prescription/medicine envelope, "MEDICAL_CERTIFICATE" for diagnosis certificate/소견서/진단서, or "UNKNOWN".',
        },
        prescriptionDate: {
            type: 'STRING',
            description: 'The date the document was issued (YYYY-MM-DD format). If not found, use current date or "UNKNOWN".',
        },
        medications: {
            type: 'ARRAY',
            description: 'List of prescribed medicines and their usage instructions (empty array if not a prescription).',
            items: {
                type: 'OBJECT',
                properties: {
                    medicineName: {
                        type: 'STRING',
                        description: 'The name of the drug/medicine. Must not be empty.',
                    },
                    dosage: {
                        type: 'STRING',
                        description: 'Dosage quantity per intake, e.g., "1정", "1.5정", "5ml". Use "UNKNOWN" if not clear.',
                    },
                    frequencyPerDay: {
                        type: 'INTEGER',
                        description: 'Number of times the medicine is taken per day. Use 0 if unknown.',
                    },
                    totalDays: {
                        type: 'INTEGER',
                        description: 'Total number of days the medicine is prescribed. Use 0 if unknown.',
                    },
                },
                required: ['medicineName', 'dosage', 'frequencyPerDay', 'totalDays'],
            },
        },
        diagnoses: {
            type: 'ARRAY',
            description: 'List of diagnoses or medical conditions found in the document (empty array if none found).',
            items: {
                type: 'OBJECT',
                properties: {
                    diseaseName: {
                        type: 'STRING',
                        description: 'The formal name of the disease/diagnosis (e.g. "본태성 고혈압", "2형 당뇨병"). Must not be empty.',
                    },
                    diseaseCode: {
                        type: 'STRING',
                        description: 'The KCD/ICD-10 classification code of the disease (e.g. "I10", "E11"). Use "UNKNOWN" if not found.',
                    },
                    diagnosisDate: {
                        type: 'STRING',
                        description: 'The date of diagnosis (YYYY-MM-DD format). If not found, use the document date or "UNKNOWN".',
                    },
                    hospitalName: {
                        type: 'STRING',
                        description: 'Name of the hospital or clinic issuing the document. Use "UNKNOWN" if not found.',
                    },
                    doctorOpinion: {
                        type: 'STRING',
                        description: 'Doctor\'s clinical opinion, notes, or advice (의사소견/치료내용). Use "" if empty.',
                    },
                },
                required: ['diseaseName', 'diseaseCode', 'diagnosisDate', 'hospitalName', 'doctorOpinion'],
            },
        },
    },
    required: ['documentType', 'prescriptionDate', 'medications', 'diagnoses'],
};
const processPrescriptionOCR = async (req, res) => {
    try {
        if (!req.file) {
            res.status(400).json({ error: 'No image file uploaded.' });
            return;
        }
        const imageBuffer = req.file.buffer;
        const base64Image = imageBuffer.toString('base64');
        const mimeType = req.file.mimetype;
        const prompt = `
      너는 대한민국 의료 처방전, 약봉투, 진단서 및 소견서 전문 데이터 파서(Parser)다.
      제공된 이미지 내의 민감한 개인식별 정보(예: 환자 주민등록번호 전체, 주소, 상세 전화번호 등)는 절대 추출하거나 노출하지 말라.
      오직 환자의 문서 발행일자(또는 처방일자), 처방 약물 목록, 그리고 진단 내역(병명, 질병코드, 진단일, 소견 등)만 정확히 추출하여 제공된 JSON Schema와 100% 일치하도록 반환하라.
      정보가 애매하거나 누락된 항목은 임의로 지어내지 말고, 텍스트 타입은 "UNKNOWN" 또는 "", 숫자 타입은 0으로 채워라.
    `;
        // Calling the Google Gen AI SDK
        const response = await gemini_1.ai.models.generateContent({
            model: 'gemini-3.5-flash',
            contents: [
                {
                    inlineData: {
                        mimeType: mimeType,
                        data: base64Image,
                    },
                },
                prompt,
            ],
            config: {
                responseMimeType: 'application/json',
                responseSchema: prescriptionSchema, // Cast due to SDK type flexibility
            },
        });
        const responseText = response.text;
        if (!responseText) {
            res.status(500).json({ error: 'AI did not return any parseable content.' });
            return;
        }
        const parsedJson = JSON.parse(responseText);
        res.status(200).json(parsedJson);
    }
    catch (error) {
        console.error('Error processing prescription OCR:', error);
        res.status(500).json({
            error: 'Failed to parse the prescription image using Gemini AI.',
            details: error.message,
        });
    }
};
exports.processPrescriptionOCR = processPrescriptionOCR;
