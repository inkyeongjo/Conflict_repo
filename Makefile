.PHONY: help build-container push-container run-dev kube-config run-pod dry-run delete-deployment delete-pvc delete-all

ifneq (,$(wildcard .env))
    include .env
    export
endif

# 기본 변수 설정 (명령행 인자가 우선, 그 다음 .env 파일, 마지막으로 기본값)
# 공백 제거를 위한 strip 함수 정의
strip = $(strip $(1))

USER_NAME := $(call strip,$(or $(user_name),$(USER_NAME),$(error user_name is required. Please set it in .env file or provide as: make <target> user_name=<your_username>)))
TEAM_NAME := $(call strip,$(or $(team_name),$(TEAM_NAME),$(error team_name is required. Please set it in .env file or provide as: make <target> team_name=<your_team_name>)))
POD_VERSION := $(call strip,$(or $(pod_version),$(POD_VERSION),cpu))
PROJECT_NAME := $(call strip,$(or $(project_name),$(PROJECT_NAME),aida))
CUDA_VERSION := $(call strip,$(or $(cuda),$(CUDA_VERSION),cpu))
PYTHON_VERSION := $(call strip,$(or $(python_version),$(PYTHON_VERSION),3.10))

SHELL_ENV := $(shell echo $$SHELL)
GPU_NUM := $(call strip,$(or $(gpu_num),$(GPU_NUM),0))
FPGA_NUM := $(call strip,$(or $(fpga_num),$(FPGA_NUM),0))

WORK_DIR ?= $(call strip,$(or $(work_dir),$(shell dirname $(shell pwd))))
FORCE_BUILD ?= $(call strip,$(or $(force_build),false))
FORCE_PUSH ?= $(call strip,$(or $(force_push),false))
SHELL_IN_CONTAINER := $(call strip,$(or $(shell_in_container),$(SHELL_IN_CONTAINER),$(shell basename $(SHELL_ENV))))
CONTAINER_POSTFIX := $(call strip,$(or $(container_postfix),$(CONTAINER_POSTFIX),))
CERTIFICATE_AUTHORITY_DATA ?= $(call strip,$(or $(certificate_authority_data),$(CERTIFICATE_AUTHORITY_DATA),$(error CERTIFICATE_AUTHORITY_DATA is required. Please set it in .env file or provide as: make <target> certificate_authority_data=<your_certificate_data>)))

help:  ## 사용 가능한 명령어 목록을 보여줍니다
	@echo "사용 가능한 명령어:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "\n환경 설정 방법:"
	@echo "# .env 파일 사용 (권장):"
	@echo "   - .env 파일에서 USER_NAME과 TEAM_NAME을 본인 정보로 수정"
	@echo "   - 이후 make 명령어를 인자 없이 실행 가능: make run-pod"
	@echo ""
	@echo "# 명령행 인자 사용:"
	@echo "   - make <target> user_name=<name> team_name=<team> [기타 옵션]"
	@echo ""
	@echo "사용 가능한 인자 (명령행에서 사용시):"
	@printf "\033[36m%-30s\033[0m %s\n" "user_name=<user name>" "사용자 이름 (예시: minho, namyoon, younghoon) [필수]"
	@printf "\033[36m%-30s\033[0m %s\n" "team_name=<team name>" "팀 이름 (ml, cmpl, simul, rt, system) [필수]"
	@printf "\033[36m%-30s\033[0m %s\n" "pod_version=<version>" "POD 버전 (cpu, fpga, gpu, hybrid) [기본값: cpu]"
	@printf "\033[36m%-30s\033[0m %s\n" "project_name=<version>" "PROJECT 버전 (aida, bertha) [기본값: aida]"
	@printf "\033[36m%-30s\033[0m %s\n" "cuda=<version>" "CUDA 버전 (cpu, cu126) [기본값: cpu]"
	@printf "\033[36m%-30s\033[0m %s\n" "python_version=<version>" "PYTHON 버전 (3.9, 3.10, 3.11, 3.12) [기본값: 3.10]"
	@printf "\033[36m%-30s\033[0m %s\n" "shell_in_container=<shell>" "컨테이너 내 사용할 shell (bash, zsh) [기본값: 현재 사용자의 shell]"
	@printf "\033[36m%-30s\033[0m %s\n" "gpu_num=<num>" "요청하는 GPU 개수 (0, 1, 2) [기본값: 0]"
	@printf "\033[36m%-30s\033[0m %s\n" "fpga_num=<num>" "요청하는 FPGA 개수 (0, 1, 2, 4, 8) [기본값: 0]"
	@printf "\033[36m%-30s\033[0m %s\n" "container_postfix=<postfix>" "컨테이너 이름 뒤에 붙일 postfix [기본값: \"\"]"
	@echo "\n사용 예시:"
	@echo "# 기존 Docker 방식으로 실행:"
	@echo "make run-dev cuda=cu126 work_dir=/path/to/directory"
	@echo "# .env 파일 사용 (권장):"
	@echo "make run-pod"
	@echo "make dry-run"
	@echo ""
	@echo "# 명령행 인자 사용:"
	@echo "make run-pod user_name=younghoon team_name=ml pod_version=gpu cuda=cu126 project_name=bertha gpu_num=2"
	@echo "make dry-run user_name=younghoon team_name=ml pod_version=hybrid cuda=cu126 project_name=aida gpu_num=2 fpga_num=2"

build-container:  ## 개발용 Docker 이미지를 빌드합니다
	bash ./dockerfiles/build_container.sh $(CUDA_VERSION) $(PROJECT_NAME) $(FORCE_BUILD)

push-container:  ## 개발용 Docker 이미지를 Harbor에 업로드합니다
	bash ./dockerfiles/push_container.sh $(CUDA_VERSION) $(PROJECT_NAME) $(FORCE_PUSH)

run-dev:  ## 개발용 Docker 컨테이너를 실행합니다 (Docker Version)
	@echo CUDA_VERSION: $(CUDA_VERSION) 
	@echo PROJECT_NAME: $(PROJECT_NAME) 
	@echo PYTHON_VERSION: $(PYTHON_VERSION) 
	@echo WORK_DIR: $(WORK_DIR) 
	@echo SHELL_IN_CONTAINER: $(SHELL_IN_CONTAINER)
	@echo CONTAINER_POSTFIX: $(CONTAINER_POSTFIX)
	bash ./scripts/run_devcontainer_docker.sh $(CUDA_VERSION) $(PROJECT_NAME) $(PYTHON_VERSION) $(WORK_DIR) $(SHELL_IN_CONTAINER) $(CONTAINER_POSTFIX)

kube-config:  ## kubeconfig 파일을 ~/.kube/config에 생성합니다
	@echo USER_NAME: $(USER_NAME)
	@echo TEAM_NAME: $(TEAM_NAME)
	@echo CERTIFICATE_AUTHORITY_DATA: $(if $(CERTIFICATE_AUTHORITY_DATA),$(shell echo $(CERTIFICATE_AUTHORITY_DATA) | cut -c1-50)...,not set)
	bash ./scripts/setting_kubeconfig.sh \
		--user-name $(USER_NAME) \
		--team-name $(TEAM_NAME) \
		$(if $(CERTIFICATE_AUTHORITY_DATA),--certificate-authority-data $(CERTIFICATE_AUTHORITY_DATA))

define run_pod_common
	@echo USER_NAME: $(USER_NAME)
	@echo TEAM_NAME: $(TEAM_NAME)
	@echo POD_VERSION: $(POD_VERSION)
	@echo PROJECT_NAME: $(PROJECT_NAME)
	@echo CUDA_VERSION: $(CUDA_VERSION) 
	@echo PYTHON_VERSION: $(PYTHON_VERSION)
	@echo SHELL_IN_CONTAINER: $(SHELL_IN_CONTAINER)
	@echo GPU_NUM: $(GPU_NUM)
	@echo FPGA_NUM: $(FPGA_NUM)
	@echo CONTAINER_POSTFIX: $(CONTAINER_POSTFIX)
	bash ./scripts/run_devcontainer.sh \
		--user-name $(USER_NAME) \
		--team-name $(TEAM_NAME) \
		--project-name $(PROJECT_NAME) \
		--cuda-version $(CUDA_VERSION) \
		--pod-version $(POD_VERSION) \
		--python-version $(PYTHON_VERSION) \
		$(if $(SHELL_IN_CONTAINER),--shell-env $(SHELL_IN_CONTAINER)) \
		--gpu-num $(GPU_NUM) \
		--fpga-num $(FPGA_NUM) \
		$(if $(CONTAINER_POSTFIX),--container-postfix $(CONTAINER_POSTFIX)) \
		--output-dir k8s-yaml \
		$(1)
endef

run-pod:  ## k8s yaml 파일을 생성하고 실행합니다
	$(call run_pod_common,--apply)

dry-run:  ## k8s yaml의 유효성에 대해 dry-run으로 확인합니다 (실제 실행 x)
	$(call run_pod_common,--dry-run)

delete-deployment:  ## Deployment를 삭제합니다
	@echo USER_NAME: $(USER_NAME)
	@echo TEAM_NAME: $(TEAM_NAME)
	@echo PROJECT_NAME: $(PROJECT_NAME)
	@echo CUDA_VERSION: $(CUDA_VERSION)
	@echo POD_VERSION: $(POD_VERSION)
	@echo CONTAINER_POSTFIX: $(CONTAINER_POSTFIX)
	bash ./scripts/delete_deployment.sh \
		--user-name $(USER_NAME) \
		--team-name $(TEAM_NAME) \
		--project-name $(PROJECT_NAME) \
		--cuda-version $(CUDA_VERSION) \
		--pod-version $(POD_VERSION) \
		$(if $(CONTAINER_POSTFIX),--container-postfix $(CONTAINER_POSTFIX))

delete-pvc:  ## PVC를 삭제합니다
	@echo USER_NAME: $(USER_NAME)
	@echo TEAM_NAME: $(TEAM_NAME)
	bash ./scripts/delete_pvc.sh \
		--user-name $(USER_NAME) \
		--team-name $(TEAM_NAME)

delete-all:  ## Deployment와 PVC를 모두 삭제합니다
	$(MAKE) delete-deployment
	$(MAKE) delete-pvc

# 기본 명령어를 help로 설정
.DEFAULT_GOAL := help 
