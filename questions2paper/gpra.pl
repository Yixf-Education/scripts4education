#!/usr/bin/env perl

use v5.10.1;

use strict;
use warnings;

#use utf8;
#binmode(STDIN, ':encoding(utf8)');
#binmode(STDOUT, ':encoding(utf8)');
#binmode(STDERR, ':encoding(utf8)');

use Getopt::Long;
use Pod::Usage;
use Config::General;
use File::Basename;
use File::Spec;
use List::Util qw(any shuffle);

# Default options
my $help        = 0;
my $man         = 0;
my $backup      = 1;
my $pdf         = 1;
my $a_or_b      = undef;
my $conf_file   = "paper.conf";
my $lib_dir     = "library";
my $snippet_dir = "snippets";
my $tex_file    = "paper.tex";
my $xelatex     = 0;
my $backup_dir  = "backups";

#my $backup_dir_snippet = "$backup_dir/snippets";

# Get options
GetOptions(
    'help|?|h'    => \$help,
    'man'         => \$man,
    'bak|b!'      => \$backup,
    'pdf|p!'      => \$pdf,
    'ab|a=s'      => \$a_or_b,
    'config|c=s'  => \$conf_file,
    'lib|l=s'     => \$lib_dir,
    'sinppet|s=s' => \$snippet_dir,
    'tex|t=s'     => \$tex_file,
    'xelatex|x!'  => \$xelatex
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;

if ($backup) {
    use Logfile::Rotate;
}

# Generate PDFs from existing TeXs
if ($xelatex) {
    my $paper = $ARGV[0] ? $ARGV[0] : "paper.tex";
    unless ( $paper =~ /\.tex$/ ) {
        $paper = $paper . ".tex";
    }
    my $paper_answer = $paper;
    $paper_answer =~ s/\.tex/_answers.tex/;
    &run_xelatex($paper);
    &run_xelatex($paper_answer);
    exit;
}

# Add the ".tex" suffix if the "$tex_file" does not have
unless ( $tex_file =~ /\.tex$/ ) {
    $tex_file = $tex_file . ".tex";
}

# Remove the "/" suffix if the "$lib_dir" have
$lib_dir =~ s/\/$//;

# Step-1: Make sure the "library" directory exist;
# Check the existence of "snippets" directory, make it if not
# Check the existence of backup directory, make it if not
&check_dir();

# Step0: Get all configures
# Step0.0: Parse the configure file
my $conf   = Config::General->new("$conf_file");
my %config = $conf->getall;

# Step0.1: Decide which class of the test paper is needed: paper A/B/...
my $paper_ab = &decide_ab();

# Step0.2: Parse other information (tixing/zhangjie/include/exclude/distribution/...)
$config{tixing} =~ s/\s+//g;
my @types = split /,/, $config{tixing};
my @chapters = &parse_number( "chapter", $config{zhangjie} );
my ( %include, %exclude );
if ( $config{include} ) {
    %include = &parse_clude( $config{include} );
}
if ( $config{exclude} ) {
    %exclude = &parse_clude( $config{exclude} );
}
my %distribution;
my %tmp = &parse_distribution();
if (%tmp) {
    %distribution = ( %distribution, %tmp );
}

# Step1: Check the information in configure file
&check_config_score();
&check_config_type();
&check_config_chapter();
&check_config_point();
&check_config_type_chapter();

# Step2: Get the library
# Step2.0: Collect questions for abjuan in the libaray
my %lib;
my @lib_files = <$lib_dir/*.tex>;
foreach my $lib_file (@lib_files) {

    # fileparse comes from File::Basename
    my ( $filename, $dirs, $suffix ) = fileparse( $lib_file, ".tex" );
    $lib{$filename} = 1;
}

# Step2.1: Only needed files are stored into %lib
# Keep questions for '$paper_ab', and delete others
# Keep questions for needed types and chapters, and delete others
&need_lib();

# Step2.2: Exclude the questions specified in the configure file
# Besides, collect warnings in modify_lib
my @warnings;
&modify_lib("exclude");

# Step2.3: Exclude the questions specified in 'include' in the configure file
# those question should be included back into '%lib' later
&modify_lib("include");

# Step2.4: Do some more checks
# Check for the existence and enough questions in the library
# NOT NEED NOW: this check is must between '&modify_lib("exclude")' and '&modify_lib("include")'
# This check exclude excluded questions (configured in include and exclude in configure file) because they have been deleted from the library
&check_lib_exist();
&check_lib_enough();

# Step3: Select questions randomly from the library
# Step3.0: This library has excluded the questions which should be included
my @questions_short;
foreach my $type (@types) {
    if ( %distribution
        && ( List::Util::any { $_ =~ /$type/ } keys %distribution ) )
    {
        foreach my $key_d ( sort keys %distribution ) {
            my ( $ab, $t, $c ) = split /_/, $key_d;
            if ( $t eq $type ) {
                my %lib_new;
                foreach my $key_l ( sort keys %lib ) {
                    if ( $key_l =~ /$key_d/ ) {
                        $lib_new{$key_l} = 1;
                    }
                }
                my @tc_shuffle = List::Util::shuffle( sort keys %lib_new );
                for ( my $i = 0 ; $i < $distribution{$key_d} ; $i++ ) {
                    push @questions_short, $tc_shuffle[$i];
                }
            }
        }
    }
    else {
        my %lib_new;
        foreach my $key ( sort keys %lib ) {
            if ( $key =~ /$type/ ) {
                $lib_new{$key} = 1;
            }
        }
        my @tcs_shuffle = List::Util::shuffle( sort keys %lib_new );
        for ( my $i = 0 ; $i < $config{$type}->{tishu} ; $i++ ) {
            push @questions_short, $tcs_shuffle[$i];
        }
    }
}

# Step3.1: Add included questions back
if (%include) {
    foreach my $question ( sort keys %include ) {
        push @questions_short, $question;
    }
}

# Step4: Get the full path for questions
my @questions_full;
foreach my $question (@questions_short) {
    push @questions_full,
      File::Spec->catfile( "$lib_dir", "$question" . ".tex" );
}

# Step5: Classify questions according to question types
my %questions_type;
foreach my $type (@types) {
    foreach my $q (@questions_full) {
        if ( $q =~ /$type\_/ ) {
            push @{ $questions_type{$type} }, $q;
        }
    }
}

# Step6: Generate the TeX configure file
# The name should not be changed, else you know how to do
my $tex_cfg_file = "TIJMUexam.cfg";
&generate_tex_cfg();

# Step7: Generate the snippets for each questions type
my @questions;
foreach my $type (@types) {
    @questions = sort @{ $questions_type{$type} };
    &generate_snippet( $type, \@questions );
}

# Step8: Generate the final TeX and PDF files
&generate_paper();

# Step9: Warn user for the warnings
if ( @warnings > 0 ) {
    print STDERR "\n\n";
    foreach my $warn (@warnings) {
        print STDERR "$warn";
    }
}

########## Start of subroutines ##########

#Check directorys for library and snippets
sub check_dir {
    unless ( -e $snippet_dir ) {
        mkdir "$snippet_dir", 0755
          or die "$0: failed to make directory '$snippet_dir': $!\n";
    }
    unless ( -e $lib_dir ) {
        die "For library: the directory '$lib_dir' does not exist!\n";
    }

    #if ($backup) {
    #unless ( -e $backup_dir ) {
    #mkdir "$backup_dir", 0755
    #or die "$0: failed to make directory '$backup_dir': $!\n";
    #}
    #unless ( -e $backup_dir_snippet ) {
    #mkdir "$backup_dir_snippet", 0755
    #or die "$0: failed to make directory '$backup_dir_snippet': $!\n";
    #}
    #}
}

sub decide_ab {
    my $ab;
    if ( defined $a_or_b ) {
        $ab = lc($a_or_b);
        return $ab;
    }
    elsif ( exists $config{abjuan} ) {
        if ( $config{abjuan} =~ /(\w)/ ) {
            $ab = lc($1);
            return $ab;
        }
        else {
            die
"For a_or_b (abjuan): Please check its format in the configure file: $conf_file!\n";
        }
    }
    else {
        die
"A or B, which test paper do you want? Please tell me in the '$conf_file' configure file, or by the '-a|--ab' option!\n";
    }
}

# Parse numbers in "1,2,3" or "1..3" or "1..3,5,7..9,11" format
# Here is the chapters (zhangjie, 章节) numbers
sub parse_number {
    my ( $string, $number_string ) = @_;
    my @numbers;
    $number_string =~ s/\s+//g;
    if ( $number_string =~ /^\d+$/ ) {
        push @numbers, $number_string;
        return @numbers;
    }
    elsif ( $number_string =~ /^\d+((,|\.{2})(\d+)?)+\d+$/ ) {
        my @tmp;
        if ( $number_string =~ /,/ ) {
            @tmp = split /,/, $number_string;
        }
        else {
            $tmp[0] = $number_string;
        }
        foreach my $tmp (@tmp) {
            if ( $tmp =~ /^(\d+)\.\.(\d+)$/ ) {
                push @numbers, $1 .. $2;
            }
            else {
                push @numbers, $tmp;
            }
        }
        return @numbers;
    }
    else {
        die
"Can not parse the numbers of '$string' in the configure file.\nOnly the integer and ',' and '..'(both in English version) can be used!\n";
    }
}

# Parse the [in|ex]clude in the configure file, save them into hash
sub parse_clude {
    my $ref = shift(@_);
    my %clude;
    if ( ref $ref eq "ARRAY" ) {
        foreach my $question ( @{$ref} ) {
            my %tmp = &filename_to_hash($question);
            %clude = ( %clude, %tmp );
        }
    }
    else {
        my %tmp = &filename_to_hash($ref);
        %clude = ( %clude, %tmp );
    }
    return %clude;
}

sub filename_to_hash {
    my $filename = shift(@_);
    $filename =~ s/\.tex$//;
    my @fields = split /_/, $filename;
    my %fn;
    if ( lc( $fields[0] ) eq $paper_ab ) {
        my $key = join "_", @fields[ 0 .. 3 ];
        $fn{$key} = 1;
        return %fn;
    }
}

# Parse the question distribution in chapters for each question type
sub parse_distribution {
    my %hash;
    foreach my $type (@types) {
        foreach my $chapter ( sort keys $config{$type} ) {
            if ( $chapter =~ /^\d+$/ ) {
                my $key = join "_", $paper_ab, $type, $chapter;
                $hash{$key} = $config{$type}->{$chapter};
            }
        }
    }
    return %hash;
}

# Check total score of the test paper, which should be equal to the sum of points for each question type (zongfen.testPaper=sum(zongfen.types))
sub check_config_score {
    my $sum;
    foreach my $type (@types) {
        $sum += $config{$type}->{zongfen};
    }
    unless ( $sum == $config{zongfen} ) {
        die
"For score: The sum of points for each question type does not equal to the total score of the test paper.\n";
    }
}

# Check the question types (tixing, 题型): each question type should have configure details
sub check_config_type {
    foreach my $type (@types) {
        unless ( exists $config{$type} ) {
            die
"For '$type': The details do not exist in the configure file: $conf_file.\n";
        }
    }
}

# Check chapters (zhangjie, 章节): the chapters in configure details for each question type should be in chapters defined in the configure file
sub check_config_chapter {
    foreach my $type (@types) {
        foreach my $key ( sort keys $config{$type} ) {
            if ( $key =~ /^\d+$/ ) {
                unless ( List::Util::any { $_ == $key } @chapters ) {
                    die
"For '$type': The chapter '$key' does not exist in '$config{zhangjie}' chapters.\n";
                }
            }
        }
    }
}

# Check points (zongfen=fen*tishu, 总分=小题分*题目数) for each question type
sub check_config_point {
    foreach my $type (@types) {
        unless ( $config{$type}->{zongfen} ==
            $config{$type}->{fen} * $config{$type}->{tishu} )
        {
            die
"For '$type': The result (point for each question times question number) does not equal to total points.\n";
        }
    }
}

# Check the question number (xiaotishu, 小题数) for each question type
sub check_config_type_chapter {
    foreach my $type (@types) {
        my $sum;
        foreach my $key ( sort keys $config{$type} ) {
            if ( $key =~ /^\d+$/ ) {
                $sum += $config{$type}->{$key};
            }
        }
        if ( defined $sum ) {
            unless ( $sum == $config{$type}->{tishu} ) {
                die
"For '$type': The sum of question number for chapters does not equal to the total question number.\n";
            }
        }
    }
}

# Keep needed questions in the library, and delete others
sub need_lib {
    foreach my $file ( sort keys %lib ) {
        $file = lc($file);
        unless ( $file =~ /^$paper_ab/ ) {
            delete $lib{$file};
        }
        my ( $ab, $t, $c, $s ) = split /_/, $file;
        unless ( List::Util::any { $_ eq $t } @types ) {
            delete $lib{$file};
        }
        unless ( List::Util::any { $_ eq $c } @chapters ) {
            delete $lib{$file};
        }
    }
}

# Exclude the questions configured in 'include'/'exclude'
# For 'include', should modify the distribution
sub modify_lib {
    my $string = shift(@_);
    my %clude;
    if ( $string eq "include" ) {
        %clude = %include;
        foreach my $key ( sort keys %clude ) {
            my ( $ab, $t, $c, $s ) = split /_/, $key;
            $config{$t}->{tishu} -= 1;
            my $k = join "_", $ab, $t, $c;
            if ( exists $distribution{$k} ) {
                $distribution{$k} -= 1;
            }
        }
    }
    if ( $string eq "exclude" ) {
        %clude = %exclude;
    }
    if (%clude) {
        foreach my $key ( sort keys %clude ) {
            if ( exists $lib{$key} ) {
                delete $lib{$key};
            }
            else {
                push @warnings,
"The $key configured in '$string' does not exist in the library. Please check it!\n";
            }
        }
    }
}

# Check library existence for question types and chapters
sub check_lib_exist {
    if (%lib) {
        my @tmp = sort keys %lib;
        my %type_lib;
        foreach my $tc (@tmp) {
            my ( $ab, $t, $c, $s ) = split /_/, $tc;
            $type_lib{$t} = 1;
        }
        foreach my $type (@types) {
            unless ( exists $type_lib{$type} ) {
                die
"There is no library for question type '$type' of paper type '$paper_ab', exit!\n";
            }
            if (%distribution) {
                foreach my $tc_d ( sort keys %distribution ) {
                    my ( $ab, $t, $c ) = split /_/, $tc_d;
                    unless ( List::Util::any { $_ =~ /^$tc_d/ } keys %lib ) {
                        die
"There is no library for 'chapter $c' of question type '$t' of paper type '$paper_ab', exit!\n";
                    }
                }
            }
        }
    }
    else {
        die "There is no library for paper type '$paper_ab', exit!\n";
    }
}

# Check library number for question types and chapters
sub check_lib_enough {
    my @tmp = sort keys %lib;
    my %type_lib;
    foreach my $tc (@tmp) {
        my ( $ab, $t, $c, $s ) = split /_/, $tc;
        $type_lib{$t}++;
    }
    foreach my $type (@types) {
        unless ( $type_lib{$type} >= $config{$type}->{tishu} ) {
            die
"For '$type': There is not enough questions in the library, own($type_lib{$type}) < need($config{$type}->{tishu})!\n";
        }
    }
    if (%distribution) {
        my %lib_tmp;
        foreach my $key ( sort keys %lib ) {
            my ( $ab, $t, $c, $s ) = split /_/, $key;
            my $key_new = join "_", $ab, $t, $c;
            $lib_tmp{$key_new}++;
        }
        foreach my $tc_d ( sort keys %distribution ) {
            my ( $ab, $t, $c ) = split /_/, $tc_d;
            my $lib_tmp_count = $lib_tmp{$tc_d};
            unless ( $lib_tmp_count >= $distribution{$tc_d} ) {
                die
"For '$t': There is not enough questions of 'chapter $c' in the library, own($lib_tmp_count) < need($distribution{$tc_d})!\n";
            }
        }
    }
}

# Generate the TeX configure file (TIJMUexam.cls)
sub generate_tex_cfg {
    my $O_file_name = $tex_cfg_file;
    open my $O, '>', $O_file_name
      or die "$0 : failed to open output file '$O_file_name' : $!\n";
    select $O;
    print "\\ProvidesFile{$tex_cfg_file}\n\n";
    print "\\def\\\@xuexiao{$config{xuexiao}}\n";
    print "\\def\\\@yearb{$config{yearb}}\n";
    print "\\def\\\@yeare{$config{yeare}}\n";
    print "\\def\\\@xueqi{$config{xueqi}}\n";
    print "\\def\\\@zhuanye{$config{zhuanye}}\n";
    print "\\def\\\@kecheng{$config{kecheng}}\n";
    print "\\def\\\@abjuan{$config{abjuan}}\n";
    print "\\def\\\@kaibijuan{$config{kaibijuan}}\n\n";
    print "\\def\\\@zongfen{$config{zongfen}}\n";
    print "\\def\\\@shijian{$config{shijian}}\n\n";

    foreach my $type (@types) {
        print "\\def\\\@$type\@zongfen{$config{$type}->{zongfen}}\n";
        print "\\def\\\@$type\@tishu{$config{$type}->{tishu}}\n";
        print "\\def\\\@$type\@fen{$config{$type}->{fen}}\n\n";
    }
    print "\\endinput";
    close $O or warn "$0 : failed to close output file '$O_file_name' : $!\n";
}

#Generate TeX snippets for each question type
sub generate_snippet {
    my ( $type, $question_ref ) = @_;
    my $O_file_type = File::Spec->catfile( "$snippet_dir",
        "$paper_ab" . "_" . "$type" . ".tex" );
    if ($backup) {
        &rotate_file($O_file_type);
    }
    open my $O, '>', $O_file_type
      or die "$0 : failed to open output file '$O_file_type' : $!\n";
    select $O;
    print "\\" . "$type\n\n";
    foreach my $question (@$question_ref) {
        print "\\input{$question}\n";
    }
    if ( $type =~ /xuan/ ) {
        my $O_file_table = File::Spec->catfile( "$snippet_dir",
            "$paper_ab" . "_" . "$type" . "_table" . ".tex" );
        if ($backup) {
            &rotate_file($O_file_table);
        }
        open my $OT, '>', $O_file_table
          or die "$0 : failed to open  output file '$O_file_table' : $!\n";
        &draw_choice_table( $type, $OT );
        close $OT
          or warn "$0 : failed to close output file '$O_file_table' : $!\n";
    }
    close $O or warn "$0 : failed to close output file '$O_file_type' : $!\n";
}

# Draw the answer table for the question type choice - single or multiple (xuanze - danxuan & duoxuan)
sub draw_choice_table {
    my ( $type, $fh ) = @_;
    my $step;
    if ( $type eq "danxuan" ) {
        $step = 10;
    }
    if ( $type eq "duoxuan" ) {
        $step = 5;
    }
    print $fh "\n\\begin{tabularx}{0.92\\textwidth}{|c|";
    print $fh "Y|" x $step;
    print $fh "}\n";
    print $fh "\\hline\n";
    my $count  = $config{$type}->{tishu};
    my $flag   = $count / $step;
    my $offset = 0;

    foreach my $tp (@types) {
        if ( $tp ne $type ) {
            $offset += $config{$tp}->{tishu};
        }
        else {
            last;
        }
    }

    my $counter;
    for ( my $i = 0 ; $i < $flag ; $i++ ) {
        print $fh "题号";
        my $start = $offset + $step * $i + 1;
        my $end = $offset + $step * ( $i + 1 );
        foreach my $i ( $start .. $end ) {
            $counter++;
            if ( $counter <= $config{$type}->{tishu} ) {
                print $fh " & $i";
            }
            else {
                print $fh " & ---";
            }
        }
        print $fh "\\" x 2;
        print $fh "\n";
        print $fh "\\hline\n";
        print $fh "答案";
        print $fh " &" x $step;
        print $fh "\\" x 2;
        print $fh "\n";
        print $fh "\\hline\n";
    }
    print $fh "\\end{tabularx}\n";
}

# Generate the final TeX files (with and without answers) for the test paper
# Add the A/B flag to the start of TeX files
sub generate_paper {
    my $fo_paper = $tex_file;
    $fo_paper =~ s/\./_${paper_ab}./;

    #my $fo_paper        = "$paper_ab" . "_" . "$tex_file";
    my $fo_paper_answer = $fo_paper;
    $fo_paper_answer =~ s/\.tex/_answers.tex/;
    if ($backup) {
        &rotate_file($fo_paper);
        &rotate_file($fo_paper_answer);
    }
    open my $OP, '>', $fo_paper
      or die "$0 : failed to open output file '$fo_paper' : $!\n";
    open my $OPA, '>', $fo_paper_answer
      or die "$0 : failed to open output file '$fo_paper_answer' : $!\n";

    #0 for without answers, 1 for with answers
    &paper_head( $OP,  0 );
    &paper_head( $OPA, 1 );
    my ( @items, %tables );
    foreach my $type (@types) {
        push @items, <$snippet_dir/$paper_ab\_$type.tex>;
        if ( $type =~ /xuan/ ) {
            $tables{$type} = "$snippet_dir/$paper_ab\_$type\_table.tex";
        }
    }
    print $OP "\\begin{questions}\n\n";
    print $OPA "\\begin{questions}\n\n";
    foreach my $item (@items) {
        &paper_body( $OP,  $item );
        &paper_body( $OPA, $item );

        #Add choice table for paper without answers
        my $bn = basename($item);
        $bn =~ s/\.tex//;
        my ( $ab, $type ) = split /_/, $bn;
        if ( $type =~ /xuan/ ) {
            print $OP "\\input{$tables{$type}}\n";
            print $OP "\n";
        }
    }
    print $OP "\\end{questions}\n\n";
    print $OPA "\\end{questions}\n\n";
    &paper_tail($OP);
    &paper_tail($OPA);
    close $OP or warn "$0 : failed to close output file '$fo_paper' : $!\n";
    close $OPA
      or warn "$0 : failed to close output file '$fo_paper_answer' : $!\n";
    if ($pdf) {
        &run_xelatex($fo_paper);
        &run_xelatex($fo_paper_answer);
    }
}

#Backup old files
sub rotate_file {
    my ($file) = shift(@_);
    if ( -e $file ) {
        my $log = new Logfile::Rotate( File => "$file", Dir => "$backup_dir" );
        $log->rotate();
    }
}

# Write the head for final TeX file
sub paper_head {
    my ( $fh, $answer ) = @_;
    if ($answer) {
        print $fh
"\\documentclass[printbox,marginline,adobefonts,answers]{TIJMUexam}\n\n";
    }
    else {
        print $fh
          "\\documentclass[printbox,marginline,adobefonts]{TIJMUexam}\n\n";
    }
    print $fh "\\begin{document}\n\n";
    print $fh "\\printml\n";
    print $fh "\\maketitle\n";
    print $fh "\n";
    print $fh "\\begin{framed}\n";
    print $fh "\\defen\n";
    print $fh "\n";
}

# Write the body (each question type) for final TeX file
sub paper_body {
    my ( $fh, $question ) = @_;
    print $fh "\\input{$question}\n";
    print $fh "\n";
}

# Write the tail for final TeX file
sub paper_tail {
    my ($fh) = shift(@_);
    print $fh
      "\\vspace{0.8\\textheight plus 0.2\\textheight minus 0.8\\textheight}\n";
    print $fh "\n";
    print $fh "\\end{framed}\n";
    print $fh "\n";
    print $fh "\\end{document}\n";
}

# Generate the final PDF files for the test paper
sub run_xelatex {
    my $file = shift(@_);
    my $log  = $file;
    $log =~ s/\.tex/.log/;
    my $aux = $file;
    $aux =~ s/\.tex/.aux/;
    system 'xelatex', $file;
    system 'xelatex', $file;
    system 'xelatex', $file;
    unlink $log;
    unlink $aux;
}

########## End of subroutines ##########

__END__

 

=head1 NAME
 
gpra.pl - Generate test paper randomly and automatically
 
=head1 SYNOPSIS
 
gpra.pl [options]

gpra.pl -x <TeX File>
 
 Options:
   -h                help message
   -m                full documentation
   -b [YES]          backup previous files
   -p [YES]          generate PDF files
   -a [undef]        test paper A/B
   -c [paper.conf]   configure file
   -l [library]      library directory 
   -s [snippets]     snippets directory 
   -t [paper.tex]    final TeX file
   -x                run xelatex
 
=head1 DESCRIPTION

gpra.pl (generate_paper_randomly_automatically.pl): Generate test paper (without & with answers) in TeX and PDF format, randomly and automatically. The steps are:

=over 4

=item 1

Read the configure file (specified by -c)

=item 2

Generate the TIJMUexam.cfg file

=item 3

Randomly select questions from library (specified by -l)

=item 4

Generate TeX snippets for each question type

=item 5

Generate the final test paper in TeX format (specified by -t)

=item 6

Generate the final test paper in PDF format

=back

There are several options to control it:
 
=over 8
 
=item B<-?, -h, --help>

Print a brief help message and exits.

=item B<-m, --man>
 
Prints the manual page and exits.

=item B<-b, --bak> B<[YES]>

Backup previous TeX files of snippets and papers (to 'backups' folder).

B<-nob, --no-bak> can be used to set it to B<NO>, when you do not want the backup, or you do not have Gzip, or the module Logfile::Rotate is not installed, ...
 
=item B<-p, --pdf> B<[YES]>

Generate the final PDF files for test papers.

B<-nop, --no-pdf> can be used to set it to B<NO>, when you do not want the PDF, or you do not have XeLaTeX, ... But you can generate PDFs using B<-x, --xelatex> option when you need them (since V3).
 
=item B<-a, --ab> B<[undef]>

Specify the class of test paper: A or B, and so on.

Generally, the class of test paper is specified in the configure file, but you can change it quickly by this option, without modifing the configure file. This option B<precede> the configure file!

=item B<-c, --config=FILE> B<[paper.conf]>

Configure file to guide this program.
 
=item B<-l, --lib=DIR> B<[library]>

Library directory containing all questions.
 
=item B<-s, --snippet=DIR> B<[snippets]>

Directory to store the snippets for each question type.
 
=item B<-t, --tex=FILE> B<[paper.tex]>

The TeX file name for final test paper.
 
=item B<-x, --xelatex> B<[NO]>

Run XeLaTeX on the existing TeX files to get the final PDFs.
 
=back
 
=head1 VERSION
 
V3 (20150628)
 Rewrite the whole script
 Add -x(--xelatex) option
 Files will be backuped to 'backups' folder
 Fix bugs:
   chapters configured in file is useless
   warnings when include/exclude is not configured
   some bugs I do not know ...
 Known bugs:
   only snippets will be backuped to specified folder, the main TeX files will not ...

V2 (20141215)

V1 (20141214)

=head1 AUTHOR

Yixf (Yi Xianfu), yixfbio@gmail.com, L<http://yixf.name/>
 
=cut


