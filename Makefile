RELEASE=3.0

# also update debian/changelog
KVMVER=1.4
KVMPKGREL=9

KVMPACKAGE=pve-qemu-kvm
KVMDIR=qemu-kvm
KVMSRC=${KVMDIR}-src.tar.gz

ARCH=amd64

KVM_DEB=${KVMPACKAGE}_${KVMVER}-${KVMPKGREL}_${ARCH}.deb

all: ${KVM_DEB} ${KVMSRC}

.PHONY: download
download:
	rm -rf ${KVMDIR} ${KVMSRC}
	git clone git://git.qemu-project.org/qemu.git -b master ${KVMDIR} 
	cd ${KVMDIR}; git checkout -b local v1.4.0
	# update to seabios 1.7.2.1
	cd ${KVMDIR}; git cherry-pick 5c75fb10029c5fd1e705a6ef5d698fbea06c7a33
	tar czf ${KVMSRC} --exclude CVS --exclude .git --exclude .svn ${KVMDIR}

${KVM_DEB} kvm: ${KVMSRC}
	rm -rf ${KVMDIR}
	tar xf ${KVMSRC} 
	cp -a debian ${KVMDIR}/debian
	cd ${KVMDIR}; dpkg-buildpackage -b -rfakeroot -us -uc
	lintian ${KVM_DEB} || true

.PHONY: upload
upload: ${KVM_DEB} ${KVMDIR}-src.tar.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -rf /pve/${RELEASE}/extra/Packages*
	rm -rf /pve/${RELEASE}/extra/${KVMPACKAGE}_*.deb
	cp ${KVM_DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: distclean
distclean: clean


.PHONY: clean
clean:
	rm -rf *~ ${KVMDIR} ${KVMPACKAGE}_*

.PHONY: dinstall
dinstall: ${KVM_DEB}
	dpkg -i ${KVM_DEB}
