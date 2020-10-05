requires 'perl', '5.008005';

requires 'Rex';
requires 'Path::Tiny';

on test => sub {
    requires 'Test::More', '0.96';
};
