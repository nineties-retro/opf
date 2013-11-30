opf_roff= groff -Tascii -man
opf_unformat=col -b
opf_as_flags = $(ASFLAGS)
opf_as=as
opf_ld=ld
opf_ld_magic_flags=-N
opf_rm=rm -f

opf_src = opf.s
opf_obj=$(opf_src:%.s=%.o)

.PHONEY: all clean realclean distclean

all:	opf opf.doc

opf:	$(opf_obj)
	$(opf_ld) $(opf_ld_magic_flags) -o $@ $(opf_obj)

opf.doc:	opf.1
	$(opf_roff) opf.1 | $(opf_unformat) > $@

%.o:	%.s
	$(opf_as) $(opf_as_flags) -o $@ $<

clean:
	$(opf_rm) opf $(opf_obj)

realclean: clean
	$(opf_rm) opf.doc

distclean: realclean
	find . -name '*~' -print0 | xargs -0 $(opf_rm)
