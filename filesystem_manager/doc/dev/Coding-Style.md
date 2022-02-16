# Coding Style

## Perl

You can use the [perltidy](https://metacpan.org/pod/distribution/Perl-Tidy/bin/perltidy) for formatting perl code easily.

we recommend using this to format the perl source code in GMS.

```
# GMS .perltidyrc file

--maximum-line-length=78                    # Max line width is 78 cols
--indent-columns=4                          # Indent level is 4 cols
--continuation-indentation=4                # Continuation indent is 4 cols

--backup-and-modify-in-place                # Write the file inline and create
                                            # a .bak file
--backup-file-extension=/                   # No backup needed
#--standard-output                           # Output to STDOUT
--standard-error-output                     # Errors to STDERR
--warning-output                            # Warnings to STDERR
--check-syntax                              # Checks syntax

##############################################################################
### Code Indentation Control
##############################################################################
--nooutdent-long-lines                      # Don't outdent long quoted
                                            # strings
--closing-token-indentation=0               # No extra indentation for
                                            # closing brackets

##############################################################################
### Whitespace Control
##############################################################################
--paren-tightness=2                         # parenthesis tightness
--square-bracket-tightness=2                # square bracket tightness
--brace-tightness=2                         # brace tightness
--block-brace-tightness=0                   # block brace tightness
--nospace-for-semicolon                     # No space before semicolons
--nological-padding                         # No logical padding

##############################################################################
### Comment Control
##############################################################################
--indent-spaced-block-comments

##############################################################################
### Line Break Control
##############################################################################
--opening-brace-on-new-line                 # Open brace on a new line
--opening-sub-brace-on-new-line             # Open sub-brace on a new line
--opening-anonymous-sub-brace-on-new-line   # Open anon-sub's sub-brace on a

--vertical-tightness=0                      # never break a line after
                                            # opening token
--vertical-tightness-closing=0              # Maximal vertical tightness
--block-brace-vertical-tightness=0          #

--weld-nested-containers                    # Weld nested containers

# Break before all operators
--want-break-before="% + - * / x != == >= <= =~ !~ < > | & = **= += *= &= <<= &&= -= /= |= >>= ||= //= .= %= ^= x= qq"

##############################################################################
### Controlling List Formatting
##############################################################################
--maximum-fields-per-table=1
--comma-arrow-breakpoints=5
```

Also you can find this file in the project root directory named as `.perltidyrc`

### Usage

```bash
[potatogim@localhost ~]# perltidy -pro=.perltidyrc lib/GMS.pm
```

## Javascript

### Usage
