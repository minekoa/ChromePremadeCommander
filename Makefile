ELM_MAKE=elm make

OUTDIR=PremaidCommander
SRCDIR=src

ELMMAIN=Main
ELMFILES=$(ELMMAIN).elm Bluetooth.elm
JSFILES=elm_import.js bluetooth.js
CHAPPS_FILES=manifest.json index.html background.js

ZIP_FILE=PremedeCommander.zip

PKGFILES=$(CHAPPS_FILES) $(JSFILES) $(ELMMAIN).js

.PHONY: all clean

all: $(ZIP_FILE)


$(ZIP_FILE) : $(OUTDIR) $(PKGFILES:%=$(OUTDIR)/%)
	zip $(ZIP_FILE) -r $(OUTDIR)

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
	rm -rf $(ZIP_FILE)
