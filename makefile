-include config.mk
# Required:
#   FALCON_PREFIX
#   FALCON_WORKSPACE
# Optional:
#   FALCON_PIP_EDIT
#   FALCON_PIP_USER
#   FALCON_INSTALL_RULE (symlink or install)
#   PYTHONUSERBASE
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
	${MAKE} install-pip
	${MAKE} install # This will double -D_GNU_SOURCE, but that is ok for now.
	${MAKE} check
checklist:
	@if [ -z "$${FALCON_PREFIX}" ]; then echo 'Error: FALCON_PREFIX is not set'; exit 1; fi
	@if [ ! -e "$${FALCON_PREFIX}/bin" ] ; then echo 'Error: directory FALCON_PREFIX/bin (${FALCON_PREFIX}/bin) does not exist'; exit 1; fi
install: install-DAZZ_DB install-DALIGNER install-DAMASKER install-DEXTRACTOR install-pypeFLOW install-FALCON install-FALCON_unzip install-git-sym install-nim-falcon
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
install-pypeFLOW:
	cd ${FALCON_WORKSPACE}/pypeFLOW; pip install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
install-FALCON: install-pypeFLOW
	cd ${FALCON_WORKSPACE}/FALCON; pip install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
install-FALCON_unzip: install-FALCON
	cd ${FALCON_WORKSPACE}/FALCON_unzip_private; pip install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
install-nim-falcon:
	make -C ${FALCON_WORKSPACE}/nim-falcon/src -j1 all
	rsync ${FALCON_WORKSPACE}/nim-falcon/src/*.exe ${FALCON_PREFIX}/bin/
install-git-sym:
	# TODO: copy vs. symlink?
	ln -sf $(abspath ${FALCON_WORKSPACE}/git-sym/git-sym) ${FALCON_PREFIX}/bin/git-sym

install-pip:
	python -c 'import pip; print pip' || python get-pip.py ${FALCON_PIP_USER}
	pip install ${FALCON_PIP_USER} --upgrade pip
	pip install ${FALCON_PIP_USER} --upgrade setuptools # needed when --edit is used
	pip install ${FALCON_PIP_USER} nose pytest # for running tests while building
show:
	mkdir -p ${FALCON_PREFIX}/bin
	which python
	echo "PYTHONUSERBASE=${PYTHONUSERBASE}"
	python -c 'import site; print site.USER_BASE'
	echo "FALCON_PIP_EDIT=${FALCON_PIP_EDIT}"
	echo "FALCON_PIP_USER=${FALCON_PIP_USER}"
check:
	python -c 'import pypeflow.simple_pwatcher_bridge; print pypeflow.simple_pwatcher_bridge'
	python -c 'import falcon_kit; print falcon_kit.falcon'
extra:
	pip install ${FALCON_PIP_USER} Cython
	pip install ${FALCON_PIP_USER} numpy
	pip install ${FALCON_PIP_USER} h5py
	cd ${FALCON_WORKSPACE}/pbcommand; pip install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
	cd ${FALCON_WORKSPACE}/pbsmrtpipe; pip install ${FALCON_PIP_USER} ${FALCON_PIP_EDIT} .
test: #after 'install'
	${MAKE} -C ${FALCON_WORKSPACE}/FALCON-examples test
clean:
	cd ${FALCON_WORKSPACE}/DAZZ_DB; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/DALIGNER; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/DAMASKER; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/pypeFLOW; python setup.py clean; rm -rf build/ dist/
	cd ${FALCON_WORKSPACE}/FALCON; python setup.py clean; rm -rf build/ dist/
remote:
	git remote add pb ssh://git@github.com/pb-cdunn/FALCON-make
