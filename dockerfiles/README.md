# Devcontainer for HyperAccel Teams

HyperAccel 개발자들을 위한 개발용 컨테이너 환경을 제공하는 레포지토리입니다. (Docker Version)

## 🚀 시작하기

### 사전 요구사항

- Docker 설치
- AWS CLI 설치
- AWS 계정 및 적절한 권한
- VSCode 또는 Cursor IDE 설치
- VSCode/Cursor의 "Remote Development" 확장 설치

### AWS 설정

1. AWS IAM 사용자 계정이 필요합니다:
   - [HyperAccel Confluence](https://hyperaccel.atlassian.net/wiki/spaces/SD/pages/101810401/Development+Secrets#HyperDex-developers-IAM)에서 확인
   - 또는 관리자에게 발급 요청

2. AWS CLI 설정:
```bash
aws configure
# AWS Access Key ID 입력
# AWS Secret Access Key 입력
# Default region: us-east-1
# Default output format: json
```

3. ECR 인증:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 637423205005.dkr.ecr.us-east-1.amazonaws.com
```

## 🛠 개발 컨테이너 사용하기

### 컨테이너 실행

```bash
make run-dev cuda=cu126 project_name=aida python_version=3.10 work_dir={작업하고 싶은 디렉토리}
```

사용 가능한 옵션:
- `cuda`: CUDA 버전 (cpu, cu126) (기본값: cpu)
- `project_name`: 프로젝트 이름 (bertha, aida) (기본값: aida)
    - `base`도 실행할 수 있으나, 개발용 컨테이너가 아닙니다.
- `python_version`: Python 버전 (3.9, 3.10, 3.11, 3.12) (기본값: 3.10)
- `work_dir`: 작업 디렉토리 (기본값: 현재 디렉토리의 부모 디렉토리)
- `shell_in_container`: 컨테이너 내부에서 사용할 쉘 (기본값: 사용자의 현재 Shell [zsh, bash])
- `container_name_postfix`: 컨테이너 이름 뒤에 붙일 postfix(기본값: "")

### VSCode/Cursor에서 컨테이너 접속

1. IDE 실행
2. Command Palette 열기 (Mac: Cmd+Shift+P, Windows/Linux: Ctrl+Shift+P)
3. "Remote-Containers: Attach to Running Container" 선택
4. 실행 중인 개발 컨테이너 선택

## 📝 주요 명령어

```bash
# 컨테이너 관련
make run-dev cuda=cu126 project_name=aida python_version=3.10 work_dir=/path/to/directory shell_in_container={zsh, bash} container_name_postfix="vllm-orion"   # 개발 컨테이너 실행
make build-container CUDA_VERSION=cu126 PROJECT_NAME=aida # 컨테이너 빌드 및 ECR에 업로드 (관리자 전용)

# 도움말
make help            # 사용 가능한 모든 명령어 확인
```

## 🔍 참고사항

- 터미널에서 실행된 컨테이너는 터미널 종료 시 함께 종료됩니다
- 컨테이너를 계속 유지하려면 tmux나 screen 같은 터미널 멀티플렉서 사용을 권장합니다
- 컨테이너 내부의 Workspace는 `/workspace/dev` 입니다
- 추가적으로 필요한 docker run 옵션은 `scripts/additional_docker_run_cmd` 파일에 추가할 수 있습니다
  - 예시: 
  ```
  # scripts/additional_docker_run_cmd
  -v ${HOME}/.git:/home/${USER}/.git \
  -v /share:/share \
  -e HF_HOME=/share/huggingface
  ```

## 📚 추가 문서

- [개발 가이드](CONTRIBUTING.md)
- [도커 이미지 가이드](dockerfiles/README.md)

# Amazon ECR 이미지 가져오기 가이드

## 사전 준비사항
- AWS CLI가 설치되어 있어야 합니다
- AWS 계정 및 적절한 권한이 필요합니다
- Docker/Podman이 로컬 시스템에 설치되어 있어야 합니다

## AWS 설정 및 ECR 인증 단계

0. AWS IAM 사용자 요청
- HyperDex-developers IAM 사용자 Access Key 확인 [HyperAccel Confluence](https://hyperaccel.atlassian.net/wiki/spaces/SD/pages/101810401/Development+Secrets#HyperDex-developers-IAM)
- Or 발급 요청 (to [devops](mailto:devops@hyperaccel.ai))

1. AWS CLI 설정하기
    ```bash
    aws configure
    ```
- 다음 정보를 입력합니다:
    - AWS Access Key ID: [액세스 키 입력]
    - AWS Secret Access Key: [시크릿 키 입력]
    - Default region name: us-east-1
    - Default output format: json

2. ECR 레지스트리 인증
    ```bash
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 637423205005.dkr.ecr.us-east-1.amazonaws.com
    ```

3. ECR 레포지토리에서 이미지 가져오기
    ```bash
    docker pull 637423205005.dkr.ecr.us-east-1.amazonaws.com/[레포지토리-이름]:[태그]
    ```

4. Repository 이름 및 태그
- 이름
    - `hyperaccel/devcontainer-base`
    - `hyperaccel/devcontainer-aida`
    - `hyperaccel/devcontainer-bertha`
- 태그
    - `hyperaccel/devcontainer-base`
        - `cpu-[버전]`
        - `cu126-[버전]`
    - `hyperaccel/devcontainer-aida`
        - `cpu-[버전]`
        - `cu126-[버전]`
    - `hyperaccel/devcontainer-bertha`
        - `cpu-[버전]`

## 문제 해결

### 일반적인 오류
1. aws configure 오류
   - AWS Access Key와 Secret Key가 올바른지 확인
   - 리전이 'us-east-1'로 정확히 설정되었는지 확인
2. 인증 실패
   - AWS 자격 증명이 올바르게 구성되어 있는지 확인
   - IAM 사용자에게 적절한 ECR 권한이 있는지 확인
3. 이미지를 찾을 수 없음
   - 레포지토리 이름과 태그가 정확한지 확인
   - 해당 리전에 레포지토리가 존재하는지 확인
