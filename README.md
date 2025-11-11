# TRACE - iOS 여행 계획 및 기록 앱


TRACE는 MVVM 아키텍처 기반으로 개발된 iOS 여행 계획 및 기록 관리 앱입니다. 사용자가 여행 계획을 세우고, 실시간으로 위치를 추적하며, 여행 기록을 사진과 함께 저장할 수 있는 종합적인 여행 관리 솔루션을 제공합니다.

## 📱 앱 스크린샷

<img width="150" alt="1" src="https://github.com/user-attachments/assets/60584dd2-1e2e-46c4-b617-7266cd470d37" />
<img width="150"  alt="2" src="https://github.com/user-attachments/assets/25351c92-c0be-48f1-9d17-b39a0bb85f7b" />
<img width="150"  alt="3" src="https://github.com/user-attachments/assets/db3ed93a-185b-4fe6-b6e5-3105af15dd7d" />
<img width="150"  alt="4" src="https://github.com/user-attachments/assets/bbf13bd5-4bb9-4247-aaf9-2a4e3c3bef64" />
<img width="150"  alt="5" src="https://github.com/user-attachments/assets/c85c3a8b-f4d0-4989-b35c-88a94bc84e2f" />


</div>

## 🏗️ 아키텍처 패턴

### MVVM (Model-View-ViewModel) 아키텍처
- **View**: 사용자 인터페이스 담당 (UIViewController)
- **ViewModel**: 비즈니스 로직 처리 및 View와 Model 간 데이터 바인딩
- **Model**: 데이터 모델 및 비즈니스 엔티티
- **화면 간 데이터 일관성 문제 해결**로 안정적인 사용자 경험 제공

### Protocol-Oriented Programming (POP)
```swift
protocol BaseViewModel {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}
```
- 공통 로직을 프로토콜로 추상화하여 코드 재사용성 극대화
- 일관된 ViewModel 인터페이스로 개발 효율성 향상

### Singleton Pattern
핵심 매니저 클래스들의 일원화된 관리:
- `RealmManager.shared`: 데이터베이스 접근 관리
- `NotificationManager.shared`: 로컬 알림 시스템 관리
- `MapManager`: 지도 및 위치 서비스 관리
- 중복 인스턴스 방지 및 메모리 효율성 확보

### Router Pattern
```swift
enum NetworkRouter: URLRequestConvertible {
    case kakaoMapsearch(query: String, headers: HTTPHeaders)
    case googleMapsSearch(query: String)
}
```
- Kakao Places API, Google Places API 요청 로직 모듈화
- API 확장 시 최소 수정으로 대응 가능한 확장성 제공

## 🛠️ 기술 스택

### 반응형 프로그래밍
- **RxSwift**: 사용자 입력과 UI 업데이트 간의 비동기 흐름을 일관성 있게 관리
- 데이터 바인딩을 통한 선언적 UI 프로그래밍 구현

### 네트워킹
- **Alamofire**: HTTP 네트워크 통신 라이브러리
- 네트워크 응답을 실시간으로 처리하고 UI에 자연스럽게 반영

### 데이터베이스
- **Realm**: 로컬 데이터베이스
- 네트워크 연결이 없는 상황에서도 오프라인 데이터 접근 가능
- App Groups를 통한 메인 앱과 위젯 간 데이터 공유

### 위치 및 지도 서비스
- **MapKit**: 지도 표시 및 경로 시각화
- **CoreLocation**: 사용자 위치 실시간 추적
- API 응답 데이터를 RxSwift 스트림으로 지도에 실시간 반영

### UI/UX 프레임워크
- **UICollectionViewCompositionalLayout**: 여행 기록, 장소 목록 등 복잡한 섹션 기반 UI를 선언적으로 구성
- **FSCalendar**: 캘린더 UI 구현 및 여행 일정 시각화
- **SnapKit**: Auto Layout 코드 작성 최적화

### 이미지 처리
- **Kingfisher**: 비동기 이미지 다운로드, 캐싱 및 메모리 최적화
- **Photos/PhotosUI**: 여행 기록에 다중 이미지 첨부 기능 및 권한 처리

### 알림 시스템
- **UserNotifications**: 로컬 알림 시스템 설계
- 여행 전날 자동 알림 발송 기능

### 다국어 지원
- **NSLocalizedString**: 한국어/영어/일본어 다국어 지원

### 분석 및 모니터링
- **Firebase Analytics**: 사용자 행동 패턴, 화면 전환, 기능 사용률 등 핵심 지표 실시간 수집
- **Firebase Crashlytics**: 앱 크래시 및 오류 자동 수집, 사용자 환경별 안정성 모니터링

### 위젯
- **WidgetKit + SwiftUI**: 홈 화면 위젯 개발
- 다가오는 여행 D-day 정보 실시간 표시

## ✨ 주요 기능

### 🗺️ 여행 계획 생성 및 관리
- 국가, 여행지, 여행 일자를 입력해 전체 일정을 일차별로 여행 계획 생성
- 국내/해외 선택에 따라 카카오·구글 API로 여행지 검색 및 최적 루트 표시
- 여행 일정의 추가·수정·삭제 기능 제공

### 📅 D-Day 및 캘린더 기능
- 가장 가까운 여행 일정의 D-Day를 메인 화면 및 위젯에서 실시간 표시
- 지역/국가별 추천 관광지 목록 제공
- 여행 일정이 달력에 자동 표시되며, 날짜 선택 시 상세 정보 확인 가능

### 🧭 실시간 지도 및 위치 서비스
- 최신 여행 일정 루트를 지도에 자동 시각화
- 실시간 위치 추적 및 현재 위치 업데이트
- 방문 예정지와 실제 방문지 비교 분석

### 📸 여행 기록 및 추억 관리
- 여행 중 촬영한 사진을 선택·저장·관리
- 방문지와 GPS 좌표를 기반으로 지도에서 추억 탐색 지원
- 다중 이미지 첨부 및 위치 정보와 연동된 기록 시스템

### 🔔 스마트 알림 시스템
- 여행 전날 오후 8시 자동 알림 발송
- 개인화된 여행 준비 리마인더
- 권한 기반 알림 관리 시스템

### 🏠 홈 화면 위젯
- 다가오는 여행의 D-Day 정보 실시간 표시
- 앱 실행 없이도 여행 일정 확인 가능
- SwiftUI 기반 네이티브 위젯 구현

## 📂 프로젝트 구조

```
TRACE/
├── Model/                          # 데이터 모델
│   ├── TravelPlanData.swift
│   ├── KakaoPlacesResponse.swift
│   ├── GooglePlacesResponse.swift
│   └── RecordDisplayData.swift
├── View/                          # UI 레이어
│   ├── TravelPlanMain/           # 메인 화면
│   ├── TravelPlanWrite/          # 여행 계획 작성
│   ├── TravelRecord/             # 여행 기록
│   ├── TravelCalendar/           # 캘린더
│   └── TravelChannel/            # 지도 채널
├── ViewModel/                     # 비즈니스 로직
│   └── Base/
│       └── BaseViewModel.swift
├── Protocol/                      # 프로토콜 정의
│   ├── BaseViewModel.swift
│   ├── DesignProtocol.swift
│   └── MapManagerDelegate.swift
├── Manager/                       # 매니저 클래스
│   ├── RealmManager.swift
│   ├── NotificationManager.swift
│   ├── MapManager.swift
│   └── DateManager.swift
├── Network/                       # 네트워킹
│   ├── NetworkRouter.swift
│   └── NetworkManager.swift
├── Realm/                        # 데이터베이스 모델
│   ├── TravelPlan.swift
│   └── TravelRecord.swift
└── Extension/                    # 확장 기능
    ├── UIView+Extension.swift
    ├── UIViewController+Extension.swift
    └── UIButton+Extension.swift
```

## 🚀 설치 및 실행

### 요구사항
- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

### 의존성 라이브러리
```
dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.7.0"),
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
    .package(url: "https://github.com/realm/realm-swift.git", from: "10.40.0"),
    .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.9.0"),
    .package(url: "https://github.com/WenchaoD/FSCalendar.git", from: "2.8.4"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]
```

### 설치 방법
1. 저장소 클론
```bash
git clone https://github.com/your-username/TRACE.git
cd TRACE
```

2. Xcode에서 프로젝트 열기
```bash
open TRACE.xcodeproj
```

3. 필요한 API 키 설정
- `APIKey.swift` 파일에 Kakao, Google API 키 추가
- Firebase 설정 파일 (`GoogleService-Info.plist`) 추가

4. 빌드 및 실행
- Xcode에서 `Cmd + R`로 빌드 및 실행

## 🔑 API 설정

### Kakao Developers API
1. [Kakao Developers](https://developers.kakao.com/) 콘솔에서 앱 등록
2. REST API 키 발급
3. `APIKey.swift`에 키 추가

### Google Places API
1. [Google Cloud Console](https://console.cloud.google.com/)에서 프로젝트 생성
2. Places API 활성화 및 API 키 발급
3. `APIKey.swift`에 키 추가

### Firebase 설정
1. [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 생성
2. iOS 앱 추가 및 `GoogleService-Info.plist` 다운로드
3. Analytics, Crashlytics 활성화

## 📱 주요 화면별 기능

### 1. 메인 화면 (TravelPlanMain)
- 다가오는 여행 D-Day 표시
- 최근 여행 계획 목록
- 위젯 연동 데이터 제공

### 2. 여행 계획 작성 (TravelPlanWrite)
- 국내/해외 여행 타입 선택
- 여행지명, 날짜 입력
- API 기반 장소 검색 및 추가

### 3. 여행 계획 상세 (TravelPlanDetail)
- 일차별 상세 일정 관리
- 지도 기반 경로 시각화
- 일정 수정 및 삭제

### 4. 여행 기록 (TravelRecord)
- 여행 완료 후 기록 작성
- 다중 이미지 업로드
- GPS 기반 위치 정보 저장

### 5. 캘린더 (TravelCalendar)
- 월간/연간 여행 일정 조회
- 날짜별 여행 계획 확인
- 일정 추가/수정 바로가기

## 🔧 개발 환경 설정

### 코드 스타일 가이드
- Swift API Design Guidelines 준수
- MVVM 패턴 일관성 유지
- Protocol-Oriented Programming 적극 활용

### Git 전략
- Git Flow 브랜치 전략 사용
- Feature 브랜치 단위 개발
- Pull Request 기반 코드 리뷰

## 📈 성능 최적화

### 메모리 관리
- Weak/Unowned 참조로 순환 참조 방지
- 이미지 캐싱으로 메모리 사용량 최적화
- Realm 객체 적절한 해제

### 네트워크 최적화
- API 응답 캐싱
- 이미지 lazy loading
- 백그라운드 스레드에서 무거운 작업 처리

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

