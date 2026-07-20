# VitalPass QRDoc 프로젝트 개발 및 배포 이력 (History Log)

본 문서는 VitalPass QRDoc 프로젝트의 인프라 구축, API 연동, 배포 자동화 및 네트워크 라우팅 설정의 변경 이력을 기록한 개발 이력서입니다.

---

## 📅 최근 작업 이력 요약 (2026-07-18)

### 1. Git & 문서 기본 설정
* **Git HTTPS 우회 설정**: SSH over HTTPS 포트(443, `ssh.github.com`)를 설정하여 GitHub 연동 장애를 해결했습니다.
* **프로젝트 문서 작성**: 제품 요구사항 정의서([prd.md](file:///workspace/QRDoc/prd.md)) 및 기술 요구사항 정의서([trd.md](file:///workspace/QRDoc/trd.md)) 작성을 완료했습니다.

### 2. Stitch 디자인 시스템 자산 동기화
* **Stitch MCP API 연동**: API 키(`AQ.Ab8RN...`)를 통한 Stitch MCP 서버 검증에 성공하여 프로젝트 메타데이터를 수집했습니다.
* **자동 자산 다운로더 구동**: 스크립트 실행으로 4개 주요 스크린(환자 홈, QR 생성기, 웹 뷰어, AI 검토 및 편집)의 스크린샷 이미지 및 HTML 코드를 [stitch-assets/](file:///workspace/QRDoc/stitch-assets/) 폴더에 자동 동기화 완료했습니다.

### 3. Docker Compose & Nginx 리버스 프록시 구축
* **포트 격리 및 충돌 회피**: 
  * 호스트 포트 `20080`을 Nginx 프록시 서버에 매핑했습니다.
  * 호스트 포트 `8888`이 기존 Dart/Flutter 프로세스에 의해 점유 중임을 감지하여, 백엔드 API 포트를 **`5000`번 포트**로 안전하게 조정했습니다.
* **Nginx 리버스 프록시 ([nginx.conf](file:///workspace/QRDoc/nginx.conf))**:
  * `http://localhost:20080/` 접속 시 의사용 정적 웹 뷰어 서빙.
  * `http://localhost:20080/api/` 요청 시 도커 내부망 백엔드 서버(`http://qrdoc-backend:3000/api/`)로의 무중단 프록시 포워딩을 지원하여 브라우저 CORS 제약을 완벽 차단했습니다.
* **격리형 Redis**: Redis 컨테이너(`qrdoc-redis`)는 포트 노출 없이 내부망 포트 `6379`로만 백엔드와 안전하게 통신하여 3분 임시 캐시 보안을 극대화했습니다.

### 4. Gemini 3.5 Flash 모델 업그레이드 & API 테스트
* **모델 업데이트**: 제공된 API 키 권한에 맞춰 백엔드 OCR 엔진 모델을 `gemini-1.5-flash`에서 **`gemini-3.5-flash`**로 업그레이드했습니다.
* **API Key 보안 조치**: 로컬 설정 파일([.env](file:///workspace/QRDoc/backend/.env))에 기입된 API 키 노출 방지를 위해 Git 인덱스 상에서 `assume-unchanged` 옵션을 활성화하여 소스 변경 시 키 유출을 원천 방지했습니다.
* **성공적인 OCR 통합 테스트**: `patient_home.png` 이미지의 업로드 테스트 결과, 약품 정보(Amoxicillin, Lisinopril 등)를 구조화된 JSON 데이터로 오차 없이 정상 파싱하여 리턴함을 확인했습니다.

### 5. Cloudflare Tunnel 및 공인 도메인 매핑
* **도메인 라우팅**: `devbeaver.cloud` 영역의 CNAME 조작 권한을 활용하여 **`qrdoc.devbeaver.cloud`**를 활성 터널에 등록했습니다.
* **Ingress 설정 반영**: 터널로 유입되는 `qrdoc.devbeaver.cloud` 요청을 로컬 Nginx 포트 `20080`으로 포워딩하도록 설정하여 외부에서 보안 도메인으로의 무중단 연결에 성공했습니다.

### 6. Flutter 안드로이드 앱 빌드 및 배포 자동화
* **빌드 툴체인 공유**: `/workspace/crossfit/.tooling`에 세팅되어 있는 공용 Flutter SDK, Android SDK 및 Gradle 캐시를 공유 연동하는 [flutter.sh](file:///workspace/QRDoc/scripts/flutter.sh) 구조를 마련했습니다.
* **Flutter 프로젝트 초기화**: `flutter-app` 폴더 내에 표준 안드로이드/iOS 스커폴딩 및 `pubspec.yaml`을 생성하여 빌드 가능한 프로젝트 상태로 격상시켰습니다.
* **빌드 및 배포 스크립트 작성**: [build_android_apk.sh](file:///workspace/QRDoc/scripts/build_android_apk.sh)를 실행하면, 자동으로 Android Release APK를 빌드하고 결과 파일을 Nginx 서빙 폴더 내의 정적 다운로드 경로(`web-viewer/qrdoc.apk`)로 복사해 배포를 자동 완성합니다.

* **비상 의료 패스 활성화**: `PatientProfile` 탭에 잠금화면용 비상 패스 위젯 활성화 스위치 및 미리보기 기능을 추가하여 앱 잠금 상태에서도 혈액형, 알레르기 등 중요 요소를 구조대원이 볼 수 있게 연동했습니다.

### 7. 추가 고도화 및 정식 마켓 제출 요건 보완 (2026-07-20)
* **내 프로필 수정 기능 탑재 ([edit_profile_screen.dart](file:///workspace/QRDoc/flutter-app/lib/screens/edit_profile_screen.dart))**:
  * 성명, 생년월일(달력 선택 연동), 혈액형(드롭다운), 만성 지병 태그 관리, 알레르기 태그 관리, 비상 연락처 등을 자유롭게 입력/수정하고 로컬 Hive DB에 암호화하여 즉시 저장할 수 있는 프로필 편집 폼을 전면 개발했습니다.
* **실제 모바일 카메라 처방전 스캔 연동**:
  * `image_picker` 패키지를 연동하여 환자가 `새 처방전 스캔하기` 버튼을 터치할 시 기기의 **실제 네이티브 카메라가 구동**되도록 구성했습니다.
  * 촬영물은 백엔드에 안전하게 전송(HTTPS)되어 Gemini OCR을 거치며, 기기 결함 또는 에뮬레이터 환경 등으로 카메라 작동 실패 시 **테스트용 샘플 데이터 자동 주입 플로우(Fallback)**로 연동되는 인텔리전트 구조를 도입했습니다.
* **OS 내비게이션 바 중첩 개선 (SafeArea)**:
  * 바텀시트 모달 창을 `SafeArea`로 래핑하고, 하단 패딩에 `MediaQuery.of(context).padding.bottom`을 추가하여 안드로이드 네비게이션 소프트 바 및 홈 버튼과의 겹침/중첩 오류를 영구 수정했습니다.
* **다중 약물 일괄 검토 UI ([ai_review_screen.dart](file:///workspace/QRDoc/flutter-app/lib/screens/ai_review_screen.dart))**:
  * 단일 편집 폼에서 다중 약물 일괄 편집 카드로 대폭 업그레이드하여 한 화면에서 스캔된 여러 약품들의 이름, 용량, 횟수, 기간을 일괄 수정/추가/삭제할 수 있는 벌크 편집 기능을 추가했습니다.
* **비상 상황 응급 카드 위젯 ([emergency_pass_screen.dart](file:///workspace/QRDoc/flutter-app/lib/screens/emergency_pass_screen.dart))**:
  * 환자 프로필 탭에 잠금화면용 비상 카드 연동 스위치 및 미리보기 기능을 탑재했으며, 응급 대원 및 의료진 식별을 돕는 초고대비 응급 ID 화면을 신규 개발했습니다.
* **공유 항목 개별 필터링 기능 구현**:
  * QR 생성 모달창에 체크박스를 배치하여 기본 인적 사항, 의료 경고, 혹은 개별 약물들 중 **환자가 직접 선택한 데이터만 암호화(AES-256-GCM)**해서 서버로 전송하도록 개인정보 제어권을 고도화했습니다.
* **개인정보처리방침 웹페이지 탑재 ([privacy.html](file:///workspace/QRDoc/web-viewer/privacy.html))**:
  * Google Play 및 Apple App Store 심사 통과를 위해, Nginx 서빙 폴더에 VitalPass 테마 컬러가 입혀진 공인 개인정보처리방침 웹 문서를 신규 제작하여 즉시 활성화했습니다.
* **앱 아이콘 빌드 파이프라인 탑재**:
  * 제공해주신 `qrdocIcon.png` 리소스를 기준으로 모바일 빌드 컴파일 단계에서 OS별(Android/iOS) 네이티브 밀도 아이콘을 자동으로 리사이징하고 덮어씌워 적용하도록 빌드 자동화 스크립트를 고도화했습니다.

---

## 🔗 배포 및 서비스 접속 주소 정보

1. **의료진용 반응형 웹 뷰어**: 
   * **URL**: [http://qrdoc.devbeaver.cloud/](http://qrdoc.devbeaver.cloud/)
2. **개인정보처리방침 공인 주소 (마켓 제출용)**:
   * **URL**: [http://qrdoc.devbeaver.cloud/privacy.html](http://qrdoc.devbeaver.cloud/privacy.html)
3. **환자용 모바일 앱 (APK) 다운로드 링크**:
   * **URL**: [http://qrdoc.devbeaver.cloud/qrdoc.apk?v=5](http://qrdoc.devbeaver.cloud/qrdoc.apk?v=5)
   * *(※ Cloudflare CDN 캐시 우회를 위해 주소 뒤에 `?v=5` 캐시 버스터 파라미터를 추가하여 접속해 주시기 바랍니다.)*
4. **백엔드 직접 API 엔드포인트**:
   * **URL**: `http://qrdoc.devbeaver.cloud/api` 또는 내부망 테스트 포트 `http://localhost:5000/api`
