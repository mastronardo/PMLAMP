#!/usr/bin/perl

$studentString = `sudo getent group | cut -f 3,4 -d : | grep 1002 | cut -f 2 -d :`; # ottengo la lista del gruppo 1002 (Studenti)
my @students = split (',', $studentString); # divido la stringa in un array

# creo il file di backup per ogni studente
foreach my $st (@students){
chomp($st);
$filename= "backup-". $st . "-'" . localtime() . "'.tar.gz";
system("sudo tar -cvzf /home/Lavori/.backup/" . $filename . " /home/Lavori/" . $st);
}
