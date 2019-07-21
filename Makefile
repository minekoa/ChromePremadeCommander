ELM_MAKE=elm make

OUTDIR=PremaidCommander
SRCDIR=src

ELMMAIN=Main
ELMFILES=$(ELMMAIN).elm Bluetooth.elm
JSFILES=elm_import.js bluetooth.js
CHAPPS_FILES=manifest.json index.html background.js

PKGFILES=$(CHAPPS_FILES:%=$(OUTDIR)/%) $(JSFILES:%=$(OUTDIR)/%) $(OUTDIR)/$(ELMMAIN).js

.PHONY: all clean

all: $(OUTDIR) $(PKGFILES)
	zip archive -r $(OUTDIR)

$(JSFILES:%=$(OUTDIR)/%) : $(JSFILES:%=$(SRCDIR)/js/%)
	cp $(SRCDIR)/js/$(notdir $@) $@

$(CHAPPS_FILES:%=$(OUTDIR)/%) : $(CHAPPS_FILES:%=$(SRCDIR)/%)
	cp $(SRCDIR)/$(notdir $@) $@

$(OUTDIR)/$(ELMMAIN).js : $(ELMFILES:%=$(SRCDIR)/elm/%)
	$(ELM_MAKE) $(SRCDIR)/elm/$(ELMMAIN).elm --output=$(OUTDIR)/$(ELMMAIN).js

$(OUTDIR):
	mkdir $@

clean:
	rm -rf $(OUTDIR)
