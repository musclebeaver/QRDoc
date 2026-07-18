// Configuration
const DEV_PORT = '3000';
const API_BASE_URL = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `http://localhost:${DEV_PORT}/api`
    : '/api'; // Relative route in production

// Global state variables (wiped on exit)
let patientData = null;
let decryptionKey = null;
let countdownInterval = null;
let timeLeft = 180; // 3 minutes (180 seconds)
const TOTAL_TIME = 180;

// Circular Progress Ring Configuration
const ring = document.getElementById('timer-ring');
const radius = ring.r.baseVal.value;
const circumference = 2 * Math.PI * radius;

// Initialize Ring Stroke Dasharray
ring.style.strokeDasharray = `${circumference} ${circumference}`;
ring.style.strokeDashoffset = 0;

function setProgress(percent) {
    const offset = circumference - (percent / 100) * circumference;
    ring.style.strokeDashoffset = offset;
}

// Helper: Convert Base64 string to Uint8Array
function base64ToUint8Array(base64String) {
    const raw = window.atob(base64String);
    const rawLength = raw.length;
    const array = new Uint8Array(new ArrayBuffer(rawLength));
    for (let i = 0; i < rawLength; i++) {
        array[i] = raw.charCodeAt(i);
    }
    return array;
}

// Helper: Convert URL-safe Base64 (Base64Url) to standard Base64
function base64UrlToBase64(base64UrlString) {
    let str = base64UrlString.replace(/-/g, '+').replace(/_/g, '/');
    while (str.length % 4) {
        str += '=';
    }
    return str;
}

// Core Decryption Logic using Web Crypto API (AES-GCM)
async function decryptPayload(ciphertextB64, ivB64, tagB64, secretKeyB64Url) {
    try {
        const ciphertext = base64ToUint8Array(ciphertextB64);
        const iv = base64ToUint8Array(ivB64);
        const tag = base64ToUint8Array(tagB64);
        const rawKey = base64ToUint8Array(base64UrlToBase64(secretKeyB64Url));

        // Concatenate ciphertext and tag for Web Crypto API AES-GCM specification
        const encryptedData = new Uint8Array(ciphertext.length + tag.length);
        encryptedData.set(ciphertext);
        encryptedData.set(tag, ciphertext.length);

        // Import raw symmetric key
        const cryptoKey = await window.crypto.subtle.importKey(
            'raw',
            rawKey,
            { name: 'AES-GCM' },
            false,
            ['decrypt']
        );

        // Perform GCM decryption
        const decryptedBuffer = await window.crypto.subtle.decrypt(
            {
                name: 'AES-GCM',
                iv: iv,
                tagLength: 128
            },
            cryptoKey,
            encryptedData
        );

        // Decode binary buffer to text string
        return new TextDecoder().decode(decryptedBuffer);
    } catch (err) {
        console.error('Decryption failed:', err);
        throw new Error('암호 복호화 과정에서 오류가 발생했습니다. 올바른 키가 아니거나 손상된 데이터입니다.');
    }
}

// Initialize Application Page
async function init() {
    // 1. URL 파라미터 파싱
    const urlParams = new URLSearchParams(window.location.search);
    const dataId = urlParams.get('id');
    const secretKeyHash = window.location.hash.substring(1); // URL Hash (# 뒤의 값)

    if (!dataId || !secretKeyHash) {
        showError('유효하지 않은 주소', '데이터 ID 혹은 복호화 암호 키가 누락되었습니다.');
        return;
    }

    decryptionKey = secretKeyHash;

    try {
        // 2. 서버에서 암호화 데이터 수집
        const response = await fetch(`${API_BASE_URL}/share/${dataId}`);
        
        if (!response.ok) {
            if (response.status === 404) {
                showError('데이터 만료됨', '데이터가 만료되었거나 이미 1회 조회가 이루어져 서버에서 완전히 삭제되었습니다.');
            } else {
                showError('네트워크 오류', '서버에서 데이터를 받아오는 과정에서 오류가 발생했습니다.');
            }
            return;
        }

        const data = await response.json(); // { ciphertext, iv, tag }

        // 3. 클라이언트 단 복호화 실행 (Zero-Knowledge)
        const decryptedText = await decryptPayload(data.ciphertext, data.iv, data.tag, decryptionKey);
        
        // 4. 구조화 JSON 파싱 및 데이터 렌더링
        patientData = JSON.parse(decryptedText);
        renderDashboard(patientData);

        // 5. 타이머 시작
        startCountdown();

    } catch (err) {
        showError('오류 발생', err.message || '데이터 처리에 실패했습니다.');
    }
}

// Render Dashboard DOM Elements
function renderDashboard(data) {
    // Hide loader & Show Dashboard
    document.getElementById('loading-state').classList.add('hidden');
    document.getElementById('dashboard').classList.remove('hidden');

    // Patient Profile
    document.getElementById('patient-name').textContent = data.profile?.name || '미기재';
    document.getElementById('patient-birth').textContent = data.profile?.birthDate || '미기재';
    document.getElementById('patient-blood').textContent = data.profile?.bloodType || '미기재';
    document.getElementById('patient-emergency').textContent = data.profile?.emergencyContact || '미기재';

    // Chronic Diseases
    const chronicContainer = document.getElementById('chronic-diseases-container');
    chronicContainer.innerHTML = '';
    const chronicList = data.profile?.chronicDiseases || [];
    if (chronicList.length > 0) {
        chronicList.forEach(disease => {
            const span = document.createElement('span');
            span.className = 'badge badge-disease';
            span.textContent = disease;
            chronicContainer.appendChild(span);
        });
    } else {
        chronicContainer.innerHTML = '<span class="no-alerts">지병 없음</span>';
    }

    // Allergies
    const allergiesContainer = document.getElementById('allergies-container');
    allergiesContainer.innerHTML = '';
    const allergyList = data.profile?.allergies || [];
    if (allergyList.length > 0) {
        allergyList.forEach(allergy => {
            const span = document.createElement('span');
            span.className = 'badge badge-allergy';
            span.textContent = allergy;
            allergiesContainer.appendChild(span);
        });
    } else {
        allergiesContainer.innerHTML = '<span class="no-alerts">알레르기 없음</span>';
    }

    // Medication logs table
    const medListContainer = document.getElementById('medication-list');
    medListContainer.innerHTML = '';
    const medications = data.medications || [];

    if (medications.length > 0) {
        medications.forEach(med => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="medication-name">${escapeHtml(med.medicineName)}</td>
                <td>${escapeHtml(med.dosage)}</td>
                <td>${med.frequencyPerDay}회</td>
                <td>${med.totalDays}일</td>
            `;
            medListContainer.appendChild(tr);
        });
    } else {
        medListContainer.innerHTML = '<tr><td colspan="4" style="text-align: center; color: var(--text-secondary);">복용 중인 약물이 없습니다.</td></tr>';
    }
}

// Timer Countdown Loop
function startCountdown() {
    timeLeft = TOTAL_TIME;
    updateTimerUI();

    countdownInterval = setInterval(() => {
        timeLeft--;
        updateTimerUI();

        // 30 Seconds warning
        if (timeLeft === 30) {
            document.getElementById('warning-toast').classList.remove('hidden');
        }

        // Timer ended
        if (timeLeft <= 0) {
            triggerExpiration();
        }
    }, 1000);
}

// Update countdown text & circle bar progress
function updateTimerUI() {
    const minutes = Math.floor(timeLeft / 60);
    const seconds = timeLeft % 60;
    const formattedSeconds = seconds < 10 ? '0' + seconds : seconds;
    const formattedMinutes = minutes < 10 ? '0' + minutes : minutes;

    document.getElementById('countdown-timer').textContent = `${formattedMinutes}:${formattedSeconds}`;
    
    // Circular Progress update
    const percent = (timeLeft / TOTAL_TIME) * 100;
    setProgress(percent);
}

// Wipes Patient Data and Forces Expiration Overlay
function triggerExpiration() {
    clearInterval(countdownInterval);
    
    // [보안 핵심] 브라우저 메모리에 상주된 환자 개인정보 완전 초기화 (Garbage Collection 유도)
    patientData = null;
    decryptionKey = null;

    // Reset DOM text contents
    const clearElements = ['patient-name', 'patient-birth', 'patient-blood', 'patient-emergency'];
    clearElements.forEach(id => {
        const el = document.getElementById(id);
        if (el) el.textContent = '***';
    });

    document.getElementById('medication-list').innerHTML = '';
    document.getElementById('chronic-diseases-container').innerHTML = '';
    document.getElementById('allergies-container').innerHTML = '';

    // Show Terminated Overlay
    document.getElementById('warning-toast').classList.add('hidden');
    document.getElementById('expired-overlay').classList.remove('hidden');
    document.getElementById('main-container').style.filter = 'blur(10px)';
}

// Error UI Display
function showError(title, message) {
    document.getElementById('loading-state').classList.add('hidden');
    document.getElementById('dashboard').classList.add('hidden');
    
    const errorState = document.getElementById('error-state');
    document.getElementById('error-title').textContent = title;
    document.getElementById('error-message').textContent = message;
    errorState.classList.remove('hidden');
    
    // Stop timer
    document.getElementById('timer-box').classList.add('hidden');
}

// HTML Escaping to prevent XSS (if medicine contains symbols)
function escapeHtml(string) {
    const matchHtmlRegExp = /["'&<>]/;
    const str = '' + string;
    const match = matchHtmlRegExp.exec(str);

    if (!match) {
        return str;
    }

    let escape;
    let html = '';
    let index = 0;
    let lastIndex = 0;

    for (index = match.index; index < str.length; index++) {
        switch (str.charCodeAt(index)) {
            case 34: // "
                escape = '&quot;';
                break;
            case 38: // &
                escape = '&amp;';
                break;
            case 39: // '
                escape = '&#39;';
                break;
            case 60: // <
                escape = '&lt;';
                break;
            case 62: // >
                escape = '&gt;';
                break;
            default:
                continue;
        }

        if (lastIndex !== index) {
            html += str.substring(lastIndex, index);
        }

        lastIndex = index + 1;
        html += escape;
    }

    return lastIndex !== index
        ? html + str.substring(lastIndex, index)
        : html;
}

// Start immediately on load
window.addEventListener('DOMContentLoaded', init);
