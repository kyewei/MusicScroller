TARGET = iphone:latest:7.0
ARCHS = armv7 arm64 armv7s

include theos/makefiles/common.mk

TWEAK_NAME = MusicScroller
MusicScroller_FILES = Tweak.xm
MusicScroller_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Music"
