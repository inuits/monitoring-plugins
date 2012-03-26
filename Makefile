all:
	make clean
	make build

clean:
	rm -rf packages/*/*/*.deb
	rm -rf packages/*/*/*.rpm

build:
	bash build.sh
