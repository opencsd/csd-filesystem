# Makefile for various po files.

libdir = ../lib

CATALOGS = $(LINGUAS)
MO_FILES = $(addsuffix .gmo, $(LINGUAS))

MSGMERGE  = msgmerge
MSGFMT    = msgfmt
XGETTEXT  = xgettext
CATOBJEXT = .po

include PACKAGE

TD = $(strip $(TEXTDOMAIN))

default: help

all: $(TD).pot update-po update-mo install

help:
	@echo "Available targets:"
	@echo "  pot                       - remake master catalog"
	@echo "  update-po                 - merge po files"
	@echo "  update-mo                 - regenerate mo files"
	@echo "  install                   - install mo files"
	@echo "  all                       - all of the above"

POTFILES = ./POTFILES \
	$(shell cat ./POTFILES)

pot: $(TD).pot

clean:
	rm -f *~ *.bak *.gmo

$(TD).pot: $(POTFILES)
	$(XGETTEXT) --output=./$(TD).pox --from-code=utf-8 \
		--add-comments=TRANSLATORS: --files-from=./POTFILES \
		--copyright-holder="$(COPYRIGHT_HOLDER)" \
		--msgid-bugs-address="$(MSGID_BUGS_ADDRESS)" \
		--keyword --keyword='$$__' --keyword=__ --keyword=__x \
		--keyword=__n:1,2 --keyword=__nx:1,2 --keyword=__xn:1,2 \
		--keyword=__p:1c,2 --keyword=__np:1c,2,3 \
		--keyword=__npx:1c,2,3 --keyword=N__ --keyword=N__n:1,2 \
		--keyword=N__p:1c,2 --keyword=N__np:1c,2,3 --keyword=%__ && \
	rm -f $@ && mv $(TD).pox $@;

install: $(MO_FILES)
	targetdir='$(INSTALL_BASE)'; \
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		mkdir -p "$$targetdir/$$lang/LC_MESSAGES" || exit 1; \
		dest="$$targetdir/$$lang/LC_MESSAGES/$(TD).mo"; \
		cat="$$lang.gmo"; \
		echo "installing $$cat as $$dest"; \
		cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
	done

update-mo: $(MO_FILES)

update-po:
	$(MAKE) $(TD).pot
	catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
		cat=`basename $$cat`; \
		lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
		echo "$$lang:"; \
		if [ ! -e $$lang.po ]; then \
			echo "msgmerge for $$cat failed!"; \
		fi; \
		if $(MSGMERGE) -U $$lang.po $(TD).pot --suffix=~; then \
			rm -f $$lang.po~; \
		fi; \
	done

.SUFFIXES: .po .gmo

.po.gmo:
	$(MSGFMT) --check --statistics --verbose -o $@ $<
