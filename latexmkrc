# 1. Standard profile is default and jobname_sufix is none
$profile = 'default';
$jobname_sufix = '';

# 2. Get kwargs from terminal
for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] =~ /^-profile=(.*)$/) {
        $profile = $1;          # Save profile name (defacult, abnt, ...)
        
        # If using other profile, put in jobname_sufix
        if ($profile ne 'default') {
            $jobname_sufix = '-' . $profile;
        }
        
        splice @ARGV, $i, 1;
        $i--;
    }
}

# 3. Define a jobaname (file output name) from jobname_sufit
$jobname = "%A" . $jobname_sufix; #<-- Append sufix to original name

# 4. Engine (LuaLaTeX) and folder config
$pdf_mode = 4; 
$emulate_aux = 1;
$aux_dir = 'build';
$out_dir = '.';

# 5. Inject profile var into LuaLaTeX enviroment to load the correct profile.toml in lua
$lualatex = 'lualatex -interaction=nonstopmode -synctex=1 -shell-escape %O "\def\CleanTeXprofile{'.$profile.'}\input{%S}"';

add_cus_dep('glo', 'gls', 0, 'run_makeglossaries');
add_cus_dep('acn', 'acr', 0, 'run_makeglossaries');

sub run_makeglossaries {
    my ($base_name, $path) = fileparse( $_[0] );
    my $dir = $aux_dir;
    if ( $dir eq '' ) { $dir = '.'; }
    system("makeglossaries -d '$dir' '$base_name'");
}