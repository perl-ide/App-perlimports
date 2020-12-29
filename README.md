[![Actions Status](https://github.com/oalders/App-perlimports/workflows/dzil-build-and-test/badge.svg)](https://github.com/oalders/App-perlimports/actions)
[![Coverage Status](https://coveralls.io/repos/oalders/App-perlimports/badge.svg?branch=master)](https://coveralls.io/r/oalders/App-perlimports?branch=master)
[![codecov](https://codecov.io/gh/oalders/App-perlimports/branch/master/graph/badge.svg)](https://codecov.io/gh/oalders/App-perlimports)
[![Kwalitee status](http://cpants.cpanauthors.org/dist/App-perlimports.png)](https://cpants.cpanauthors.org/dist/App-perlimports)
[![GitHub tag](https://img.shields.io/github/tag/oalders/App-perlimports.svg)]()
[![Cpan license](https://img.shields.io/cpan/l/App-perlimports.svg)](https://metacpan.org/release/App-perlimports)

# NAME

App::perlimports - Make implicit imports explicit

# VERSION

version 0.001

## formatted\_import\_statement

Returns a [PPI::Statement::Include](https://metacpan.org/pod/PPI%3A%3AStatement%3A%3AInclude). This can be stringified into an import
statement or used to replace an existing [PPI::Statement::Include](https://metacpan.org/pod/PPI%3A%3AStatement%3A%3AInclude).

# CAVEATS

Does not work with modules using [Sub::Exporter](https://metacpan.org/pod/Sub%3A%3AExporter).

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
