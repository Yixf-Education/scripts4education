#!/usr/bin/env perl 
use strict;
use warnings;

#use utf8;
#use Data::Dumper;

use Getopt::Long;
use Pod::Usage;
use Config::General;
use File::Basename;
use File::Spec;
use List::Util qw(any shuffle);

#default options
my $help        = 0;
my $man         = 0;
my $backup      = 1;
my $pdf         = 1;
my $a_or_b      = undef;
my $conf_file   = "paper.conf";
my $lib_dir     = "library";
my $snippet_dir = "snippets";
my $tex_file    = "paper.tex";

#get options
GetOptions(
    'help|?|h'    => \$help,
    'man'         => \$man,
    'bak|b!'      => \$backup,
    'pdf|p!'      => \$pdf,
    'ab|a=s'      => \$a_or_b,
    'config|c=s'  => \$conf_file,
    'lib|l=s'     => \$lib_dir,
    'sinppet|s=s' => \$snippet_dir,
    'tex|t=s'     => \$tex_file
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitval => 0, -verbose => 2 ) if $man;

if ($backup) {
    use Logfile::Rotate;
}

#Add the ".tex" suffix if the "$tex_file" does not have
unless ( $tex_file =~ /\.tex$/ ) {
    $tex_file = $tex_file . ".tex";
}

#Step1: Get all configures
my $conf   = Config::General->new("$conf_file");
my %config = $conf->getall;

#Step2: Make sure "library" directory exist; check the exist of "snippets" directory, make it if not
&check_dir();

#Step3: Decide which test paper is needed: paper A or paper B
my $paper_ab = &decide_ab();

#Get the global arrays and hash
$config{tixing} =~ s/\s+//g;
my @types = split /,/, $config{tixing};
my @chapters     = &parser_number( "chapter", $config{zhangjie} );
my @include      = &parser_clude( $config{include} );
my @exclude      = &parser_clude( $config{exclude} );
my %distribution = &parser_distribution();

#Step4: Do some checks
&check_type();
&check_question_number();
&check_point();
&check_chapter();
&check_score();

#Step5: Get the library
#Only needed files are stored into %lib
my %lib;
my @lib_files = <$lib_dir/*.tex>;
my ( %lib_count_ab, %lib_count_type, %lib_count_chapter );
foreach my $lib_file (@lib_files) {
    my ( $filename, $dirs, $suffix ) = fileparse( $lib_file, ".tex" );
    my ( $ab, $type, $chapter, $seq ) = split /_/, $filename;
    if ( lc($ab) eq $paper_ab ) {
        $lib_count_ab{ lc($ab) }++;
        if ( List::Util::any { $_ eq $type } @types ) {
            $lib_count_type{ lc($ab) }->{$type}++;
            if ( List::Util::any { $_ eq $chapter } @chapters ) {
                $lib_count_chapter{ lc($ab) }->{$type}->{$chapter}++;
                $lib{$filename} = $lib_file;
            }
        }
    }
}

unless (%lib) {
    die "For 'a_or_b': There is no library for '$paper_ab', exit!\n";
}

#Clect warnings in modify_lib
my @warnings;
my %exclude_fullname = &modify_lib("exclude");

#Do some more checks
#Check for enough questions in the library, this check must is between '&modify_lib("exclude")' and '&modify_lib("include")'
#This check exclude excluded questions
&check_type_chapter;
my %include_fullname = &modify_lib("include");

#Step6: Shuffle the questions in the library to make them random
my @lib_shuffle = List::Util::shuffle( sort keys %lib );

#Step7: Select questions randomly
my %questions;
my %count;

#Firstly, exclude included questions
foreach my $type (@types) {
    if ( exists $distribution{$type} ) {
        foreach my $chapter ( sort keys $distribution{$type} ) {
            $count{$type}->{$chapter} = $distribution{$type}->{$chapter};
            if ( exists $include_fullname{$type}->{$chapter} ) {
                $count{$type}->{$chapter} -=
                  scalar( @{ $include_fullname{$type}->{$chapter} } );
            }
        }
    }
    else {
        $count{$type} = $config{$type}->{tishu};
        if ( exists $include_fullname{$type} ) {
            $count{$type} -= scalar( @{ $include_fullname{$type} } );
        }
    }
}

#Secondly, get the other questions
foreach my $filename (@lib_shuffle) {
    my ( $ab, $type, $chapter, $seq ) = split /_/, $filename;
    if ( exists $distribution{$type} ) {
        if (   ( exists $count{$type}->{$chapter} )
            && ( $count{$type}->{$chapter} > 0 ) )
        {
            push @{ $questions{$type} }, $lib{$filename};
            $count{$type}->{$chapter} -= 1;
        }
    }
    else {
        if ( $count{$type} > 0 ) {
            push @{ $questions{$type} }, $lib{$filename};
            $count{$type} -= 1;
        }
    }
}

#Finally, add included questions back
if ( @include > 0 ) {
    foreach my $type ( sort keys %include_fullname ) {
        if ( exists $distribution{$type} ) {
            foreach my $chapter ( sort keys $include_fullname{$type} ) {
                push @{ $questions{$type} },
                  @{ $include_fullname{$type}->{$chapter} };
            }
        }
        else {
            push @{ $questions{$type} }, @{ $include_fullname{$type} };
        }
    }
}

#Step 8: Generate the TeX configure file
#The name can not be changed, else you know how to do
my $tex_cfg_file = "TIJMUexam.cfg";
&generate_tex_cfg();

#Step 9: Generate the snippets for each questions type
foreach my $type (@types) {
    my @question = sort @{ $questions{$type} };
    &generate_snippet( $type, \@question );
}

#Step 10: Generate the final TeX and PDF files
&generate_paper();

#Warn user for the warnings
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
}

sub decide_ab {
    my $ab;
    if ( exists $config{abjuan} ) {
        if ( !( defined $a_or_b ) ) {
            if ( $config{abjuan} =~ /(\w)/ ) {
                $ab = lc($1);
            }
            else {
                die
"For a_or_b (abjuan): Please check its format in the configure file: $conf_file!\n";
            }
        }
        else {
            $ab = lc($a_or_b);
        }
    }
    else {
        if ( defined $a_or_b ) {
            $ab = lc($a_or_b);
        }
        else {
            die
"A or B, which test paper do you want? Please tell me in the '$conf_file' configure file, or by the '-a|--ab' option!\n";
        }
    }
    return $ab;
}

#Parse numbers in "1..3,5,7..9,11" format
#Here is the chapters (zhangjie, 章节) numbers
sub parser_number {
    my ( $string, $number_string ) = @_;
    $number_string =~ s/\s+//g;
    if ( $number_string =~ /^(\d|,|\.{2})+$/ ) {
        my @numbers;
        my @tmp = split /,/, $number_string;
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

#Parse the [in|ex]clude in the configure file, save them into array
sub parser_clude {
    my $ref = shift(@_);
    my @clude;
    if ( ref $ref eq "ARRAY" ) {
        foreach my $question ( @{$ref} ) {
            $question =~ s/\.tex$//;
            push @clude, $question;
        }
    }
    else {
        $ref =~ s/\.tex$//;
        push @clude, $ref;
    }
    return @clude;
}

#Parse the question distribution in chapters for each question type
sub parser_distribution {
    my %hash;
    foreach my $type (@types) {
        foreach my $chapter ( sort keys $config{$type} ) {
            if ( $chapter =~ /^\d+$/ ) {
                $hash{$type}->{$chapter} = $config{$type}->{$chapter};
            }
        }
    }
    return %hash;
}

#Check the question types (tixing, 题型)
sub check_type {
    foreach my $type (@types) {
        unless ( exists $config{$type} ) {
            die
"For '$type': The details do not exist in the configure file: $conf_file.\n";
        }
    }
}

#Check the question number (xiaotishu, 小题数) for each question type
sub check_question_number {
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

#Check points (zongfen=fen*tishu, 总分=小题分*题目数) for each question type
sub check_point {
    foreach my $type (@types) {
        unless ( $config{$type}->{zongfen} ==
            $config{$type}->{fen} * $config{$type}->{tishu} )
        {
            die
"For '$type': The result, point for each question times question number, does not equal to total points.\n";
        }
    }
}

#Check chapters (zhangjie, 章节)
sub check_chapter {
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

#Check total score of the test paper, which should be equal to the sum of points for each question type (zongfen.testPaper=sum(zongfen.types))
sub check_score {
    my $sum;
    foreach my $type (@types) {
        $sum += $config{$type}->{zongfen};
    }
    unless ( $sum == $config{zongfen} ) {
        die
"For score: The sum of points for each question type does not equal to the total score of the test paper.\n";
    }
}

#Generate the TeX configure file (TIJMUexam.cls)
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

#Exclude the items configured in 'include' and 'exclude', and get the full path for each question
sub modify_lib {
    my $string = shift(@_);
    my @clude;
    my %hash;
    if ( $string eq "include" ) {
        @clude = @include;
    }
    if ( $string eq "exclude" ) {
        @clude = @exclude;
    }
    if ( @clude > 0 ) {
        foreach my $question (@clude) {
            if ( exists $lib{$question} ) {
                delete $lib{$question};
                my ( $ab, $type, $chapter, $seq ) = split /_/, $question;
                my $clude_fullname =
                  File::Spec->catfile( "$lib_dir", "$question" . ".tex" );
                if ( exists $distribution{$type} ) {
                    push @{ $hash{$type}->{$chapter} }, $clude_fullname;
                }
                else {
                    push @{ $hash{$type} }, $clude_fullname;
                }
            }
            else {
#warn "The $ti configured in '$string' does not exist in the library. Please check it!\n";
                push @warnings,
"The $question configured in '$string' does not exist in the library. Please check it!\n";
            }
        }
    }
    return %hash;
}

sub check_type_chapter {
    my ( %number_type, %number_chapter, %number_type_chapter );
    foreach my $filename ( sort keys %lib ) {
        my ( $ab, $type, $chapter, $seq ) = split /_/, $filename;
        $number_chapter{$chapter}++;
        $number_type{$type}++;
        $number_type_chapter{$type}->{$chapter}++;
    }
    foreach my $chapter (@chapters) {
        unless ( exists $number_chapter{$chapter} ) {
            die
"For chapter: The 'chapter $chapter' does not exist in the library!\n";
        }
    }
    foreach my $type (@types) {
        unless ( $number_type{$type} >= $config{$type}->{tishu} ) {
            die
"For '$type': There is not enough questions in the library, own($number_type{$type}) < need($config{$type}->{tishu})!\n";
        }
        if ( exists $distribution{$type} ) {
            foreach my $chapter ( sort keys $distribution{$type} ) {
                unless ( $number_type_chapter{$type}->{$chapter} >=
                    $distribution{$type}->{$chapter} )
                {
                    die
"For '$type': There is not enough questions of 'chapter $chapter' in the library, own($number_type_chapter{$type}->{$chapter}) < need($distribution{$type}->{$chapter})!\n";
                }
            }
        }
    }
}

#Generate TeX snippets for each question type
sub generate_snippet {
    my ( $type, $question_ref ) = @_;
    my $O_file_name = File::Spec->catfile( "$snippet_dir",
        "$paper_ab" . "_" . "$type" . ".tex" );
    if ($backup) {
        &rotate_file($O_file_name);
    }
    open my $O, '>', $O_file_name
      or die "$0 : failed to open output file '$O_file_name' : $!\n";
    select $O;
    print "\\" . "$type\n\n";
    foreach my $question (@$question_ref) {
        print "\\input{$question}\n";
    }
    if ( $type =~ /xuan/ ) {
        &draw_choice_table($type);
    }
    close $O or warn "$0 : failed to close output file '$O_file_name' : $!\n";
}

#Backup old files
sub rotate_file {
    my $file = shift(@_);
    if ( -e $file ) {
        my $log = new Logfile::Rotate( File => "$file" );
        $log->rotate();
    }
}

#Draw the answer table for the question type choice - single or multiple (xuanze - danxuan & duoxuan)
sub draw_choice_table {
    my $type = shift(@_);
    my $step;
    if ( $type eq "danxuan" ) {
        $step = 10;
    }
    if ( $type eq "duoxuan" ) {
        $step = 5;
    }
    print "\n\\begin{tabularx}{0.92\\textwidth}{|c|";
    print "Y|" x $step;
    print "}\n";
    print "\\hline\n";
    print "题号";
    my $count = $config{$type}->{tishu};
    my $flag  = $count / $step;

    for ( my $i = 0 ; $i < $flag ; $i++ ) {
        my $start = $step * $i + 1;
        my $end = $step * ( $i + 1 );
        foreach my $i ( $start .. $end ) {
            print " & $i";
        }
        print "\\" x 2;
        print "\n";
        print "\\hline\n";
        print "答案";
        print " &" x $step;
        print "\\" x 2;
        print "\n";
        print "\\hline\n";
    }
    print "\\end{tabularx}\n";
}

#Generate the final TeX files (with and without answers) for the test paper
#Add the A/B flag to the start of TeX files
sub generate_paper {
    my $fo_paper        = "$paper_ab" . "_" . "$tex_file";
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
    my @items;
    foreach my $type (@types) {
        push @items, <$snippet_dir/$paper_ab\_$type.tex>;
    }
    foreach my $item (@items) {
        my $bn = basename($item);
        if ( $bn =~ /^$paper_ab/ ) {
            &paper_body( $OP,  $item );
            &paper_body( $OPA, $item );
        }
    }
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

#Write the head for final TeX file
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
    print $fh "\\printmlol\n";
    print $fh "\\maketitle\n";
    print $fh "\n";
    print $fh "\\begin{framed}\n";
    print $fh "\\defen\n";
    print $fh "\n";
}

#Write the body (each question type) for final TeX file
sub paper_body {
    my ( $fh, $question ) = @_;
    print $fh "\\begin{questions}\n";
    print $fh "\\input{$question}\n";
    print $fh "\\end{questions}\n";
    print $fh "\n";
}

#Write the tail for final TeX file
sub paper_tail {
    my ($fh) = shift(@_);
    print $fh "\\end{framed}\n";
    print $fh "\n";
    print $fh "\\end{document}\n";
}

#Generate the final PDF files for the test paper
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

Backup previous TeX files of snippets and papers.

B<-nob, --no-bak> can be used to set it to B<NO>, when you do not want the backup, or you do not have Gzip, or the module Logfile::Rotate is not installed, ...
 
=item B<-p, --pdf> B<[YES]>

Generate the final PDF files for test papers.

B<-nop, --no-pdf> can be used to set it to B<NO>, when you do not want the PDF, or you do not have XeLaTeX, ...
 
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
 
=back
 
=head1 VERSION
 
V1 (20141214)

=head1 AUTHOR

Yixf (Yi Xianfu), yixfbio@gmail.com, L<http://yixf.name/>
 
=cut


