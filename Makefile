EMACS=emacs
ORG_CONFIG_FILE=publish-config.el
EMACS_OPTS=--batch --eval "(load-file \"$(ORG_CONFIG_FILE)\")" -f myweb-publish

all: html 

html:
	@echo "Generating HTML..."
	@$(EMACS) $(EMACS_OPTS)
	@echo "HTML generation done"

clean: clean_bak

clean_bak:
	@find . | grep ~$$ | while read l; do rm $$l; done
