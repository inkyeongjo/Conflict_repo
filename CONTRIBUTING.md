# 개발 가이드

## 개발 환경 설정

### 1. 사전 요구사항

- Docker가 설치되어 있어야 합니다
- Harbor 계정 및 적절한 권한이 필요합니다 (참고: [Harbor 설정](dockerfiles/README.md))
- VSCode 또는 Cursor IDE가 설치되어 있어야 합니다
- VSCode/Cursor의 경우 "Remote Development" 확장이 설치되어 있어야 합니다

### 2. 개발 컨테이너 설정

#### 2.1 개발 컨테이너 빌드 (Admin 유저 전용)

```bash
# CUDA 버전 지정 (기본값: cu126)
make build-container CUDA_VERSION=cu126
```

- 새로운 버전의 container가 필요한 경우, 
  - `dockerfiles`를 수정하시고, `dockerfiles/base_version` 또는 `dockerfiles/dev_version`을 업데이트
  - main branch에 PR을 날리시고, PR에 `Build&Push` label을 붙이시면 자동으로 빌드 및 푸시가 이루어집니다.

#### 2.2 개발 컨테이너 실행

```bash
make run-dev cuda=cu126 work_dir={본인이 작업하고 싶은 디렉토리, default: 현재 디렉토리의 부모 디렉토리}
```

- 주의 사항
  - 터미널에서 실행된 컨테이너는, 터미널이 종료되면 컨테이너도 종료됩니다.
  - 따라서 컨테이너를 계속 유지하고 싶다면, tmux 또는 screen 등의 터미널 멀티플렉서를 사용해야 합니다.
  - 컨테이너 내부의 Workspace는 `/workspace/dev` 입니다.

#### 2.3 VSCode/Cursor에서 컨테이너 접속

1. VSCode/Cursor를 실행합니다
2. F1 또는 Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows/Linux)를 눌러 명령 팔레트를 엽니다
3. "Remote-Containers: Attach to Running Container"를 선택합니다
4. 실행 중인 개발 컨테이너를 선택합니다

> 새로운 버전의 컨테이너에 처음 접속하는 경우, 다음 과정을 따라주세요

5. F1 또는 Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows/Linux)를 눌러 명령 팔레트를 엽니다
6. "Dev Container: Open Attached Container Configuration File..."를 선택합니다
7. 현재 접속한 컨테이너의 설정 파일을 엽니다
8. "remoteUser"를 본인의 사용자 이름으로 변경합니다
9. 파일을 저장하고 닫습니다
10. IDE를 재시작합니다.

## 사용 가능한 make 명령어
```bash
make help        # 사용 가능한 모든 make 명령어 목록 확인
``` 