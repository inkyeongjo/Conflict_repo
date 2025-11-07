set -e

# Install pybind11 for each python version
bash -c ". ${VENV_PATH}/3.9/bin/activate \
    && pip install pybind11"

bash -c ". ${VENV_PATH}/3.10/bin/activate \
    && pip install pybind11"

bash -c ". ${VENV_PATH}/3.11/bin/activate \
    && pip install pybind11"

bash -c ". ${VENV_PATH}/3.12/bin/activate \
    && pip install pybind11"
