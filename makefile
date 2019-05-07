# Optional:
#   PYTHONUSERBASE
#   FALCON_PREFIX
#   FALCON_WORKSPACE
#   FALCON_PIP_EDIT
#   FALCON_PIP_USER
#   FALCON_INSTALL_RULE (symlink or install)
FALCON_WORKSPACE?=${CURDIR}/..
PYTHONUSERBASE?=${CURDIR}/../.git/LOCAL
FALCON_PREFIX?=${PYTHONUSERBASE}
FALCON_PIP_USER?=--user
FALCON_PIP_EDIT?=--edit
FALCON_INSTALL_RULE?=symlink
export CC=gcc
export CXX=g++
export CPPFLAGS+=-D_GNU_SOURCE

all: checklist
	${MAKE} show
	${MAKE} install # This will double -D_GNU_SOURCE, but that is ok for now.
	${MAKE} check
checklist:
	@if [ -z "$${FALCON_PREFIX}" ]; then echo 'Error: FALCON_PREFIX is not set'; exit 1; fi
	@if [ ! -e "$${FALCON_PREFIX}/bin" ] ; then echo 'Error: directory FALCON_PREFIX/bin (${FALCON_PREFIX}/bin) does not exist'; exit 1; fi
install: install-DAZZ_DB install-DALIGNER install-DAMASKER install-DEXTRACTOR install-pypeflow3 install-falcon3 install-falcon_unzip3 install-git-sym install-nim-falcon install-racon
install-DAZZ_DB:
	${MAKE} -C ${FALCON_WORKSPACE}/DAZZ_DB all
	PREFIX=${FALCON_PREFIX} ${MAKE} -C ${FALCON_WORKSPACE}/DAZZ_DB ${FALCON_INSTALL_RULE}
install-DALIGNER: install-DAZZ_DB
	${MAKE} -C ${FALCON_WORKSPACE}/DALIGNER all
	PREFIX=${FALCON_PREFIX} ${MAKE} -C ${FALCON_WORKSPACE}/DALIGNER ${FALCON_INSTALL_RULE}
install-DAMASKER:
	${MAKE} -C ${FALCON_WORKSPACE}/DAMASKER all
	PREFIX=${FALCON_PREFIX} ${MAKE} -C ${FALCON_WORKSPACE}/DAMASKER ${FALCON_INSTALL_RULE}
install-DEXTRACTOR:
	${MAKE} -C ${FALCON_WORKSPACE}/DEXTRACTOR all
	PREFIX=${FALCON_PREFIX} ${MAKE} -C ${FALCON_WORKSPACE}/DEXTRACTOR ${FALCON_INSTALL_RULE}
install-pypeflow3:
	cd ${FALCON_WORKSPACE}/pypeflow3; pip3 install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
install-falcon3: install-pypeflow3
	cd ${FALCON_WORKSPACE}/falcon3; pip3 install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
install-falcon_unzip3: install-falcon3
	cd ${FALCON_WORKSPACE}/falcon_unzip3; pip3 install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
install-nim-falcon:
	${MAKE} -C ${FALCON_WORKSPACE}/nim-falcon install
	PREFIX=${FALCON_PREFIX} ${MAKE} -C ${FALCON_WORKSPACE}/nim-falcon link
	#rsync ${FALCON_WORKSPACE}/nim-falcon/bin/*.exe ${FALCON_PREFIX}/bin/
install-git-sym:
	# TODO: copy vs. symlink?
	ln -sf $(abspath ${FALCON_WORKSPACE}/git-sym/git-sym) ${FALCON_PREFIX}/bin/git-sym

show:
	mkdir -p ${FALCON_PREFIX}/bin
	which python3
	echo "PYTHONUSERBASE=${PYTHONUSERBASE}"
	python3 -c 'import site; print(site.USER_BASE)'
	echo "FALCON_PIP_EDIT=${FALCON_PIP_EDIT}"
	echo "FALCON_PIP_USER=${FALCON_PIP_USER}"
check:
	python3 -c 'import pypeflow.simple_pwatcher_bridge; print(pypeflow.simple_pwatcher_bridge)'
	python3 -c 'import falcon_kit; print(falcon_kit.falcon)'
extra:
	pip3 install ${FALCON_PIP_USER} Cython
	pip3 install ${FALCON_PIP_USER} numpy
	pip3 install ${FALCON_PIP_USER} h5py
	cd ${FALCON_WORKSPACE}/pbcommand; pip3 install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
	cd ${FALCON_WORKSPACE}/pbsmrtpipe; pip3 install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
test: #after 'install'
	${MAKE} -C ${FALCON_WORKSPACE}/FALCON-examples test
clean:
	cd ${FALCON_WORKSPACE}/DAZZ_DB; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/DALIGNER; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/DAMASKER; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/pypeflow3; python3 setup.py clean; rm -rf build/ dist/
	cd ${FALCON_WORKSPACE}/falcon3; python3 setup.py clean; rm -rf build/ dist/
	rm -rf ${RACON_BUILD_DIR}
remote:
	git remote add pb ssh://git@github.com/pb-cdunn/FALCON-make

RACON_BUILD_DIR=$(CURDIR)/build-racon

build-racon:
	mkdir -p ${RACON_BUILD_DIR}
	cd ../racon && meson -Ddefault_library=static --buildtype=release -Dc_args=-O3 --prefix=${FALCON_PREFIX} ${RACON_BUILD_DIR}

install-racon: | build-racon
	ninja -v -C ${RACON_BUILD_DIR} reconfigure
	ninja -v -C ${RACON_BUILD_DIR} install
