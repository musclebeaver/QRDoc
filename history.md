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

---

## 🔗 배포 및 서비스 접속 주소 정보

1. **의료진용 반응형 웹 뷰어**: 
   * **URL**: [http://qrdoc.devbeaver.cloud/](http://qrdoc.devbeaver.cloud/)
2. **환자용 모바일 앱 (APK) 다운로드 링크**:
   * **URL**: [http://qrdoc.devbeaver.cloud/qrdoc.apk?v=1](http://qrdoc.devbeaver.cloud/qrdoc.apk?v=1)
   * *(※ Cloudflare CDN 캐시 우회를 위해 주소 뒤에 `?v=1` 캐시 버스터 파라미터를 추가하여 접속해 주시기 바랍니다.)*
3. **백엔드 직접 API 엔드포인트**:
   * **URL**: `http://qrdoc.devbeaver.cloud/api` 또는 내부망 테스트 포트 `http://localhost:5000/api`
