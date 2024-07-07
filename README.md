# MadCamp-week1
몰입캠프 1주차 산출물입니다.


### 개요

---
<div align="center">
<img src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/eab95bb2-0e39-40ff-afb4-2a559883fec1" width="30%">
</div>


### 학교 생활 종합도우미, UNiV를 소개합니다.

UNiV는 대학생들의 학교생활을 도와주는 앱입니다.

⚠️ 과제와 시간표를 자꾸 깜빡하시나요? 

⚠️ 필요한 링크를 한 곳에 모아두고 싶으신가요? 

⚠️ 친구들의 학번, 이메일이 기억나지 않나요? 

⚠️ 또는, 관련 사진들을 한 곳에 모아서 보고 싶으신가요?

이 모든 것이 **단 하나의 앱**으로 가능하다면 어떨까요?

UNiV를 이용해보세요!

<br>
<br>

### 우리팀을 소개합니다 🙋‍♀️

<div align="center">

---

|      정지윤       |          조영서         |          한종국         |                                                                                                               
| :------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: |
|   <img width="30%" src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/67b24f11-2c48-4704-ac34-6c3be41c9982" />    |                      <img width="30%" src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/ac1b51dc-f570-4056-84a4-c9bf5125f6f8" />    |                      <img width="30%" src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/550c5a73-982d-449e-90d9-21f548f51456" />    |
|   [@enchantee00](https://github.com/enchantee00)   |    [@cyshello](https://github.com/cyshello)  |    [@jkookhan03](https://github.com/jkookhan03)  |
| 부산대학교 정보컴퓨터공학부 3학년 | 카이스트 전산학부 2학년 | 카이스트 전산학부 3학년 |


</div>

<br>
<br>

### Tech Stack ⚒️
---


**IDE** : Android Studio

**개발 언어** : Flutter, Python

**웹 프레임워크**: Flask

<br>
<br>

### Motivation

---

대학생활을 하면서 필요한 정보들이 구분되어 있지 않아 불편함을 겪은 적이 많았습니다. 이러한 불편함을 하나의 앱으로 해결하고 싶어 만들게 되었습니다.

😱 학술문화관 예약을 해야하는데 팀원 학번이 기억이 안 나!

😱 한달 전에 찍어놓은 흉부엑스레이 결과지를 제출해야 하는데 앨범에서 찾기 힘들어 ㅠㅠ

😱 시간표, 해야 할 일, 필요한 링크를 한 곳에서 한눈에 보고싶어!

<br>
<br>

### Tab 1 : 연락처 📒

---

첫 번째 탭은 연락처 탭입니다. 다음과 같은 기능이 있습니다.

<div align="center">
<img src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/439ded24-cf8c-4ca3-a91e-d1f21f6272ff" width="30%">
</div>

- **기기의 연락처 불러오기**
flutter의 `ContactsService`와 `Permission_handler` 패키지를 사용하여 기기의 연락처를 불러왔습니다. `Permission.contacts`를 요청하고, 권한이 부여되면 `ContactsService.getContacts()`를 사용하여 모든 연락처를 불러오도록 했습니다. 불러온 연락처는 `contacts` 리스트에 저장되고, `SharedPreferences`를 통해 저장됩니다.
    
- **앱에서 연락처 수정 후 기기에 반영**
사용자가 연락처를 수정하면 `ContactsService.updateContact()`를 호출하여 변경 사항을 기기에 반영하도록 했습니다. 수정된 연락처는 `SharedPreferences`에도 저장됩니다.
    
- **연락처 검색 및 추가**
    
    `TextEditingController`를 사용하여 검색어 입력을 감지하고, 입력된 검색어와 일치하는 연락처를 필터링하여 `filteredContacts` 리스트에 저장합니다. 새로운 연락처 추가는 `showDialog()`를 사용하여 사용자에게 필요한 정보를 입력받은 후, `ContactsService.addContact()`를 호출하여 기기에 저장합니다.
    
- **학번, 이메일 등 수정**
연락처 세부 화면에서 사용자가 학번, 이메일 등의 정보를 수정할 수 있도록 `TextEditingController`를 사용하여 해당 필드를 제공합니다. 수정된 내용은 `ContactsService.updateContact()`를 통해 기기에 반영됩니다.
- **전화, 메세지 걸기**
    
    `url_launcher` 패키지를 사용하여 연락처의 전화번호로 전화를 걸거나 메시지를 보낼 수 있습니다. `tel:` 및 `sms:` URI 스킴을 사용하여 전화 및 메시지 기능을 구현했습니다.
    
- **이메일 연동**
    
    `url_launcher` 패키지를 사용하여 연락처의 이메일 주소로 이메일을 보낼 수 있습니다. `mailto:` URI 스킴을 사용하여 이메일 클라이언트를 호출했습니다.
    
- **메모 기능**
    
    각 연락처에 메모를 추가할 수 있습니다. 메모는 `SharedPreferences`에 저장되며, 앱이 종료되더라도 메모가 유지됩니다.
    

<br>
<br>

### Tab 2 : 갤러리 🌄

---

두 번째 탭은 갤러리 탭입니다. 다음과 같은 기능이 있습니다. 

<div align="center">
<img src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/a0ca8344-a645-4ac0-be3b-2298a54b330a" width="30%">
</div>

- **사진 나열 및 UI 구성**
    
    `ListView.builder`와 `GridView.builder`를 사용하여 그룹화된 사진들을 날짜별로 나열합니다. 각 날짜 그룹에 대해 날짜를 제목으로 표시하고, 해당 날짜에 속하는 사진들을 3열의 그리드 형태로 표시합니다.
    
- **기기의 갤러리 불러오기**
    
    `path_provider` 패키지를 사용하여 애플리케이션 문서 디렉토리를 찾고, 해당 디렉토리의 'Pictures' 폴더에 저장된 이미지를 불러옵니다. `Directory.listSync()`를 사용하여 파일 목록을 가져오고, 확장자가 `.png` 또는 `.jpg`인 파일만 필터링하여 `images` 리스트에 추가하도록 했습니다.
    
- **사진 그룹화**
    
    `images` 리스트의 사진 파일들을 불러온 후, `lastModifiedSync()`를 사용하여 파일의 마지막 수정 날짜를 가져옵니다. `DateFormat('yyyy-MM-dd')`를 사용하여 날짜를 형식화한 후, 이를 기준으로 사진들을 그룹화합니다. 그룹화된 사진들은 날짜를 키로 가지는 `Map<String, List<File>>` 구조로 저장됩니다.
    
- **선택 모드 및 삭제 기능**
    
    사진을 길게 누르면 선택 모드로 전환되며, 선택된 사진에는 체크 아이콘이 표시됩니다. 선택 모드에서는 사진을 탭하여 선택을 해제할 수 있으며, 선택된 사진들을 삭제할 수 있는 버튼이 화면에 나타납니다. `deleteSelectedImages()` 함수를 통해 선택된 사진들을 삭제합니다.

    
- **사진 확대, 축소**
    
    `InteractiveViewer` 위젯을 사용하여 사용자가 사진을 확대하고 축소할 수 있도록 구현했습니다. 더블 탭을 통해 확대/축소 기능을 제공하며, `TransformationController`를 사용하여 현재 확대/축소 상태를 관리합니다.
    
- **사진의 상세정보 불러오기**
    
    `image` 패키지를 사용하여 이미지 파일을 디코딩하고, 이미지의 해상도를 가져옵니다. 또한, `File` 클래스의 `lastModifiedSync()`를 사용하여 마지막 수정 날짜를 가져오고, 파일 크기 및 파일 이름 정보를 함께 제공하여 사용자가 사진의 상세정보를 볼 수 있도록 합니다. `DraggableScrollableSheet`를 사용하여 이 정보를 화면 하단에서 드래그하여 볼 수 있게 구현하였습니다.


<br>
<br>    

### Tab 3 : 메인화면 🏠

---

세 번째 탭은 메인화면입니다. 다음과 같은 기능이 있습니다.

<div align="center">
<img src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/021c58f5-72bf-49ce-a276-5f8e55395a36" width="30%">
</div>


- **프로필 수정, 크게보기**
    
    flutter의 `SharedPreference` 기능을 이용하여 사용자의 프로필을 저장하였으며, `Container`, `Row`, `Column`을 이용해 적절히 프로필 화면을 구성하였습니다.
    
- **위젯 슬라이드 (Links, TODO, Image)**
    
    flutter의 `Carousel Slider`를 이용하여 위젯들을 정렬했습니다. 이때, `SharedPreference`를 이용해 위젯들의 정보와 마지막으로 찾아본 슬라이드를 저장하여 앱을 종료해도 마지막으로 본 탭이 나오게 하였습니다.
    
    또한, `CarouseController`를 변수로 저장하여 위젯들 아래에 Slider를 `Row` Widget으로 구현하였으며 `MediaQuery.of(context)` 를 이용하여 전체 화면의 크기를 이용해 프로필 화면이 동적으로 나타나게 하였습니다. 
    
- **위젯 추가, 삭제, 수정**
    
    `FloatingActionBotton`의 `Speed Dial`을 이용해 Home 화면에서 다른 기능을 추가하였습니다.
    
    위젯의 정보들을 List 형태로 저장하여 각 Widget에 파라미터로 넘겨주고, 추가, 삭제, 수정 버튼을 누를 때 수정하여 넘겨주는 방법으로 위젯을 설정하는 기능을 만들었습니다. 또한, `onLongPress()` 함수를 이용해 위젯을 꾹 눌렀을 때 수정화면이 뜨도록 하였습니다.
    
- **사진을 찍어 갤러리에 추가**
    
    `Add to Gallery` 버튼을 누르면 `_showCameraScreen()` 함수를 호출해 카메라 화면을 열고, 사진을 찍으면 곧 바로 앱 내의 갤러리 탭에 저장됩니다. 
    
    OCR 수행 부분에서도 카메라 화면을 쓰기 때문에 해당 버튼과 동일한 카메라 화면을 쓰되, `performOCR`(OCR 수행 여부)에 따라 내부 로직을 다르게 설계해 코드 재사용성을 높였습니다.
    

- **사진을 찍은 후, OCR로 인식해 이름과 학번을 가져와서 연락처에 업데이트**
    
    `Add to Contacts` 버튼을 누르면 두 가지 선택지가 나옵니다.
    
    - 촬영
        
        촬영 버튼을 누르면 카메라 화면으로 넘어가고 사진 촬영 시 곧 바로 OCR을 수행해 이름과 학번을 추출합니다.
        
    - 불러오기
        
        불러오기 버튼을 누르면 ImagePicker를 통해 기기의 갤러리 사진을 불러오고 사진을 선택하면 OCR을 수행해 이름과 학번을 추출하게 됩니다.
        
    
    이후 추출된 정보를 사용자에게 확인시킨 후, 추가 정보를 입력할 수 있는 화면이 나옵니다. 마지막으로 저장 버튼을 누르면 앱 내의 연락처에 업데이트 되거나 새로 생성됩니다.

  <div align="center">
    <img src="https://github.com/enchantee00/MadCamp-week1/assets/62553866/aaaeb7fe-2fbe-4c40-82d8-cc807e3b707a" width="30%">
    </div>
  
    
    **OCR**
    
    OCR - `Google Vision API`
    
    학번&이름 추출 - `OPEN AI API`
    
    두 가지 API를 사용하여 기능을 수행했고, 웹 서버를 따로 구축해 API를 사용하는 것이 재사용성, 확장성 및 보안 측면에서 적절하다고 판단해 웹 서버에서 통신을 수행했습니다. 
    
    `Flask`로 웹 서버를 열어 HTTP 통신으로 사진을 받고 처리하여 결과값을 앱으로 다시 보내주는 방식으로 처리하였습니다.
  
<br>
<br>

### APK link

---

[app-release.apk](https://drive.google.com/file/d/1J24z7bmLMmocCYyDcAKaixYScoyAwnmI/view?usp=sharing)
