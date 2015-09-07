FALCON_WORKSPACE?=..
FALCON_PREFIX?=../fc_env
VDIR:=${FALCON_PREFIX}
export CC=gcc
export CXX=g++

install: build
	# There is a race-condition when installing python, so we serialize.
	which python
	cd ${FALCON_WORKSPACE}/pypeFLOW; python setup.py install
	python -c 'import pypeflow.common; print pypeflow.common'
	${MAKE} install-FALCON
	${MAKE} symlink
install-FALCON:
	# Unforch, setup.py develop-mode does not work for falcon_kit, so we must always re-install upon any change.
	cd ${FALCON_WORKSPACE}/FALCON; python setup.py install
	python -c 'import falcon_kit; print falcon_kit.falcon'
symlink:
	cd ${FALCON_WORKSPACE}/DAZZ_DB; ln -sf $$PWD/DBrm $$PWD/DBshow $$PWD/DBsplit $$PWD/DBstats $$PWD/fasta2DB ${VDIR}/bin/
	cd ${FALCON_WORKSPACE}/DALIGNER; ln -sf $$PWD/daligner $$PWD/daligner_p $$PWD/DB2Falcon $$PWD/HPCdaligner $$PWD/LA4Falcon $$PWD/LAmerge $$PWD/LAsort $$PWD/LAcat $$PWD/LAshow  ${VDIR}/bin
build: build-DAZZ_DB build-DALIGNER build-FALCON build-pypeFLOW
build-DAZZ_DB:
	${MAKE} -C ${FALCON_WORKSPACE}/DAZZ_DB
build-DALIGNER: build-DAZZ_DB
	${MAKE} -C ${FALCON_WORKSPACE}/DALIGNER
build-FALCON:
	cd ${FALCON_WORKSPACE}/FALCON; python setup.py build
build-pypeFLOW:
	cd ${FALCON_WORKSPACE}/pypeFLOW; python setup.py build
develop: build-DAZZ_DB build-DALIGNER
	${MAKE} symlink
	cd ${FALCON_WORKSPACE}/pypeFLOW; python setup.py develop
	${MAKE} install-FALCON
	cd ${FALCON_WORKSPACE}/pbcommand; pip install -e .
	cd ${FALCON_WORKSPACE}/pbsmrtpipe; pip install -e .
	cd ${FALCON_WORKSPACE}/FALCON-pbsmrtpipe; python setup.py develop
bootstrap:
	pip install --upgrade pip
	pip install Cython
	# And for good measure
	pip install numpy
	pip install h5py
test: #after 'install'
	${MAKE} -C ${FALCON_WORKSPACE}/FALCON-examples test
# 'clean' operates on the repo dirs, not necessarily fc_env.
clean:
	cd ${FALCON_WORKSPACE}/DAZZ_DB; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/DALIGNER; ${MAKE} clean
	cd ${FALCON_WORKSPACE}/pypeFLOW; python setup.py clean; rm -rf build/ dist/
	cd ${FALCON_WORKSPACE}/FALCON; python setup.py clean; rm -rf build/ dist/
