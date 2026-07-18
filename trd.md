# Technical Requirement Document (TRD): QRDoc (VitalPass)

## 1. 시스템 아키텍처 개요 (System Architecture)
본 시스템은 개인정보 유출 리스크를 원천 차단하기 위해 **'Zero-Knowledge (무지식 증명) 지향형 하이브리드 아키텍처'**를 채택한다. 모든 민감 데이터의 암호화 및 복호화는 클라이언트 단(Flutter 앱 및 웹 브라우저)에서 수행되며, 백엔드 중계 서버는 암호화된 바이너리 데이터를 메모리 상에서 3분간 중계하는 역할만 수행한다.

```text
[환자용 Flutter 앱]                               [의료진용 반응형 웹 뷰어]
│                                                    ▲
│ (1) AES-256-GCM 암호화                              │ (5) URL Fragment(#) Key로 복호화
▼                                                    │
[암호화 데이터] ──(2) POST (유효기간 3분)──> [임시 중계 서버] ──(4) GET ──┘
(Node.js/Redis)
│
(3) QR 코드 URL 매핑
(https://domain.com/v/id#key)
```

---

## 2. 기술 스택 (Technology Stack)

### 2.1 클라이언트 (Client)
* **환자용 모바일 애플리케이션 (Patient App):**
  * **Framework:** Flutter (Dart 3.x)
  * **Local Storage:** `flutter_secure_storage` (생체인증 연동 암호화 키 관리) + `hive` 또는 `sqflite` (AES-256 적용 로컬 DB)
  * **AI OCR SDK:** `google_generative_ai` (서버리스/백엔드 프록시 호출을 통한 안전한 키 관리 적용)
  * **Camera & QR:** `camera` (처방전 촬영용), `qr_flutter` (의사용 QR 코드 생성)
* **의료진용 웹 뷰어 (Medical Web Viewer):**
  * **Framework:** HTML5 / Vanilla TS (또는 Next.js / Vite Static HTML Export)
  * **Styling:** Vanilla CSS (다양한 의료기기 화면 해상도 대응을 위한 반응형 레이아웃)
  * **Crypto:** `Web Crypto API` (브라우저 내장 네이티브 암호화 엔진 활용)

### 2.2 백엔드 & 인프라 (Backend & Infrastructure)
* **중계 서버 (Relay Server):**
  * **Runtime:** Node.js (TypeScript) + Express 또는 Fastify
* **In-Memory 데이터베이스:** 
  * **Redis:** 임시 데이터 중계 및 `TTL (Time-To-Live)`을 활용한 3분(180초) 후 영구 자동 파기
* **AI Engine:**
  * **Model:** Google Gemini 1.5 Flash API (Multimodal 이미지 및 텍스트 구조화 동시 처리)
* **배포 인프라:**
  * **Serverless / Container:** AWS Lambda + API Gateway 또는 AWS ECS Fargate
  * **CDN / Hosting:** Vercel 또는 AWS S3 + CloudFront (웹 뷰어 호스팅)

---

## 3. 핵심 기술적 구현 명세 (Technical Specifications)

### 3.1 종단간 암호화 및 휘발성 QR 메커니즘 (End-to-End Encryption)
1. **데이터 패키징:** Flutter 앱 내 로컬 DB에서 공유할 환자 프로필 및 최근 복용 약물 목록을 하나의 JSON 데이터로 결합한다.
2. **클라이언트 대칭키 생성:** 무작위 대칭키(`Secret_Key`, 256-bit)와 초기화 벡터(`IV`)를 앱 내에서 실시간 생성한다.
3. **데이터 암호화:** `AES-256-GCM` 알고리즘을 사용하여 JSON 데이터를 암호화하여 `ciphertext`를 생성하고 검증용 `tag`를 획득한다.
4. **중계 서버 업로드:**
   * Flutter 앱은 중계 서버의 `/api/share` 엔드포인트로 `ciphertext`, `iv`, `tag` 패키지를 전송한다.
   * 서버는 수신된 데이터를 Redis에 저장하고, 무작위 매핑 ID(`Data_ID`)를 생성하여 반환한다.
   * **Redis TTL 및 휘발성 설정:** `SETEX share:{dataId} 180 {json_payload}` (3분 후 메모리에서 자동 삭제되며 디스크에 백업하지 않음).
5. **URL Fragment ID 기반 QR 생성:**
   * 앱은 서버로부터 받은 `Data_ID`와 로컬에서 보관 중인 `Secret_Key`를 결합하여 URL을 생성한다.
   * **구조:** `https://viewer.qrdoc.com/view/{Data_ID}#{Secret_Key}`
   * **보안 핵심:** URL의 `#`(Fragment identifier) 뒷부분은 HTTP 요청 시 서버로 전송되지 않는 브라우저 고유 명세이므로, 중계 서버는 어떠한 경우에도 `Secret_Key`를 알 수 없다.
6. **웹 브라우저 복호화 및 즉시 파기 (Burn After Reading):**
   * 의사가 QR을 스캔하면 브라우저가 `Data_ID`를 기반으로 서버에서 `ciphertext`, `iv`, `tag` 데이터를 가져온다.
   * **[보안 보완] 조회 즉시 파기:** 중계 서버는 해당 `GET /api/share/:dataId` 요청을 처리한 즉시 Redis에서 데이터를 영구 삭제하여 재조회 공격을 방지한다.
   * 브라우저는 주소창의 `#` 뒤에 붙은 `Secret_Key`를 가져와 `Web Crypto API`로 복호화하여 화면에 출력한다.

### 3.2 Gemini 1.5 Flash를 이용한 단일 파이프라인 OCR (Proxy Architecture)
1. **이미지 처리:** Flutter `camera` 패키지를 통해 처방전을 촬영한 후, `flutter_image_compress`를 통해 2MB 이하의 JPEG 이미지로 압축 및 인코딩한다.
2. **Gemini API Proxy 호출 (보안):**
   * 모바일 앱 내 API Key 노출 방지를 위해 Flutter 앱은 이미지 바이너리를 Node.js 중계 서버의 `/api/ocr` 엔드포인트로 전송한다.
   * 서버는 수신한 이미지를 환경 변수로 주입된 `GEMINI_API_KEY`를 통해 Gemini 1.5 Flash API로 안전하게 전달한다.
   * 서버는 데이터 보안을 위해 원본 이미지와 추출된 데이터를 로깅하거나 디스크에 임시 저장하지 않는다.
3. **구조화 프롬프트 및 스키마 강제 (Structured Outputs):**
   * **Prompt:** *"너는 대한민국 의료 처방전 전문 데이터 파서다. 이미지 내의 민감한 환자 식별 정보(주민번호 등)를 제외하고, 복용 약물 목록과 진단 내역만 추출하여 완벽한 JSON 포맷으로 반환하라. 확실하지 않은 약물 정보는 빈 값으로 두지 말고 필드 값을 'UNKNOWN'으로 채워라. 억지로 유추하지 말 것."*
   * Gemini API의 `responseSchema` 옵션을 활용하여 아래 정의된 JSON 구조체(Schema)와 100% 일치하는 결과를 반환하도록 강제한다.
4. **로컬 스토리지 반영:** 반환된 JSON 데이터를 유저 검토 UI에 바인딩하고, 유저 승인 시 Flutter 로컬 Hive/sqflite DB에 암호화하여 저장한다.

---

## 4. 데이터 모델 명세 (Data Model Specification)

### 4.1 로컬 데이터베이스 스키마 (Flutter Hive/sqflite)
```dart
// PatientProfile: 환자 기본 인적사항 및 핵심 병력
class PatientProfile {
  final String uuid;
  final String name;
  final String birthDate; // YYYY-MM-DD
  final String bloodType;
  final List<String> chronicDiseases; // 만성 질환 이력
  final List<String> allergies; // 알레르기 유무
  final String emergencyContact;
  final String updatedAt; // ISO 8601
}

// MedicationLog: 복용 약물 이력 및 AI 추출 기록
class MedicationLog {
  final String id;
  final String medicineName; // 약품명
  final String dosage; // 1회 복용량 (예: 1정)
  final int frequencyPerDay; // 1일 복용 횟수
  final int totalDays; // 총 복용일수
  final String prescriptionDate; // 처방 일자
  final String inputMethod; // 'GEMINI_AI_OCR' 또는 'MANUAL'
  final bool isActive; // 현재 복용 여부
}
```

### 4.2 중계 서버 API 및 Redis 데이터 포맷

#### 공유 데이터 등록 API (`POST /api/share`):
* **Request Body**:
  ```json
  {
    "ciphertext": "Base64_Encoded_AES_GCM_Ciphertext",
    "iv": "Base64_Encoded_IV",
    "tag": "Base64_Encoded_Tag"
  }
  ```
* **Response Body**:
  ```json
  {
    "dataId": "string_uuid_or_short_id"
  }
  ```

#### 공유 데이터 조회 API (`GET /api/share/:dataId`):
* **Response Body**:
  ```json
  {
    "ciphertext": "Base64_Encoded_AES_GCM_Ciphertext",
    "iv": "Base64_Encoded_IV",
    "tag": "Base64_Encoded_Tag"
  }
  ```

#### Redis Storage 구조:
* **Key**: `share:{dataId}`
* **Value**: `{ "ciphertext": "...", "iv": "...", "tag": "..." }` (JSON String)
* **Expiry**: 180 seconds (조회 시 즉시 삭제 로직과 중첩 운영)

---

## 5. 보안 및 성능 비기능적 요구사항

### 5.1 보안 (Security)
* **Transport Layer Security**: 모든 API 엔드포인트는 HTTPS TLS 1.3 적용 및 HSTS(HTTP Strict Transport Security)를 강제 적용한다.
* **서버 컴플라이언스**: 중계 서버 환경에서는 Redis의 AOF 및 RDB 스냅샷 기능을 차단하여 휘발성 데이터가 디스크 잔재물로 남는 것을 방지한다.
* **CORS 및 접근 제어**: `GET /api/share/:dataId` API는 사전에 정의된 의료진 전용 웹 뷰어 도메인으로부터의 원본 요청(Origin)만 허용한다.

### 5.2 성능 및 사용성 (Performance & Reliability)
* **AI 처리 속도**: Gemini 1.5 Flash 모델의 특성을 활용하여 이미지 업로드부터 JSON 결과 반환까지의 E2E Latency를 평균 2.5초 이내로 유지한다.
* **의료진 뷰어 응답성**: 의사가 QR 코드를 스캔한 후 화면 로드, API 호출, 브라우저 단 복호화 완료 후 데이터 렌더링까지 총 소요 시간을 1.5초 이내로 달성한다.
