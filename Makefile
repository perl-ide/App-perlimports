# This Makefile is for the App::perlimports extension to perl.
#
# It was generated automatically by MakeMaker version
# 7.70 (Revision: 77000) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     ABSTRACT => q[Make implicit imports explicit]
#     AUTHOR => [q[Olaf Alders <olaf@wundercounter.com>]]
#     BUILD_REQUIRES => {  }
#     CONFIGURE_REQUIRES => { ExtUtils::MakeMaker=>q[0] }
#     DISTNAME => q[App-perlimports]
#     EXE_FILES => [q[script/dump-perl-exports], q[script/perlimports]]
#     LICENSE => q[perl]
#     MIN_PERL_VERSION => q[5.018000]
#     NAME => q[App::perlimports]
#     PREREQ_PM => { Capture::Tiny=>q[0], Class::Inspector=>q[1.36], Cpanel::JSON::XS=>q[0], Data::Dumper=>q[0], Data::UUID=>q[0], ExtUtils::MakeMaker=>q[0], File::Basename=>q[0], File::Spec=>q[0], File::XDG=>q[1.01], File::pushd=>q[0], Getopt::Long::Descriptive=>q[0], List::Util=>q[0], Log::Dispatch=>q[2.70], Log::Dispatch::Array=>q[0], Memoize=>q[0], Module::Runtime=>q[0], Moo=>q[0], Moo::Role=>q[0], MooX::StrictConstructor=>q[0], PPI=>q[1.276], PPI::Document=>q[0], PPI::Dumper=>q[0], PPIx::Utils::Classification=>q[0], Path::Iterator::Rule=>q[0], Path::Tiny=>q[0], Perl::Tidy=>q[20220613], Pod::Usage=>q[0], Ref::Util=>q[0], Scalar::Util=>q[0], Sereal::Decoder=>q[0], Sereal::Encoder=>q[0], Sub::Exporter=>q[0], Sub::HandlesVia=>q[0], Symbol::Get=>q[0.10], TOML::Tiny=>q[0.16], Test::Differences=>q[0], Test::Fatal=>q[0], Test::More=>q[0], Test::Needs=>q[0], Test::RequiresInternet=>q[0], Test::Script=>q[1.29], Test::Warnings=>q[0], Text::Diff=>q[0], Text::SimpleTable::AutoWidth=>q[0], Try::Tiny=>q[0], Types::Standard=>q[0], feature=>q[0], lib=>q[0], strict=>q[0], utf8=>q[0], warnings=>q[0] }
#     TEST_REQUIRES => { ExtUtils::MakeMaker=>q[0], File::Spec=>q[0], File::pushd=>q[0], Log::Dispatch::Array=>q[0], PPI::Dumper=>q[0], Sub::Exporter=>q[0], Test::Differences=>q[0], Test::Fatal=>q[0], Test::More=>q[0], Test::Needs=>q[0], Test::RequiresInternet=>q[0], Test::Script=>q[1.29], Test::Warnings=>q[0], lib=>q[0] }
#     VERSION => q[0.000059]
#     test => { TESTS=>q[t/*.t t/ExportInspector/*.t t/cpan-modules/*.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/x86_64-linux-gnu/perl-base/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = x86_64-linux-gnu-gcc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
CPPRUN = x86_64-linux-gnu-gcc  -E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = x86_64-linux-gnu-gcc
LDDLFLAGS = -shared -L/usr/local/lib -fstack-protector-strong
LDFLAGS =  -fstack-protector-strong -L/usr/local/lib
LIBC = /lib/x86_64-linux-gnu/libc.so.6
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 6.1.0
RANLIB = :
SITELIBEXP = /usr/local/share/perl/5.38.2
SITEARCHEXP = /usr/local/lib/x86_64-linux-gnu/perl/5.38.2
SO = so
VENDORARCHEXP = /usr/lib/x86_64-linux-gnu/perl5/5.38
VENDORLIBEXP = /usr/share/perl5


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = App::perlimports
NAME_SYM = App_perlimports
VERSION = 0.000059
VERSION_MACRO = VERSION
VERSION_SYM = 0_000059
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 0.000059
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1p
MAN3EXT = 3pm
MAN1SECTION = 1
MAN3SECTION = 3
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /usr
SITEPREFIX = /usr/local
VENDORPREFIX = /usr
INSTALLPRIVLIB = /usr/share/perl/5.38
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /usr/local/share/perl/5.38.2
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = /usr/share/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /usr/lib/x86_64-linux-gnu/perl/5.38
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /usr/local/lib/x86_64-linux-gnu/perl/5.38.2
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = /usr/lib/x86_64-linux-gnu/perl5/5.38
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /usr/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /usr/local/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = /usr/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /usr/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /usr/local/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = /usr/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /usr/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /usr/local/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = /usr/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /usr/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /usr/local/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = /usr/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB = /usr/share/perl/5.38
PERL_ARCHLIB = /usr/lib/x86_64-linux-gnu/perl/5.38
PERL_ARCHLIBDEP = /usr/lib/x86_64-linux-gnu/perl/5.38
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/x86_64-linux-gnu/perl/5.38/CORE
PERL_INCDEP = /usr/lib/x86_64-linux-gnu/perl/5.38/CORE
PERL = "/usr/bin/perl"
FULLPERL = "/usr/bin/perl"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/share/perl/5.38/ExtUtils/MakeMaker.pm
MM_VERSION  = 7.70
MM_REVISION = 77000

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = App/perlimports
BASEEXT = perlimports
PARENT_NAME = App
DLBASE = $(BASEEXT)
VERSION_FROM = 
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = script/dump-perl-exports \
	script/perlimports
MAN3PODS = lib/App/perlimports.pm \
	lib/App/perlimports/Annotations.pm \
	lib/App/perlimports/CLI.pm \
	lib/App/perlimports/Config.pm \
	lib/App/perlimports/Document.pm \
	lib/App/perlimports/ExportInspector.pm \
	lib/App/perlimports/Include.pm \
	lib/App/perlimports/Sandbox.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIBDEP)$(DFSEP)Config.pm $(PERL_INCDEP)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)/App
INST_ARCHLIBDIR  = $(INST_ARCHLIB)/App

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVEDEP    = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = lib/App/perlimports.pm \
	lib/App/perlimports/Annotations.pm \
	lib/App/perlimports/CLI.pm \
	lib/App/perlimports/Config.pm \
	lib/App/perlimports/Document.pm \
	lib/App/perlimports/ExportInspector.pm \
	lib/App/perlimports/Include.pm \
	lib/App/perlimports/Role/Logger.pm \
	lib/App/perlimports/Sandbox.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 7.70
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --
CP_NONEMPTY = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'cp_nonempty' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(NOECHO) $(NOOP)
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = App-perlimports
DISTVNAME = App-perlimports-0.000059


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	LD="$(LD)"\
	PREFIX="$(PREFIX)"\
	PASTHRU_DEFINE='$(DEFINE) $(PASTHRU_DEFINE)'\
	PASTHRU_INC='$(INC) $(PASTHRU_INC)'


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir pure_all subdirs clean_subdirs makemakerdflt manifypods realclean_subdirs subdirs_dynamic subdirs_pure_nolink subdirs_static subdirs-test_dynamic subdirs-test_static test_dynamic test_static



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)

pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: dynamic
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) config $(INST_BOOT) $(INST_DYNAMIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config  \
	lib/App/perlimports.pm \
	lib/App/perlimports/Annotations.pm \
	lib/App/perlimports/CLI.pm \
	lib/App/perlimports/Config.pm \
	lib/App/perlimports/Document.pm \
	lib/App/perlimports/ExportInspector.pm \
	lib/App/perlimports/Include.pm \
	lib/App/perlimports/Sandbox.pm \
	script/dump-perl-exports \
	script/perlimports
	$(NOECHO) $(POD2MAN) --section=$(MAN1EXT) --perm_rw=$(PERM_RW) -u \
	  script/dump-perl-exports $(INST_MAN1DIR)/dump-perl-exports.$(MAN1EXT) \
	  script/perlimports $(INST_MAN1DIR)/perlimports.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=$(MAN3EXT) --perm_rw=$(PERM_RW) -u \
	  lib/App/perlimports.pm $(INST_MAN3DIR)/App::perlimports.$(MAN3EXT) \
	  lib/App/perlimports/Annotations.pm $(INST_MAN3DIR)/App::perlimports::Annotations.$(MAN3EXT) \
	  lib/App/perlimports/CLI.pm $(INST_MAN3DIR)/App::perlimports::CLI.$(MAN3EXT) \
	  lib/App/perlimports/Config.pm $(INST_MAN3DIR)/App::perlimports::Config.$(MAN3EXT) \
	  lib/App/perlimports/Document.pm $(INST_MAN3DIR)/App::perlimports::Document.$(MAN3EXT) \
	  lib/App/perlimports/ExportInspector.pm $(INST_MAN3DIR)/App::perlimports::ExportInspector.$(MAN3EXT) \
	  lib/App/perlimports/Include.pm $(INST_MAN3DIR)/App::perlimports::Include.$(MAN3EXT) \
	  lib/App/perlimports/Sandbox.pm $(INST_MAN3DIR)/App::perlimports::Sandbox.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = script/dump-perl-exports script/perlimports

pure_all :: $(INST_SCRIPT)/dump-perl-exports $(INST_SCRIPT)/perlimports
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/dump-perl-exports $(INST_SCRIPT)/perlimports 

$(INST_SCRIPT)/dump-perl-exports : script/dump-perl-exports $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/dump-perl-exports
	$(CP) script/dump-perl-exports $(INST_SCRIPT)/dump-perl-exports
	$(FIXIN) $(INST_SCRIPT)/dump-perl-exports
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/dump-perl-exports

$(INST_SCRIPT)/perlimports : script/perlimports $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/perlimports
	$(CP) script/perlimports $(INST_SCRIPT)/perlimports
	$(FIXIN) $(INST_SCRIPT)/perlimports
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/perlimports



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  $(BASEEXT).bso $(BASEEXT).def \
	  $(BASEEXT).exp $(BASEEXT).x \
	  $(BOOTSTRAP) $(INST_ARCHAUTODIR)/extralibs.all \
	  $(INST_ARCHAUTODIR)/extralibs.ld $(MAKE_APERL_FILE) \
	  *$(LIB_EXT) *$(OBJ_EXT) \
	  *perl.core MYMETA.json \
	  MYMETA.yml blibdirs.ts \
	  core core.*perl.*.? \
	  core.[0-9] core.[0-9][0-9] \
	  core.[0-9][0-9][0-9] core.[0-9][0-9][0-9][0-9] \
	  core.[0-9][0-9][0-9][0-9][0-9] lib$(BASEEXT).def \
	  mon.out perl \
	  perl$(EXE_EXT) perl.exe \
	  perlmain.c pm_to_blib \
	  pm_to_blib.ts so_locations \
	  tmon.out 
	- $(RM_RF) \
	  blib 
	  $(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
# so clean is forced to complete before realclean_subdirs runs
realclean_subdirs : clean
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge :: realclean_subdirs
	- $(RM_F) \
	  $(FIRST_MAKEFILE) $(MAKEFILE_OLD) 
	- $(RM_RF) \
	  $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	$(NOECHO) $(ECHO) '---' > META_new.yml
	$(NOECHO) $(ECHO) 'abstract: '\''Make implicit imports explicit'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'author:' >> META_new.yml
	$(NOECHO) $(ECHO) '  - '\''Olaf Alders <olaf@wundercounter.com>'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'build_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Spec: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::pushd: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Log::Dispatch::Array: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  PPI::Dumper: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Sub::Exporter: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Differences: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Fatal: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::More: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Needs: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::RequiresInternet: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Script: '\''1.29'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Test::Warnings: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  lib: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'configure_requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  ExtUtils::MakeMaker: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'dynamic_config: 1' >> META_new.yml
	$(NOECHO) $(ECHO) 'generated_by: '\''ExtUtils::MakeMaker version 7.70, CPAN::Meta::Converter version 2.150010'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'license: perl' >> META_new.yml
	$(NOECHO) $(ECHO) 'meta-spec:' >> META_new.yml
	$(NOECHO) $(ECHO) '  url: http://module-build.sourceforge.net/META-spec-v1.4.html' >> META_new.yml
	$(NOECHO) $(ECHO) '  version: '\''1.4'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'name: App-perlimports' >> META_new.yml
	$(NOECHO) $(ECHO) 'no_index:' >> META_new.yml
	$(NOECHO) $(ECHO) '  directory:' >> META_new.yml
	$(NOECHO) $(ECHO) '    - t' >> META_new.yml
	$(NOECHO) $(ECHO) '    - inc' >> META_new.yml
	$(NOECHO) $(ECHO) 'requires:' >> META_new.yml
	$(NOECHO) $(ECHO) '  Capture::Tiny: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Class::Inspector: '\''1.36'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Cpanel::JSON::XS: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Data::Dumper: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Data::UUID: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::Basename: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  File::XDG: '\''1.01'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Getopt::Long::Descriptive: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  List::Util: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Log::Dispatch: '\''2.70'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Memoize: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Module::Runtime: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Moo: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Moo::Role: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  MooX::StrictConstructor: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  PPI: '\''1.276'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  PPI::Document: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  PPIx::Utils::Classification: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Path::Iterator::Rule: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Path::Tiny: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Perl::Tidy: '\''20220613'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Pod::Usage: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Ref::Util: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Scalar::Util: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Sereal::Decoder: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Sereal::Encoder: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Sub::HandlesVia: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Symbol::Get: '\''0.10'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  TOML::Tiny: '\''0.16'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Text::Diff: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Text::SimpleTable::AutoWidth: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Try::Tiny: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  Types::Standard: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  feature: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  perl: '\''5.018000'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  strict: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  utf8: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) '  warnings: '\''0'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'version: '\''0.000059'\''' >> META_new.yml
	$(NOECHO) $(ECHO) 'x_serialization_backend: '\''CPAN::Meta::YAML version 0.018'\''' >> META_new.yml
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
	$(NOECHO) $(ECHO) Generating META.json
	$(NOECHO) $(ECHO) '{' > META_new.json
	$(NOECHO) $(ECHO) '   "abstract" : "Make implicit imports explicit",' >> META_new.json
	$(NOECHO) $(ECHO) '   "author" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "Olaf Alders <olaf@wundercounter.com>"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "dynamic_config" : 1,' >> META_new.json
	$(NOECHO) $(ECHO) '   "generated_by" : "ExtUtils::MakeMaker version 7.70, CPAN::Meta::Converter version 2.150010",' >> META_new.json
	$(NOECHO) $(ECHO) '   "license" : [' >> META_new.json
	$(NOECHO) $(ECHO) '      "perl_5"' >> META_new.json
	$(NOECHO) $(ECHO) '   ],' >> META_new.json
	$(NOECHO) $(ECHO) '   "meta-spec" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",' >> META_new.json
	$(NOECHO) $(ECHO) '      "version" : 2' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "name" : "App-perlimports",' >> META_new.json
	$(NOECHO) $(ECHO) '   "no_index" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "directory" : [' >> META_new.json
	$(NOECHO) $(ECHO) '         "t",' >> META_new.json
	$(NOECHO) $(ECHO) '         "inc"' >> META_new.json
	$(NOECHO) $(ECHO) '      ]' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "prereqs" : {' >> META_new.json
	$(NOECHO) $(ECHO) '      "build" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "configure" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "runtime" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "Capture::Tiny" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Class::Inspector" : "1.36",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Cpanel::JSON::XS" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Data::Dumper" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Data::UUID" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Basename" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::XDG" : "1.01",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Getopt::Long::Descriptive" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "List::Util" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Log::Dispatch" : "2.70",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Memoize" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Module::Runtime" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Moo" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Moo::Role" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "MooX::StrictConstructor" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "PPI" : "1.276",' >> META_new.json
	$(NOECHO) $(ECHO) '            "PPI::Document" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "PPIx::Utils::Classification" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Path::Iterator::Rule" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Path::Tiny" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Perl::Tidy" : "20220613",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Pod::Usage" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Ref::Util" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Scalar::Util" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Sereal::Decoder" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Sereal::Encoder" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Sub::HandlesVia" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Symbol::Get" : "0.10",' >> META_new.json
	$(NOECHO) $(ECHO) '            "TOML::Tiny" : "0.16",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Text::Diff" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Text::SimpleTable::AutoWidth" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Try::Tiny" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Types::Standard" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "feature" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "perl" : "5.018000",' >> META_new.json
	$(NOECHO) $(ECHO) '            "strict" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "utf8" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "warnings" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      },' >> META_new.json
	$(NOECHO) $(ECHO) '      "test" : {' >> META_new.json
	$(NOECHO) $(ECHO) '         "requires" : {' >> META_new.json
	$(NOECHO) $(ECHO) '            "ExtUtils::MakeMaker" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::Spec" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "File::pushd" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Log::Dispatch::Array" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "PPI::Dumper" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Sub::Exporter" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Differences" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Fatal" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::More" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Needs" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::RequiresInternet" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Script" : "1.29",' >> META_new.json
	$(NOECHO) $(ECHO) '            "Test::Warnings" : "0",' >> META_new.json
	$(NOECHO) $(ECHO) '            "lib" : "0"' >> META_new.json
	$(NOECHO) $(ECHO) '         }' >> META_new.json
	$(NOECHO) $(ECHO) '      }' >> META_new.json
	$(NOECHO) $(ECHO) '   },' >> META_new.json
	$(NOECHO) $(ECHO) '   "release_status" : "stable",' >> META_new.json
	$(NOECHO) $(ECHO) '   "version" : "0.000059",' >> META_new.json
	$(NOECHO) $(ECHO) '   "x_serialization_backend" : "JSON::PP version 4.16"' >> META_new.json
	$(NOECHO) $(ECHO) '}' >> META_new.json
	-$(NOECHO) $(MV) META_new.json $(DISTVNAME)/META.json


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)_uu'

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).tar$(SUFFIX)'
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).zip'
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(NOECHO) $(ECHO) 'Created $(DISTVNAME).shar'
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir distmeta 
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:
ci :
	$(ABSPERLRUN) -MExtUtils::Manifest=maniread -e '@all = sort keys %{ maniread() };' \
	  -e 'print(qq{Executing $(CI) @all\n});' \
	  -e 'system(qq{$(CI) @all}) == 0 or die $$!;' \
	  -e 'print(qq{Executing $(RCS_LABEL) ...\n});' \
	  -e 'system(qq{$(RCS_LABEL) @all}) == 0 or die $$!;' --


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.yml to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add META.json to MANIFEST: $${'\''@'\''}"' --



# --- MakeMaker distsignature section:
distsignature : distmeta
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) }' \
	  -e '    or die "Could not add SIGNATURE to MANIFEST: $${'\''@'\''}"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		"$(INST_LIB)" "$(DESTINSTALLPRIVLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLARCHLIB)" \
		"$(INST_BIN)" "$(DESTINSTALLBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(SITEARCHEXP)/auto/$(FULLEXT)"


pure_site_install :: all
	$(NOECHO) umask 02; $(MOD_INSTALL) \
		read "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist" \
		write "$(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist" \
		"$(INST_LIB)" "$(DESTINSTALLSITELIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLSITEARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLSITEBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLSITESCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLSITEMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLSITEMAN3DIR)"
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		"$(PERL_ARCHLIB)/auto/$(FULLEXT)"

pure_vendor_install :: all
	$(NOECHO) umask 022; $(MOD_INSTALL) \
		"$(INST_LIB)" "$(DESTINSTALLVENDORLIB)" \
		"$(INST_ARCHLIB)" "$(DESTINSTALLVENDORARCH)" \
		"$(INST_BIN)" "$(DESTINSTALLVENDORBIN)" \
		"$(INST_SCRIPT)" "$(DESTINSTALLVENDORSCRIPT)" \
		"$(INST_MAN1DIR)" "$(DESTINSTALLVENDORMAN1DIR)" \
		"$(INST_MAN3DIR)" "$(DESTINSTALLVENDORMAN3DIR)"


doc_perl_install :: all

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to "$(DESTINSTALLSITEARCH)/perllocal.pod"
	-$(NOECHO) umask 02; $(MKPATH) "$(DESTINSTALLSITEARCH)"
	-$(NOECHO) umask 02; $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> "$(DESTINSTALLSITEARCH)/perllocal.pod"

doc_vendor_install :: all


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) "$(SITEARCHEXP)/auto/$(FULLEXT)/.packlist"

uninstall_from_vendordirs ::


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = "/usr/bin/perl"
MAP_PERLINC   = "-Iblib/arch" "-Iblib/lib" "-I/usr/lib/x86_64-linux-gnu/perl/5.38" "-I/usr/share/perl/5.38"

$(MAP_TARGET) :: $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : static $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR="" \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:
TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/*.t t/ExportInspector/*.t t/cpan-modules/*.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)
	$(NOECHO) $(NOOP)

test :: $(TEST_TYPE)
	$(NOECHO) $(NOOP)

# Occasionally we may face this degenerate target:
test_ : test_dynamic
	$(NOECHO) $(NOOP)

subdirs-test_dynamic :: dynamic pure_all

test_dynamic :: subdirs-test_dynamic
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: dynamic pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

subdirs-test_static :: static pure_all

test_static :: subdirs-test_static
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_static :: static pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)



# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="App-perlimports" VERSION="0.000059">' > App-perlimports.ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT>Make implicit imports explicit</ABSTRACT>' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '    <AUTHOR>Olaf Alders &lt;olaf@wundercounter.com&gt;</AUTHOR>' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <PERLCORE VERSION="5,018000,0,0" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Capture::Tiny" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Class::Inspector" VERSION="1.36" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Cpanel::JSON::XS" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Data::Dumper" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Data::UUID" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::Basename" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="File::XDG" VERSION="1.01" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Getopt::Long::Descriptive" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="List::Util" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Log::Dispatch" VERSION="2.70" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Memoize::" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Module::Runtime" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Moo::" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Moo::Role" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="MooX::StrictConstructor" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="PPI::" VERSION="1.276" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="PPI::Document" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="PPIx::Utils::Classification" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Path::Iterator::Rule" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Path::Tiny" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Perl::Tidy" VERSION="20220613" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Pod::Usage" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Ref::Util" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Scalar::Util" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Sereal::Decoder" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Sereal::Encoder" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Sub::HandlesVia" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Symbol::Get" VERSION="0.10" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="TOML::Tiny" VERSION="0.16" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Text::Diff" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Text::SimpleTable::AutoWidth" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Try::Tiny" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Types::Standard" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="feature::" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="strict::" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="utf8::" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="warnings::" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-gnu-thread-multi-5.38" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> App-perlimports.ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> App-perlimports.ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  'lib/App/perlimports.pm' 'blib/lib/App/perlimports.pm' \
	  'lib/App/perlimports/Annotations.pm' 'blib/lib/App/perlimports/Annotations.pm' \
	  'lib/App/perlimports/CLI.pm' 'blib/lib/App/perlimports/CLI.pm' \
	  'lib/App/perlimports/Config.pm' 'blib/lib/App/perlimports/Config.pm' \
	  'lib/App/perlimports/Document.pm' 'blib/lib/App/perlimports/Document.pm' \
	  'lib/App/perlimports/ExportInspector.pm' 'blib/lib/App/perlimports/ExportInspector.pm' \
	  'lib/App/perlimports/Include.pm' 'blib/lib/App/perlimports/Include.pm' \
	  'lib/App/perlimports/Role/Logger.pm' 'blib/lib/App/perlimports/Role/Logger.pm' \
	  'lib/App/perlimports/Sandbox.pm' 'blib/lib/App/perlimports/Sandbox.pm' 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:

# here so even if top_targets is overridden, these will still be defined
# gmake will silently still work if any are .PHONY-ed but nmake won't

static ::
	$(NOECHO) $(NOOP)

dynamic ::
	$(NOECHO) $(NOOP)

config ::
	$(NOECHO) $(NOOP)


# --- MakeMaker postamble section:


# End.
