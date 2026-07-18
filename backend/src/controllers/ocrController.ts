import { Request, Response } from 'express';
import { ai } from '../config/gemini';

// Structured Output Schema for Gemini 1.5 Flash API
const prescriptionSchema = {
  type: 'OBJECT',
  properties: {
    prescriptionDate: {
      type: 'STRING',
      description: 'The date the prescription was issued (YYYY-MM-DD format). If not found, use current date or "UNKNOWN".',
    },
    medications: {
      type: 'ARRAY',
      description: 'List of prescribed medicines and their usage instructions.',
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
      description: 'List of diagnoses or ICD codes/names found in the document.',
      items: {
        type: 'STRING',
      },
    },
  },
  required: ['medications'],
};

export const processPrescriptionOCR = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'No image file uploaded.' });
      return;
    }

    const imageBuffer = req.file.buffer;
    const base64Image = imageBuffer.toString('base64');
    const mimeType = req.file.mimetype;

    const prompt = `
      너는 대한민국 의료 처방전 및 약봉투 전문 데이터 파서(Parser)다.
      제공된 이미지 내의 민감한 개인식별 정보(예: 환자 주민등록번호 전체 등)는 절대 추출하거나 노출하지 말라.
      오직 환자의 처방 일자, 처방 약물 목록, 그리고 진단 내역만 추출하여 제공된 JSON Schema와 100% 일치하도록 반환하라.
      정보가 애매하거나 누락된 항목은 임의로 지어내지 말고, 텍스트 타입은 "UNKNOWN", 숫자 타입은 0으로 채워라.
    `;

    // Calling the Google Gen AI SDK
    const response = await ai.models.generateContent({
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
        responseSchema: prescriptionSchema as any, // Cast due to SDK type flexibility
      },
    });

    const responseText = response.text;

    if (!responseText) {
      res.status(500).json({ error: 'AI did not return any parseable content.' });
      return;
    }

    const parsedJson = JSON.parse(responseText);

    res.status(200).json(parsedJson);
  } catch (error: any) {
    console.error('Error processing prescription OCR:', error);
    res.status(500).json({
      error: 'Failed to parse the prescription image using Gemini AI.',
      details: error.message,
    });
  }
};
