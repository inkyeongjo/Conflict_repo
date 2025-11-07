# Devcontainer for HyperAccel Software Group

HyperAccel 개발자들을 위한 개발용 컨테이너 환경을 제공하는 레포지토리입니다.
- 기존 docker run version 사용을 원하시는 분들은 [여기](dockerfiles/README.md)를 참고하시면 됩니다.

## 🚀 시작하기

### For Newcomers

신규 입사자분들께서는 [Jira Infra Service](https://hyperaccel.atlassian.net/servicedesk/customer/portal/4)를 통해 권한 부여 및 NAS 디렉토리 설정이 필요합니다.

Jira Infra Service 접속하셔서 DevOps Support -> k8s 작업 요청에서 "devcontainer 사용을 위한 권한 및 세팅 요청"을 제목으로 요청주시면 담당자가 빠르게 처리해드리겠습니다.

위 작업이 완료된 후에 아래 설명 따라서 실행하시면 됩니다.

### 사전 요구사항

- kubeconfig 설정
- kubectl 설치
- kubelogin 설치
- VSCode 또는 Cursor IDE 설치 (선택)
- VSCode/Cursor의 "Remote Development" 및 "Kubernetes" 확장 설치

### .env 파일 설정

- 보다 편리한 사용을 위해 파라미터 설정을 .env 파일로 통일했습니다
- .env 파일 예시:

  ```script
  CERTIFICATE_AUTHORITY_DATA=     # k8s 클러스터 인증서 데이터 [필수], 최초 설정 시 1회만

  # Required (반드시 입력해야 합니다)
  USER_NAME=your_name             # 사용자 이름 (예시: minho, namyoon, younghoon)
  TEAM_NAME=your_team_name        # 팀 이름 (ml, cmpl, simul, rt, system)

  # Optional (기본값이 있으므로 필요시에만 수정하시면 됩니다)
  POD_VERSION=cpu                 # POD 버전 (cpu, fpga, gpu, hybrid) [기본값: cpu]
  PROJECT_NAME=aida               # PROJECT 버전 (aida, bertha) [기본값: aida]
  CUDA_VERSION=cpu                # CUDA 버전 (cpu, cu126) [기본값: cpu]
  PYTHON_VERSION=3.10             # PYTHON 버전 (3.9, 3.10, 3.11, 3.12) [기본값: 3.10]
  SHELL_IN_CONTAINER=             # 컨테이너 내 사용할 shell (bash, zsh) [기본값: 현재 사용자의 shell]
  GPU_NUM=0                       # 요청하는 GPU 개수 (0, 1, 2) [기본값: 0]
  FPGA_NUM=0                      # 요청하는 FPGA 개수 (0, 1, 2, 4, 8) [기본값: 0]
  CONTAINER_POSTFIX=              # 컨테이너 이름 뒤에 붙일 postfix [기본값: ""]
  ```
  - .env 파일 확인 후 필요한 사항 작성해주시면 make 명령어에 파라미터가 자동으로 붙습니다
  - 필수로 입력하셔야 하는 항목 확인 후 입력하시면 됩니다

### 🚀 아래 설명부터는 .env 파일에 정상적으로 파라미터가 입력되었다는 가정 하에 진행하겠습니다 🚀

### Kubernetes 환경설정

1. kubeconfig 설정

   ```bash
    make kube-config
    ```

- `.env` 파일에서 `CERTIFICATE_AUTHORITY_DATA` 를 반드시 추가해주셔야 됩니다
  - data는 [여기](https://hyperaccel.atlassian.net/wiki/spaces/SD/pages/101810401/Development+Secrets)에서 확인하실 수 있습니다
- 해당 명령어 실행 시 `~/.kube/config` 위치에 kubeconfig 파일이 저장됩니다

2. kubectl 설치

- kubectl이란, k8s 클러스터를 관리하기 위한 명령어 도구입니다

  ```bash
  # macOS
  brew install kubectl
  ```

3. kubelogin 설치

- kubelogin은 일반 사용자가 쿠버네티스 클러스터 사용 권한을 얻을 때 사용됩니다

  ```bash
  # macOS
  brew install int128/kubelogin/kubelogin
  ```

4. kubectl 사용 권한 취득

- kubectl 명령어를 실행하시면 microsoft 콘솔 화면이 뜹니다
- 사내에서 사용하시는 ms teams 계정으로 로그인하실 수 있도록 설정하였습니다
- 로그인을 마치면 kubectl 명령어를 사용할 수 있습니다
- 테스트:

  ```bash
  kubectl get pods -n hyperaccel-{team_name}-ns
  ```

## 🛠 개발 컨테이너 사용하기

### 컨테이너 실행

- 예시
  ```bash
  # .env 설정 완료
  make run-pod
  ```

  ```bash
  # .env 미설정
  make run-pod user_name={your-name} team_name={your-team-name} pod_version=gpu project_name=aida cuda=cu126 python_version=3.10 gpu_num=2
  ```

사용 가능한 옵션:
- `user_name`: 사용자 이름, 필수 입력값입니다. (예시: younghoon)
- `team_name`: 팀 이름, 필수 입력값입니다. (예시: ml)
- `pod_version`: Pod 버전 (cpu, fpga, gpu, hybrid) (기본값: cpu)
- `project_name`: 프로젝트 이름 (bertha, aida) (기본값: aida)
    - base도 실행할 수 있으나, 개발용 컨테이너가 아닙니다.
- `cuda`: CUDA 버전 (cpu, cu126) (기본값: cpu)
- `python_version`: Python 버전 (3.9, 3.10, 3.11, 3.12) (기본값: 3.10)
- `shell_in_container`: 컨테이너 내부에서 사용할 쉘 (기본값: 사용자의 현재 Shell [zsh, bash])
- `gpu_num`: 컨테이너에 할당할 GPU 개수 (기본값: 0)
- `fpga_num`: 컨테이너에 할당할 FPGA 개수 (기본값: 0)
- `container_postfix`: 컨테이너 이름 뒤에 붙일 postfix, 혼동을 막기 위해 가급적 하나의 string으로 지정하는 것을 권장 (기본값: "")

### Terminal에서 컨테이너 접속
1. Terminal 실행
2. `kubectl get pods -n hyperaccel-{team_name}-ns`를 통해 실행 중인 pod 이름 확인
3. `kubectl exec -it {pod_name} -n hyperaccel-{team_name}-ns -- /bin/bash`를 통해 접속

### VSCode/Cursor에서 컨테이너 접속

1. IDE 실행
2. Command Palette 열기 (Mac: `Cmd+Shift+P`, Windows/Linux: `Ctrl+Shift+P`)
3. `Dev Containers: Attach to Running Kubernetes Container` 선택
4. 실행 중인 개발 컨테이너 선택

## 📝 주요 명령어

```bash
# 컨테이너 실행
make run-pod
make run-pod user_name=younghoon team_name=ml pod_version=gpu cuda=cu126 project_name=bertha gpu_num=2 container_postfix=berthaGPU2

# 명령어 유효성 검사
make dry-run
make dry-run user_name=younghoon team_name=ml pod_version=hybrid cuda=cu126 project_name=aida gpu_num=2 fpga_num=2

# 컨테이너 관련 컴포넌트 삭제
## deployment 삭제
make delete-deployment user_name=younghoon team_name=ml pod_version=cpu cuda=cpu project_name=aida container_postfix=aidaCPU
## pvc 삭제
make delete-pvc user_name=younghoon team_name=ml
## 전부 삭제
make delete-all user_name=younghoon team_name=ml pod_version=cpu cuda=cpu project_name=aida container_postfix=aidaCPU

# 컨테이너 빌드 및 ECR에 업로드 (관리자 전용)
make build-container CUDA_VERSION=cu126 PROJECT_NAME=aida
make push-container CUDA_VERSION=cu126 PROJECT_NAME=aida


# 도움말
make help            # 사용 가능한 모든 명령어 확인
```

- 컨테이너 삭제 시에 container_postfix가 있다면 parameter로 꼭 추가해주어야 합니다
  - pvc 삭제 시에는 추가하지 않으셔야 합니다
- 컨테이너 삭제 관련 사항은 [참고](https://hyperaccel.atlassian.net/wiki/spaces/Kubernetes/pages/215548599/Deployment+PVC) 문서 확인 바랍니다

## 🛠 k9s 활용

- k9s를 활용하면 보다 편리하게 개발 컨테이너를 사용할 수 있습니다
- k9s를 통해 개발 컨테이너의 현재 상태 조회, 로그 확인, 삭제 등 여러 작업을 직관적으로 진행할 수 있습니다

### 설치 및 실행 방법

```bash
# 설치
brew update
brew install k9s || brew install derailed/k9s/k9s
# 버전 확인
k9s version

# 실행
k9s
```

## 🔍 참고사항

- 개발 컨테이너는 k8s deployment 형태로 떠있으므로 deployment가 삭제되지 않는 한 컨테이너는 1개로 유지됩니다
- 컨테이너 내부의 workspace는 `/root` 입니다
- Pod 실행이 안되는 경우, `kubectl describe pod {pod_name} -n hyperaccel-{team_name}-ns` 혹은 `kubectl logs pod {pod_name} -n hyperaccel-{team_name}-ns` 를 통해 로그 확인 후 스스로 해결이 어려울 경우 관리자에게 문의 바랍니다

## 📊 리소스 모니터링

개발 컨테이너의 리소스 사용량을 실시간으로 모니터링할 수 있습니다:

- **Grafana 대시보드**: [k8s-grafana.hyperaccel.ai](http://k8s-grafana.hyperaccel.ai)
  - CPU, 메모리, GPU 사용량 확인
  - Pod별 리소스 소비량 확인
  - 네임스페이스별 리소스 현황 조회
  - Grafana 로그인 계정 정보는 Vault에서 확인 가능합니다

## 🔐 Vault 시크릿 관리

개발 환경에 필요한 시크릿 정보는 HashiCorp Vault에서 관리됩니다:

- **Vault UI**: [vault.hyperaccel.net](https://vault.hyperaccel.net)
  - Azure AD 계정으로 로그인 가능
    - Method에 `OIDC` 지정하시고 Role 항목에는 아무 입력 없이 `Sign in with OIDC Provider` 버튼 누르시면 바로 진행됩니다
  - 개발 컨테이너 이미지 태그 정보 확인 (`secret/images/devcontainer`)
  - Harbor 레지스트리 인증 정보 및 기타 시크릿 관리

**주요 시크릿 경로:**
- `secret/images/devcontainer`: 개발 컨테이너 이미지 태그 정보
- `secret/harbor`: Harbor 레지스트리 인증 정보

## 📚 추가 문서

- [개발 가이드](CONTRIBUTING.md)
- [도커 이미지 가이드](dockerfiles/README.md)
- [k8s 활용 가이드](https://hyperaccel.atlassian.net/wiki/spaces/Kubernetes/pages/166920375/User+Onboarding)
