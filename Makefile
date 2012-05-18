all:
	make clean
	make build

clean:
	rm -rf ../build/*.deb
	rm -rf ../build/*.rpm
	rm -rf packages/*/*/*.deb
	rm -rf packages/*/*/*.rpm

build:
	bash build.sh

vagrant-build:
	cd vagrant && vagrant ssh -c 'cd build; make'

vagrant-validate:
	cd vagrant && cucumber
