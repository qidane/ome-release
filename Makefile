PY=python
PELICAN=pelican
PELICANOPTS=

IMAGESDIR=images/
BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/output
CONTENTDIR=$(BASEDIR)/content
CONFFILE=$(BASEDIR)/pelicanconf.py

DEBUG ?= 0
ifeq ($(DEBUG), 1)
	PELICANOPTS += -D
endif

omero: gen

bf: bfgen

figure: figuregen

flimfit: flimfitgen

searcher: searchergen

utrack: utrackgen

mtools: mtoolsgen

webtagging: webtagginggen

gen:
	mkdir -p $(CONTENTDIR)
	python gen.py $(RELEASE) $(OMERO_BUILD) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

bfgen:
	mkdir -p $(CONTENTDIR)
	python bfgen.py $(RELEASE) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

figuregen:
	mkdir -p $(CONTENTDIR)
	python figuregen.py $(RELEASE) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

flimfitgen:
	mkdir -p $(CONTENTDIR)
	python flimfitgen.py $(RELEASE) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

searchergen:
	mkdir -p $(CONTENTDIR)
	python searchergen.py $(RELEASE) $(PYSLIDVERSION) $(RICERCAVERSION) $(BUILDNUM) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

utrackgen:
	mkdir -p $(CONTENTDIR)
	python utrackgen.py $(RELEASE) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

mtoolsgen:
	mkdir -p $(CONTENTDIR)
	python mtoolsgen.py $(RELEASE) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

webtagginggen:
	mkdir -p $(CONTENTDIR)
	python webtagginggen.py $(RELEASE) > $(CONTENTDIR)/index.html
	cp -r $(IMAGESDIR) $(CONTENTDIR)

html:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)

regenerate:
	$(PELICAN) -r $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

serve:
ifdef PORT
	cd $(OUTPUTDIR) && $(PY) -m pelican.server $(PORT)
else
	cd $(OUTPUTDIR) && $(PY) -m pelican.server
endif

devserver:
ifdef PORT
	$(BASEDIR)/develop_server.sh restart $(PORT)
else
	$(BASEDIR)/develop_server.sh restart
endif

stopserver:
	kill -9 `cat pelican.pid`
	kill -9 `cat srv.pid`
	@echo 'Stopped Pelican and SimpleHTTPServer processes running in background.'

publish:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(PUBLISHCONF) $(PELICANOPTS)

ssh_upload: publish
	scp -P $(SSH_PORT) -r $(OUTPUTDIR)/* $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)

rsync_upload: publish
	rsync -e "ssh -p $(SSH_PORT)" -P -rvz --delete $(OUTPUTDIR)/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR) --cvs-exclude

dropbox_upload: publish
	cp -r $(OUTPUTDIR)/* $(DROPBOX_DIR)

ftp_upload: publish
	lftp ftp://$(FTP_USER)@$(FTP_HOST) -e "mirror -R $(OUTPUTDIR) $(FTP_TARGET_DIR) ; quit"

s3_upload: publish
	s3cmd sync $(OUTPUTDIR)/ s3://$(S3_BUCKET) --acl-public --delete-removed

cf_upload: publish
	cd $(OUTPUTDIR) && swift -v -A https://auth.api.rackspacecloud.com/v1.0 -U $(CLOUDFILES_USERNAME) -K $(CLOUDFILES_API_KEY) upload -c $(CLOUDFILES_CONTAINER) .

github: publish
	ghp-import $(OUTPUTDIR)
	git push origin gh-pages

.PHONY: html help clean regenerate serve devserver publish ssh_upload rsync_upload dropbox_upload ftp_upload s3_upload cf_upload github
