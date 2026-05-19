M := .cache/makes
$(shell [ -d $M ] || (git clone -q https://github.com/makeplus/makes $M))

include $M/init.mk
include $M/nono.mk
include $M/claude.mk
include $M/perl.mk
include $M/clean.mk
include $M/shell.mk

MAKES-CLEAN := \
  MYMETA.json \
  MYMETA.yml \
  Makefile \
  blib \
  pm_to_blib \

CLAUDE-OPTS := \
  --dangerously-skip-permissions \


test: Makefile $(PERL-CPANFILE-DEPS)
	make -f $< $@

claude: claude-nono-start
